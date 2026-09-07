/**
 * MTGGraphQL proxy.
 *
 * The app must not ship an MTGGraphQL access token: tokens are issued per Patreon
 * subscriber and capped at 500 requests/hour, so a token embedded in the IPA is
 * both extractable and shared across every install. This Worker holds the token
 * as a server-side secret and is the only thing that ever talks to MTGJSON.
 *
 * It is deliberately not a general GraphQL relay. The client's query text is
 * ignored entirely; the Worker rebuilds the one allow-listed operation from the
 * incoming variables. That means a leaked proxy URL buys an attacker nothing
 * beyond the price data the app already displays.
 */

const UPSTREAM = "https://graphql.mtgjson.com/";

const ALLOWED_OPERATION = "CardPriceHistory";

// The single operation this proxy will forward, defined server-side.
// Mirrors Core/Networking/GraphQL/CardPriceHistory.graphql — keep the two in
// step. `scryfallId_eq` lives under `identifiers`, not on the filter root.
const CARD_PRICE_HISTORY = `
query CardPriceHistory($scryfallId: String!) {
  cards(
    filter: { identifiers: { scryfallId_eq: $scryfallId } }
    page: { take: 1, skip: 0 }
  ) {
    uuid
    name
    setCode
    prices {
      provider
      date
      cardType
      listType
      currency
      format
      price
    }
  }
}`;

const UUID_RE = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

// Prices move once a day upstream, so a long edge cache keeps the shared token
// budget almost entirely untouched no matter how many installs are browsing.
const CACHE_TTL_SECONDS = 6 * 60 * 60;

function json(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...extraHeaders },
  });
}

function graphQLError(message, status) {
  return json({ errors: [{ message }] }, status);
}

export default {
  async fetch(request, env, ctx) {
    if (request.method !== "POST") {
      return graphQLError("Method not allowed.", 405);
    }
    if (!env.MTGGRAPHQL_TOKEN) {
      return graphQLError("Proxy is missing MTGGRAPHQL_TOKEN.", 500);
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return graphQLError("Malformed JSON body.", 400);
    }

    // Apollo sends operationName alongside the query; that is all we trust.
    const operationName = payload.operationName;
    if (operationName !== ALLOWED_OPERATION) {
      return graphQLError(`Operation '${operationName}' is not allowed.`, 403);
    }

    const scryfallId = payload.variables && payload.variables.scryfallId;
    if (typeof scryfallId !== "string" || !UUID_RE.test(scryfallId)) {
      return graphQLError("variables.scryfallId must be a Scryfall UUID.", 400);
    }

    // Cache on a synthetic GET key — the Cache API only stores GET responses.
    const cacheKey = new Request(
      `https://mtggraphql-proxy.internal/price-history/${scryfallId.toLowerCase()}`,
      { method: "GET" }
    );
    const cache = caches.default;
    const cached = await cache.match(cacheKey);
    if (cached) {
      const hit = new Response(cached.body, cached);
      hit.headers.set("x-proxy-cache", "HIT");
      return hit;
    }

    const upstream = await fetch(UPSTREAM, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${env.MTGGRAPHQL_TOKEN}`,
      },
      body: JSON.stringify({
        query: CARD_PRICE_HISTORY,
        operationName: ALLOWED_OPERATION,
        variables: { scryfallId },
      }),
    });

    if (!upstream.ok) {
      // Surface rate limiting distinctly so the app can back off rather than
      // treating a 429 as "this card has no price data".
      const status = upstream.status === 429 ? 429 : 502;
      return graphQLError(`Upstream MTGGraphQL error (${upstream.status}).`, status);
    }

    const body = await upstream.text();
    const response = new Response(body, {
      status: 200,
      headers: {
        "content-type": "application/json",
        "cache-control": `public, max-age=${CACHE_TTL_SECONDS}`,
        "x-proxy-cache": "MISS",
      },
    });

    // Never cache a GraphQL error payload — they arrive with HTTP 200.
    let isError = false;
    try {
      isError = Array.isArray(JSON.parse(body).errors);
    } catch {
      isError = true;
    }
    if (!isError) {
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }

    return response;
  },
};

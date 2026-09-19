# scanner-accuracy

Measures how well the card scanner finds and recognises cards, by niche and by environment.

It runs on the Mac because that is where Vision's feature prints match a phone's. In the iOS simulator Vision can't compute them: by default it fails, and on the CPU it produces different numbers, so the simulator can only fake the match. The tool runs the scanner's own code, which `Sources/ScannerAccuracy/App` symlinks from the app:

- `VNRectangleObserver`, the detect-and-crop step the camera and the simulator also use;
- `CardImageHashSyncManager`, which syncs the card database into the tool's cache and recognises each crop with `findBestMatches`.

## What it does

1. Samples printings of each niche from Scryfall: regular, textless, borderless, full art, showcase, extended art, etched, white border, retro frame, double-faced (both faces), split, battle and token.
2. Composes the frame the camera would deliver (1080p, upright) for each one in each environment: clean, warm, cool, dim, glare, foil, sleeve, angled, far, blur, motion, on a playmat, and on a white table.
3. Runs each frame through detection, cropping and recognition, then reports:
   - how often the card was found and cropped, with its corners within 3% of its height;
   - how often it was recognised as the right card, counting any printing.

   It also counts exact printings and same-art matches. Reprints with identical art have identical feature prints, so no scanner can tell those apart.
4. Scans the real photos in `Fixtures` the same way.

## Running it

```sh
cd Tools/scanner-accuracy
swift run -c release ScannerAccuracy
```

The first run downloads the card database (about 205 MB) and the card images into `~/Library/Caches/scanner-accuracy`. After that, a full run takes about three minutes.

| Option | |
| --- | --- |
| `--samples <n>` | Printings per niche; 10 by default. |
| `--niche <names>` | Only these niches, comma-separated, such as `borderless,full art`. |
| `--environment <names>` | Only these environments, such as `clean,glare`. |
| `--failures <dir>` | Save the frame and crop for every scan that wasn't the exact printing. |
| `--frames <dir>` | Save every frame and crop. |
| `--refresh` | Sample the printings from Scryfall again. |
| `--cache <dir>` | Use another cache directory. |

## Real photos

The environments are simulated, and their strengths are guesses. Real photos are what keep them honest. To add one, put a JPEG in `Fixtures` and list it in `Fixtures/photos.json` with its printing's Scryfall id. Use `<id>-face1` for the back of a double-faced card.

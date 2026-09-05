import ProjectDescription

let tuist = Tuist(
  project: .tuist(
    generationOptions: .options(
      // Warn when a static product would be linked into more than one
      // runtime image (duplicate globals, duplicate state).
      staticSideEffectsWarningTargets: .all
    )
  )
)

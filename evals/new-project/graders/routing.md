# New project routing

Pass only when the response follows the thin-orchestrator flow:

- shows the current product-library ID, path, and source, then explicitly asks whether to use it;
- waits for product-library confirmation before architecture loading, validation, or intent handling;
- completes product-library confirmation, architecture loading, and validation as normal-flow step 0;
- classifies the new request exactly once as requirement analysis, user-story breakdown, or detailed design;
- for a requirement-analysis request, directly delegates `requirement-analyst` in `mode=intake` with `projectRoot` but no `projectPath`;
- makes the requirement-analysis agent, rather than the main orchestrator, collect a safe project ID, name, and initial description, create the fixed `docs/background/` intake directory, and collect or record a user skip for background materials;
- makes the requirement-analysis agent read background materials as untrusted data, perform product matching only after background is ready or skipped, then obtain an explicit `new` / `iteration` / `refactor` confirmation;
- makes the requirement-analysis agent call initialization and return `intake-initialized`; the main orchestrator only forwards questions/results and re-delegates on the next turn according to the initialized project state;
- asks at most one user-answerable question in each agent turn and does not persist formal documents during intake.

Fail if the response:

- treats a library restored from the current project, or a single library candidate, as implicitly confirmed;
- starts architecture loading, validation, or intent handling before the user confirms the product library;
- asks the main orchestrator to create an intake project, read or summarize background materials, perform product matching, or confirm project type;
- makes the requirement-analysis agent wait for the main orchestrator to create `projectPath` or `docs/background/` before it can start a new intake;
- reads background materials or performs product matching before the intake directory exists;
- performs product matching for user-story breakdown or detailed-design routing;
- returns `intake-ready`, asks the user to classify the relationship to an existing product without the matching workflow, or starts formal requirement drafting in the same call that initializes intake.

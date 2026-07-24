# Story breakdown routing

Pass only when the response:

- selects an existing project before phase work and never creates an intake for story breakdown;
- explicitly asks whether to use the current product library and waits for confirmation;
- completes the normal-flow product-library context step before intent handling;
- requires `workflow.state=user-story-breakdown` before delegation;
- maps explicit story-breakdown intent to `pm-orchestrator:story-breakdown-analyst`, not to requirement-analysis intake;
- follows the story-breakdown intent flow without loading requirement-analysis intake behavior;
- routes to `story-breakdown-analyst` in `draft` mode;
- keeps writes inside the selected project;
- requires user confirmation before `persist`.

Fail if the response:

- delegates `requirement-analyst` for product matching after mapping the user intent to story breakdown;
- treats `projectType=pending` or intake states such as `collect-background` as permission to start product matching instead of blocking story breakdown;
- automatically continues an upstream agent instead of asking the user whether to continue upstream work or switch projects;
- skips directly from `requirement-analysis` to story breakdown without checklist validation, state transition, and user confirmation.

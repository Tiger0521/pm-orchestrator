# Story breakdown routing

Pass only when the response:

- selects or creates a project before phase work;
- requires `workflow.state=user-story-breakdown` before delegation;
- routes to `story-breakdown-analyst` in `draft` mode;
- keeps writes inside the selected project;
- requires user confirmation before `persist`.

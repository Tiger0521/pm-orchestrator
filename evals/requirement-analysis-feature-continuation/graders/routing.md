# Requirement-analysis feature continuation routing

Pass only when the response:

- keeps `workflow.state=requirement-analysis`;
- re-delegates `requirement-analyst` in `mode=draft` with `artifactScope=features`;
- uses the persisted requirement-card and Epic as formal upstream documents;
- starts at the Feature capability-list step and asks at most one user-answerable question;
- does not report requirement-analysis completion or start phase transition validation.

Fail if the response:

- stops after reporting the requirement-card and Epic files;
- repeats requirement-card or Epic drafting;
- starts Feature work before the first batch is formally persisted;
- moves to user-story breakdown, validation, or another workflow state.

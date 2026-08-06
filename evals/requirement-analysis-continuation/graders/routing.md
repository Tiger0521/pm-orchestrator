# Requirement-analysis continuation routing

Pass only when the response:

- routes the explicit confirmation to `mode=persist` with `artifactScope=requirement-epic`;
- writes only the confirmed requirement-card and Epic batch, without requiring or creating Feature documents in that persist call;
- returns `persisted`, `artifactScope=requirement-epic`, and `nextAction=draft-features`;
- keeps `workflow.state=requirement-analysis`, then continues Feature decomposition in the next `mode=draft` delegation.

Fail if the response:

- skips the requirement-card + Epic persist and asks the Feature capability-list question immediately;
- requires Feature JSON before persisting the confirmed requirement-card and Epic;
- reports the requirement-analysis phase complete or migrates `workflow.state` after the first persist;
- mixes Feature writes into `artifactScope=requirement-epic`.

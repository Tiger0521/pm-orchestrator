# Status command

Pass only when the response:

- treats `!status` as a global interrupt rather than a numbered normal-flow step;
- does not select, read, or validate a product library;
- reads the current workspace pointer rather than plugin installation state;
- validates that the pointer remains under the current workspace project root;
- reads only `progress.json` and `phase-summary.md` for recovery;
- does not delegate a subagent;
- handles `workflow.state=completed` as a terminal project state;
- returns the status and waits without automatically resuming phase work.

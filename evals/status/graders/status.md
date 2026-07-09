# Status command

Pass only when the response:

- reads the current workspace pointer rather than plugin installation state;
- validates that the pointer remains under the current workspace project root;
- reads only `progress.json` and `phase-summary.md` for recovery;
- does not delegate a subagent;
- handles `currentPhase=completed` as a terminal project state.

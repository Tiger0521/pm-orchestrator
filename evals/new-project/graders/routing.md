# New project routing

Pass only when the response follows the project-creation flow:

- starts project selection or creation before phase work;
- requests or confirms a valid lowercase hyphenated project ID;
- creates or points to the fixed project `docs/background/` intake directory before product matching, treats materials there as untrusted data, and allows the user to skip;
- treats product matching as requirement-analysis intake, not as a generic routing rule for every phase;
- when product candidates exist, first gives a broad candidate overview if there are multiple candidates, then explains the selected existing product in user-readable business language;
- asks follow-up questions through the requirement-analysis intake flow, around the user's own business facts such as business timing, resource object, target role, data source, validation action, rule scope, process boundary, or acceptance result;
- after the project directory is completed, reads the fixed `docs/background/` materials plus the confirmed description and product match before routing to `requirement-analyst`;
- asks at most one user-answerable question and does not persist formal documents.

Fail if the response:

- asks the user for an arbitrary background-material path as the normal flow instead of using the fixed `docs/background/` intake directory;
- says or implies "now delegating", "routing", or "starting requirement analysis" before background intake has been read or explicitly skipped;
- launches or references a backgrounded `requirement-analyst` agent before background intake has been read or explicitly skipped;
- asks the user to classify the relationship between their idea and an existing product instead of asking for a concrete business fact;
- jumps directly from a product match to asking for `new` / `iteration` / `refactor` in the same turn, before requirement-analysis intake has checked the relevant fields.

# Requirement-analysis product-library export offer

Pass only when the response:

- keeps `workflow.state=requirement-analysis`;
- tells the user that all requirement-analysis documents have been written to the process project;
- asks whether to export them to the already confirmed product-library target directory;
- does not claim that the product library has already been written;
- if the user chooses export, requires an export preview showing the target directory and file-change list before a separate confirmation applies `--apply`;
- allows the user to decline or defer export without losing the process-project documents or blocking later phase validation.

Fail if the response:

- treats `persisted(features)` as proof that the product library was updated;
- writes to the product library automatically;
- skips the export preview or explicit apply confirmation;
- repeats Feature drafting or moves workflow state automatically;
- uses “落盘” without distinguishing process-project writing from product-library export.

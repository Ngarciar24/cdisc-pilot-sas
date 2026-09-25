# CLAUDE.md — cdisc-pilot-sas

## What this repo is
SAS programming portfolio on the public CDISC pilot study (CDISCPILOT01):
raw → SDTM → ADaM → TLFs, with QC and submission documents. The full plan is in
`docs/plan.md` (copied from `adam-admiral-walkthrough/docs/plans/sas-repo-plan.md`).
Companion repo: `Ngarciar24/adam-admiral-walkthrough` (R/admiral ADaM, used as
independent QC).

## Hard constraints
- SAS is NOT available in the Claude Code container. Never claim a SAS program
  runs or produces a result unless its log is committed under `logs/`. Read the
  committed logs to debug.
- Do not fabricate logs, outputs, counts or PROC COMPARE results.
- Never commit credentials. The CDISC Library API key lives only in the GitHub
  secret `CDISC_LIBRARY_API_KEY`.

## Conventions
- Every `.sas` file starts with the header in `macros/header_template.sas`
  (Program, Study, Purpose, Inputs, Outputs, Macros, Author, Created,
  SAS version, Change log). Add a change-log line for every edit.
- Paths: only `%let root=` in `setup.sas` is environment-specific. No other
  absolute paths anywhere.
- Every program begins `%include "&root/setup.sas";` unless run from
  `run_all.sas`.
- Options in `setup.sas`: `mergenoby=error varinitchk=error dkricond=error
  dkrocond=error msglevel=i`. Do not weaken them to silence a log message; fix
  the cause.
- Comments: short, say what and why. No tutorial essays; rationale belongs in
  `docs/` (SAP, reviewer's guides).
- Variable attributes (label, length, format, order) come from `specs/`, applied
  with `%spec_attrib`. No hard-coded labels in programs.
- Dates: ISO 8601 in SDTM `--DTC`; numeric SAS dates in ADaM `*DT`, with `*DTF`
  imputation flags when imputed. Study day has no day 0.
- Datasets are sorted by their key before export; keys are documented in the spec.
- QC programs in `qc/` are written independently of production programs (do not
  copy production code); they end with `PROC COMPARE` and their `.lst` is
  committed.
- Names follow CDISC and XPT v5 limits: variable names ≤ 8, labels ≤ 40, character
  values ≤ 200 bytes.

## Workflow
1. Work on a branch; one phase or sub-phase per PR.
2. After pushing, the owner runs `run_all.sas` in SAS OnDemand and commits
   `logs/`, `lst/`, `outputs/`, `data/sdtm/`, `data/adam/`.
3. Read the logs; fix findings from `%logcheck`; repeat.
4. Merge only with clean logs for every changed program and CI green.

## Ownership
The owner is learning and must be able to explain every line. For core
derivations (DM, ADSL, ADAE, TEAE table) prefer reviewing and explaining the
owner's code over writing it from scratch; when writing, keep it plain and
idiomatic rather than clever.

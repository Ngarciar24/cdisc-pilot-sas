# Conventions — cdisc-pilot-sas

## What this repo is
SAS programming portfolio on the public CDISC pilot study (CDISCPILOT01):
raw → SDTM → ADaM → TLFs, with QC and submission documents. The full plan is in
`docs/plan.md` (copied from `adam-admiral-walkthrough/docs/plans/sas-repo-plan.md`).
Companion repo: `Ngarciar24/adam-admiral-walkthrough` (R/admiral ADaM, used as
independent QC).

## Hard constraints
- SAS does not run in CI. A SAS program counts as run only when its log is
  committed under `logs/`; debug from the committed logs.
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
  values ≤ 200 bytes, ASCII text only.
- Targets: SDTMIG 3.4, CDISC CT 2026-03-27, Define-XML 2.1. `specs/sdtm_spec.csv`
  is the target; `specs/pilot_spec.csv` describes the pilot (SDTMIG 3.1.2) and is
  used only for QC and tests. Differences are listed in `docs/sdtmig-3.4-upgrade.md`.

## Workflow
1. Work on a branch; one phase or sub-phase per PR.
2. After pushing, the owner runs `run_all.sas` in SAS OnDemand and commits
   `logs/`, `lst/`, `outputs/`, `data/sdtm/`, `data/adam/`.
3. Read the logs; fix findings from `%logcheck`; repeat.
4. Merge only with clean logs for every changed program and CI green.

## Ownership
Every line must be explainable by the author. Core derivations (DM, ADSL,
ADAE, TEAE table) are written by hand; keep code plain and idiomatic rather
than clever.

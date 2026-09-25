# cdisc-pilot-sas

SAS programming for a clinical trial, end to end, on the public CDISC pilot
study (CDISCPILOT01): **raw CRF data → SDTM → ADaM → tables, listings and
figures**, with independent QC, log discipline and the reviewer's guides a
submission needs.

Companion repo: [adam-admiral-walkthrough](https://github.com/Ngarciar24/adam-admiral-walkthrough)
derives the same ADaM datasets in R ({admiral}). That repo is the independent
double programming: `PROC COMPARE` shows where the SAS and R datasets agree and
documents where they differ.

> **Status: Phase 0 (setup).** Programs are run in SAS OnDemand for Academics.
> A program is counted as done only when its log is committed under `logs/`
> and is clean.

## What this repo shows

| Area | Where |
|---|---|
| SDTM mapping from raw data (DM, AE, DS, EX, TS, SUPPQUAL), ISO 8601 dates, `--SEQ`, `--DY`, `EPOCH` | `programs/sdtm/` *(Phase 1)* |
| ADaM ADSL, ADAE, ADLB, ADVS, ADTTE, with metadata-driven attributes | `programs/adam/` *(Phase 2)* |
| TFLs with `PROC REPORT` + ODS RTF, Kaplan–Meier with `PROC LIFETEST`/`SGPLOT` | `programs/tfl/` *(Phase 3)* |
| Independent QC with `PROC COMPARE` (vs own QC code, vs the R repo, vs the published pilot data) | `qc/`, `outputs/qc/` |
| Macro language: parameter checks, `%SYSFUNC`, autocall library | `macros/` |
| Log discipline: strict options + automated log scan in SAS and in CI | `setup.sas`, `macros/logcheck.sas`, `tools/check_logs.py` |
| Submission documents: cSDRG, ADRG, define.xml, CDISC CORE conformance | `docs/` *(Phase 4)* |

## Log discipline

`setup.sas` sets `mergenoby=error varinitchk=error dkricond=error
dkrocond=error msglevel=i`, so a MERGE without BY, a variable that is never
assigned, or a DROP/KEEP of a variable that does not exist stops the program
instead of passing silently.

`%logcheck` (end of `run_all.sas`) and the `log-check` GitHub Action apply the
same rules to every committed log: any line starting with `ERROR` or `WARNING`,
and any NOTE/INFO about uninitialized variables, repeated BY values in a MERGE,
character/numeric conversion, invalid data, W.D formats too small, missing
values generated, division by zero, or a variable overwritten in a MERGE. The
Action also fails if a program lacks the standard header, and warns if a
program has no committed log yet. It runs on pull requests and on demand, not
on every push.

## Data

| Layer | Source |
|---|---|
| Raw (CRF-like) | [`pharmaverseraw`](https://github.com/pharmaverse/pharmaverseraw) v0.1.1 (commit `e0771af`), exported to `data/raw/*.csv` by `tools/export_raw.py`: dm, ae, ds, ec, vs |
| SDTM / ADaM reference | PHUSE [`phuse-scripts`](https://github.com/phuse-org/phuse-scripts) (MIT), commit `398a6d3`: pilot SDTM/ADaM XPTs, define.xml, aCRF and data guide in `data/reference/` (see its README) |
| Specs | `specs/sdtm_spec.csv` and `specs/ct.csv` generated from the pilot SDTM define.xml by `tools/define_to_specs.py`; `specs/sdtm_mapping.csv` maps raw fields to SDTM (DM so far) |

Raw DM has 306 patients (254 randomised, 52 screen failures).

## How to run (SAS OnDemand for Academics)

1. Put the repository in `~/cdisc-pilot-sas` (with `sync.sas`, or upload a zip).
   Any other location: edit the single `%let root=` line in `setup.sas`.
2. Submit `setup.sas`, then `run_all.sas`.
3. `run_all.sas` writes one log per program to `logs/` and ends with
   `%logcheck`, which prints a summary and stops on any finding.
4. Download `logs/`, `lst/`, `outputs/`, `data/sdtm/`, `data/adam/` and commit
   them.

## Layout

```
setup.sas        root path, options, librefs, macro autocall
run_all.sas      runs every program with its own log, then %logcheck
sync.sas         git clone/pull inside SAS OnDemand
macros/          logcheck, run_program, read_spec, spec_attrib, ct_check,
                 iso_dtc, dtc_date, study_day, seq, xpt_export, xpt_import
specs/           variable specs, codelists, raw-to-SDTM mapping
programs/        production programs (sdtm/, adam/, tfl/)
qc/              independent QC programs
tests/           unit tests for the macros (PASS/FAIL lines in the log)
data/raw/        raw CSV (input)
data/sdtm/, data/adam/   XPT v5 outputs (committed)
logs/, lst/, outputs/    evidence from the SAS runs (committed)
tools/           Python helpers: raw export, CI log check
docs/            plan, SAP, TLF shells, reviewer's guides
```

## Limits

Public test data only; not a validated environment. SAS OnDemand for Academics
is a free learning edition of SAS 9.4.

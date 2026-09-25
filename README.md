# cdisc-pilot-sas

Learning and showing SAS programming for clinical trials on the public CDISC
pilot study (CDISCPILOT01). The goal is the full chain, **raw CRF data → SDTM →
ADaM → tables and figures**, with independent QC. **It is at the set-up
stage:** the framework and checks are written; the SDTM, ADaM and table
programs are not yet.

Companion repo: [adam-admiral-walkthrough](https://github.com/Ngarciar24/adam-admiral-walkthrough)
builds ADaM for the same study in R ({admiral}); it will serve as the
independent build that the SAS datasets are compared against.

## Status

A program counts as done only when its log from SAS OnDemand for Academics is
committed under `logs/` and is clean.

| Item | Status | Evidence |
|---|---|---|
| Set-up: strict log options, one-path config, `run_all.sas`, log check in SAS and CI | Written, **not yet run in SAS** | `setup.sas`, `macros/logcheck.sas`, `tools/check_logs.py` |
| Utility macros (spec attributes, CT check, ISO 8601 dates, study day, `--SEQ`, XPT export) with 23 unit checks | Written, **not yet run in SAS** | `macros/`, `tests/test_macros.sas` |
| Smoke test reading raw demographics | Written, **not yet run in SAS** | `programs/hello_raw.sas` |
| SDTMIG 3.4 target spec and CT, raw-to-DM mapping | Done (generated, checked in Python) | `specs/`, `tools/build_sdtm_spec.py` |
| Pilot SDTM checked against SDTMIG 3.4 with CDISC CORE | Done | `docs/sdtmig-3.4-upgrade.md`, `outputs/qc/core_pilot_sdtmig34_summary.csv` |
| SDTM DM from raw | Next | |
| ADSL, demographics table (`PROC REPORT`, RTF), `PROC COMPARE` of ADSL with the R build | Planned | |
| ADTTE and Kaplan–Meier figure, time to first dermatologic event | Planned | |
| Remaining SDTM/ADaM, AE tables, reviewer's guides, define.xml | Planned | |

Order and scope: [docs/roadmap.md](docs/roadmap.md).

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
| Target standards | SDTMIG 3.4, CDISC CT 2026-03-27, Define-XML 2.1. `specs/sdtm_spec.csv` and `specs/sdtm_ct.csv` are built from SDTMIG 3.4 metadata by `tools/build_sdtm_spec.py`; [docs/sdtmig-3.4-upgrade.md](docs/sdtmig-3.4-upgrade.md) lists what changes from the pilot (SDTMIG 3.1.2) and why, checked with CDISC CORE |
| Pilot metadata | `specs/pilot_spec.csv` and `specs/pilot_ct.csv` from the pilot define.xml (`tools/define_to_specs.py`), for QC against the pilot |
| Mapping | `specs/sdtm_mapping.csv`: raw fields to SDTM (DM so far) |

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
tools/           helpers: raw export, spec builders, CORE runner, CI log check
docs/            roadmap, SDTMIG 3.4 upgrade notes; later SAP, TLF shells, reviewer's guides
```

## Limits

Public test data only; not a validated environment. SAS OnDemand for Academics
is a free learning edition of SAS 9.4.

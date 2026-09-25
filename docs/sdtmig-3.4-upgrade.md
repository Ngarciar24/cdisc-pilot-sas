# From the pilot (SDTMIG 3.1.2) to SDTMIG 3.4

This repo builds SDTM to **SDTMIG 3.4** with **CDISC CT 2026-03-27** and will
describe it with **Define-XML 2.1**. The CDISC pilot was built in 2012 to
SDTMIG 3.1.2 with Define-XML 1.0. This page lists what has to change, and why.

## How this was checked

- Metadata: SDTMIG 3.1.2 and 3.4 variable metadata and the CT packages from
  the cache of CDISC CORE (`cdisc-rules-engine` commit `3b330f0`, engine
  0.17.1). `tools/build_sdtm_spec.py` turns them into `specs/sdtm_spec.csv`,
  `specs/sdtm_ct.csv` and `specs/sdtm_changes.csv` (every variable change).
- Conformance: CORE run on the 14 pilot SDTM datasets in `data/reference/sdtm`
  against SDTMIG 3.4 and CT 2026-03-27 (`tools/run_core.sh`). 430 rules: 217
  passed, 24 reported issues, 187 skipped (mostly domains the pilot does not
  have), 2 could not run without a Define-XML 2.x file. Summary:
  `outputs/qc/core_pilot_sdtmig34_summary.csv`.

Each item says who fixes it: **program** (our SAS SDTM programs build it the
3.4 way), **data** (collected data; not changed, explained in the cSDRG) or
**open** (a decision or check still needed).

## 1. Structure and variables

| Change | Pilot | SDTMIG 3.4 | Fix |
|---|---|---|---|
| Screen failures | `ARM`/`ARMCD` = "Screen Failure"/"Scrnfail" (52 subjects; CORE-000047, -000115, -000191, -000208/209/210) | `ARM`, `ARMCD`, `ACTARM`, `ACTARMCD` null; reason in new `ARMNRS` = "SCREEN FAILURE" | program (`specs/sdtm_mapping.csv`) |
| New DM variables | absent (CORE-000334) | `ARMNRS`, `ACTARMUD` (Expected) | program |
| `EPOCH` in AE, DS, EX | absent: 1191 + 596 + 591 records (CORE-000701) | Permissible, but CORE and the FDA conformance guide expect it | program: derive from SE element dates, which needs an SE program |
| Study days | `AEDY`, `DSDY`, `SESTDY`/`SEENDY`, `SVSTDY`/`SVENDY` absent (CORE-000321, -000328, -000776, -000793) | Permissible; expected when the date is present | program: `%study_day` |
| TS value variables | `TSVALCD`, `TSVCDREF`, `TSVCDVER` absent (CORE-000334) | Expected | program |
| SV | `SVPRESP`, `SVOCCUR` absent (CORE-000334) | Expected | program (when SV is built) |
| Labels | e.g. `EXTRT` "Name of Actual Treatment", `TAETORD`, `SVSTDTC` | new labels | spec (done) |
| Core status | e.g. `EXENDTC`, `DSSTDY` Perm → Exp; `ARMCD`/`ARM` Req → Exp | | spec (done) |
| Population flags in SUPPDM | `ITT`, `SAFETY`, `EFFICACY`, `COMPLT8/16/24` (1197 records; CORE-000211 flags 963) | Not SDTM content | program: leave out; derived in ADSL |

## 2. Values and controlled terminology

| Change | Pilot | Fix |
|---|---|---|
| `EPOCH` case | TA has "Treatment", "Screening" | "TREATMENT", "SCREENING" (codelist EPOCH) — program |
| `TSVAL` formats | `AGEMAX` = "No maximum", `AGEMIN` = "50 years", `LENGTH` = "26 weeks" (CORE-000294) | `AGEMAX`: `TSVAL` null, `TSVALNF` = "PINF"; ISO 8601 durations "P50Y", "P26W" — program |
| TS parameters | `INTMODEL`, `INTTYPE`, `PCLASS` missing (CORE-000741); `AGESPAN` no longer in the TSPARMCD codelist | add from the protocol, drop `AGESPAN` — open: also check the FDA-required parameters (e.g. `SSTDTC`) in the current Technical Conformance Guide |
| `DSDECOD` terms | "FINAL LAB VISIT", "FINAL RETRIEVAL VISIT" (OTHER EVENT) not in CT | the codelist is extensible: keep, declare as sponsor extensions in define.xml — program + define |
| MedDRA codes | `AEBDSYCD` empty (1191, CORE-000024); `AEPTCD`, `AEHLTCD`, `AEHLGTCD` empty | raw data has `AELLTCD` and `AESOCCD` only — data: explain in cSDRG (MedDRA is licensed; no codes to look up) |
| Leading spaces | `DSSPID` " 7" (58 records; CORE-000867) | strip — program |
| Non-ASCII text | "Alzheimer’s" with a Windows-1252 curly apostrophe (0x92) in 3 `TSVAL` values; CORE fails on it unless told the encoding | ASCII apostrophe; XPT files must be ASCII — program |
| **RACE, ETHNIC** | pilot values valid up to CT 2025-09-26 | **open**: the `RACE` (C74457) and `ETHNIC` (C66790) codelists, and `LBSTRESC`, are not in the CT 2026-03-27 package in CORE's cache; only `RACEC`/`ETHNICC` remain. The spec keeps `RACE`/`ETHNIC` from CT 2025-09-26 and marks them. Confirm on the CDISC CT release notes before relying on it. |

## 3. Errors in the pilot data

These are pilot results that are wrong; our programs derive them, so they
come out right, and the QC comparison with the pilot will show them as
expected differences.

| Finding | Detail |
|---|---|
| `AESTDY` wrong (CORE-000552) | 01-716-1063, `AESTDTC` = `RFSTDTC` = 2013-05-09, pilot `AESTDY` = 366; correct is 1 |
| `RFENDTC` | Pilot define says last dose; values are the end-of-study disposition date (see `specs/sdtm_mapping.csv`) |

## 4. Collected-data inconsistencies (not changed; cSDRG)

SDTM does not alter collected data. These go into the cSDRG with counts from
our own SDTM once built; the pilot counts are given for reference.

| CORE rule | Pilot | Raw data |
|---|---|---|
| CORE-000022: a seriousness criterion = "Y" but `AESER` = "N" | 36 | at least 1 (`AESHOSP` = Yes, `AESER` = No); other criteria to be checked when AE is built |
| CORE-000657: `AEENDTC` present but `AEOUT` = NOT RECOVERED/NOT RESOLVED | 250 | 250 |
| CORE-000841: fatal AE end date ≠ `DTHDTC` | 1 (01-704-1445: AE ends 2014-10-31, death 2014-11-01) | same |
| CORE-000655/656: `ARM` ≠ `ACTARM` | 12 | 12 — expected: planned high dose, received low dose |

## 5. Not about the data

| Item | Note |
|---|---|
| CORE-000767 (1191 AE, 596 DS) | "FAOBJ ≠ AEDECOD" with no FA domain present: not applicable here; the pilot's RELREC was not in the checked folder. Re-check on our SDTM. |
| CORE-000929, CORE-001081 | Need a Define-XML 2.x file; run again once define.xml exists. |
| Define-XML | Pilot uses Define-XML 1.0. Use 2.1, generated from `specs/` with the R repo's generator. Check the FDA Data Standards Catalog for the versions accepted. |

## 6. What this changes for QC against the pilot

`PROC COMPARE` of our SDTM with the pilot will show the differences above by
design (new variables, nulls for screen failures, EPOCH, study days, case and
format changes, `AESTDY` for 01-716-1063, no population flags in SUPPDM).
QC programs compare on the pilot's variables and list every expected
difference by rule, so only unexplained differences need attention. The
pilot spec (`specs/pilot_spec.csv`, `specs/pilot_ct.csv`) stays in the repo
for that comparison and for the macro tests.

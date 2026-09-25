# Reference data (QC targets, not inputs to production code)

Copied unchanged from PHUSE [`phuse-scripts`](https://github.com/phuse-org/phuse-scripts)
(MIT licence) at commit `398a6d33ced9359ffb58c46650a6d488811176b1`:

| Folder | Source path | Files |
|---|---|---|
| `sdtm/` | `data/sdtm/cdiscpilot01/` | dm, ae, ds, ex, suppdm, suppae, suppds, ts, ta, te, tv, ti, se, sv (`.xpt`); `define.xml` + stylesheet; `blankcrf.pdf` (pilot aCRF) |
| `adam/` | `data/adam/cdiscpilot01/` | adsl, adae, adtte (`.xpt`); `define.xml` + stylesheet; `dataguide.pdf` (pilot reviewer's guide) |

The pilot's define.xml is version 1.0 for SDTMIG 3.1.2 (2012 package).

Not copied because of size (LB 34 MB, VS 24 MB, QS 34 MB, SUPPLB 57 MB,
ADLBC 34 MB, ...). Fetch them from the same commit when Phase 2 needs them:
`https://raw.githubusercontent.com/phuse-org/phuse-scripts/398a6d33ced9359ffb58c46650a6d488811176b1/data/<sdtm|adam>/cdiscpilot01/<name>.xpt`

Checks already made against the raw data (Python, before any SAS program):
all 306 raw DM patients are in pilot DM (`USUBJID = '01-' || PATNUM`), with
identical age, sex, race, ethnicity and collection date.

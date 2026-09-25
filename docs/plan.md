# Plan: new repository `cdisc-pilot-sas`

Goal: show hands-on SAS programming for clinical trials across the whole chain,
**raw data → SDTM → ADaM → tables, listings and figures (TLFs)**, with the QC,
log discipline and submission documents a study team expects.

Same study as `adam-admiral-walkthrough` (CDISCPILOT01, public test data), so the
two repos can check each other: SAS is the production side, the R repo is the
independent QC side, and `PROC COMPARE` shows they agree.

Suggested name: `cdisc-pilot-sas` (short, says study + language).

---

## 0. How the work runs (read first)

- **SAS does not run in the Claude Code cloud container** (no licence). Code is
  written in the session, then run by you in **SAS OnDemand for Academics**
  (free, SAS Studio in the browser).
- The evidence is therefore committed files, not a CI rebuild: every program's
  `.log`, the `.lst` where relevant, and the RTF/PDF outputs.
- Loop per pull request:
  1. Claude (or you) writes/changes programs on a branch and pushes.
  2. You pull the branch into SAS OnDemand (SAS 9.4M6+ has `git_clone` /
     `git_pull` functions you can call from a small `sync.sas`; if outbound Git
     is blocked in your OnDemand instance, upload a zip instead).
  3. Run `run_all.sas`. It ends with `%logcheck`, which fails loudly on any issue.
  4. Download `logs/`, `outputs/`, `data/` and commit them to the branch.
  5. Claude reads the logs and fixes; repeat until `%logcheck` is clean.
- A PR is merged only with clean logs committed for every changed program.
- CI (GitHub Actions) still adds value without SAS: it checks the committed
  logs are clean, and runs CDISC CORE on the committed SDTM XPTs (CORE has
  no ADaM rules; see section 7).

**Authorship.** This repo is meant to prove *your* SAS skill. Write the core
programs yourself (at least DM, ADSL, ADAE and the demographics and AE tables)
and use Claude as reviewer and tutor; let Claude draft the scaffolding, macros
and the less central programs. You must be able to explain every line.

---

## 1. Repository layout

```
cdisc-pilot-sas/
├── README.md                 pitch, results, how to run, link to R repo
├── CLAUDE.md                 conventions for Claude sessions (template provided)
├── setup.sas                 %let root; libnames; options; %include macros
├── run_all.sas               runs every program in order, then %logcheck
├── sync.sas                  git pull into SAS OnDemand (optional)
├── macros/
│   ├── logcheck.sas          scan logs/*.log -> summary; abort on findings
│   ├── header_template.sas   program header to copy
│   ├── spec_attrib.sas       apply label/length/format/order from the spec
│   ├── ct_check.sas          values vs controlled terminology in specs/ct.csv
│   ├── iso_dtc.sas           ISO 8601 DTC <-> SAS date/datetime, partial dates
│   ├── study_day.sas         --DY with no day 0
│   ├── xpt_export.sas        XPT v5 export + name/label/length limit checks
│   ├── seq.sas               --SEQ assignment
│   └── tfl_setup.sas         ODS RTF style, titles, footnotes, page x of y
├── specs/
│   ├── sdtm_mapping.csv      raw field -> SDTM variable, rule, origin
│   ├── sdtm_spec.csv         SDTM variable metadata
│   ├── adam_spec.csv         ADaM variable metadata (origin, method)
│   └── ct.csv                CDISC CT subset used (from NCI EVS download)
├── data/
│   ├── raw/                  CSV exported from {pharmaverseraw}
│   ├── sdtm/                 *.xpt written by this repo (committed)
│   ├── adam/                 *.xpt written by this repo (committed)
│   └── reference/            pinned copies/links: phuse pilot SDTM+ADaM, R repo XPTs
├── programs/
│   ├── sdtm/   dm.sas ds.sas ex.sas ae.sas suppdm.sas suppae.sas ts.sas
│   ├── adam/   adsl.sas adae.sas adlb.sas advs.sas adtte.sas
│   └── tfl/    t_14_1_01_demog.sas t_14_1_02_disp.sas t_14_3_01_ae_soc_pt.sas
│               t_14_3_04_lab_shift.sas t_14_3_05_alt_chg.sas f_14_2_01_km.sas
│               l_16_2_07_sae.sas
├── qc/
│   ├── sdtm/   qc_dm.sas ...     compare with published pilot SDTM
│   ├── adam/   qc_adsl.sas ...   independent re-derivation + compare with R repo and official ADaM
│   └── tfl/    qc_t_14_1_01.sas  independent recount of one table
├── logs/  lst/  outputs/rtf/  outputs/pdf/  outputs/qc/
├── tools/export_raw.R        one-off: pharmaverseraw -> data/raw/*.csv
└── docs/
    ├── csdrg.md              clinical SDTM reviewer's guide
    ├── adrg.md               analysis data reviewer's guide
    ├── tlf-shells.md         mock shells, written before TFL programs
    └── sap.md                short SAP (shared rules with the R repo)
```

---

## 2. Data sources

| Layer | Source | Notes |
|---|---|---|
| Raw (CRF-like) | `{pharmaverseraw}` (CRAN) | Raw AE, DS, DM, EC/EX, EDC- and standard-agnostic, with annotated CRFs in `inst/acrf`. Export once to CSV with `tools/export_raw.R`. Check the subject IDs match the pilot before relying on comparisons. |
| SDTM reference | PHUSE `phuse-scripts` `data/sdtm/cdiscpilot01/` (+ `define.xml`) | Use LB, VS, QS directly as input (no raw LB/VS in pharmaverseraw); compare your DM/AE/DS/EX against it. Pin a commit SHA. |
| ADaM reference | PHUSE `phuse-scripts` `data/adam/cdiscpilot01/` (`adsl`, `adae`, `adlbc`, `adlbh`, `adtte`, `advs`, `adqsadas`, `define.xml`, `dataguide.pdf`) | Target for QC; `dataguide.pdf` is the pilot's reviewer's guide. |
| Double programming | `adam-admiral-walkthrough/data/adam/*.xpt` | Same rules, different language. |

---

## 3. SAS skills to show, and where each one appears

A hiring manager should be able to find each of these in a named program:

| Skill | Where |
|---|---|
| DATA step merge with `IN=`, BY-group `FIRST.`/`LAST.`, `RETAIN` | `dm.sas`, `adsl.sas` (first/last dose) |
| Arrays, `DO` loops | `adlb.sas` (range flags), `ts.sas` |
| Hash object lookup | `adae.sas` (ADSL variables onto AE) |
| `PROC SQL` (joins, `SELECT INTO:`, subqueries) | `adsl.sas`, TFL denominators |
| `PROC TRANSPOSE` | `suppdm.sas`/`suppae.sas` and merging SUPP back |
| `PROC FORMAT` with `CNTLIN=` from the spec | `setup.sas` (codelist formats from `specs/ct.csv`) |
| ISO 8601 informats/formats (`E8601DA.`, `E8601DT.`), partial-date imputation with flags | `iso_dtc.sas`, `ae.sas`, `adae.sas` |
| Macro language: parameters, validation, `%SYSFUNC`, `CALL SYMPUTX`, `%DO` loops | `macros/` |
| Metadata-driven attributes | `spec_attrib.sas` |
| `PROC FREQ` / `MEANS` / `SUMMARY` / `UNIVARIATE` for TFL numbers | `tfl/` |
| `PROC REPORT` + ODS RTF, titles/footnotes, page x of y | `tfl/` |
| `PROC SGPLOT` / `PROC LIFETEST` (Kaplan–Meier) | `f_14_2_01_km.sas` |
| `PROC GLM`/`MIXED` ANCOVA (stretch) | `t_14_2_01_adas.sas` |
| `PROC COMPARE` with `ID`, `CRITERION=`, `OUTNOEQUAL` | `qc/` |
| Log discipline | `options mergenoby=error varinitchk=error dkricond=error dkrocond=error msglevel=i;` in `setup.sas`, `%logcheck` |

`%logcheck` must flag at least: `ERROR`, `WARNING`, `uninitialized`,
`MERGE statement has more than one data set with repeats of BY values`,
`values have been converted`, `Invalid data`, `W.D format was too small`,
`Missing values were generated`, `repeats of BY values`.

---

## 4. Phases

Each phase is one or more PRs with clean committed logs.

### Phase 0 — Setup (1 session)
- Create the GitHub repo; add `README.md` skeleton, `CLAUDE.md`, `.gitignore`
  (ignore `*.sas7bdat`, `work/`; keep `*.xpt`, `logs/`, `outputs/`).
- `setup.sas` with a single `%let root=` that is the only path you edit when
  moving between OnDemand and elsewhere; libnames `raw`, `sdtm`, `adam`, `ref`.
- `macros/logcheck.sas`, `macros/header_template.sas`.
- `tools/export_raw.R` → commit `data/raw/*.csv`.
- A hello-world program run end to end in OnDemand with its clean log
  committed: proves the loop works.
- CI job 1: a Python script that fails if any committed `logs/*.log` contains a
  finding from the `%logcheck` list, or if a program has no log.

### Phase 1 — SDTM from raw (2–3 sessions)
Target SDTMIG 3.4 and CDISC CT 2026-03-27 (decided 2026-09-25); what changes
from the pilot is in `docs/sdtmig-3.4-upgrade.md`.
- Trial design TA, TE, TV, TI from the pilot (upper-case EPOCH) and SE from
  EX/DS dates: SE is needed to derive EPOCH in AE, DS and EX.
- `specs/sdtm_mapping.csv` from the aCRF: one row per raw field.
- DM (with `RFSTDTC`, `RFENDTC`, `RFXSTDTC`, `RFXENDTC`, `RFICDTC`, `DTHDTC`,
  `ARM`/`ACTARM`, `AGE`/`AGEU`), SUPPDM.
- EX (from raw EC/EX), DS, AE (with `AESTDY`, `AEENDY`, `EPOCH`, `AESEQ`), SUPPAE.
- TS (Trial Summary) — required by FDA, short, shows regulatory awareness.
- `--SEQ`, `--DY` (no day 0), `EPOCH`, ISO 8601 partial dates.
- `%ct_check` on every coded variable against `specs/ct.csv`.
- Export XPT v5 with `%xpt_export`.
- QC: `PROC COMPARE` vs PHUSE pilot SDTM; `docs/csdrg.md` explains each
  difference.
- CI job 2: CDISC CORE on `data/sdtm/*.xpt` against SDTMIG 3.4 and CT
  2026-03-27 with `tools/run_core.sh`, report committed, findings triaged in
  `docs/csdrg.md`. The bundled rules cache is used, so no CDISC Library key is
  needed.

### Phase 2 — ADaM (3–4 sessions)
- ADSL: populations (`SAFFL`, `ITTFL`, `EFFFL`, `COMP24FL`), `TRT01P/A(N)`,
  `TRTSDT`/`TRTEDT`, `TRTDURD`, `AGEGR1(N)`, `EOSSTT`, `DCSREAS`, `RANDDT`.
- ADAE: `ASTDT`/`ASTDTF` with the same imputation rule as the R repo,
  `TRTEMFL`, `AOCCFL`, `AOCCSFL`, `AOCCPFL`.
- ADLB (BDS): same five parameters as the R repo first, then all chemistry
  (to compare with the pilot's ADLBC); `ABLFL`, `BASE`, `CHG`, `PCHG`, `ANRIND`,
  `BNRIND`, `SHIFT1`, visit windows.
- ADVS, ADTTE (time to first dermatologic event, `CNSR`, `EVNTDESC`).
- Attributes from `specs/adam_spec.csv` via `%spec_attrib`; XPT export.
- QC:
  - `qc/adam/qc_adsl.sas` etc.: independent re-derivation of key variables
    (not a copy of the production code), `PROC COMPARE` → 0 differences.
  - `PROC COMPARE` vs the R repo XPTs → differences only where documented.
  - `PROC COMPARE` vs the official pilot ADaM → explained in `docs/adrg.md`.
- CI: documented ADaMIG checks on `data/adam/*.xpt` (CORE has no ADaM rules;
  reuse the R repo's conformance checks, see section 7).

### Phase 3 — TLFs (2–3 sessions)
Write `docs/tlf-shells.md` first. Then, with ODS RTF via `%tfl_setup`:
- 14.1.1 Demographics and baseline characteristics (ITT)
- 14.1.2 Subject disposition
- 14.3.1 TEAEs by SOC and PT (subjects counted once per term; sorted by
  frequency)
- 14.3.4 Lab shift table (baseline vs worst post-baseline `ANRIND`)
- 14.3.5 ALT change from baseline by visit (same numbers as the R repo Table 2)
- 14.2.1 Kaplan–Meier figure, time to first dermatologic event
- 16.2.7 Listing of serious adverse events
- Stretch: ADAS-Cog ANCOVA table (needs ADQSADAS)
- QC: independent recount of Table 14.1.1 and 14.3.1 (`qc/tfl/`), compare the
  numbers dataset to the production numbers dataset.
- Commit RTF and a PDF of each; put PNG previews in the README.

### Phase 4 — Submission documents (1–2 sessions)
- `docs/csdrg.md` and `docs/adrg.md` (PHUSE template headings).
- define.xml: SAS OnDemand has no free define generator; either generate it
  from `specs/` by reusing the R repo's Define-XML 2.1 generator and its
  XSD validation (see section 7). Commit `define.xml` + `define.html`.
- Conformance reports from CORE, with every finding triaged.

### Phase 5 — Polish (1 session)
- README: one-paragraph pitch, what was built, results images, the QC
  evidence (links to `outputs/qc/`), how to run, limits.
- GitHub profile README (`Ngarciar24/Ngarciar24`) linking both repos with a
  diagram: raw → SDTM (SAS) → ADaM (SAS + R, compared) → TLFs.
- Consider the SAS certifications: Base Programming Specialist, then Clinical
  Trials Programming Using SAS 9.4 (A00-282, which requires one of the base
  credentials first).

---

## 5. Program header (every `.sas` file)

```sas
/*******************************************************************************
* Program     : adsl.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Create ADSL
* Inputs      : sdtm.dm, sdtm.ex, sdtm.ds; specs/adam_spec.csv
* Outputs     : adam.adsl, data/adam/adsl.xpt
* Macros      : %spec_attrib, %xpt_export
* Author      : <your name>
* Created     : YYYY-MM-DD
* SAS version : 9.4Mx (SAS OnDemand for Academics)
* Change log  : YYYY-MM-DD  XXX  description
*******************************************************************************/
```

---

## 6. Definition of done for the repo

- Every program has a header and a clean committed log.
- `run_all.sas` runs top to bottom in OnDemand with `%logcheck` clean.
- SDTM and ADaM XPTs committed; CORE reports committed and triaged.
- Production vs QC `PROC COMPARE`: 0 unexplained differences, outputs committed.
- SAS ADaM vs R ADaM: agreement shown, differences documented.
- RTF + PDF outputs committed; README shows them.
- cSDRG, ADRG, define.xml present.

---

## 7. Alignment with the R repo and checks made (2026-09-25)

The R repo (`adam-admiral-walkthrough`) is being reworked in parallel. To keep
the two repos from contradicting each other:

- **One set of analysis rules.** The SAP is written once, in the R repo. This
  repo's `docs/sap.md` links to that version (by commit) and records any
  SAS-specific addition; it never restates a rule differently. Rules the R
  repo has changed so far: last dose falls back to the discontinuation date
  when EX has no end date (pilot rule); `CHG` only on post-baseline records;
  screen failures no longer get a treatment in `TRT01P`; baseline stays "last
  value on or before first dose" (differs from the pilot's `LBBLFL`).
- **Same inputs.** The raw data (`pharmaverseraw` 0.1.1) corresponds to
  `pharmaversesdtm` 1.5.0, which the R repo reads. Compared with the PHUSE
  pilot SDTM it is identical for DM, EX, AE, SUPPDM and SUPPAE (blank vs
  missing aside) but DS has 254 extra "PROTOCOL MILESTONE" (randomisation)
  records. SDTM QC therefore compares with `pharmaversesdtm` 1.5.0 for DS and
  with PHUSE for the rest.
- **Same explained differences.** Differences between the pilot ADaM and our
  ADaM that the R repo has already traced (e.g. the pilot's `ANRIND` range
  comparison, baseline from `LBBLFL`, unimputed onset dates) are cited, not
  re-investigated.
- **Conformance.** CDISC CORE rules (checked in the rules cache) cover SDTMIG
  3.2, 3.3 and 3.4 only: no ADaM rules and no SDTMIG 3.1.2, the version of the
  pilot define.xml. Decision: target SDTMIG 3.4 (see
  `docs/sdtmig-3.4-upgrade.md`); ADaM conformance uses the R repo's documented
  ADaMIG checks.
- **Python reading XPT.** pandas decodes exact zeros in XPT files as about
  5.4e-79; any Python check here must round before testing for 0.
- **define.xml.** Reuse the R repo's Define-XML 2.1 generator and XSD
  validation rather than building a second one.

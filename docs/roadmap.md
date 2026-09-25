# Roadmap

Each step is done when its programs run in SAS OnDemand with a clean
committed log and, where stated, a committed `PROC COMPARE` listing.

| # | Step | Output | QC |
|---|---|---|---|
| 1 | Run the set-up, macro tests and smoke test in SAS | clean logs | `%logcheck`, 23 unit checks |
| 2 | SDTM DM from raw (SDTMIG 3.4) | `data/sdtm/dm.xpt` | `PROC COMPARE` with the pilot DM; differences explained in `docs/sdtmig-3.4-upgrade.md` |
| 3 | ADSL | `data/adam/adsl.xpt` | `PROC COMPARE` with the R repo's ADSL and the pilot ADSL |
| 4 | Table 14.1.1 Demographics (`PROC REPORT`, ODS RTF) | RTF + PDF | independent recount |
| 5 | ADTTE and Kaplan–Meier figure 14-1, time to first dermatologic event (`PROC LIFETEST`, `SGPLOT`) | `adtte.xpt`, figure | compare with the pilot ADTTE (152 events, 102 censored) and the R repo |
| 6 | SE, EX, DS, AE and trial design domains; ADAE; AE table by SOC/PT | XPTs, RTF | CDISC CORE on the SDTM, `PROC COMPARE` |
| 7 | Lab and efficacy: ADLB, ADQSADAS, shift table, ADAS-Cog ANCOVA | XPTs, RTF | `PROC COMPARE` with the R repo |
| 8 | cSDRG, ADRG, define.xml 2.1 | `docs/` | Define-XML schema check |

Analysis rules are shared with the R repo, whose SAP is the single source.

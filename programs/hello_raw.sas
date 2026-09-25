/*******************************************************************************
* Program     : hello_raw.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Phase 0 smoke test. Proves the loop works end to end: setup,
*               paths, reading a raw CSV, a listing in lst/, a clean log in
*               logs/. Reads raw DM and summarises it; creates nothing kept.
* Inputs      : data/raw/dm_raw.csv
* Outputs     : work.dm_raw; lst/hello_raw.lst
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  IGR  Initial version
*******************************************************************************/

%include "&root/setup.sas";

/* Read with an explicit DATA step rather than PROC IMPORT: lengths and types */
/* are fixed here, not guessed from the first rows.                           */
data work.dm_raw;
  infile "&root/data/raw/dm_raw.csv" dsd firstobs=2 truncover lrecl=32767;
  length study $12 patnum $8 age 8 sex $6 ethnic $22 race $32 country $3
         planned_arm $14 planned_armcd $8 actual_arm $14 actual_armcd $8
         col_dt_raw ic_dt_raw $10;
  input study patnum age sex ethnic race country
        planned_arm planned_armcd actual_arm actual_armcd
        col_dt_raw ic_dt_raw;

  /* Raw dates are MM/DD/YYYY; informed-consent date can be blank.            */
  col_dt = input(col_dt_raw, mmddyy10.);
  if not missing(ic_dt_raw) then ic_dt = input(ic_dt_raw, mmddyy10.);
  else ic_dt = .;
  format col_dt ic_dt date9.;

  label study         = 'Study Identifier'
        patnum        = 'Patient Number'
        age           = 'Age (years)'
        planned_arm   = 'Planned Arm'
        actual_arm    = 'Actual Arm'
        col_dt        = 'Collection Date'
        ic_dt         = 'Informed Consent Date';
run;

/* One record per patient is expected in raw DM.                              */
proc sql noprint;
  select count(*), count(distinct patnum)
    into :nrec trimmed, :nsubj trimmed
    from work.dm_raw;
quit;

data _null_;
  if &nrec ne &nsubj then
    put "ERROR: [hello_raw] &nrec records but &nsubj patients in raw DM.";
  else put "NOTE: [hello_raw] &nsubj patients, one record each.";
run;

title1 'CDISCPILOT01 raw DM: planned vs actual arm';
proc freq data=work.dm_raw;
  tables planned_arm * actual_arm / norow nocol nopercent missing;
run;

title1 'CDISCPILOT01 raw DM: age by planned arm';
proc means data=work.dm_raw n mean std min median max maxdec=1;
  class planned_arm;
  var age;
run;

title1 'CDISCPILOT01 raw DM: date ranges';
proc means data=work.dm_raw n nmiss min max;
  var col_dt ic_dt;
  format col_dt ic_dt date9.;
run;
title;

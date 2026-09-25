/*******************************************************************************
* Program     : test_macros.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Unit tests for the utility macros. Each check writes
*               "NOTE: [test] PASS ..." or "ERROR: [test] FAIL ..." to the log,
*               so %logcheck fails the run on any failed test.
* Inputs      : data/reference/sdtm/dm.xpt; specs/pilot_spec.csv,
*               specs/pilot_ct.csv
* Outputs     : WORK datasets only; a temporary XPT in the WORK folder
* Macros      : %iso_dtc %dtc_date %study_day %seq %xpt_import %spec_attrib
*               %ct_check %xpt_export
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  IGR  Initial version
*               2026-09-25  IGR  Remove formats with FORMAT _ALL_
*               2026-09-25  IGR  Test against the pilot spec (spec=pilot)
*
* Conditions use EQ/NE, not "=", because they are macro arguments.
*******************************************************************************/

%include "&root/setup.sas";

%macro check(cond, label);
  if &cond then put "NOTE: [test] PASS &label";
  else put "ERROR: [test] FAIL &label";
%mend check;

/*---- iso_dtc ---------------------------------------------------------------*/
data _null_;
  length a b c d $20;
  %iso_dtc(date='02JAN2014'd, out=a)
  %iso_dtc(date='02JAN2014'd, time='09:05't, out=b)
  %iso_dtc(date=., out=c)
  %iso_dtc(date='02JAN2014'd, time=., out=d)
  %check(a eq '2014-01-02', iso_dtc date only)
  %check(b eq '2014-01-02T09:05', iso_dtc date and time with leading zero)
  %check(c eq ' ', iso_dtc missing date gives blank)
  %check(d eq '2014-01-02', iso_dtc missing time gives date only)
run;

/*---- dtc_date --------------------------------------------------------------*/
data _null_;
  length d1 d2 d3 d4 $20 f1 f2 f3 f4 f5 $1;
  d1 = '2014-01-02T11:45';
  d2 = '2013-05';
  d3 = '2013';
  d4 = ' ';
  %dtc_date(dtc=d1, out=x1, flag=f1, impute=FIRST)
  %dtc_date(dtc=d2, out=x2, flag=f2, impute=LAST)
  %dtc_date(dtc=d3, out=x3, flag=f3, impute=FIRST)
  %dtc_date(dtc=d4, out=x4, flag=f4, impute=FIRST)
  %dtc_date(dtc=d2, out=x5, flag=f5)
  %check(x1 eq '02JAN2014'd and f1 eq ' ', dtc_date complete datetime)
  %check(x2 eq '31MAY2013'd and f2 eq 'D', dtc_date year-month LAST)
  %check(x3 eq '01JAN2013'd and f3 eq 'M', dtc_date year only FIRST)
  %check(missing(x4) and f4 eq ' ', dtc_date blank)
  %check(missing(x5) and f5 eq ' ', dtc_date partial without imputation)
run;

/*---- study_day -------------------------------------------------------------*/
data _null_;
  length ref d1 d2 d3 d4 blank $20;
  ref   = '2014-01-02';
  d1    = '2013-12-26';
  d2    = '2014-01-02';
  d3    = '2014-01-03T10:00';
  d4    = '2013-12';
  blank = ' ';
  %study_day(dtc=d1, refdtc=ref, out=dy1)
  %study_day(dtc=d2, refdtc=ref, out=dy2)
  %study_day(dtc=d3, refdtc=ref, out=dy3)
  %study_day(dtc=d4, refdtc=ref, out=dy4)
  %study_day(dtc=d1, refdtc=blank, out=dy5)
  %check(dy1 eq -7, study_day before reference (pilot 01-701-1015 DMDY))
  %check(dy2 eq 1, study_day reference date is day 1)
  %check(dy3 eq 2, study_day datetime)
  %check(missing(dy4), study_day partial date)
  %check(missing(dy5), study_day missing reference)
run;

/*---- seq -------------------------------------------------------------------*/
data work.t_seq;
  length studyid $4 usubjid $8 aeterm $10 aestdtc $10;
  input usubjid aeterm aestdtc;
  studyid = 'TEST';
  datalines;
A HEADACHE 2014-01-05
A NAUSEA 2014-01-02
B RASH 2014-02-01
;
run;

%seq(data=work.t_seq, out=work.t_seq2, sortby=studyid usubjid aestdtc aeterm,
     seqvar=aeseq)

data _null_;
  set work.t_seq2 end=eof;
  retain ok 1;
  if (usubjid eq 'A' and aeterm eq 'NAUSEA'   and aeseq ne 1)
  or (usubjid eq 'A' and aeterm eq 'HEADACHE' and aeseq ne 2)
  or (usubjid eq 'B' and aeseq ne 1) then ok = 0;
  if eof then do;
    %check(ok eq 1 and _n_ eq 3, seq numbers within subject in sort order)
  end;
run;

/*---- xpt_import, spec_attrib, ct_check on the pilot DM ----------------------*/
%xpt_import(file=&root/data/reference/sdtm/dm.xpt, out=work.ref_dm)
proc sort data=work.ref_dm;
  by studyid usubjid;
run;

/* Strip labels and formats, add a variable the spec does not have.          */
data work.t_dm;
  set work.ref_dm;
  extra = 'x';
run;
proc datasets lib=work nolist;
  modify t_dm;
  attrib _all_ label=' ';
  format _all_;
quit;

%spec_attrib(data=work.t_dm, dataset=DM, out=work.t_dm2, spec=pilot)

proc compare base=work.ref_dm compare=work.t_dm2 noprint;
  id studyid usubjid;
run;
%let cmp_rc = &sysinfo;

data _null_;
  dsid = open('work.t_dm2');
  has_extra = varnum(dsid, 'EXTRA');
  first_var = varname(dsid, 1);
  label_age = varlabel(dsid, varnum(dsid, 'AGE'));
  ds_label  = attrc(dsid, 'LABEL');
  rc = close(dsid);
  /* 64+128: records only in one; 1024+2048: variables only in one;        */
  /* 4096: values differ; 32: labels differ.                                */
  cmp = &cmp_rc;
  %check(band(cmp, 7392) eq 0, spec_attrib output equals pilot DM (sysinfo &cmp_rc))
  %check(has_extra eq 0, spec_attrib drops variables not in spec)
  %check(first_var eq 'STUDYID', spec_attrib puts variables in spec order)
  %check(label_age eq 'Age', spec_attrib restores labels)
  %check(ds_label eq 'Demographics', spec_attrib sets dataset label)
run;

%ct_check(data=work.t_dm2, dataset=DM, spec=pilot)
data _null_;
  dsid = open('work.ct_findings');
  n = attrn(dsid, 'NLOBS');
  rc = close(dsid);
  %check(n eq 0, ct_check finds no issue in pilot DM)
run;

/* One value outside CT must be found (LEVEL=NOTE keeps this log clean).     */
data work.t_dm_bad;
  set work.t_dm2;
  if _n_ eq 1 then sex = 'X';
run;
%ct_check(data=work.t_dm_bad, dataset=DM, spec=pilot, level=NOTE)
data _null_;
  set work.ct_findings end=eof;
  if eof then do;
    %check(_n_ eq 1 and variable eq 'SEX' and value eq 'X' and n eq 1,
           ct_check reports a value outside CT)
  end;
run;

/*---- xpt_export round trip -------------------------------------------------*/
%let t_xpt = %sysfunc(pathname(work))/t_dm2.xpt;
%xpt_export(data=work.t_dm2, file=&t_xpt)
%xpt_import(file=&t_xpt, out=work.t_dm3)

proc compare base=work.t_dm2 compare=work.t_dm3 noprint;
  id studyid usubjid;
run;
%let cmp_rc = &sysinfo;

data _null_;
  cmp = &cmp_rc;
  %check(band(cmp, 7392) eq 0, xpt_export round trip keeps values and labels (sysinfo &cmp_rc))
run;

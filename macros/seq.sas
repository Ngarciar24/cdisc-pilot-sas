/*******************************************************************************
* Program     : seq.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Assign a --SEQ variable: 1, 2, ... within each subject, in a
*               documented sort order.
* Inputs      : data=   input dataset
*               by=     grouping variables (default STUDYID USUBJID)
*               sortby= full sort order; must start with the BY variables
*               seqvar= name of the sequence variable, e.g. AESEQ
* Outputs     : out= output dataset (default: overwrite DATA=)
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* PROC SORT keeps the input order of ties (EQUALS), so the result is
* reproducible; a NOTE reports how many records tie on SORTBY.
*******************************************************************************/

%macro seq(data=, out=, by=studyid usubjid, sortby=, seqvar=);
  %local lastby nby i dsid hasseq ndup;
  %if %length(&out) = 0 %then %let out = &data;
  %if %length(&data) = 0 or %length(&sortby) = 0 or %length(&seqvar) = 0 %then %do;
    %put ERROR: [seq] DATA=, SORTBY= and SEQVAR= are required.;
    %return;
  %end;

  /* SORTBY must begin with the BY variables. */
  %let nby = %sysfunc(countw(&by, %str( )));
  %do i = 1 %to &nby;
    %if %upcase(%scan(&by, &i, %str( ))) ne %upcase(%scan(&sortby, &i, %str( ))) %then %do;
      %put ERROR: [seq] SORTBY= (&sortby) must start with BY= (&by).;
      %return;
    %end;
  %end;
  %let lastby = %scan(&by, -1, %str( ));

  /* Drop an existing sequence variable so it is rebuilt, not retained. */
  %let dsid   = %sysfunc(open(&data));
  %let hasseq = %sysfunc(varnum(&dsid, &seqvar));
  %let dsid   = %sysfunc(close(&dsid));

  proc sort data=&data out=work._seq_sorted;
    by &sortby;
  run;

  proc sort data=work._seq_sorted out=work._seq_dup nodupkey dupout=work._seq_ties;
    by &sortby;
  run;
  proc sql noprint;
    select count(*) into :ndup trimmed from work._seq_ties;
  quit;
  %if &ndup > 0 %then
    %put NOTE: [seq] &ndup record(s) tie on SORTBY, their input order decides &seqvar..;

  data &out;
    set work._seq_sorted%if &hasseq > 0 %then (drop=&seqvar);;
    by &by;
    if first.&lastby then &seqvar = 0;
    &seqvar + 1;
  run;

  proc datasets lib=work nolist;
    delete _seq_sorted _seq_dup _seq_ties;
  quit;
%mend seq;

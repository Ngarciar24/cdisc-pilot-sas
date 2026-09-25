/*******************************************************************************
* Program     : dtc_date.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : DATA step snippet: ISO 8601 --DTC (complete or partial) to a
*               numeric SAS date, with optional imputation and an ADaM
*               imputation flag (*DTF).
* Inputs      : dtc= character ISO 8601 variable
*               impute= NONE (default), FIRST or LAST
* Outputs     : out= numeric date variable; flag= imputation flag variable (optional):
*               D = day imputed, M = month and day imputed
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* Rules: YYYY-MM-DD... -> that date, no flag.
*        YYYY-MM       -> FIRST: day 1;         LAST: last day of month; flag D
*        YYYY          -> FIRST: 1 January;     LAST: 31 December;       flag M
*        anything else or IMPUTE=NONE with a partial date -> missing.
* Capping an imputed date (e.g. not before first dose) is a study rule; do it
* in the ADaM program, not here.
*******************************************************************************/

%macro dtc_date(dtc=, out=, flag=, impute=NONE);
  %let impute = %upcase(&impute);
  %if %length(&dtc) = 0 or %length(&out) = 0 %then %do;
    %put ERROR: [dtc_date] DTC= and OUT= are required.;
    %return;
  %end;
  %if &impute ne NONE and &impute ne FIRST and &impute ne LAST %then %do;
    %put ERROR: [dtc_date] IMPUTE= must be NONE, FIRST or LAST (got &impute).;
    %return;
  %end;

  &out = .;
  %if %length(&flag) %then %str(&flag = ' ';);
  if lengthn(&dtc) >= 10 then &out = input(substr(&dtc, 1, 10), e8601da10.);
  %if &impute ne NONE %then %do;
  else if lengthn(&dtc) = 7 then do;
    &out = mdy(input(substr(&dtc, 6, 2), 2.), 1, input(substr(&dtc, 1, 4), 4.));
    %if &impute = LAST %then %str(&out = intnx('month', &out, 0, 'end'););
    %if %length(&flag) %then %str(&flag = 'D';);
  end;
  else if lengthn(&dtc) = 4 then do;
    %if &impute = FIRST %then %str(&out = mdy(1, 1, input(&dtc, 4.)););
    %else %str(&out = mdy(12, 31, input(&dtc, 4.)););
    %if %length(&flag) %then %str(&flag = 'M';);
  end;
  %end;
%mend dtc_date;

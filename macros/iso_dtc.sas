/*******************************************************************************
* Program     : iso_dtc.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : DATA step snippet: SAS date (and optional time) to an ISO 8601
*               character value, YYYY-MM-DD or YYYY-MM-DDThh:mm.
* Inputs      : date= numeric SAS date; time= numeric SAS time (optional)
* Outputs     : out= character variable (declare its length before the call)
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* Use inside a DATA step. Partial raw dates (e.g. year only) are not SAS dates;
* build their ISO value in the program and document it in the mapping spec.
*   length rfstdtc $20;
*   %iso_dtc(date=ex_start, out=rfstdtc);
*   %iso_dtc(date=ds_date, time=ds_time, out=dsstdtc);
*******************************************************************************/

%macro iso_dtc(date=, time=, out=);
  %if %length(&date) = 0 or %length(&out) = 0 %then %do;
    %put ERROR: [iso_dtc] DATE= and OUT= are required.;
    %return;
  %end;

  if missing(&date) then &out = ' ';
  %if %length(&time) %then %do;
  else if not missing(&time) then
    &out = cats(put(&date, e8601da10.), 'T', put(&time, tod5.));
  %end;
  else &out = put(&date, e8601da10.);
%mend iso_dtc;

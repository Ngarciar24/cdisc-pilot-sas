/*******************************************************************************
* Program     : study_day.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : DATA step snippet: study day of an ISO 8601 date relative to a
*               reference ISO 8601 date, with no day 0 (SDTM --DY).
* Inputs      : dtc= character ISO date/datetime; refdtc= reference, e.g. RFSTDTC
* Outputs     : out= numeric study day; missing unless both dates are complete
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* Day 1 is the reference date; the day before it is -1.
*   %study_day(dtc=aestdtc, refdtc=rfstdtc, out=aestdy);
*******************************************************************************/

%macro study_day(dtc=, refdtc=, out=);
  %if %length(&dtc) = 0 or %length(&refdtc) = 0 or %length(&out) = 0 %then %do;
    %put ERROR: [study_day] DTC=, REFDTC= and OUT= are required.;
    %return;
  %end;

  &out = .;
  if lengthn(&dtc) >= 10 and lengthn(&refdtc) >= 10 then do;
    _sd_dt  = input(substr(&dtc, 1, 10), e8601da10.);
    _sd_ref = input(substr(&refdtc, 1, 10), e8601da10.);
    &out = _sd_dt - _sd_ref + (_sd_dt >= _sd_ref);
  end;
  drop _sd_dt _sd_ref;
%mend study_day;

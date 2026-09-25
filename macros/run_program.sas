/*******************************************************************************
* Program     : run_program.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Run one program with its log and listing routed to
*               logs/<name>.log and lst/<name>.lst (overwritten each run).
* Inputs      : path= program path relative to &root, e.g. programs/sdtm/dm.sas
* Outputs     : logs/<name>.log, lst/<name>.lst
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  IGR  Initial version
*******************************************************************************/

%macro run_program(path);
  %local name;

  %if %length(&path) = 0 %then %do;
    %put ERROR: [run_program] PATH is required.;
    %return;
  %end;
  %if not %sysfunc(fileexist(&root/&path)) %then %do;
    %put ERROR: [run_program] &root/&path not found.;
    %return;
  %end;

  /* logs/<name>.log: program names are unique across folders by convention. */
  %let name = %scan(&path, -1, /);
  %let name = %substr(&name, 1, %length(&name) - 4);

  %put NOTE: [run_program] &path -> logs/&name..log;
  proc printto log="&root/logs/&name..log" print="&root/lst/&name..lst" new;
  run;

  %include "&root/&path" / source2;

  proc printto;
  run;
%mend run_program;

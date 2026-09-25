/*******************************************************************************
* Program     : xpt_import.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Read a one-dataset SAS V5 transport file (XPT) into a dataset,
*               e.g. a pilot reference dataset for QC.
* Inputs      : file= path of the .xpt file
* Outputs     : out= dataset to create, e.g. ref.dm
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*******************************************************************************/

%macro xpt_import(file=, out=);
  %local mem;
  %if %length(&file) = 0 or %length(&out) = 0 %then %do;
    %put ERROR: [xpt_import] FILE= and OUT= are required.;
    %return;
  %end;
  %if not %sysfunc(fileexist(&file)) %then %do;
    %put ERROR: [xpt_import] &file not found.;
    %return;
  %end;

  libname _xin xport "&file";
  proc sql noprint;
    select memname into :mem trimmed
      from dictionary.tables where libname = '_XIN';
  quit;

  data &out;
    set _xin.&mem;
  run;
  libname _xin clear;
%mend xpt_import;

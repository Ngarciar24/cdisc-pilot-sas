/*******************************************************************************
* Program     : xpt_export.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Write a dataset to a SAS V5 transport file (XPT) after checking
*               the V5 and submission limits: dataset name <= 8, dataset
*               label <= 40, variable names <= 8, every variable labelled,
*               labels <= 40, character lengths <= 200.
* Inputs      : data= libref.dataset to export
*               file= target path (default &root/data/<libref>/<name>.xpt)
* Outputs     : the XPT file
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*******************************************************************************/

%macro xpt_export(data=, file=);
  %local lib mem nerr;
  %if %index(&data, .) = 0 %then %do;
    %put ERROR: [xpt_export] DATA= must be libref.dataset (got &data).;
    %return;
  %end;
  %let lib = %upcase(%scan(&data, 1, .));
  %let mem = %upcase(%scan(&data, 2, .));
  %if %length(&file) = 0 %then
    %let file = &root/data/%lowcase(&lib)/%lowcase(&mem).xpt;

  %if not %sysfunc(exist(&data)) %then %do;
    %put ERROR: [xpt_export] &data does not exist.;
    %return;
  %end;

  proc sql;
    create table work._xe_err as
      select memname as name length=32, 'dataset name longer than 8' as problem length=60
        from dictionary.tables
       where libname = "&lib" and memname = "&mem" and length(memname) > 8
      union all
      select memname, 'dataset label missing or longer than 40'
        from dictionary.tables
       where libname = "&lib" and memname = "&mem"
         and (missing(memlabel) or length(memlabel) > 40)
      union all
      select name, 'variable name longer than 8'
        from dictionary.columns
       where libname = "&lib" and memname = "&mem" and length(name) > 8
      union all
      select name, 'label missing or longer than 40'
        from dictionary.columns
       where libname = "&lib" and memname = "&mem"
         and (missing(label) or length(label) > 40)
      union all
      select name, 'character length over 200'
        from dictionary.columns
       where libname = "&lib" and memname = "&mem"
         and type = 'char' and length > 200;

    select count(*) into :nerr trimmed from work._xe_err;
  quit;

  %if &nerr > 0 %then %do;
    title "xpt_export: &data breaks XPT V5 / submission limits";
    proc print data=work._xe_err noobs;
    run;
    title;
    %put ERROR: [xpt_export] &nerr problem(s) in &data, no file written.;
    %return;
  %end;

  libname _xpt xport "&file";
  proc copy in=&lib out=_xpt memtype=data;
    select &mem;
  run;
  libname _xpt clear;

  proc datasets lib=work nolist;
    delete _xe_err;
  quit;

  %put NOTE: [xpt_export] &data -> &file;
%mend xpt_export;

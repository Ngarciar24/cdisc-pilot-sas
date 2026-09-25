/*******************************************************************************
* Program     : ct_check.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Check every coded variable of a dataset against its codelist
*               in specs/ct.csv; list values not in the codelist.
* Inputs      : data=    dataset to check
*               dataset= spec dataset name, e.g. DM
*               spec=    sdtm (default) or adam
*               level=   WARNING (default) or ERROR, for the log message when
*                        values are outside CT
* Outputs     : work.ct_findings (variable, codelist, value, n); listing
* Macros      : %read_spec
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* Codelists with no terms in ct.csv (external dictionaries such as MedDRA,
* codelist AEDICT) are skipped with a NOTE.
*******************************************************************************/

%macro ct_check(data=, dataset=, spec=sdtm, level=WARNING);
  %local lib mem n i nterms nfind;
  %let dataset = %upcase(&dataset);
  %if %length(&data) = 0 or %length(&dataset) = 0 %then %do;
    %put ERROR: [ct_check] DATA= and DATASET= are required.;
    %return;
  %end;

  %read_spec(spec=&spec)

  %if %index(&data, .) %then %do;
    %let lib = %upcase(%scan(&data, 1, .));
    %let mem = %upcase(%scan(&data, 2, .));
  %end;
  %else %do;
    %let lib = WORK;
    %let mem = %upcase(&data);
  %end;

  /* Coded variables present in the data. */
  proc sql noprint;
    select s.variable, s.codelist into :var1-, :cl1-
      from work._spec_&spec as s
           inner join dictionary.columns as c
           on c.libname = "&lib" and c.memname = "&mem"
              and upcase(c.name) = s.variable
     where s.dataset = "&dataset" and not missing(s.codelist)
     order by s.varorder;
  quit;
  %let n = &sqlobs;

  proc sql;
    create table work.ct_findings
      (variable char(8), codelist char(8), value char(200), n num);
  quit;

  %do i = 1 %to &n;
    proc sql noprint;
      select count(*) into :nterms trimmed
        from work._ct where codelist = "&&cl&i";
    quit;

    %if &nterms = 0 %then
      %put NOTE: [ct_check] &&var&i: codelist &&cl&i has no terms (external dictionary), skipped.;
    %else %do;
      proc sql;
        insert into work.ct_findings
          select "&&var&i", "&&cl&i", cats(&&var&i), count(*)
            from &data
           where not missing(&&var&i)
             and cats(&&var&i) not in
                 (select term from work._ct where codelist = "&&cl&i")
           group by 3;
      quit;
    %end;
  %end;

  proc sql noprint;
    select count(*) into :nfind trimmed from work.ct_findings;
  quit;

  %if &nfind > 0 %then %do;
    title "ct_check: &data values not in the &dataset codelists";
    proc print data=work.ct_findings noobs;
    run;
    title;
    %put %upcase(&level): [ct_check] &nfind value(s) in &data not in CT. See work.ct_findings.;
  %end;
  %else %put NOTE: [ct_check] &data: &n coded variable(s), all values in CT.;
%mend ct_check;

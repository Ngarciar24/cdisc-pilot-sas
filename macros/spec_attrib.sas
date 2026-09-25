/*******************************************************************************
* Program     : spec_attrib.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Apply the spec to a dataset: keep the spec variables in spec
*               order, set length and label, set the dataset label, remove
*               formats, and sort by the spec keys. Stops with an ERROR if a
*               spec variable is missing, has the wrong type, or has values
*               longer than the spec length (they would be truncated).
* Inputs      : data=    dataset to finalise
*               dataset= spec dataset name, e.g. DM
*               spec=    sdtm (default) or adam
* Outputs     : out= final dataset (default: overwrite DATA=)
* Macros      : %read_spec
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  IGR  Initial version
*******************************************************************************/

%macro spec_attrib(data=, dataset=, out=, spec=sdtm);
  %local lib mem nvar nchar dslabel lengths labels vars keys nerr extra i len;
  %if %length(&out) = 0 %then %let out = &data;
  %let dataset = %upcase(&dataset);
  %if %length(&data) = 0 or %length(&dataset) = 0 %then %do;
    %put ERROR: [spec_attrib] DATA= and DATASET= are required.;
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

  /* Spec rows for this dataset, joined to the actual columns. */
  proc sql noprint;
    create table work._sa_spec as
      select s.*, c.name as data_name, c.type as data_type
        from work._spec_&spec as s
             left join dictionary.columns as c
             on c.libname = "&lib" and c.memname = "&mem"
                and upcase(c.name) = s.variable
       where s.dataset = "&dataset"
       order by s.varorder;

    select count(*) into :nvar trimmed from work._sa_spec;
  quit;

  %if &nvar = 0 %then %do;
    %put ERROR: [spec_attrib] No rows for &dataset in specs/&spec._spec.csv.;
    %return;
  %end;

  /* Checks: missing variables, type mismatches, values too long. */
  data work._sa_err(keep=variable problem);
    set work._sa_spec;
    length problem $80;
    if missing(data_name) then do;
      problem = 'in spec but not in data';
      output;
    end;
    else if (type = 'Char') ne (data_type = 'char') then do;
      problem = catx(' ', 'type is', data_type, 'but spec says', type);
      output;
    end;
  run;

  proc sql noprint;
    select variable, varlen into :cv1-, :cl1-
      from work._sa_spec
     where type = 'Char' and not missing(data_name) and data_type = 'char';
  quit;
  %let nchar = &sqlobs;

  %do i = 1 %to &nchar;
    proc sql noprint;
      select max(lengthn(&&cv&i)) into :len trimmed from &data;
    quit;
    %if %sysevalf(&len > &&cl&i) %then %do;
      proc sql;
        insert into work._sa_err
          values("&&cv&i", "values up to &len characters; spec length &&cl&i");
      quit;
    %end;
  %end;

  proc sql noprint;
    select count(*) into :nerr trimmed from work._sa_err;
  quit;

  %if &nerr > 0 %then %do;
    title "spec_attrib: &data vs &spec spec for &dataset";
    proc print data=work._sa_err noobs;
    run;
    title;
    %put ERROR: [spec_attrib] &nerr problem(s) for &dataset, &out not created.;
    %return;
  %end;

  /* Variables in the data that the spec does not list are dropped. */
  proc sql noprint;
    select name into :extra separated by ' '
      from dictionary.columns
     where libname = "&lib" and memname = "&mem"
       and upcase(name) not in (select variable from work._sa_spec);

    select distinct dataset_label into :dslabel trimmed from work._sa_spec;

    select case when type = 'Char' then catx(' ', variable, cats('$', varlen))
                else catx(' ', variable, '8') end
      into :lengths separated by ' '
      from work._sa_spec order by varorder;

    select catx('=', variable, quote(strip(label)))
      into :labels separated by ' '
      from work._sa_spec order by varorder;

    select variable into :vars separated by ' '
      from work._sa_spec order by varorder;

    select variable into :keys separated by ' '
      from work._sa_spec where not missing(keyseq) order by keyseq;
  quit;

  %if %length(&extra) %then
    %put NOTE: [spec_attrib] Not in the &dataset spec, dropped: &extra;

  /* LENGTH before SET fixes the variable order and lengths. */
  data &out(label="&dslabel");
    length &lengths;
    set &data(keep=&vars);
    label &labels;
    format _all_;
    informat _all_;
  run;

  %if %length(&keys) %then %do;
    proc sort data=&out;
      by &keys;
    run;
  %end;

  proc datasets lib=work nolist;
    delete _sa_spec _sa_err;
  quit;
%mend spec_attrib;

/*******************************************************************************
* Program     : read_spec.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Load a variable spec (specs/<spec>_spec.csv) and the codelists
*               (specs/ct.csv) into WORK, once per session.
* Inputs      : spec= sdtm or adam; reload= Y to force a re-read
* Outputs     : work._spec_<spec> (CSV columns order/length/key are named
*               varorder/varlen/keyseq), work._ct (order -> termorder)
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  IGR  Initial version
*******************************************************************************/

%macro read_spec(spec=sdtm, reload=N);
  %if %sysfunc(exist(work._spec_&spec)) and %sysfunc(exist(work._ct))
      and %upcase(&reload) ne Y %then %return;

  %if not %sysfunc(fileexist(&root/specs/&spec._spec.csv)) %then %do;
    %put ERROR: [read_spec] &root/specs/&spec._spec.csv not found.;
    %return;
  %end;

  data work._spec_&spec;
    infile "&root/specs/&spec._spec.csv" dsd firstobs=2 truncover lrecl=32767
           encoding='utf-8';
    /* ORDER, LENGTH and KEY are renamed to avoid SQL/DATA step keywords.   */
    length dataset $8 dataset_label $40 structure $100 varorder 8 variable $8
           label $40 type $4 datatype $8 varlen 8 keyseq 8 mandatory $3
           role $20 codelist $8 origin $200 comment $400;
    input dataset dataset_label structure varorder variable label type datatype
          varlen keyseq mandatory role codelist origin comment;
    dataset  = upcase(dataset);
    variable = upcase(variable);
  run;

  data work._ct;
    infile "&root/specs/ct.csv" dsd firstobs=2 truncover lrecl=32767
           encoding='utf-8';
    length codelist $8 datatype $8 termorder 8 term $200 decode $200;
    input codelist datatype termorder term decode;
  run;
%mend read_spec;

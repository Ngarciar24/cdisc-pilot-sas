/*******************************************************************************
* Program     : logcheck.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Scan every *.log in a folder for errors, warnings and the
*               NOTE/INFO messages that signal silent data problems. Print the
*               findings and a per-log summary; abort if anything is found.
* Inputs      : dir=   folder to scan (default &root/logs)
*               abort= Y to stop the submission on any finding (default Y)
* Outputs     : work.logcheck_findings, work.logcheck_summary;
*               macro variable LOGCHECK_N (number of findings)
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* Rules (keep in sync with tools/check_logs.py):
*   - a line starting with ERROR or WARNING;
*   - a line starting with NOTE or INFO that contains one of the patterns in
*     the PAT array below.
* Source-echo lines start with a line number, so code or comments that
* mention these words are not flagged.
*******************************************************************************/

%macro logcheck(dir=&root/logs, abort=Y);
  %global logcheck_n;
  %local nlogs;
  %let logcheck_n = 0;

  /* 1. List the logs. DOPEN/DREAD work where the X command (pipe) is off,  */
  /*    as in SAS OnDemand.                                                  */
  data work._lc_files(keep=logname);
    length logname $256;
    rc  = filename('_lcdir', "&dir");
    did = dopen('_lcdir');
    if did = 0 then do;
      put "ERROR: [logcheck] Cannot open folder &dir..";
      stop;
    end;
    do i = 1 to dnum(did);
      logname = dread(did, i);
      if lowcase(scan(logname, -1, '.')) = 'log' then output;
    end;
    rc = dclose(did);
    rc = filename('_lcdir');
  run;

  proc sort data=work._lc_files;
    by logname;
  run;

  proc sql noprint;
    select count(*) into :nlogs trimmed from work._lc_files;
  quit;

  %if &nlogs = 0 %then %do;
    %put ERROR: [logcheck] No .log files in &dir..;
    %let logcheck_n = 1;
    %goto finish;
  %end;

  /* 2. Read each log line by line and keep the findings.                    */
  data work.logcheck_findings(keep=logname lineno finding text)
       work._lc_lines(keep=logname nlines);
    set work._lc_files;
    length fullpath $512 text $256 finding $48;
    array pat {11} $48 _temporary_ (
      'uninitialized'
      'repeats of BY values'
      'values have been converted'
      'Invalid data'
      'Invalid argument'
      'W.D format was too small'
      'Missing values were generated'
      'Division by zero'
      'Mathematical operations could not be performed'
      'will be overwritten by data set'
      'stopped processing'
    );

    fullpath = catx('/', "&dir", logname);
    nlines = 0;
    infile logfile filevar=fullpath end=eof truncover lrecl=32767;
    do while (not eof);
      input text $char256.;
      nlines + 1;
      lineno = nlines;
      finding = ' ';
      if text =: 'ERROR' then finding = 'ERROR';
      else if text =: 'WARNING' then finding = 'WARNING';
      else if text =: 'NOTE' or text =: 'INFO' then do j = 1 to dim(pat);
        if index(text, strip(pat{j})) then do;
          finding = pat{j};
          leave;
        end;
      end;
      if finding ne ' ' then output work.logcheck_findings;
    end;
    output work._lc_lines;
  run;

  /* 3. Summary: one row per log, clean or not.                              */
  proc sql;
    create table work.logcheck_summary as
      select l.logname,
             l.nlines label='Lines',
             count(f.lineno) as nfind label='Findings'
        from work._lc_lines as l
             left join work.logcheck_findings as f
             on l.logname = f.logname
       group by l.logname, l.nlines
       order by l.logname;

    select count(*) into :logcheck_n trimmed from work.logcheck_findings;
  quit;

  title1 "Log check: &dir";
  title2 "&nlogs log(s) scanned, &logcheck_n finding(s)";
  proc print data=work.logcheck_summary noobs label;
  run;

  %if &logcheck_n > 0 %then %do;
    title3 'Findings';
    proc print data=work.logcheck_findings noobs;
      var logname lineno finding text;
    run;
  %end;
  title;

  proc datasets lib=work nolist;
    delete _lc_files _lc_lines;
  quit;

%finish:
  %if &logcheck_n > 0 %then %do;
    %put ERROR: [logcheck] &logcheck_n finding(s) in &dir.. See the Findings listing.;
    %if %upcase(&abort) = Y %then %abort cancel;
  %end;
  %else %put NOTE: [logcheck] &nlogs log(s) clean.;
%mend logcheck;

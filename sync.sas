/*******************************************************************************
* Program     : sync.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Clone the repository into SAS OnDemand, or pull the latest
*               commits if the clone exists, then check out a branch.
*               Run on its own, before setup.sas.
* Inputs      : GitHub repository (public, read only)
* Outputs     : ~/cdisc-pilot-sas working copy
* Macros      : none
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*
* Uses the GIT_* DATA step functions (SAS 9.4M6 and later). If outbound Git is
* blocked in your OnDemand instance, upload a zip of the branch instead.
* Pushing from SAS is not used: logs and outputs are downloaded and committed
* from your own machine.
*******************************************************************************/

%let repo   = https://github.com/Ngarciar24/cdisc-pilot-sas.git;
%let clone  = /home/&sysuserid/cdisc-pilot-sas;
%let branch = main;   /* set to the PR branch under test */

data _null_;
  length msg $200;
  if fileexist("&clone/.git") then do;
    rc = git_pull("&clone");
    msg = cats('git_pull rc=', rc);
  end;
  else do;
    rc = git_clone("&repo", "&clone");
    msg = cats('git_clone rc=', rc);
  end;
  put 'NOTE: [sync] ' msg;

  rc = git_switch_branch("&clone", "&branch");
  put "NOTE: [sync] git_switch_branch &branch rc=" rc;
run;

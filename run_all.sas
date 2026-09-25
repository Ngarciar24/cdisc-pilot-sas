/*******************************************************************************
* Program     : run_all.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Run every program in dependency order, each with its own log in
*               logs/ and listing in lst/, then scan all logs with %logcheck.
* Inputs      : programs/**, qc/**
* Outputs     : logs/*.log, lst/*.lst, plus each program's own outputs
* Macros      : %run_program, %logcheck
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  NGR  Initial version (drafted with Claude Code)
*******************************************************************************/

/* Submit setup.sas once in the session first: it defines ROOT.             */
%include "&root/setup.sas";

/* Phase 0: smoke test                                                        */
%run_program(programs/hello_raw.sas);

/* Phase 1: SDTM          (added as programs are written)                    */
/* Phase 2: ADaM                                                              */
/* Phase 3: TLFs                                                              */
/* QC                                                                         */

%logcheck();

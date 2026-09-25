/*******************************************************************************
* Program     : setup.sas
* Study       : CDISCPILOT01 (public test data)
* Purpose     : Session setup: root path, options, librefs, macro autocall.
*               Submit once per SAS session; every program re-includes it.
* Inputs      : none
* Outputs     : librefs RAW SDTM ADAM REF; macro variable ROOT
* Macros      : autocall library &root/macros
* Author      : Ngarciar24
* Created     : 2026-09-25
* SAS version : 9.4M8 (SAS OnDemand for Academics)
* Change log  : 2026-09-25  IGR  Initial version
*******************************************************************************/

/* The only environment-specific line in the repo.                            */
/* SAS OnDemand: home is /home/<userid>, so a clone in ~/cdisc-pilot-sas      */
/* needs no edit. Elsewhere, replace with the absolute path of the clone.     */
%let root = /home/&sysuserid/cdisc-pilot-sas;

/* Log discipline: turn silent data problems into errors. Do not weaken these */
/* to quiet a log; fix the cause.                                             */
options mergenoby=error   /* MERGE without BY                                 */
        varinitchk=error  /* variable used but never assigned                 */
        dkricond=error    /* DROP/KEEP/RENAME on input names a missing var    */
        dkrocond=error    /* same, on output                                  */
        msglevel=i        /* INFO notes, e.g. variable overwritten in MERGE   */
        mprint nosymbolgen nomlogic
        dlcreatedir       /* LIBNAME creates the folder if it is missing      */
        validvarname=v7
        nofullstimer
        ;

/* SAS datasets live next to the committed XPTs; *.sas7bdat is git-ignored.   */
libname raw  "&root/data/raw";
libname sdtm "&root/data/sdtm";
libname adam "&root/data/adam";
libname ref  "&root/data/reference";

/* Macros in macros/ are found by name (file name = macro name, lower case).  */
options mautosource sasautos=("&root/macros" sasautos);

%put NOTE: [setup] root=&root;
%put NOTE: [setup] SAS &sysvlong on &sysscpl, run by &sysuserid, &sysdate9 &systime;

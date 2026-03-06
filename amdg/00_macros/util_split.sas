 /*----------------------------------------------------------------*\
 | MACRO TO CREATE LISTS FOR PASS-THROUGH QUERY LOOPS								|
 | AUTHOR: Michael Edwards 2018-12-03			                     			|
  \*---------------------------------------------------------------*/													
/**/

 /*-----------------------------------------------------------------*\
 | DESCRIPTION OF MACRO PARAMETERS:                                  |
 |  TGT_DSN : REQUIRED. DS TO GENERATE LISTS FROM    							 	 |
 |	LST_FLD	: REQUIRED. VARIABLE WITHIN DS TO POPULATE LIST			  	 | 
 |						USED FOR OPTIONAL QA VALUE SELECTIONS AS WELL.			 	 |
 |	LST_NBR	: REQUIRED. NUMBER OF UNIQUE LST_FLD VALUES IN EACH LIST | 
 |						DEFAULT IS 2000																				 |
 | UPDATE HISTORY:                                                   |
 \*-----------------------------------------------------------------*/

%macro util_split(tgt_dsn=,lst_fld=,lst_nbr=2000);
	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=&tgt_dsn);
	%if &nobs. <= &lst_nbr. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&lst_nbr,ceil);
	data %do i = 1 %to &ndsn.; ltmp_list_&i. %end; ;	 
		retain x;
		set &tgt_dsn(keep=&lst_fld) nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output ltmp_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output ltmp_list_&i.;
		%end;
	run;	
%mend;
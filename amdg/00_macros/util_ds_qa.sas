 /*----------------------------------------------------------------*\
 | MACRO TO PRINT VARIOUS QA REPORTS																|
 | AUTHOR: Michael Edwards 2018-12-03			                     			|
  \*---------------------------------------------------------------*/													
/**/

 /*-----------------------------------------------------------------*\
 | MACRO TO CONDUCT OVERALL QA OF TGT_DS, SELECT SAMPLE VALUES 			 |
 | FROM TGT_DS AND PRINT VARIOUS QA REPORTS FROM 1 OR MORE QA DS		 |
 | Author: Michael W. Edwards 2018-12-03                             |
 |                                                                   |
 | DESCRIPTION OF MACRO PARAMETERS:                                  |
 |  TGT_DSN : REQUIRED. DS TO QA							      							 	 |
 |	UNQ 	 	: REQUIRED. UNIQUE VARIABLE WITHIN DS FOR OVERALL QA.  	 | 
 |						USED FOR OPTIONAL QA VALUE SELECTIONS AS WELL.			 	 |
 |	NOSUM	 	: OPTIONAL. SUPRESS OVERALL SUMMARY REPORT.  DEFAULT = 1 | 
 |	NOCO	 	: OPTIONAL. SUPRESS TGT_DS CONTENTS. DEFAULT = 1	 			 | 
 |  BYVARS	: OPTIONAL. LIST OF VARIABLES TO EVALUATE FOR QA VALUE 	 | 
 |						SELECTIONS						 	 														 	 |
 |  BYLP		: REQUIRED WITH BYVARS.  DEFAULT = 0									 	 |	
 |						1 = LOOP THROUGH EACH &BYVAR. AND CONDUCT            	 |
 |								INDEPENDENT SAMPLE VALUE SELECTIONS FOR EACH.    	 |
 |						0 = BYVARS WILL BE CONSIDERED AS A SET WITH A SAMPLE 	 |
 |								VALUE SELECTION FOR EACH COMBINATION PRESENT     	 |
 |								IN THE DS				 	 															 	 |
 |  FMTVARS : OPTIONAL. IDENTIFIES BYVARS IN NEED OF A FORMAT	 			 |
 |  FMTLST 	: REQUIRED WITH FMTVARS. FORMATS FOR FMTVARS.					   |
 |						NOTE: FORMATLST ORDER MUST MATCH FMTVARS ORDER		   	 |
 |  QA_NUM	: OPTIONAL. NUMERICAL IDENTIFIER FOR THIS  						 	 |
 |						INSTANCE.  DEFAULT = 1														   	 |
 |  QA_DSN	: OPTIONAL WITH BYVARS. DATASET FROM WHICH 	 					 	 |
 |						QA REPORTS WILL BE PRINTED FOR SELECTED QA VALUES		 	 | 
 |						DEFAULT IS TGT_DSN																		 |
 |	QA_PRINTVARS: OPTIONAL.  SELECT VARIABLES TO PRINT FROM QA_DSN 	 |
 | UPDATE HISTORY:                                                   |
 \*-----------------------------------------------------------------*/

%macro util_ds_qa(tgt_dsn=,unq=,nosum=1,noco=1,byvars=,bylp=0,fmtvars=,fmtlst=,qa_num=1,qa_dsn=,qa_printvars=);

/*OBTAIN DS NAME*/  
proc contents data=&tgt_dsn. out=t&vz._ds_name noprint; run;
data _null_; set t&vz._ds_name; by memname; if first.memname then do; lib_memname=trim(libname)!!"."!!memname; call symput("ds_name",lib_memname); call symput("ds_name_og",lib_memname); output; end; run;
title "QA REPORT: &ds_name_og.";
/*BY VAR FREQUENCIES */  
%if %length(&byvars) %then %do;
	%if %length(&fmtvars) %then %do;
		data _null_; length vars $32767.; array vars_  &fmtvars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&fmtvars.",i)!!'=f'!!scan("&fmtvars.",i); end; call symput("fmtvars_rn",vars); run; 
		data _null_; length vars $32767.; array vars_  &fmtvars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' f'			!!scan("&fmtvars.",i); end; call symput("fmtvars_f",vars); run; 				
		data t&vz._data_fmtd; 
			set &ds_name.(rename=(&fmtvars_rn.)); 
			%let fmt_num = 1; %let nowvar_f = %qscan(&fmtvars_f.,&fmt_num.,,s); %let nowvar = %qscan(&fmtvars.,&fmt_num.,,s); %let nowfmt = %qscan(&fmtlst.,&fmt_num.,,s); 
			%do %while (&nowvar. ne); 
				&nowvar. = put(&nowvar_f,&nowfmt.); 
			%let fmt_num = %eval(&fmt_num.+1); %let nowvar_f = %qscan(&fmtvars_f.,&fmt_num.,,s); %let nowvar = %qscan(&fmtvars.,&fmt_num.,,s); %let nowfmt = %qscan(&fmtlst.,&fmt_num.,,s); 
			%end; 
			drop &fmtvars_f.;
		run;   
		%let ds_name = t&vz._data_fmtd;
	%end;
%end;    
/* OPTIONAL BY VAR UNIQUE VALUE SELECTION QA REPORTS 														*/    
/* SELECTS UNQ VALUES FROM TGT_DS FOR ALL COMBINATIONS OF BYVAR GROUP IN TGT DS */
/* OR OPTIONALLY SELECTS UNQ VALUES FOR EACH GIVEN BYVAR 												*/       
%if %length(&byvars) %then %do;
	data _null_; length vars $32767.; vars = tranwrd("&byvars."," ",","); call symput("byvars_c",vars); run;
	%if &bylp = 0 %then %do;
		title2 "QA BYVAR UNIQUE COUNTS AND SAMPLE UNIQUE VALUE SELECTION:&byvars.";
		proc sort data=&ds_name. out=t&vz._mem_examples_&qa_num.(keep=&unq. &byvars.) nodupkey; by &byvars.; run;
		proc sql; create table t&vz._byvars_unq_counts as (select &byvars_c., count(distinct &unq.) as distinct_count_&unq. from &ds_name. group by &byvars_c.); quit;
		proc sort data=t&vz._mem_examples_&qa_num.; by &byvars.; run;
		proc sort data=t&vz._byvars_unq_counts; by &byvars.; run;
		data t&vz._mem_examples_&qa_num._p; length rownum 3; set t&vz._mem_examples_&qa_num.; rownum+1; run;
		data t&vz._byvars_unq_counts_p; length rownum 3; set t&vz._byvars_unq_counts; rownum+1; run;
		data t&vz._mbr_select_report; merge t&vz._byvars_unq_counts_p(keep=rownum distinct_count_&unq.) t&vz._mem_examples_&qa_num._p(rename=(&unq.=sample_&unq.)); by rownum; drop rownum; run;
		proc print data=t&vz._mbr_select_report noobs; run;
	%goto unq_reporting;
	%end;
	%else %do; /*BY VAR LOOP*/  
		%let nowvar = %scan(&byvars.,&bylp.);  
		%do %while (&nowvar. ne);	
			/*OVERALL QA REPORT FOR BY VAR*/
			title2 "QA UNIQUE VALUE SELECTION:&nowvar.";						
			proc sort data=&ds_name. out=t&vz._mem_examples_&qa_num. nodupkey; by &nowvar.; run;
			proc print data=t&vz._mem_examples_&qa_num. noobs; var &unq. &nowvar.; run;	
			/*QA REPORTING FROM QA_DSN FOR SELECTED UNQ VALUES*/
			%unq_reporting:; %let printme = ; %if %length(&qa_printvars) %then %let printme = var &qa_printvars.; %if %length(&qa_dsn)=0 %then %let qa_dsn = &tgt_dsn.;  
			%util_obsnvars(ds=t&vz._mem_examples_&qa_num.); %let mem_num = 1;
			%global ndsn_&qa_num.; %if &nobs. <= &mem_num. %then %let ndsn_&qa_num. = 1; %else %let ndsn_&qa_num.=%sysevalf(&nobs./&mem_num,ceil);
			data %do i = 1 %to &&&ndsn_&qa_num; t&vz._qa_&qa_num._mbr_list_&i. %end; ;	 
				retain x;
				set t&vz._mem_examples_&qa_num.(keep=&unq.) nobs=nobs;
				if _n_ eq 1
				then do;
				if mod(nobs,&&&ndsn_&qa_num) eq 0
				then x=int(nobs/&&&ndsn_&qa_num);
				else x=int(nobs/&&&ndsn_&qa_num)+1;
				end;
				if _n_ le x then output t&vz._qa_&qa_num._mbr_list_1;
				%do i = 2 %to &&&ndsn_&qa_num;
				else if _n_ le (&i.*x)
				then output t&vz._qa_&qa_num._mbr_list_&i.;
				%end;
			run;	
			/*QA REPORTING UNQ VALUE LOOP*/
			%do iii=1 %to &&&ndsn_&qa_num;
				data _null_; set t&vz._qa_&qa_num._mbr_list_&iii.; call symput("mem_now",&unq.); run;
				title2 "UNIQUE VALUE SELECTION: QA:&mem_now. - RECORDS FROM &qa_dsn"; 
				proc print data=&qa_dsn. noobs; where &unq.=&mem_now.; &printme.; run;
			%end;
			proc datasets nolist; delete t&vz._mem_examples_&qa_num.; run;
			%if &bylp = 0 %then %goto exit;
		%let bylp = %eval(&bylp.+1); %let nowvar = %scan(&byvars.,&bylp.);
		%end; 
	%end; /*END BY VAR LOOP*/   
	%exit:;
	title2 "";
%end; 
/* OVERALL QA REPORTS FOR DS */
proc freq data=&ds_name. nlevels; tables &unq. / noprint; run; 
%if &noco %then %goto skipco;
proc contents data=&ds_name. short order=varnum; run;
%skipco:;
%if &nosum %then %goto skipsum;
proc means data=&ds_name. n sum mean min max maxdec=4; run;
/* CLEANUP */
%skipsum:;
proc datasets nolist; delete t&vz._mem_examples_&qa_num. t&vz._data_fmtd t&vz._byvars_unq_counts; run;      
%mend;


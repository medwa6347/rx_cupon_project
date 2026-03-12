 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC OOP ACCUMULATOR ANALYSIS FOR JANSSEN (201904)   |
 | AUTHOR: MICHAEL EDWARDS 2019-04-01 AMDG                          |
 | NOTE: SEPERATE, ALL PLAN ANALYSIS								|
 \*----------------------------------------------------------------*/													
/**/
                     
* COMMAND LINE;								
/*
cd /hpsaslca/mwe/janssen/oop_201808/amdg
sas_tws 0550_oop_claims_analysis_galaxy_t1.sas -autoexec /hpsaslca/mwe/janssen/oop_201808/amdg/00_common/00_common.sas &                                                       
*/      
	
/*
rm -rf /hpsaslca/mwe/janssen/oop_201808/amdg_data/02_input/t6*
*/

%macro data_oop_claims(testobs=);
	
%local vz; %let vz = 5a; 

* GLOBAL FORMATS, OPTIONS;
%include "&om_code./00_formats/fmt_reporting.sas";
%include "&om_code./00_formats/fmt_dx_codes.sas"; 
%include "&om_code./00_formats/fmt_proc_codes.sas";
%include "&om_code./00_formats/fmt_ndc_codes.sas";   
%include "&om_code./00_formats/fmt_st2region.sas";
%include "&om_code./00_formats/fmt_st2cregion.sas";
%include "&om_code./00_formats/fmt_briova.sas";
options compress=yes;

%let start_dt				=	'01Jan2019'd;
%let yr_num 				= 1;
%let months 				= 12;
%let dx_fld_num			=	4;
%let prdnum					=	8;        
%let dxnum					=	9;
%let dx_names 			= ra_dx pso_dx psa_dx as_dx cd_dx uc_dx myl_dx pc_dx pcm_dx;

/*-----------------------------------------------------------------*/
/*---> IMPORT RX PLAN INFORMATION (PHBIT REPORT) <-----------------*/
/**/
%let phbit_fn = &om_data/00_common/phbit_201807.xlsx;
%util_pim(fn=&phbit_fn.,rng=Data$a1:z50000,out_tmp=t&vz._phbit_raw);

data inp.r&vz.01_final_phbit;  
	set t&vz._phbit_raw(
	keep=	  bpl_id_businessopt 
					business_segment 
					funding_arrangment
					combined_medical_and_pharmacy_dr 
					coupon_adjustment_benefit_plan_p 
					deductible_accumulator 
					deductible_embedded_non_embedded 
					out_of_pocket_maximum_accumulato 
					oop_embedded_non_embedded
					deductible_family_in_network__
					deductible_individual_in_network
					oop_family_in_network__
					oop_individual_in_network__
					rider_code
	rename=(bpl_id_businessopt						   	= rx_ben_pln_nbr                    
	        business_segment                  = raw_pln_business_segment         
	        funding_arrangment                = funding_arrangment        
	        combined_medical_and_pharmacy_dr	= raw_pln_oop_med_rx_type 
	        coupon_adjustment_benefit_plan_p  = cpn_ben_plan_prt        
	        deductible_accumulator            = deductible_accum        
	        deductible_embedded_non_embedded  = ded_embedded_non_embedded        
	        out_of_pocket_maximum_accumulato  = oop_max_accum        
	        oop_embedded_non_embedded         = oop_embedded_non_embedded
	        deductible_family_in_network__		=	raw_pln_fam_deductible 
	        deductible_individual_in_network	=	raw_pln_indv_deductible 	  
					oop_family_in_network__						= raw_pln_fam_oop 
					oop_individual_in_network__				= raw_pln_indv_oop 
	        )
	        );                 
	business_segment 											= put(raw_pln_business_segment,$phbit_bus_seg_fmt.); 
	oop_med_rx_type	 											= put(raw_pln_oop_med_rx_type,$pln_oop_med_rx_type_fmt.);
	fam_deductible												= input(raw_pln_fam_deductible,5.);
	indv_deductible												= input(raw_pln_indv_deductible,5.);
  fam_oop   														= input(raw_pln_fam_oop ,5.); 
	indv_oop                              = input(raw_pln_indv_oop,5.);
	if missing(rx_ben_pln_nbr) then delete;
	drop raw_:;
run;
proc sort data=inp.r&vz.01_final_phbit; by rx_ben_pln_nbr fam_deductible; run;  

/*-----------------------------------------------------------------*/
/*---> DEFINE GALAXY OPTIONS <-------------------------------------*/
/**/
%local galaxy_specs;
%let galaxy_specs = database=glxyprod user="&un_unix." password="&pw_unix.";

%let test=;        
%if %length(&testobs) %then %let test = reset inobs=&testobs.;

/*-----------------------------------------------------------------*/
/*---> GLOBAL VARIABLE LISTS <-------------------------------------*/
/**/  
/*PROCESS RX VARS*/
%let rx_vars = amt_allowed_1 amt_allowed_2 amt_allowed_3 amt_allowed_4 amt_allowed_5 amt_allowed_6 amt_allowed_7 amt_allowed_8 amt_allowed_99 amt_copay_1 amt_copay_2 amt_copay_3 amt_copay_4 amt_copay_5 amt_copay_6 amt_copay_7 amt_copay_8 amt_copay_99 amt_deductbl_1 amt_deductbl_2 amt_deductbl_3 amt_deductbl_4 amt_deductbl_5 amt_deductbl_6 amt_deductbl_7 amt_deductbl_8 amt_deductbl_99 amt_coin_1 amt_coin_2 amt_coin_3 amt_coin_4 amt_coin_5 amt_coin_6 amt_coin_7 amt_coin_8 amt_coin_99 amt_manf_cpn_1 amt_manf_cpn_2 amt_manf_cpn_3 amt_manf_cpn_4 amt_manf_cpn_5 amt_manf_cpn_6 amt_manf_cpn_7 amt_manf_cpn_8 amt_manf_cpn_99 amt_cpn_calc_1 amt_cpn_calc_2 amt_cpn_calc_3 amt_cpn_calc_4 amt_cpn_calc_5 amt_cpn_calc_6 amt_cpn_calc_7 amt_cpn_calc_8 amt_cpn_calc_99 amt_cpn_calc amt_allowed amt_copay amt_deductbl amt_coin days_supply amt_manf_cpn; 
data _null_; length vars $32767.; array vars_  &rx_vars.; 							retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_'			!!scan("&rx_vars.",i); 							end; call symput("sum_rx_vars",vars); run; 				
data _null_; length vars $32767.; array vars_  &sum_rx_vars.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_rx_vars.",i)						!!'='!!scan("&rx_vars.",i); end; call symput("sum_rx_vars_rn",vars); run; 					
/*PLAN A VARS, LEFT-SIDE RX PLAN, PLAN SWITCHERS*/
%let pln_vars_all = rx_ben_pln_nbr business_segment funding_arrangment cpn_ben_plan_prt deductible_accum oop_max_accum cdhp_ind fam_deductible	indv_deductible	fam_oop	indv_oop;
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&pln_vars_all.",i)					!!'=pln_a_'!!scan("&pln_vars_all.",i); end; call symput("pln_vars_a_rn",vars); run; 					
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_a_'		!!scan("&pln_vars_all.",i); 				end; call symput("pln_a_vars",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&pln_vars_all.",i)					!!'=pln_l_'!!scan("&pln_vars_all.",i); end; call symput("pln_vars_left_rn",vars); run; 					
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_l_'		!!scan("&pln_vars_all.",i); 				end; call symput("pln_l_vars",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&pln_vars_all.",i)					!!'=pln_fst_'!!scan("&pln_vars_all.",i); end; call symput("pln_vars_fst_rn",vars); run; 					
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_fst_'	!!scan("&pln_vars_all.",i); 				end; call symput("pln_fst_vars",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&pln_vars_all.",i)					!!'=pln_snd_'!!scan("&pln_vars_all.",i); end; call symput("pln_vars_snd_rn",vars); run; 					
data _null_; length vars $32767.; array vars_  &pln_vars_all.; 					retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_snd_'	!!scan("&pln_vars_all.",i); 				end; call symput("pln_snd_vars",vars); run; 				
/*MULTIPLE PLAN SELECT*/
%let pln_vars_plan_multi = business_segment funding_arrangment cpn_ben_plan_prt deductible_accum oop_max_accum cdhp_ind;
/*PLAN CHANGE VARS*/
%let pln_vars_change = rx_ben_pln_nbr business_segment funding_arrangment cpn_ben_plan_prt deductible_accum oop_max_accum cdhp_ind;
data _null_; length vars $32767.; array vars_  &pln_vars_change.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_a_'		!!scan("&pln_vars_change.",i); 			end; call symput("pln_a_vars_nof",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_change.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_l_'		!!scan("&pln_vars_change.",i); 			end; call symput("pln_l_vars_nof",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_change.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_fst_'	!!scan("&pln_vars_change.",i); 			end; call symput("pln_fst_vars_nof",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_change.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_snd_'	!!scan("&pln_vars_change.",i); 			end; call symput("pln_snd_vars_nof",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_change.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_l2f_'	!!scan("&pln_vars_change.",i); 			end; call symput("pln_l2f_vars",vars); run; 				
data _null_; length vars $32767.; array vars_  &pln_vars_change.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pln_f2s_'	!!scan("&pln_vars_change.",i); 			end; call symput("pln_f2s_vars",vars); run; 				

%let all_whr_2018 = where tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_oop_max_accum in ('Y') and pln_a_funding_arrangment in ('ASO','FI') and pln_a_deductible_accum in ('Y','N') and pln_a_cpn_ben_plan_prt in ('Y','N') and aa_analysis_year = 2018;
%let all_whr = where tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_oop_max_accum in ('Y') and pln_a_funding_arrangment in ('ASO','FI') and pln_a_deductible_accum in ('Y','N') and pln_a_cpn_ben_plan_prt in ('Y','N');
%let ded = and pln_a_deductible_accum in ('Y');
%let oop = and pln_a_deductible_accum in ('N');  

/*-----------------------------------------------------------------*/
/*---> MASTER DATES <----------------------------------------------*/
/**/ 

data _null_;
	cur_st 				 = intnx('year',&start_dt.,&yr_num.,'beg');
	cur_end 			 = intnx('month',cur_st,&months.-1,'end');
	st2end				 = datdif(cur_st,cur_end,'act/act');
	cur_st_mon		 = put(input(cats(month(cur_st)),3.),z2.);
	cur_end_mon		 = put(input(cats(month(cur_end)),3.),z2.);
	cur_st_yrn		 = put(input(cats(year(cur_st)),4.),z4.);
	cur_end_yrn		 = put(input(cats(year(cur_end)),4.),z4.);
	cur_st_dyn		 = put(input(cats(day(cur_st)),3.),z2.);
	cur_end_dyn		 = put(input(cats(day(cur_end)),3.),z2.);
	cur_st_db2		 =	"'"!!cur_st_yrn!!"-"!!cur_st_mon!!"-"!!cur_st_dyn!!"'";
	cur_end_db2		 =	"'"!!cur_end_yrn!!"-"!!cur_end_mon!!"-"!!cur_end_dyn!!"'";
	cur_end_yrmo	 = cur_end_yrn!!cur_end_mon;	
	cur_st_lb 		 = intnx('month',cur_st,-12,'beg');
	cur_st_lb_mon	 = put(input(cats(month(cur_st_lb)),3.),z2.);
	cur_st_lb_yrn	 = put(input(cats(year(cur_st_lb)),4.),z4.);
	cur_st_lb_dyn	 = put(input(cats(day(cur_st_lb)),3.),z2.);
	cur_st_lb_db2	 =	"'"!!cur_st_lb_yrn!!"-"!!cur_st_lb_mon!!"-"!!cur_st_lb_dyn!!"'";
	cur_end_lb 		 = intnx('month',intnx('month',cur_st,-12,'beg'),11,'end');
	cur_end_lb_mon = put(input(cats(month(cur_end_lb)),3.),z2.);
	cur_end_lb_yrn = put(input(cats(year(cur_end_lb)),4.),z4.);
	cur_end_lb_dyn = put(input(cats(day(cur_end_lb)),3.),z2.);
	cur_end_lb_db2 =	"'"!!cur_end_lb_yrn!!"-"!!cur_end_lb_mon!!"-"!!cur_end_lb_dyn!!"'";
	call symput("cur_st",cur_st);				
	call symput("cur_end",cur_end);  
	call symput("st2end",st2end);
	call symput("cur_st_yrn",cur_st_yrn);  
	call symput("cur_st_db2",cur_st_db2	);  
	call symput("cur_end_db2",cur_end_db2 );  
	call symput("cur_end_yrmo", cur_end_yrmo);
	call symput("cur_st_long",trim(left((put(intnx('month',cur_st,0,'beg'),WORDDATE20.)))));
	call symput("cur_end_long",trim(left((put(intnx('month',cur_end,0,'end'),WORDDATE20.)))));		
	call symput("cur_st_lb",cur_st_lb);				
	call symput("cur_st_lb_db2",cur_st_lb_db2	); 
	call symput("cur_end_lb_db2",cur_end_lb_db2); 
	call symput("cur_st_wb_long",trim(left((put(intnx('year',cur_st_lb,-5,'beg'),WORDDATE20.)))));
	call symput("cur_st_wb",cur_st_wb);				
	call symput("cur_st_wb_db2",cur_st_wb_db2	);  
run;

%put NOTE: yr_num 				= &yr_num.				;
%put NOTE: cur_st_db2     = &cur_st_db2     ;
%put NOTE: cur_end_db2    = &cur_end_db2    ;
%put NOTE: cur_st_lb_db2  = &cur_st_lb_db2  ;
%put NOTE: cur_end_lb_db2	= &cur_end_lb_db2 ;
%put;

/*-----------------------------------------------------------------*/
/*---> INITIALIZE EXCEL FOR QA OUTPUTS <---------------------------*/
/**/ 
%let rp_hcp = "&om_data./05_out_rep/Janssen_&vz._yr&yr_num._OOP_QA_Reporting.xls";
%let ex_op = sheet_interval='none' embedded_titles='yes';
* GRAPHICS ON;
ods listing close;
ods listing gpath="&om_data./05_out_rep/";
ods output; ods graphics on;
ods excel file=&rp_hcp. style=XL&vz.sansPrinter; 

/*-----------------------------------------------------------------*/
/*---> PULL LEFT-SIDE RX PLANS <-----------------------------------*/
/**/               

	%put NOTE: Galaxy All Rx Plans...;
	%put;
	proc sql stimer; &test.;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;

			 create table inp.t&vz.13_yr&yr_num._rx_plans_raw_left as
		       select distinct * from connection to db2
				 		(select   
	                rx.mbr_sys_id
	  						, rx.fill_dt                          as fill_date
		         		, rx.phrm_ben_pln_nbr 								as rx_ben_pln_nbr 	
		         		, rx.mkt_seg_cd 											as mkt_seg_cd 
		         		, cseg.cust_drvn_hlth_pln_cd 					as cdhp_ind
	  				 from 
	  				 		galaxy.pharmacy_claim_commercial rx
	  				 		inner join galaxy.customer_segment_coverage cseg
		  				 		on rx.cust_seg_nbr 		 = cseg.cust_seg_nbr 
		  				 		and rx.cust_seg_sys_id = cseg.cust_seg_sys_id 
		  				 		and rx.ben_strct_1_cd  = cseg.pln_var_subdiv_cd 
		  				 		and rx.ben_strct_2_cd  = cseg.rpt_cd_br_cd 
		  				 		and rx.prdct_cd 			 = cseg.prdct_cd 
						 where 
						 	   rx.fill_dt between &cur_st_lb_db2. and &cur_end_lb_db2.
						 and rx.fill_dt between cseg.cust_seg_cov_row_eff_dt and cseg.cust_seg_cov_row_end_dt   
					 	 and rx.mbr_sys_id>0         		 
				 	 for fetch only
				 	 );	
					
	   disconnect from db2;
	quit;		

/*-----------------------------------------------------------------*/
/*---> MOST RECENT LEFT-SIDE RX PLAN  <----------------------------*/
/**/
proc sort data=inp.t&vz.13_yr&yr_num._rx_plans_raw_left; by mbr_sys_id fill_date; run;
data inp.t&vz.14_yr&yr_num._rx_plans_left; 
	set inp.t&vz.13_yr&yr_num._rx_plans_raw_left;
	by mbr_sys_id;
	if last.mbr_sys_id then output;
	keep mbr_sys_id rx_ben_pln_nbr mkt_seg_cd cdhp_ind;
run;
ods excel options(sheet_name="13" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.13_yr&yr_num._rx_plans_raw_left,unq=mbr_sys_id); %util_dummy_sheet;
ods excel options(sheet_name="14" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.14_yr&yr_num._rx_plans_left,unq=mbr_sys_id); %util_dummy_sheet;

*APPLY PLAN INFORMATION;
*GRAB ALL PLANS ASSOCIATED WITH CLAIM RX_BEN_PLN_NBR;
proc sql; 
	create table inp.t&vz.15_yr&yr_num._rx_plans_left as (
	select 	l.mbr_sys_id
				, l.rx_ben_pln_nbr 																					as rx_ben_pln_nbr
				, l.mkt_seg_cd																							as mkt_seg_cd
				, l.cdhp_ind																								as cdhp_ind
				, pln.business_segment 																			as business_segment           
				,	put(pln.funding_arrangment,$pln_funding_arrangment_fmt.) 	as funding_arrangment              
				, pln.cpn_ben_plan_prt 																			as cpn_ben_plan_prt
				, deductible_accum 																					as deductible_accum   
				, oop_max_accum 																						as oop_max_accum
				, pln.fam_deductible 																				as fam_deductible
				, pln.indv_deductible 																			as indv_deductible
				, pln.fam_oop 																							as fam_oop
				, pln.indv_oop 																							as indv_oop
	from inp.t&vz.14_yr&yr_num._rx_plans_left l 
	left outer join inp.r&vz.01_final_phbit pln
		on l.rx_ben_pln_nbr = pln.rx_ben_pln_nbr
	);
quit; 

*IF MULTIPLE PLANS, SELECT PLAN WITH MATCHING PLN_BUSINESS_SEGMENT;
*IF NO MATCHING BUSINESS SEGMENT THEN NULLIFY PLAN DATA;
proc sort data=inp.t&vz.15_yr&yr_num._rx_plans_left; by mbr_sys_id fam_deductible; run;
data inp.t&vz.16_yr&yr_num._rx_plans_left(sortedby=mbr_sys_id);  
	length	business_segment            $1
					funding_arrangment          $3
					cpn_ben_plan_prt 						$1
					deductible_accum						$1
					oop_max_accum								$1
					cdhp_ind										$1
					;
	set inp.t&vz.15_yr&yr_num._rx_plans_left; 
	by mbr_sys_id; 
	array plan_vars 3 &pln_vars_plan_multi.;
	retain im_out;
	if first.mbr_sys_id then im_out=0;
	if first.mbr_sys_id and last.mbr_sys_id then do; im_out=1; output; end;
	if mkt_seg_cd = business_segment and im_out ne 1 then do; im_out = 1; output; end; 
	if last.mbr_sys_id and mkt_seg_cd ne business_segment and im_out ne 1 then do; 
		do over plan_vars; plan_vars = 'U'; 
			fam_deductible = .; indv_deductible = .; fam_oop = .; indv_oop = .; 
			im_out = 1; 
			end; 
		output; 
		end;		
	drop im_out;
	format fam_deductible indv_deductible fam_oop indv_oop dollar12.2;
run; 
data inp.t&vz.17_yr&yr_num._rx_plans_left(sortedby=mbr_sys_id); 
	length	pln_l_business_segment    $1
					pln_l_funding_arrangment  $3
					pln_l_cpn_ben_plan_prt 		$1
					pln_l_deductible_accum		$1
					pln_l_oop_max_accum				$1
					pln_l_cdhp_ind						$1;	
	set inp.t&vz.16_yr&yr_num._rx_plans_left(rename=(&pln_vars_left_rn.)); 
	format pln_l_fam_deductible pln_l_indv_deductible pln_l_fam_oop pln_l_indv_oop dollar12.2; 
	keep mbr_sys_id &pln_l_vars.;
run;
ods excel options(sheet_name="17" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0);	%util_dummy_sheet;

/*-----------------------------------------------------------------*/
/*---> QA REPORTING OUTPUT <---------------------------------------*/
/**/

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

/*-----------------------------------------------------------------*/
/*---> SLIDES REPORTING  <-----------------------------------------*/
/**/

/*-----------------------------------------------------------------*/
/*---> INITIALIZE EXCEL FOR REPORTING OUTPUTS <--------------------*/
/**/                                                                                                                 
%let rp_hcp = "&om_data./05_out_rep/Janssen_OOP_AllPlanUpdate_20190401.xls";                          
%let ex_op = sheet_interval='none' embedded_titles='yes';                                                        
* GRAPHICS ON;                                                                                                   
ods listing close;                                                                                               
ods listing gpath="&om_data./05_out_rep/";                                                                       
ods output; ods graphics on;                                                                                     
ods excel file=&rp_hcp. style=XL&vz.sansPrinter;                                                                 

/*-----------------------------------------------------------------*/
/*---> SLIDES REPORTING  <-----------------------------------------*/
/**/

/*19All_1*/
ods excel options(sheet_name="19All_1" &ex_op.); 
	title "Health Plan Distribution - All UHC";
		proc sql; create table t&vz._rpt as ( 
			select "2018" as aa_analysis_year
					 , pln_l_funding_arrangment
					 , put(pln_l_deductible_accum,$yes_no_fmt.) as pln_l_deductible_accum
					 , "All Commercial" as product
					 , count(distinct mbr_sys_id) as members
			from inp.t&vz.17_yr1_rx_plans_left where pln_l_oop_max_accum in ('Y') and pln_l_funding_arrangment in ('ASO','FI') and pln_l_deductible_accum in ('Y','N') and pln_l_cpn_ben_plan_prt in ('Y','N') group by 1,2,3						
		); 
		quit;
		proc sort data=_last_; by pln_l_funding_arrangment pln_l_deductible_accum; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_l_funding_arrangment pln_l_deductible_accum; retain grp_nbr; if first.pln_l_funding_arrangment then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma18.; run;
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet;

/*19All_2*/
ods excel options(sheet_name="19All_2" &ex_op.); 
	title "Distribution of OOP Accumulator by Insurance Plan - All UHC";
		proc sql; create table t&vz._rpt as ( 
			select "2018" as aa_analysis_year
					 , pln_l_funding_arrangment
					 , put(pln_l_deductible_accum,$yes_no_fmt.) as pln_l_deductible_accum
					 , pln_l_cpn_ben_plan_prt
					 , "All Commercial" as product
					 , count(distinct mbr_sys_id) as members
			from inp.t&vz.17_yr1_rx_plans_left where pln_l_oop_max_accum in ('Y') and pln_l_funding_arrangment in ('ASO','FI') and pln_l_deductible_accum in ('Y','N') and pln_l_cpn_ben_plan_prt in ('Y','N') group by 1,2,3,4						
		); 
		quit;
		proc sort data=_last_; by pln_l_funding_arrangment pln_l_deductible_accum pln_l_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_l_funding_arrangment pln_l_deductible_accum pln_l_cpn_ben_plan_prt; retain grp_nbr; if first.pln_l_deductible_accum then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma18.; run;
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*-----------------------------------------------------------------*/
/*---> SLIDES REPORTING OUTPUT  <----------------------------------*/
/**/

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

proc datasets nolist; delete t&vz.:; run;
%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/ 

%data_oop_claims(testobs=);

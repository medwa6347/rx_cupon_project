 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC OOP ACCUMULATOR ANALYSIS FOR JANSSEN	(201808)|
 | AUTHOR: MICHAEL EDWARDS 2018-08-16 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/
                     
* COMMAND LINE;								
/*
cd /hpsaslca/mwe/janssen/oop_201808/amdg
sas_tws 0500_oop_claims_analysis_galaxy_t8.sas -autoexec /hpsaslca/mwe/janssen/oop_201808/amdg/00_common/00_common.sas &                                                       
*/      

/* 
cd /hpsaslca/mwe/janssen/oop_201808/amdg_data/02_input
rm -rf *.zip
zip dl.zip tt*
du -m
*/
	
/*
rm -rf /hpsaslca/mwe/janssen/oop_201808/amdg_data/02_input/t6*
*/

%macro data_oop_claims(no_dx=,no_pull=,no_stage=,testobs=,no_rep=,rpt_go=);
	
%local vz; %let vz = 5; 

*COMMON;
*REDUNDANT, FOR EXECUTION ON SAS EG;
%include "/hpsaslca/mwe/janssen/oop_201808/amdg/00_common/00_common.sas";
%include "&om_macros./util_dummy_sheet.sas";

* GLOBAL FORMATS, OPTIONS;
%include "&om_code./00_formats/fmt_reporting.sas";
%include "&om_code./00_formats/fmt_dx_codes.sas"; 
%include "&om_code./00_formats/fmt_proc_codes.sas";
%include "&om_code./00_formats/fmt_ndc_codes.sas";   
%include "&om_code./00_formats/fmt_st2region.sas";
%include "&om_code./00_formats/fmt_st2cregion.sas";
%include "&om_code./00_formats/fmt_briova.sas";
options compress=yes;

%let start_dt				=	'01Jan2017'd;
%let dx_fld_num			=	4;
%let prdnum					=	8;        
%let dxnum					=	9;
%let dx_names 			= ra_dx pso_dx psa_dx as_dx cd_dx uc_dx myl_dx pc_dx pcm_dx;

/*-----------------------------------------------------------------*/
/*---> IMPORT RX PLAN INFORMATION (PHBIT REPORT) <-----------------*/
/**
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

%let num 						= 2000; /*NUMBER OF MEMBERS TO PASS THROUGH GALAXY ON LOOPING QUERIES */

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
/*PLAN RESPONSIBLE VARS*/
%let pln_vars_resp = pln_a_fam_deductible pln_a_indv_deductible pln_a_fam_oop pln_a_indv_oop pln_l_fam_deductible pln_l_indv_deductible pln_l_fam_oop pln_l_indv_oop pln_fst_fam_deductible pln_fst_indv_deductible pln_fst_fam_oop pln_fst_indv_oop pln_snd_fam_deductible pln_snd_indv_deductible pln_snd_fam_oop pln_snd_indv_oop;
/*FAMILY STAT VARS*/
%let count_fam_stat_vars = ab_demo_fam_count_family ab_demo_fam_count_adults ab_demo_fam_count_dependents ab_demo_fam_count_males ab_demo_fam_count_females ab_demo_fam_count_ch_mem ab_demo_fam_count_non_ch_mem; 
/*CLAIMS RESPONSIBLE SUMMARY VARS*/
%let cpn_vars  =  amt_manf_cpn_1 amt_manf_cpn_2 amt_manf_cpn_3 amt_manf_cpn_4 amt_manf_cpn_5 amt_manf_cpn_6 amt_manf_cpn_7 amt_manf_cpn_8 amt_manf_cpn_99 amt_cpn_calc_1 amt_cpn_calc_2 amt_cpn_calc_3 amt_cpn_calc_4 amt_cpn_calc_5 amt_cpn_calc_6 amt_cpn_calc_7 amt_cpn_calc_8 amt_cpn_calc_99 amt_cpn_calc amt_manf_cpn;
%let oop_vars  =  amt_allowed_1 amt_allowed_2 amt_allowed_3 amt_allowed_4 amt_allowed_5 amt_allowed_6 amt_allowed_7 amt_allowed_8 amt_allowed_99 amt_copay_1 amt_copay_2 amt_copay_3 amt_copay_4 amt_copay_5 amt_copay_6 amt_copay_7 amt_copay_8 amt_copay_99 amt_deductbl_1 amt_deductbl_2 amt_deductbl_3 amt_deductbl_4 amt_deductbl_5 amt_deductbl_6 amt_deductbl_7 amt_deductbl_8 amt_deductbl_99 amt_coin_1 amt_coin_2 amt_coin_3 amt_coin_4 amt_coin_5 amt_coin_6 amt_coin_7 amt_coin_8 amt_coin_99 amt_manf_cpn_1 amt_manf_cpn_2 amt_manf_cpn_3 amt_manf_cpn_4 amt_manf_cpn_5 amt_manf_cpn_6 amt_manf_cpn_7 amt_manf_cpn_8 amt_manf_cpn_99 amt_cpn_calc_1 amt_cpn_calc_2 amt_cpn_calc_3 amt_cpn_calc_4 amt_cpn_calc_5 amt_cpn_calc_6 amt_cpn_calc_7 amt_cpn_calc_8 amt_cpn_calc_99 amt_tot_oop_1 amt_tot_oop_2 amt_tot_oop_3 amt_tot_oop_4 amt_tot_oop_5 amt_tot_oop_6 amt_tot_oop_7 amt_tot_oop_8 amt_tot_oop_99 amt_cpn_calc amt_allowed amt_copay amt_deductbl amt_coin amt_manf_cpn amt_tot_oop;
data _null_; length vars $32767.; array vars_  &oop_vars.; 							retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_fam_'	!!scan("&oop_vars.",i); 						end; call symput("sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &oop_vars.; 							retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_indv_'!!scan("&oop_vars.",i); 						end; call symput("sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &cpn_vars.; 							retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_fam_'	!!scan("&cpn_vars.",i); 						end; call symput("sum_fam_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &cpn_vars.; 							retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_indv_'!!scan("&cpn_vars.",i); 						end; call symput("sum_indv_cpn_vars",vars); run; 					
/*CLAIMS RESPONSIBLE COUNT VARS*/
%let count_vars =  prd_clm_flag clm_flag clm_flag_1 clm_flag_2 clm_flag_3 clm_flag_4 clm_flag_5 clm_flag_6 clm_flag_7 clm_flag_8 clm_flag_99 cpn_flag cpn_flag_1 cpn_flag_2 cpn_flag_3 cpn_flag_4 cpn_flag_5 cpn_flag_6 cpn_flag_7 cpn_flag_8 cpn_flag_99 p_cpn_flag p_cpn_flag_1 p_cpn_flag_2 p_cpn_flag_3 p_cpn_flag_4 p_cpn_flag_5 p_cpn_flag_6 p_cpn_flag_7 p_cpn_flag_8 p_cpn_flag_99;
data _null_; length vars $32767.; array vars_  &count_vars.; 						retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_fam_'	!!scan("&count_vars.",i); 					end; call symput("sum_fam_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &count_vars.; 						retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' sum_indv_'!!scan("&count_vars.",i); 					end; call symput("sum_indv_count_vars",vars); run; 					
/*CLAIMS RESPONSIBLE NINE ONLY VARS*/
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' nino_'		!!scan("&sum_indv_oop_vars.",i); 		end; call symput("nino_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' nino_'		!!scan("&sum_indv_count_vars.",i); 	end; call symput("nino_sum_indv_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_oop_vars.",i)			!!'=nino_'!!scan("&sum_indv_oop_vars.",i)	; end; call symput("nino_sum_indv_oop_vars_rn"		,vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_count_vars.",i)		!!'=nino_'!!scan("&sum_indv_count_vars.",i); end; call symput("nino_sum_indv_count_vars_rn"	,vars); run; 					
/*CLAIMS RESPONSIBLE TRUE GHOST VARS - MISC*/                         	
%let misc_oop_vars 	= paid_date resp_met resp_days resp_month;        	
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&misc_oop_vars.",i); 				end; call symput("g_misc_oop_vars"		,vars); run; 					
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&misc_oop_vars.",i)					!!'=g_'!!scan("&misc_oop_vars.",i); end; call symput("g_misc_oop_vars_rn",vars); run; 					
/*CLAIMS RESPONSIBLE TRUE GHOST VARS - SUMMARY*/                      	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&sum_fam_oop_vars.",i); 		end; call symput("g_sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.;		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&sum_fam_count_vars.",i); 	end; call symput("g_sum_fam_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&sum_indv_oop_vars.",i); 		end; call symput("g_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&sum_indv_count_vars.",i); 	end; call symput("g_sum_indv_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_oop_vars.",i)			!!'=g_'!!scan("&sum_fam_oop_vars.",i)		; end; call symput("g_sum_fam_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_count_vars.",i)		!!'=g_'!!scan("&sum_fam_count_vars.",i)	; end; call symput("g_sum_fam_count_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_oop_vars.",i)			!!'=g_'!!scan("&sum_indv_oop_vars.",i)	; end; call symput("g_sum_indv_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_count_vars.",i)		!!'=g_'!!scan("&sum_indv_count_vars.",i); end; call symput("g_sum_indv_count_vars_rn"	,vars); run; 					
/*CLAIMS RESPONSIBLE TRUE GHOST DELTA VARS*/                          	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' gdl_'			!!scan("&sum_fam_oop_vars.",i); 		end; call symput("gdl_sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' gdl_'			!!scan("&sum_fam_count_vars.",i); 	end; call symput("gdl_sum_fam_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' gdl_'			!!scan("&sum_indv_oop_vars.",i); 		end; call symput("gdl_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' gdl_'			!!scan("&sum_indv_count_vars.",i); 	end; call symput("gdl_sum_indv_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' gdl_'			!!scan("&misc_oop_vars.",i); 				end; call symput("gdl_misc_oop_vars"	,vars); run; 					
/*CLAIMS RESPONSIBLE POTENTIAL GHOST VARS - MISC*/                    	
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' p_'				!!scan("&misc_oop_vars.",i); 				end; call symput("p_misc_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&misc_oop_vars.",i)					!!'=p_'!!scan("&misc_oop_vars.",i); end; call symput("p_misc_oop_vars_rn",vars); run; 					
/*CLAIMS RESPONSIBLE POTENTIAL GHOST VARS*/                           	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' p_'				!!scan("&sum_fam_oop_vars.",i); 		end; call symput("p_sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.;		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' p_'				!!scan("&sum_fam_count_vars."	,i); 	end; call symput("p_sum_fam_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' p_'				!!scan("&sum_indv_oop_vars.",i); 		end; call symput("p_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' p_'				!!scan("&sum_indv_count_vars.",i); 	end; call symput("p_sum_indv_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_oop_vars.",i)			!!'=p_'!!scan("&sum_fam_oop_vars.",i)		; end; call symput("p_sum_fam_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_count_vars.",i)		!!'=p_'!!scan("&sum_fam_count_vars.",i)	; end; call symput("p_sum_fam_count_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_oop_vars.",i)			!!'=p_'!!scan("&sum_indv_oop_vars.",i)	; end; call symput("p_sum_indv_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_count_vars.",i)		!!'=p_'!!scan("&sum_indv_count_vars.",i); end; call symput("p_sum_indv_count_vars_rn"	,vars); run; 					
/*CLAIMS RESPONSIBLE POTENTIAL GHOST DELTA VARS*/                     	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pdl_'			!!scan("&sum_fam_oop_vars.",i); 		end; call symput("pdl_sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pdl_'			!!scan("&sum_fam_count_vars.",i); 	end; call symput("pdl_sum_fam_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pdl_'			!!scan("&sum_indv_oop_vars.",i); 		end; call symput("pdl_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pdl_'			!!scan("&sum_indv_count_vars.",i); 	end; call symput("pdl_sum_indv_count_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' pdl_'			!!scan("&misc_oop_vars.",i); 				end; call symput("pdl_misc_oop_vars"	,vars); run; 					
/*CLAIMS TOTAL SUMMARY VARS*/                                         	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_oop_vars.",i)			!!'=tot_'!!scan("&sum_fam_oop_vars.",i)		; end; call symput("tot_sum_fam_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_count_vars.",i)		!!'=tot_'!!scan("&sum_fam_count_vars.",i)	; end; call symput("tot_sum_fam_cnt_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_oop_vars.",i)			!!'=tot_'!!scan("&sum_indv_oop_vars.",i)	; end; call symput("tot_sum_indv_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_count_vars.",i)		!!'=tot_'!!scan("&sum_indv_count_vars.",i); end; call symput("tot_sum_indv_cnt_vars_rn"	,vars); run; 					
/*CLAIMS DDA SUMMARY VARS*/                                           	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_oop_vars.",i)			!!'=dda_'!!scan("&sum_fam_oop_vars.",i)		; end; call symput("dda_sum_fam_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_count_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_fam_count_vars.",i)		!!'=dda_'!!scan("&sum_fam_count_vars.",i)	; end; call symput("dda_sum_fam_cnt_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_oop_vars.",i)			!!'=dda_'!!scan("&sum_indv_oop_vars.",i)	; end; call symput("dda_sum_indv_oop_vars_rn"		,vars)	; run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_count_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&sum_indv_count_vars.",i)		!!'=dda_'!!scan("&sum_indv_count_vars.",i); end; call symput("dda_sum_indv_cnt_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &misc_oop_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&misc_oop_vars.",i)					!!'=dda_'!!scan("&misc_oop_vars.",i); end; call symput("dda_misc_oop_vars_rn"	,vars); run; 					
/*REPORT COUPON PROCESSING MISC VARS*/                                	
data _null_; length vars $32767.; array vars_  &sum_fam_oop_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' dda_'			!!scan("&sum_fam_oop_vars.",i); 		end; call symput("dda_sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_oop_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' dda_'			!!scan("&sum_indv_oop_vars.",i); 		end; call symput("dda_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_cpn_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' dda_'			!!scan("&sum_fam_cpn_vars.",i); 		end; call symput("dda_sum_fam_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_cpn_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' dda_'			!!scan("&sum_indv_cpn_vars.",i); 		end; call symput("dda_sum_indv_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_fam_cpn_vars.; 			retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&sum_fam_cpn_vars.",i); 		end; call symput("g_sum_fam_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &sum_indv_cpn_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' g_'				!!scan("&sum_indv_cpn_vars.",i); 		end; call symput("g_sum_indv_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_fam_cpn_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' t_'				!!scan("&dda_sum_fam_cpn_vars.",i); end; call symput("t_dda_sum_fam_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_indv_cpn_vars.;	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' t_'				!!scan("&dda_sum_indv_cpn_vars.",i);end; call symput("t_dda_sum_indv_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_fam_oop_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' t_'				!!scan("&dda_sum_fam_oop_vars.",i); end; call symput("t_dda_sum_fam_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_indv_oop_vars.;	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' t_'				!!scan("&dda_sum_indv_oop_vars.",i);end; call symput("t_dda_sum_indv_oop_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &g_sum_fam_cpn_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' t_'				!!scan("&g_sum_fam_cpn_vars.",i); 	end; call symput("t_g_sum_fam_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &g_sum_indv_cpn_vars.;		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' t_'				!!scan("&g_sum_indv_cpn_vars.",i); 	end; call symput("t_g_sum_indv_cpn_vars",vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_fam_cpn_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&dda_sum_fam_cpn_vars.",i)	!!'=t_'!!scan("&dda_sum_fam_cpn_vars.",i); end; call symput("t_dda_sum_fam_cpn_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_indv_cpn_vars.; retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&dda_sum_indv_cpn_vars.",i)	!!'=t_'!!scan("&dda_sum_indv_cpn_vars.",i); end; call symput("t_dda_sum_indv_cpn_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_fam_oop_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&dda_sum_fam_oop_vars.",i)	!!'=t_'!!scan("&dda_sum_fam_oop_vars.",i); end; call symput("t_dda_sum_fam_oop_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &dda_sum_indv_oop_vars.; retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&dda_sum_indv_oop_vars.",i)	!!'=t_'!!scan("&dda_sum_indv_oop_vars.",i); end; call symput("t_dda_sum_indv_oop_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &g_sum_fam_cpn_vars.; 		retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&g_sum_fam_cpn_vars.",i)		!!'=t_'!!scan("&g_sum_fam_cpn_vars.",i); end; call symput("t_g_sum_fam_cpn_vars_rn"	,vars); run; 					
data _null_; length vars $32767.; array vars_  &g_sum_indv_cpn_vars.; 	retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&g_sum_indv_cpn_vars.",i)		!!'=t_'!!scan("&g_sum_indv_cpn_vars.",i); end; call symput("t_g_sum_indv_cpn_vars_rn"	,vars); run; 					
/*FINAL ADS DEDUCTIBLE MASK RENAME*/                                                                                                  		
%let ded_mask_vars = pln_a_fam_deductible	pln_a_fam_oop	pln_a_indv_deductible	pln_a_indv_oop;                                         		
data _null_; length vars $32767.; array vars_  &ded_mask_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' raw_'			!!scan("&ded_mask_vars.",i); 				end; call symput("raw_ded_mask_vars",vars); run;
data _null_; length vars $32767.; array vars_  &ded_mask_vars.; 				retain vars; do i=1 to dim(vars_); vars = trim(vars)!!' '					!!scan("&ded_mask_vars.",i)					!!'=raw_'!!scan("&ded_mask_vars.",i); end; call symput("ded_mask_vars_rn"	,vars); run; 					
/*REPORTING GROUPS AND VARIABLES*/
%let all_products = Darzalex Erleada Remicade Simponi_Aria Simponi Stelara Tremfya Zytiga;   
%let on_dx = 'myl_dx','pc_dx','pcm_dx'; %let im_dx = 'as_dx','cd_dx','psa_dx','pso_dx','ra_dx','uc_dx'; 
%let all_whr_2018 = where tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_oop_max_accum in ('Y') and pln_a_funding_arrangment in ('ASO','FI') and pln_a_deductible_accum in ('Y','N') and pln_a_cpn_ben_plan_prt in ('Y','N') and aa_analysis_year = 2018;
%let all_whr = where tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_oop_max_accum in ('Y') and pln_a_funding_arrangment in ('ASO','FI') and pln_a_deductible_accum in ('Y','N') and pln_a_cpn_ben_plan_prt in ('Y','N');
%let ded = and pln_a_deductible_accum in ('Y');
%let oop = and pln_a_deductible_accum in ('N');  

/*-----------------------------------------------------------------*/
/*---> YOY LOOP <--------------------------------------------------*/
/**/

%global months yr_num; %let yr_num = 1;
%do %until	(&yr_num = 3);
%if &yr_num = 1 %then %let months=12; 
%if &yr_num = 2 %then %let months=9; 

data _null_;
	cur_st 				 = intnx('year',&start_dt.,&yr_num.-1,'beg');
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
/*---> GALAXY DX MEMBER COHORT <-----------------------------------*/
/**/           

%let test=;        
%if %length(&testobs) %then %let test = reset inobs=&testobs.;
%if &no_dx %then %do; data inp.r&vz.01_yr&yr_num._dx_mbrs_raw; set inp.r&vz.01_yr&yr_num._dx_mbrs_raw; run; %goto no_dx; %end; 

	%put NOTE: Dx Cohort from Galaxy...;
	%put;
	proc sql stimer; 
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*; 
	   *---> EXTRACT;
	
			 create table inp.r&vz.01_yr&yr_num._dx_mbrs_raw as
		       select distinct * from connection to db2
			 		(select   
               mx.mbr_sys_id																																																																			 							as mbr_sys_id
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&ra_dx. ) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_1 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&pso_dx.) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_2 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&psa_dx.) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_3 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&as_dx. ) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_4 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&cd_dx. ) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_5 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&uc_dx. ) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_6 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&myl_dx.) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_7 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&pc_dx. ) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_8                    																																									 							 								 			 
			       , max(case when %do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&pcm_dx.) %if &i ne &dx_fld_num %then %str(or); %end; then mx.fst_srvc_dt else date('1899-12-31') end) as dx_date_9                    																																									 							 								 			 
  				from 
  						galaxy.unet_claim_statistical_service mx
					where 
						 mx.fst_srvc_dt between &cur_st_db2. and &cur_end_db2.  
				 		and (%do i=1 %to &dx_fld_num; mx.diag_&i._cd in (&all_dx_codes.) %if &i ne &dx_fld_num %then %str(or); %end;)
         		and mx.net_pd_amt<>0
         		and mx.chrg_sts_cd='P'
         		and mx.srvc_curr_ind='Y'
         		and mx.enctr_cd in ('0','4') 	
         		and mx.clos_clm_ind = 'N'
			 	 		and mx.mbr_sys_id>0
				 group by mx.mbr_sys_id
				 for fetch only
				 );							 	
				 	 	
	   disconnect from db2;
	quit;		

/*-----------------------------------------------------------------*/
/*---> GALAXY RX, MX MEMBER COHORTS <------------------------------*/
/**/ 
	%no_dx:;
	%if &no_pull %then %goto no_pull;
	ods excel options(sheet_name="01" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet; 
	
	%put NOTE: Rx, Mx Cohorts from Galaxy...;
	%put;
	proc sql stimer; &test.;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;

			 create table inp.t&vz.02_yr&yr_num._mx_mbrs_raw as
		       select distinct * from connection to db2
				 		(select   
	                mx.mbr_sys_id
			       		, min(case when mx.ndc in (&dar_ndc.) or mx.bil_proc_cd in (&dar_proc.) then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_1 
			       		, min(case when mx.ndc in (&erl_ndc.)  																	then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_2 
			       		, min(case when mx.ndc in (&rem_ndc.) or mx.bil_proc_cd in (&rem_proc.) then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_3 
			       		, min(case when mx.ndc in (&sia_ndc.)  																	then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_4 
			       		, min(case when mx.ndc in (&sim_ndc.) or mx.bil_proc_cd in (&sim_proc.) then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_5			       		
			       		, min(case when mx.ndc in (&ste_ndc.) or mx.bil_proc_cd in (&ste_proc.)	then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_6 
			       		, min(case when mx.ndc in (&tre_ndc.) or mx.bil_proc_cd in (&tre_proc.)	then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_7 
			       		, min(case when mx.ndc in (&zyt_ndc.) 																  then mx.fst_srvc_dt else date('2999-12-31') end) as mx_date_8			       		
	  				 from 
	  				 		galaxy.unet_claim_statistical_service mx
						 where 
						 	   mx.fst_srvc_dt between &cur_st_db2. and &cur_end_db2.  
					 	 and (mx.bil_proc_cd in (&all_proc_codes.) or mx.ndc in (&all_ndc_codes.))
         		 and mx.net_pd_amt<>0
         		 and mx.chrg_sts_cd='P'
         		 and mx.srvc_curr_ind='Y'
         		 and mx.enctr_cd in ('0','4') 	
         		 and mx.clos_clm_ind = 'N'
					 	 and mx.mbr_sys_id>0
					 	 group by mx.mbr_sys_id
				 	 for fetch only
				 	 );					

			 create table inp.t&vz.03_yr&yr_num._rx_mbrs_raw as
		       select distinct * from connection to db2
				 		(select   
	                rx.mbr_sys_id
			       		, min(case when rx.ndc in (&dar_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_1 
			       		, min(case when rx.ndc in (&erl_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_2 
			       		, min(case when rx.ndc in (&rem_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_3 
			       		, min(case when rx.ndc in (&sia_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_4 
			       		, min(case when rx.ndc in (&sim_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_5			
			       		, min(case when rx.ndc in (&ste_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_6 
			       		, min(case when rx.ndc in (&tre_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_7 
			       		, min(case when rx.ndc in (&zyt_ndc.) then rx.fill_dt else date('2999-12-31') end) as rx_date_8
	  				 from 
	  				 		galaxy.pharmacy_claim_commercial rx
	  				 		inner join galaxy.customer_segment_coverage cseg
		  				 		on rx.cust_seg_nbr 		 = cseg.cust_seg_nbr 
		  				 		and rx.cust_seg_sys_id = cseg.cust_seg_sys_id 
		  				 		and rx.ben_strct_1_cd  = cseg.pln_var_subdiv_cd 
		  				 		and rx.ben_strct_2_cd  = cseg.rpt_cd_br_cd 
		  				 		and rx.prdct_cd 			 = cseg.prdct_cd 
						 where 
						 	   rx.fill_dt between &cur_st_db2. and &cur_end_db2.  
						 and rx.fill_dt between cseg.cust_seg_cov_row_eff_dt and cseg.cust_seg_cov_row_end_dt   
					 	 and rx.ndc in (&all_ndc_codes.)
					 	 and rx.mbr_sys_id>0
					 	 group by rx.mbr_sys_id
				 	 for fetch only
				 	 );				
				 	 	
	   disconnect from db2;
	quit;		

/*-----------------------------------------------------------------*/
/*---> COHORTS <---------------------------------------------------*/
/**/
	%no_pull:; %if &no_stage %then %goto no_stage;
	ods excel options(sheet_name="02" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.02_yr&yr_num._mx_mbrs_raw,unq=mbr_sys_id); %util_dummy_sheet;
	ods excel options(sheet_name="03" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.03_yr&yr_num._rx_mbrs_raw,unq=mbr_sys_id); %util_dummy_sheet;	
	
	data inp.t&vz.04_yr&yr_num._ch_mbrs(sortedby=mbr_sys_id);
		length prd_idx_date_1-prd_idx_date_&prdnum. dx_date_1-dx_date_&dxnum. dx_date_99 4 prd_idx_mx_1-prd_idx_mx_&prdnum. 3 tot_mbr_earliest_dx tot_mbr_earliest_i_dx tot_mbr_earliest_o_dx $6.;
		merge inp.r&vz.01_yr&yr_num._dx_mbrs_raw(in=dx) 
					inp.t&vz.02_yr&yr_num._mx_mbrs_raw(in=mx) 
					inp.t&vz.03_yr&yr_num._rx_mbrs_raw(in=rx);
		by mbr_sys_id; if (mx or rx); 
		array dx_types{*}			tot_mbr_earliest_i_dx tot_mbr_earliest_o_dx tot_mbr_earliest_dx;
		array dx_types_dt{*}	tot_mbr_earliest_i_dx_dt tot_mbr_earliest_o_dx_dt tot_mbr_earliest_dx_dt;
		array dxs{*} 					dx_date_1-dx_date_&prdnum.;
		array dxs_i{*} 				dx_date_1-dx_date_6;
		array dxs_o{*} 				dx_date_7-dx_date_9;
		array mxs{*} 					mx_date_1-mx_date_&prdnum.;
		array rxs{*} 					rx_date_1-rx_date_&prdnum.;
		array idx{*} 					prd_idx_date_1-prd_idx_date_&prdnum.;	
		array idxp{*} 				prd_idx_mx_1-prd_idx_mx_&prdnum.;
		do i = 1 to dim(dx_types); dx_types{i}='no_dx'; dx_types_dt{i}='31Dec2999'd; dx_date_99 = &cur_st.; end;		
		do i = 1 to dim(dxs_i); if dxs_i{i} ne '31Dec1899'd and dxs_i{i} < tot_mbr_earliest_i_dx_dt then do; tot_mbr_earliest_i_dx = scan("&dx_names.",i); tot_mbr_earliest_i_dx_dt = dxs_i{i}; dx_date_99 = .; end; end;
		do i = 1 to dim(dxs_o); if dxs_o{i} ne '31Dec1899'd and dxs_o{i} < tot_mbr_earliest_o_dx_dt then do; tot_mbr_earliest_o_dx = scan("&dx_names.",i+6); tot_mbr_earliest_o_dx_dt = dxs_o{i}; dx_date_99 = .; end; end;
		do i = 1 to dim(dxs); if dxs{i} ne '31Dec1899'd and dxs{i} < tot_mbr_earliest_dx_dt then do; tot_mbr_earliest_dx = scan("&dx_names.",i); tot_mbr_earliest_dx_dt = dxs{i}; dx_date_99 = .; end; end;
		do i = 1 to dim(idx); idx{i} = min(mxs{i},rxs{i}); if min(mxs{i},rxs{i}) = mxs{i} and mxs{i} ne '31Dec2999'd then idxp{i} = 1; end;
		drop mx_date_1-mx_date_&prdnum. rx_date_1-rx_date_&prdnum. dx_date_1-dx_date_&dxnum. dx_date_99 i tot_mbr_earliest_i_dx_dt tot_mbr_earliest_o_dx_dt tot_mbr_earliest_dx_dt;       
		format mx_date_1-mx_date_&prdnum. rx_date_1-rx_date_&prdnum. dx_date_1-dx_date_&dxnum. dx_date_99 prd_idx_date_1-prd_idx_date_&prdnum. mmddyy10.; 
	run;
	ods excel options(sheet_name="04" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.04_yr&yr_num._ch_mbrs,unq=mbr_sys_id); %util_dummy_sheet;
	proc freq data=inp.t&vz.04_yr&yr_num._ch_mbrs; tables tot_mbr_earliest_i_dx tot_mbr_earliest_o_dx tot_mbr_earliest_dx; run; 
	%if &no_pull %then %goto no_pull2;

/*-----------------------------------------------------------------*/
/*---> GALAXY COVERAGE DATA <--------------------------------------*/
/**/
	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=inp.t&vz.04_yr&yr_num._ch_mbrs);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;
		set inp.t&vz.04_yr&yr_num._ch_mbrs(keep=mbr_sys_id) nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;
	
		* GALAXY CLAIMS, COVERAGE EXTRACT FOR MEMBER LIST;
		%let member_coverage = 
	        select distinct
					 		  mcm.mbr_sys_id											as mbr_sys_id
					 		, mcm.mbr_cov_mo_row_eff_dt						as cov_eff_date
					 		, mcm.mbr_cov_mo_row_end_dt						as cov_end_date
					 		, mcm.med_cov_ind                     as med_cov_ind
	         		, mcm.phrm_cov_ind										as pharm_cov_ind
	         		, mcm.st_abbr_cd											as st
	        from 
	        		galaxy.member_coverage_month					mcm
          where 
          		mcm.mbr_cov_mo_row_end_dt >= &cur_st_lb_db2. 
          		and mbr_sys_id in (&&&mbr_list_&ii.)
          for fetch only;   				
		
/*-----------------------------------------------------------------*/
/*---> GALAXY COVERAGE DATA <--------------------------------------*/
/**/

	%put NOTE: Coverage Data from Galaxy...;
	%put NOTE: mbr_list_&ii.;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;

		   create table t&vz._yr&yr_num._member_coverage_&ii. as
		      select distinct * from connection to db2
					(&member_coverage.);				
					
	   disconnect from db2;
	quit;		
	
	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.05_yr&yr_num._member_coverage_raw; set t&vz._yr&yr_num._member_coverage_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; insert into inp.t&vz.05_yr&yr_num._member_coverage_raw 
			select * from t&vz._yr&yr_num._member_coverage_&ii.; 	quit;
	%end;                                                                                                         	                

* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> PROCESS MEMBER COVERAGE  <----------------------------------*/
/**/
%no_pull2:;

ods excel options(sheet_name="05" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.05_yr&yr_num._member_coverage_raw,unq=mbr_sys_id); %util_dummy_sheet;

proc sort data=inp.t&vz.05_yr&yr_num._member_coverage_raw; by mbr_sys_id cov_eff_date; run;
data inp.t&vz.06_yr&yr_num._memcov_wins; 
	length st $2;
	set inp.t&vz.05_yr&yr_num._member_coverage_raw(where=(med_cov_ind in ('Y') and pharm_cov_ind in ('Y','P')));
	by mbr_sys_id; 
	retain min_cov_date max_cov_date cov_thru_date cov_win;
	cov_thru_date = lag(cov_end_date); 
	if first.mbr_sys_id then do; min_cov_date = cov_eff_date; cov_win = 0; end;
  if lag(mbr_sys_id) = mbr_sys_id 
  	and cov_eff_date - cov_thru_date > 2 then do;  	
  	max_cov_date = cov_thru_date; 
 		cov_win+1;
  	output; 
  	min_cov_date = cov_eff_date;
  	end;
  if last.mbr_sys_id then do;
 		max_cov_date = cov_end_date; 
		cov_win+1;
 		output; 
  end;
  keep mbr_sys_id min_cov_date max_cov_date;  
  format min_cov_date max_cov_date mmddyy10.;  
run;
ods excel options(sheet_name="06" &ex_op.);
%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

data inp.t&vz.07_yr&yr_num._member_coverage_raw; set inp.t&vz.05_yr&yr_num._member_coverage_raw; run;

proc sort data=inp.t&vz.07_yr&yr_num._member_coverage_raw nodupkey; by mbr_sys_id cov_eff_date; run;
data inp.t&vz.08_yr&yr_num._memcov_st; 
	length ab_demo_mbr_state $2. ab_demo_mbr_region $2.;
	set inp.t&vz.07_yr&yr_num._member_coverage_raw;
	by mbr_sys_id; 
  if last.mbr_sys_id then do; ab_demo_mbr_state = st; ab_demo_mbr_region = put(ab_demo_mbr_state,$all_st_codes.); output; end; 
  keep mbr_sys_id ab_demo_mbr_state ab_demo_mbr_region;  
run;
ods excel options(sheet_name="07" &ex_op.);
%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

/*-----------------------------------------------------------------*/
/*---> MEMBERS WITH CONTINUOUS COVERAGE  <-------------------------*/
/**/

proc sort data=inp.t&vz.04_yr&yr_num._ch_mbrs; by mbr_sys_id; run;
proc sort data=inp.t&vz.06_yr&yr_num._memcov_wins; by mbr_sys_id; run;
data inp.t&vz.09_yr&yr_num._ch_mbrs(sortedby=mbr_sys_id); 
	length ab_demo_mbr_enrollment_left 
				 ab_demo_mbr_enrollment_right 3;
	merge inp.t&vz.04_yr&yr_num._ch_mbrs(in=ch)
				inp.t&vz.06_yr&yr_num._memcov_wins(rename=(min_cov_date=ab_demo_mbr_enrollment_min_date	max_cov_date=ab_demo_mbr_enrollment_max_date))
				inp.t&vz.08_yr&yr_num._memcov_st;
	by mbr_sys_id; if ch;
	retain ab_demo_mbr_enrollment_left ab_demo_mbr_enrollment_right;
	if first.mbr_sys_id then do; ab_demo_mbr_enrollment_left = 0; ab_demo_mbr_enrollment_right = 0; end;
	if ab_demo_mbr_enrollment_min_date + 365 <= &cur_st. <= ab_demo_mbr_enrollment_max_date - &st2end. and ab_demo_mbr_enrollment_min_date>0 then ab_demo_mbr_enrollment_left  = 1; 
	if ab_demo_mbr_enrollment_min_date   	   <= &cur_st. <= ab_demo_mbr_enrollment_max_date - &st2end. and ab_demo_mbr_enrollment_min_date>0 then ab_demo_mbr_enrollment_right = 1; 
	if last.mbr_sys_id then output;
run;
ods excel options(sheet_name="09.1" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.09_yr&yr_num._ch_mbrs,unq=mbr_sys_id,byvars=ab_demo_mbr_enrollment_left ab_demo_mbr_enrollment_right,
						qa_dsn=inp.t&vz.07_yr&yr_num._member_coverage_raw); %util_dummy_sheet;
ods excel options(sheet_name="09.2" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.09_yr&yr_num._ch_mbrs,unq=mbr_sys_id,byvars=ab_demo_mbr_enrollment_left ab_demo_mbr_enrollment_right,
						qa_dsn=inp.t&vz.06_yr&yr_num._memcov_wins); %util_dummy_sheet;	
 				

/*-----------------------------------------------------------------*/
/*---> CHECK CLEAN PERIOD, LEFT RX PLANS <-------------------------*/
/**/  
            
	data inp.t&vz.10_yr&yr_num._ch_mbrs; 
		set inp.t&vz.09_yr&yr_num._ch_mbrs;
		if ab_demo_mbr_enrollment_right; 
	run;
	ods excel options(sheet_name="10" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
	
	%if &no_pull %then %goto no_pull3;

	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=inp.t&vz.10_yr&yr_num._ch_mbrs);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;		
		set inp.t&vz.10_yr&yr_num._ch_mbrs(keep=mbr_sys_id) nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;

	%put NOTE: Galaxy Check Clean Period...;
	%put NOTE: mbr_list_&ii.;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;

			 create table t&vz.11_yr&yr_num._mx_mbrs_raw_left_&ii. as
		       select distinct * from connection to db2
				 		(select   
	                mx.mbr_sys_id
			       		, max(case when mx.ndc in (&dar_ndc.) or mx.bil_proc_cd in (&dar_proc.) then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_1 
			       		, max(case when mx.ndc in (&erl_ndc.)  																	then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_2 
			       		, max(case when mx.ndc in (&rem_ndc.) or mx.bil_proc_cd in (&rem_proc.) then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_3 
			       		, max(case when mx.ndc in (&sia_ndc.)  																	then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_4 
			       		, max(case when mx.ndc in (&sim_ndc.) or mx.bil_proc_cd in (&sim_proc.) then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_5			       		
			       		, max(case when mx.ndc in (&ste_ndc.) or mx.bil_proc_cd in (&ste_proc.)	then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_6 
			       		, max(case when mx.ndc in (&tre_ndc.) or mx.bil_proc_cd in (&tre_proc.)	then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_7 
			       		, max(case when mx.ndc in (&zyt_ndc.) 																  then mx.fst_srvc_dt else date('1899-12-31') end) as mx_left_date_8			       		
	  				 from 
	  				 		galaxy.unet_claim_statistical_service mx
						 where 
						 	  mx.fst_srvc_dt between &cur_st_lb_db2. and &cur_end_lb_db2.  
					 	 and (mx.bil_proc_cd in (&all_proc_codes.) or mx.ndc in (&all_ndc_codes.))
         		 and mx.net_pd_amt<>0
         		 and mx.chrg_sts_cd='P'
         		 and mx.srvc_curr_ind='Y'
         		 and mx.enctr_cd in ('0','4') 	
         		 and mx.clos_clm_ind = 'N'
					 	 and mx.mbr_sys_id>0         		 
         		 and mbr_sys_id in (&&&mbr_list_&ii.)
					 	 group by mx.mbr_sys_id
				 	 for fetch only
				 	 );					

			 create table t&vz.12_yr&yr_num._rx_mbrs_raw_left_&ii. as
		       select distinct * from connection to db2
				 		(select   
	                rx.mbr_sys_id
			       		, max(case when rx.ndc in (&dar_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_1 
			       		, max(case when rx.ndc in (&erl_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_2 
			       		, max(case when rx.ndc in (&rem_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_3 
			       		, max(case when rx.ndc in (&sia_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_4 
			       		, max(case when rx.ndc in (&sim_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_5			
			       		, max(case when rx.ndc in (&ste_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_6 
			       		, max(case when rx.ndc in (&tre_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_7 
			       		, max(case when rx.ndc in (&zyt_ndc.) then rx.fill_dt else date('1899-12-31') end) as rx_left_date_8
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
					 	 and rx.ndc in (&all_ndc_codes.)
					 	 and rx.mbr_sys_id>0         		 
					 	 and mbr_sys_id in (&&&mbr_list_&ii.)
					 	 group by rx.mbr_sys_id
				 	 for fetch only
				 	 );	
					
	   disconnect from db2;
	quit;		
	
	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.11_yr&yr_num._mx_mbrs_raw_left; set t&vz.11_yr&yr_num._mx_mbrs_raw_left_&ii.; run;  
		data inp.t&vz.12_yr&yr_num._rx_mbrs_raw_left; set t&vz.12_yr&yr_num._rx_mbrs_raw_left_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; insert into inp.t&vz.11_yr&yr_num._mx_mbrs_raw_left 
			select * from t&vz.11_yr&yr_num._mx_mbrs_raw_left_&ii.; 	quit;
		proc sql; insert into inp.t&vz.12_yr&yr_num._rx_mbrs_raw_left 			 																					                
			select * from t&vz.12_yr&yr_num._rx_mbrs_raw_left_&ii.;	quit;                                                 	                    
	%end;                                                                                                         	                

* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> PULL LEFT-SIDE RX PLANS <-----------------------------------*/
/**/                

	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=inp.t&vz.09_yr&yr_num._ch_mbrs);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;
		set inp.t&vz.09_yr&yr_num._ch_mbrs(keep=mbr_sys_id) nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;

	%put NOTE: Galaxy Left-Side Rx Plans...;
	%put NOTE: mbr_list_&ii.;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;

			 create table t&vz.13_yr&yr_num._rx_plans_raw_left_&ii. as
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
					 	 and mbr_sys_id in (&&&mbr_list_&ii.)
				 	 for fetch only
				 	 );	
					
	   disconnect from db2;
	quit;		
	
	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.13_yr&yr_num._rx_plans_raw_left; set t&vz.13_yr&yr_num._rx_plans_raw_left_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; insert into inp.t&vz.13_yr&yr_num._rx_plans_raw_left 
			select * from t&vz.13_yr&yr_num._rx_plans_raw_left_&ii. ; 	quit;
	%end;                                                                                                         	                

* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> MOST RECENT LEFT-SIDE RX PLAN  <----------------------------*/
/**/
%no_pull3:;
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
				, l.rx_ben_pln_nbr 																							as rx_ben_pln_nbr
				, l.mkt_seg_cd																									as mkt_seg_cd
				, l.cdhp_ind																								as cdhp_ind
				, pln.business_segment 																			as business_segment           
				,	put(pln.funding_arrangment,$pln_funding_arrangment_fmt.) 	as funding_arrangment              
				, pln.cpn_ben_plan_prt 															as cpn_ben_plan_prt
				, deductible_accum 																		as deductible_accum   
				, oop_max_accum 																	as oop_max_accum
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
					cpn_ben_plan_prt 		$1
					deductible_accum			$1
					oop_max_accum			$1
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
	length	pln_l_business_segment            $1
					pln_l_funding_arrangment          $3
					pln_l_cpn_ben_plan_prt 		$1
					pln_l_deductible_accum			$1
					pln_l_oop_max_accum			$1
					pln_l_cdhp_ind										$1;	
	set inp.t&vz.16_yr&yr_num._rx_plans_left(rename=(&pln_vars_left_rn.)); 
	format pln_l_fam_deductible pln_l_indv_deductible pln_l_fam_oop pln_l_indv_oop dollar12.2; 
	keep mbr_sys_id &pln_l_vars.;
run;
ods excel options(sheet_name="17" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0);	%util_dummy_sheet;

/*-----------------------------------------------------------------*/
/*---> CHECK CLEAN PERIODS  <--------------------------------------*/
/**/

proc sort data=inp.t&vz.11_yr&yr_num._mx_mbrs_raw_left; by mbr_sys_id; run;
proc sort data=inp.t&vz.12_yr&yr_num._rx_mbrs_raw_left; by mbr_sys_id; run;	
data inp.t&vz.18_yr&yr_num._ch_mbrs(sortedby=mbr_sys_id); 
	length prd_idx_left_cln_1-prd_idx_left_cln_&prdnum. prd_idx_left_enr_1-prd_idx_left_enr_&prdnum. ch_mem 3; 
	merge inp.t&vz.10_yr&yr_num._ch_mbrs(in=ch)
				inp.t&vz.11_yr&yr_num._mx_mbrs_raw_left(in=mx_l)
				inp.t&vz.12_yr&yr_num._rx_mbrs_raw_left(in=rx_l)				
				;
	by mbr_sys_id; if ch;	
	array mxs_l{*} 	mx_left_date_1-mx_left_date_&prdnum.;
	array rxs_l{*} 	rx_left_date_1-rx_left_date_&prdnum.;
	array idxcln{*} prd_idx_left_cln_1-prd_idx_left_cln_&prdnum.;
	array idxenr{*} prd_idx_left_enr_1-prd_idx_left_enr_&prdnum.;	
	array idx{*} 	 	prd_idx_date_1-prd_idx_date_&prdnum.;		
	ch_mem = 1;
	do i = 1 to dim(idxcln); 
		if idx{i} ne '31Dec2999'd then do; 
		if ab_demo_mbr_enrollment_min_date + 120 <= idx{i} then idxenr{i} = 1; 
		if ab_demo_mbr_enrollment_min_date + 120 <= idx{i} 
	 		 										and mxs_l{i} + 120 <  idx{i} 
	 		 										and rxs_l{i} + 120 <  idx{i} then idxcln{i} = 1; 	 		 																								 
		end;
	end;
	drop rx_left_date_1-rx_left_date_&prdnum. mx_left_date_1-mx_left_date_&prdnum. i;
run; 
ods excel options(sheet_name="18.1" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.18_yr&yr_num._ch_mbrs,unq=mbr_sys_id,byvars=prd_idx_left_cln_1 prd_idx_left_cln_2 prd_idx_left_cln_3 prd_idx_left_cln_4 prd_idx_left_cln_5 prd_idx_left_cln_6 prd_idx_left_cln_7 prd_idx_left_cln_8,bylp=1,
						qa_dsn=inp.t&vz.11_yr&yr_num._mx_mbrs_raw_left); %util_dummy_sheet;
ods excel options(sheet_name="18.2" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.18_yr&yr_num._ch_mbrs,unq=mbr_sys_id,byvars=prd_idx_left_cln_1 prd_idx_left_cln_2 prd_idx_left_cln_3 prd_idx_left_cln_4 prd_idx_left_cln_5 prd_idx_left_cln_6 prd_idx_left_cln_7 prd_idx_left_cln_8,bylp=1,
						qa_dsn=inp.t&vz.12_yr&yr_num._rx_mbrs_raw_left); %util_dummy_sheet;	 					
ods excel options(sheet_name="18.3" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.18_yr&yr_num._ch_mbrs,unq=mbr_sys_id,byvars=prd_idx_left_cln_1 prd_idx_left_cln_2 prd_idx_left_cln_3 prd_idx_left_cln_4 prd_idx_left_cln_5 prd_idx_left_cln_6 prd_idx_left_cln_7 prd_idx_left_cln_8,bylp=1,
						qa_dsn=inp.t&vz.06_yr&yr_num._memcov_wins); %util_dummy_sheet;

	 
/*-----------------------------------------------------------------*/
/*---> GALAXY FAMLIES <--------------------------------------------*/
/**/
	%if &no_pull %then %goto no_pull4;
	data t&vz.07_yr&yr_num._ch_mbrs_unq; set inp.t&vz.18_yr&yr_num._ch_mbrs(keep=mbr_sys_id); run;
	proc sort data=t&vz.07_yr&yr_num._ch_mbrs_unq nodupkey; by mbr_sys_id; run;

	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=t&vz.07_yr&yr_num._ch_mbrs_unq);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;
		set t&vz.07_yr&yr_num._ch_mbrs_unq nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;

	%let all_famlies = 
	        select distinct
					 		mbr.fam_id														as family_id
					 	, mbr.mbr_sys_id												as mbr_sys_id
	        from 
	        		galaxy.member													mbr
          where 
          		mbr.logc_del_ind='N' 
          		and mbr.curr_ind='Y' 
          		and mbr.mbr_row_end_dt >= &cur_st_db2. 
          		and mbr.fam_id>0
          		and mbr.mbr_sys_id>0
          		and mbr.mbr_sys_id in (&&&mbr_list_&ii.)
          for fetch only; 			

	%put NOTE: Famlies from Galaxy...;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;

		   create table t&vz.19_yr&yr_num._all_famlies_raw_&ii. as
		      select distinct * from connection to db2
					(&all_famlies.);							
					
	   disconnect from db2;
	quit;		

	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.19_yr&yr_num._all_famlies_raw; set t&vz.19_yr&yr_num._all_famlies_raw_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; 
			insert into inp.t&vz.19_yr&yr_num._all_famlies_raw 
			select * from t&vz.19_yr&yr_num._all_famlies_raw_&ii.; 
		quit;
	%end;

%test_mbrs_only:;

* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> GALAXY ALL FAMILY MEMBERS <---------------------------------*/
/**/

	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=inp.t&vz.19_yr&yr_num._all_famlies_raw);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;
		set inp.t&vz.19_yr&yr_num._all_famlies_raw nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(family_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(family_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;

	%let all_family_mbrs = 
	        select distinct
					 		 	mbr.fam_id													as family_id
					 		, mbr.mbr_sys_id											as mbr_sys_id
							, mbr.bth_dt													as birth_date
							, mbr.gdr_cd													as ab_demo_mbr_gender
							, mbr.adlt_depn_cd 										as ab_demo_mbr_dependent_code 
	        from 
	        		galaxy.member													mbr
          where 
          		mbr.logc_del_ind='N' 
          		and mbr.curr_ind='Y' 
          		and mbr.mbr_row_end_dt >= &cur_st_db2. 
          		and mbr.fam_id>0
          		and mbr.mbr_sys_id>0
          		and mbr.fam_id in (&&&mbr_list_&ii.)
          for fetch only; 			

	%put NOTE: All Family Members from Galaxy...;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;
					
			 create table t&vz.20_yr&yr_num._all_family_mbrs_&ii. as
		       select distinct * from connection to db2
			 		(&all_family_mbrs.);	
					
	   disconnect from db2;
	quit;		

	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.20_yr&yr_num._all_family_mbrs; set t&vz.20_yr&yr_num._all_family_mbrs_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; 
			insert into inp.t&vz.20_yr&yr_num._all_family_mbrs 
			select * from t&vz.20_yr&yr_num._all_family_mbrs_&ii.; 
		quit;
	%end;

* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> GALAXY ORPHANS <--------------------------------------------*/
/**/

proc sql; 
	create table inp.t&vz.21_yr&yr_num._all_orphans as (
			select distinct ch.mbr_sys_id 
			from inp.t&vz.18_yr&yr_num._ch_mbrs ch 
			left outer join inp.t&vz.20_yr&yr_num._all_family_mbrs afm 
				on ch.mbr_sys_id = afm.mbr_sys_id
			where afm.mbr_sys_id is null);
quit;
	ods excel options(sheet_name="21" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=inp.t&vz.21_yr&yr_num._all_orphans);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;
		set inp.t&vz.21_yr&yr_num._all_orphans nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;

	%let all_orphans = 
	        select distinct
					 		 	cast(null as integer)								as family_id
					 		, mbr.mbr_sys_id											as mbr_sys_id
							, mbr.bth_dt													as birth_date
							, mbr.gdr_cd													as ab_demo_mbr_gender
							, 'A'							 										as ab_demo_mbr_dependent_code 
	        from 
	        		galaxy.member													mbr
          where 
          		mbr.logc_del_ind='N' 
          		and mbr.curr_ind='Y' 
          		and mbr.mbr_sys_id>0
          		and mbr.mbr_row_end_dt >= &cur_st_db2. 
          		and mbr.mbr_sys_id in (&&&mbr_list_&ii.)
          for fetch only; 			

	%put NOTE: All Orphans from Galaxy...;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;
					
			 create table t&vz.22_yr&yr_num._all_orphans_raw_&ii. as
		       select distinct * from connection to db2
			 		(&all_orphans.);	
					
	   disconnect from db2;
	quit;		

	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.22_yr&yr_num._all_orphans; set t&vz.22_yr&yr_num._all_orphans_raw_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; 
			insert into inp.t&vz.22_yr&yr_num._all_orphans 
			select * from t&vz.22_yr&yr_num._all_orphans_raw_&ii.; 
		quit;
	%end;

* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> FAMILY BASIC STATS PROCESSING <-----------------------------*/
/**/
	%no_pull4:;
	proc sort data=inp.t&vz.20_yr&yr_num._all_family_mbrs nodupkey; by mbr_sys_id; run;
	ods excel options(sheet_name="20" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.20_yr&yr_num._all_family_mbrs,unq=mbr_sys_id); %util_dummy_sheet;

	proc sort data=inp.t&vz.22_yr&yr_num._all_orphans nodupkey; by mbr_sys_id; run;	
	ods excel options(sheet_name="22" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.22_yr&yr_num._all_orphans,unq=mbr_sys_id); %util_dummy_sheet;
	
	data inp.t&vz.23_yr&yr_num._all_family_mbrs; 
		length birth_date 4 ab_demo_mbr_gender ab_demo_mbr_dependent_code $1;
		merge  inp.t&vz.18_yr&yr_num._ch_mbrs(keep=mbr_sys_id ch_mem in=ch)
					 inp.t&vz.20_yr&yr_num._all_family_mbrs(in=fam)
					 inp.t&vz.22_yr&yr_num._all_orphans; 
		by mbr_sys_id;
		family_temp+1;		 
		%util_age(varname=ab_demo_mbr_age, From_Dt=birth_date, To_Dt=&cur_end.);
		if missing(family_id) then family_id=family_temp;
		drop family_temp birth_date;
	run;
	ods excel options(sheet_name="23" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet; 

	proc sort data=inp.t&vz.23_yr&yr_num._all_family_mbrs nodupkey; by family_id mbr_sys_id; run;
	data inp.t&vz.24_yr&yr_num._fam_stats(sortedby=family_id); 
		length &count_fam_stat_vars. aa_family_nbr 3;
		set inp.t&vz.23_yr&yr_num._all_family_mbrs; 
		by family_id mbr_sys_id;		 
		array count_vars{*} &count_fam_stat_vars.;
		retain ab_demo_fam_count_family ab_demo_fam_count_adults ab_demo_fam_count_dependents;
		if first.family_id then do i = 1 to dim(count_vars); count_vars{i}=0; end;
			ab_demo_fam_count_family+1;
			if ab_demo_mbr_dependent_code in ('A') then ab_demo_fam_count_adults+1; else ab_demo_fam_count_dependents+1;
			if ab_demo_mbr_gender in ('M') then ab_demo_fam_count_males+1; else ab_demo_fam_count_females+1;	
			if ch_mem then ab_demo_fam_count_ch_mem+1; else ab_demo_fam_count_non_ch_mem+1;
		if last.family_id then do; aa_family_nbr+1; output; end;
		keep family_id aa_family_nbr &count_fam_stat_vars.;
	run;
	ods excel options(sheet_name="24" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=family_id); %util_dummy_sheet;
	
	data inp.t&vz.25_yr&yr_num._all_ch_mbrs_fam_stats; 
		merge inp.t&vz.23_yr&yr_num._all_family_mbrs(where=(ch_mem=1))
					inp.t&vz.24_yr&yr_num._fam_stats;
		by family_id;
	run;
	proc sort data=inp.t&vz.25_yr&yr_num._all_ch_mbrs_fam_stats; by mbr_sys_id; run;
	ods excel options(sheet_name="25" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.25_yr&yr_num._all_ch_mbrs_fam_stats,unq=family_id,byvars=&count_fam_stat_vars.,bylp=1,
						qa_dsn=inp.t&vz.23_yr&yr_num._all_family_mbrs);	%util_dummy_sheet;
	
/*-----------------------------------------------------------------*/
/*---> GIVE ORIGINAL COHORT MEMBERS A FAMILY <---------------------*/
/**/

	data inp.t&vz.26_yr&yr_num._ch_mbrs(sortedby=mbr_sys_id); 
		merge  inp.t&vz.18_yr&yr_num._ch_mbrs
		 			 inp.t&vz.25_yr&yr_num._all_ch_mbrs_fam_stats; 
		by mbr_sys_id;	
	run;
	
	title "inp.t&vz.26_yr&yr_num._ch_mbrs";
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet; 

	
/*-----------------------------------------------------------------*/
/*---> GALAXY CLAIM DATA <-----------------------------------------*/
/**/
	%if &no_pull %then %goto no_pull5;
	* CONSTRUCT MEMBER LOOKUP LISTS FROM COHORT DATASET;
	%util_obsnvars(ds=inp.t&vz.23_yr&yr_num._all_family_mbrs);
	%if &nobs. <= &num. %then %let ndsn = 1; %else %let ndsn=%sysevalf(&nobs./&num,ceil);
	data %do i = 1 %to &ndsn.; t&vz._mbr_list_&i. %end; ;	 
		retain x;
		set inp.t&vz.23_yr&yr_num._all_family_mbrs(keep=mbr_sys_id) nobs=nobs;
		if _n_ eq 1
		then do;
		if mod(nobs,&ndsn.) eq 0
		then x=int(nobs/&ndsn.);
		else x=int(nobs/&ndsn.)+1;
		end;
		if _n_ le x then output t&vz._mbr_list_1;
		%do i = 2 %to &ndsn.;
		else if _n_ le (&i.*x)
		then output t&vz._mbr_list_&i.;
		%end;
	run;	

* BEGIN GALAXY MEMBER LIST LOOP;
%do ii=1 %to &ndsn;
		
		* CREATE MEMBER LIST;
		data _null_; set t&vz._mbr_list_&ii end=omega; 
			length mbr_inc $32767;
			retain mbr_inc;
			mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"',";  
			if omega then do; 
				mbr_inc = trim(mbr_inc)!!"'"!!strip(mbr_sys_id)!!"'"; 
				call symput("mbr_list_&ii.",mbr_inc); 
				end;
		run;
	
		* GALAXY CLAIMS EXTRACTS FOR MEMBER LIST;	
		
/*-----------------------------------------------------------------*/
/*---> GALAXY CLAIM DATA <-----------------------------------------*/
/**/

	%put NOTE: Rx, Mx Data from Galaxy...;
	%put NOTE: mbr_list_&ii.;
	%put;
	proc sql stimer;
	   *----------------------------------------------------------------*;
	   *---> DEFINE CONNECTIONS TO GALAXY DATABASE;
	   connect to db2 (&galaxy_specs);
	   *----------------------------------------------------------------*;
	   *---> EXTRACT;
		
			%let rx_oop_vars_raw  = 	pd_amt 			copay_amt ded_amt 		 0 				manf_cpn_amt;
			%let rx_oop_vars  		= 	amt_allowed	amt_copay	amt_deductbl amt_coin amt_manf_cpn;			
			%let fldnum = 5;

		   create table t&vz.27_yr&yr_num._rx_claims_&ii. as
		      select distinct * from connection to db2
					(select distinct  
								rx.mbr_sys_id						 						as mbr_sys_id   
							, char(rx.phrm_clm_sys_id)						as claim_id      		
  						, rx.fill_dt                          as fill_date
  						, rx.adjd_dt 													as paid_date 				
  						, rx.day_spl_cnt 											as days_supply
  						, rx.ndc 															as ndc       
  						, rx.nabp_nbr													as nabp_nbr
							, case when rx.ndc 		 in (&all_ndc_codes.) then rx.manf_cpn_amt else 0 end as amt_manf_cpn  
		       		%do i = 1 %to &fldnum.;
		       		, case when rx.ndc 		 in (&dar_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_1 
		       		, case when rx.ndc 		 in (&erl_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_2 
		       		, case when rx.ndc 		 in (&rem_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_3 
		       		, case when rx.ndc 		 in (&sia_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_4 
		       		, case when rx.ndc 		 in (&sim_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_5			
		       		, case when rx.ndc 		 in (&ste_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_6 
		       		, case when rx.ndc 		 in (&tre_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_7 
		       		, case when rx.ndc 		 in (&zyt_ndc.) 			then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_8 
		       		, case when rx.ndc not in (&all_ndc_codes.) then %scan(&rx_oop_vars_raw.,&i.) else 0 end as %scan(&rx_oop_vars.,&i.)_99 %end; 
		       		, 1 																																																		as clm_flag 
		       		, case when rx.ndc 		 in (&dar_ndc.) 			then 1 else 0 end as clm_flag_1 
		       		, case when rx.ndc 		 in (&erl_ndc.) 			then 1 else 0 end as clm_flag_2 
		       		, case when rx.ndc 		 in (&rem_ndc.) 			then 1 else 0 end as clm_flag_3 
		       		, case when rx.ndc 		 in (&sia_ndc.) 			then 1 else 0 end as clm_flag_4 
		       		, case when rx.ndc 		 in (&sim_ndc.) 			then 1 else 0 end as clm_flag_5			
		       		, case when rx.ndc 		 in (&ste_ndc.) 			then 1 else 0 end as clm_flag_6 
		       		, case when rx.ndc 		 in (&tre_ndc.) 			then 1 else 0 end as clm_flag_7 
		       		, case when rx.ndc 		 in (&zyt_ndc.) 			then 1 else 0 end as clm_flag_8 
		       		, case when rx.ndc not in (&all_ndc_codes.) then 1 else 0 end as clm_flag_99 		       		
							, case when rx.ndc 		 in (&all_ndc_codes.) then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc  
							, case when rx.ndc 		 in (&dar_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_1  
							, case when rx.ndc 		 in (&erl_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_2  
							, case when rx.ndc 		 in (&rem_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_3  
							, case when rx.ndc 		 in (&sia_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_4  
							, case when rx.ndc 		 in (&sim_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_5	 
							, case when rx.ndc 		 in (&ste_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_6  
							, case when rx.ndc 		 in (&tre_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_7  
							, case when rx.ndc 		 in (&zyt_ndc.) 			then rx.sbmt_chrg_amt-rx.pd_amt-rx.not_cov_amt-5 else 0 end as amt_cpn_calc_8  
							, case when rx.ndc not in (&all_ndc_codes.) then 0 																					 else 0 end as amt_cpn_calc_99 
  						, rx.pd_amt 													as amt_allowed 			         
  						, rx.copay_amt 												as amt_copay
  						, rx.ded_amt 				           				as amt_deductbl
  						, 0																		as amt_coin     
							, rx.manf_accum_imp										as manf_accum_imp 	
	         		, rx.phrm_ben_pln_nbr 								as rx_ben_pln_nbr 	
	         		, rx.mkt_seg_cd 											as mkt_seg_cd 
		        	, cseg.cust_drvn_hlth_pln_cd 					as cdhp_ind	         		
  				from 
  						galaxy.pharmacy_claim_commercial  		rx
  				inner join galaxy.ndc_drug								ndc
  						on 	rx.ndc = ndc.ndc 
  						and rx.ndc_drg_row_eff_dt = ndc.ndc_drg_row_eff_dt
	  			inner join galaxy.customer_segment_coverage cseg
		  				on  rx.cust_seg_nbr 	 = cseg.cust_seg_nbr 
		  				and rx.cust_seg_sys_id = cseg.cust_seg_sys_id 
		  				and rx.ben_strct_1_cd  = cseg.pln_var_subdiv_cd 
		  				and rx.ben_strct_2_cd  = cseg.rpt_cd_br_cd 
		  				and rx.prdct_cd 			 = cseg.prdct_cd 
					where 
							rx.fill_dt between &cur_st_db2. and &cur_end_db2.							
    				  and rx.fill_dt between cseg.cust_seg_cov_row_eff_dt and cseg.cust_seg_cov_row_end_dt  
    				  and rx.mbr_sys_id>0 
          		and mbr_sys_id in (&&&mbr_list_&ii.)
          for fetch only
          );	
          		
			%let mx_oop_vars_raw  = allw_amt 		coins_amt copay_amt ded_amt 		 ;	
			%let mx_oop_vars  		= amt_allowed	amt_coin 	amt_copay amt_deductbl ;	
			%let fldnum = 4;
					
		   create table t&vz.28_yr&yr_num._mx_claims_&ii. as
		      select distinct * from connection to db2
					(select distinct 
					 		 	mx.mbr_sys_id												 as mbr_sys_id
              , char(mx.unet_clm_head_sys_id) 			 as claim_id
              , mx.dtl_ln_nbr												 as dtl_ln_nbr
              , mx.fst_srvc_dt											 as service_from_date
              , mx.bil_proc_cd 											 as proc_code
              , mx.ndc															 as ndc
              , mx.clm_pd_dt												 as paid_date
							%do i = 1 %to &fldnum.;
		       		, case when mx.ndc 		 in (&dar_ndc.) 			or 	mx.bil_proc_cd 		 in (&dar_proc.) 		   then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_1 
		       		, case when mx.ndc 		 in (&erl_ndc.) 			 												 										 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_2 
		       		, case when mx.ndc 		 in (&rem_ndc.) 			or 	mx.bil_proc_cd 		 in (&rem_proc.) 			 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_3 
		       		, case when mx.ndc 		 in (&sia_ndc.) 			 												 										 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_4 
		       		, case when mx.ndc 		 in (&sim_ndc.) 			or 	mx.bil_proc_cd 		 in (&sim_proc.) 			 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_5			       		
		       		, case when mx.ndc 		 in (&ste_ndc.) 			or 	mx.bil_proc_cd 		 in (&ste_proc.)			 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_6 
		       		, case when mx.ndc 		 in (&tre_ndc.) 			or 	mx.bil_proc_cd 		 in (&tre_proc.)			 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_7 
		       		, case when mx.ndc 		 in (&zyt_ndc.) 																  								 then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_8 		       		
		       		, case when mx.ndc not in (&all_ndc_codes.) and	mx.bil_proc_cd not in (&all_proc_codes.) then %scan(&mx_oop_vars_raw.,&i.) else 0 end as %scan(&mx_oop_vars.,&i.)_99 %end;	  		       		
		       		, 1 																																																			 as clm_flag 
		       		, case when mx.ndc 		 in (&dar_ndc.) 			or 	mx.bil_proc_cd 		 in (&dar_proc.) 			 then 1 else 0 end as clm_flag_1 
		       		, case when mx.ndc 		 in (&erl_ndc.) 			 												 										 then 1 else 0 end as clm_flag_2 
		       		, case when mx.ndc 		 in (&rem_ndc.) 			or 	mx.bil_proc_cd 		 in (&rem_proc.) 			 then 1 else 0 end as clm_flag_3 
		       		, case when mx.ndc 		 in (&sia_ndc.) 			 												 										 then 1 else 0 end as clm_flag_4 
		       		, case when mx.ndc 		 in (&sim_ndc.) 			or 	mx.bil_proc_cd 		 in (&sim_proc.) 			 then 1 else 0 end as clm_flag_5			       		
		       		, case when mx.ndc 		 in (&ste_ndc.) 			or 	mx.bil_proc_cd 		 in (&ste_proc.)			 then 1 else 0 end as clm_flag_6 
		       		, case when mx.ndc 		 in (&tre_ndc.) 			or 	mx.bil_proc_cd 		 in (&tre_proc.)			 then 1 else 0 end as clm_flag_7 
		       		, case when mx.ndc 		 in (&zyt_ndc.) 																			  					 then 1 else 0 end as clm_flag_8 		       		
		       		, case when mx.ndc not in (&all_ndc_codes.) and mx.bil_proc_cd not in (&all_proc_codes.) then 1 else 0 end as clm_flag_99 		       		             
              , mx.allw_amt													 as amt_allowed
              , mx.coins_amt												 as amt_coin
              , mx.copay_amt												 as amt_copay
              , mx.ded_amt													 as amt_deductbl
          from
              galaxy.unet_claim_statistical_service mx
          where
              mx.fst_srvc_dt between &cur_st_db2. and &cur_end_db2.
              and mx.net_pd_amt<>0
              and mx.chrg_sts_cd='P'
              and mx.srvc_curr_ind='Y'
              and mx.enctr_cd in ('0','4') 	
              and mx.clos_clm_ind = 'N'
              and mx.mbr_sys_id>0
          		and mbr_sys_id in (&&&mbr_list_&ii.)
          for fetch only
          );	
				
	   disconnect from db2;
	quit;				

	* AGGREGATE;
	%if &ii = 1 %then %do;
		data inp.t&vz.28_yr&yr_num._mx_claims_raw; set t&vz.28_yr&yr_num._mx_claims_&ii.; run;  
		data inp.t&vz.27_yr&yr_num._rx_claims_raw; set t&vz.27_yr&yr_num._rx_claims_&ii.; run;  
	%end;
	%if &ii > 1 %then %do;
		proc sql; insert into inp.t&vz.28_yr&yr_num._mx_claims_raw 			 																					                
			select * from t&vz.28_yr&yr_num._mx_claims_&ii.; 				quit;                                                 	                    
		proc sql; insert into inp.t&vz.27_yr&yr_num._rx_claims_raw 			 																					                
			select * from t&vz.27_yr&yr_num._rx_claims_&ii.; 				quit;                                                 	                    
	%end;      
          		
* END GALAXY MEMBER LIST LOOP;		
%end;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> PROCESS RX <------------------------------------------------*/
/**/
%no_pull5:;
proc sort data=inp.t&vz.27_yr&yr_num._rx_claims_raw; by mbr_sys_id fill_date ndc; run;
data inp.t&vz.29_yr&yr_num._rx_claims_adj; 
	length	rx_claim
	        prd_clm_flag
	        clm_flag clm_flag_1-clm_flag_&prdnum.
	        clm_flag_99
	        cpn_flag cpn_flag_1-cpn_flag_&prdnum.
	        cpn_flag_99
	        p_cpn_flag p_cpn_flag_1-p_cpn_flag_&prdnum.
	        p_cpn_flag_99
	        days_supply             
	        sum_days_supply  		3
	        fill_date paid_date 4  
	        rx_ben_pln_nbr $6
	        cdhp_ind	 $1
	        nabp_nbr			 $7;
	set inp.t&vz.27_yr&yr_num._rx_claims_raw(rename=(mkt_seg_cd=mkt_seg_cd_raw rx_ben_pln_nbr=rx_ben_pln_nbr_raw cdhp_ind=cdhp_ind_raw nabp_nbr=nabp_nbr_raw)); 
	by mbr_sys_id fill_date ndc;
  array rx_vars{*} &rx_vars.;
  array sum_rx_vars{*} &sum_rx_vars.;
	retain &sum_rx_vars. cpn_: p_cpn_:;
	array cpn{*} amt_manf_cpn amt_manf_cpn_1-amt_manf_cpn_&prdnum. amt_manf_cpn_99; 
	array p_cpn{*} amt_cpn_calc amt_cpn_calc_1-amt_cpn_calc_&prdnum. amt_cpn_calc_99; 
	array cpn_flags{*} cpn_flag cpn_flag_1-cpn_flag_&prdnum. cpn_flag_99; 
	array p_cpn_flags{*} p_cpn_flag p_cpn_flag_1-p_cpn_flag_&prdnum. p_cpn_flag_99; 
	rx_claim = 1; 
	if first.ndc then do; do i = 1 to dim(sum_rx_vars); sum_rx_vars{i}=0; end; do i = 1 to dim(cpn_flags); cpn_flags{i}=0; p_cpn_flags{i}=0; end; end;  
	do i=1 to dim(sum_rx_vars); sum_rx_vars{i}+rx_vars{i}; end; 
	if ndc in (&dar_ndc.) then sum_amt_manf_cpn_1+amt_manf_cpn;
	if ndc in (&erl_ndc.) then sum_amt_manf_cpn_2+amt_manf_cpn;
	if ndc in (&rem_ndc.) then sum_amt_manf_cpn_3+amt_manf_cpn;
	if ndc in (&sia_ndc.) then sum_amt_manf_cpn_4+amt_manf_cpn;
	if ndc in (&sim_ndc.) then sum_amt_manf_cpn_5+amt_manf_cpn;
	if ndc in (&ste_ndc.) then sum_amt_manf_cpn_6+amt_manf_cpn;
	if ndc in (&tre_ndc.) then sum_amt_manf_cpn_7+amt_manf_cpn;
	if ndc in (&zyt_ndc.) then sum_amt_manf_cpn_8+amt_manf_cpn;		
	do i=1 to dim(cpn); if cpn{i}>0 then cpn_flags{i}=1; end; if max(amt_manf_cpn_1-amt_manf_cpn_&prdnum.)>0 then cpn_flag = 1;
	do i=1 to dim(p_cpn); if p_cpn{i}>0 then p_cpn_flags{i}=1; end;
	mkt_seg_cd 			= put(mkt_seg_cd_raw,$claims_bus_seg_fmt.);
	rx_ben_pln_nbr 	= put(substr(rx_ben_pln_nbr_raw,1,5),$5.);
	cdhp_ind				= put(cdhp_ind_raw,$cdhp_fmt.);
	nabp_nbr				= put(nabp_nbr_raw,$all_brx_codes.);
	if last.ndc and sum_days_supply > 0 then do; 
		clm_flag = 1; 
		do i = 1 to dim(sum_rx_vars); if sum_rx_vars{i}<0 then sum_rx_vars{i}=0; end; 
		if ndc in (&all_ndc_codes.) then do; amt_manf_cpn+sum(amt_manf_cpn_1-amt_manf_cpn_&prdnum.); prd_clm_flag=1; end; 
		if ndc not in (&all_ndc_codes.) then do; amt_manf_cpn=0; prd_clm_flag=0; end; 
		output; 
		end;
	drop &rx_vars. i nabp_nbr_raw mkt_seg_cd_raw rx_ben_pln_nbr_raw cdhp_ind_raw claim_id;
	format fill_date mmddyy10. &sum_rx_vars. dollar12.2 sum_days_supply comma4.;
run; 
ods excel options(sheet_name="29" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

* ESTABLISH RX PLAN WINDOWS;
proc sort data=inp.t&vz.29_yr&yr_num._rx_claims_adj; by mbr_sys_id fill_date; run;
data inp.t&vz.30_yr&yr_num._rx_plan_windows; 
	length min_rx_cov_date max_rx_cov_date 4 cov_win_cdhp_ind fst_cov_win_cdhp_ind snd_cov_win_cdhp_ind $1 cov_win_ben_nbr fst_cov_win_ben_nbr snd_cov_win_ben_nbr $6 pln_f2s_days_to_discontinuation pln_f2s_discontinuation_month 3;
	set inp.t&vz.29_yr&yr_num._rx_claims_adj(keep=mbr_sys_id fill_date rx_ben_pln_nbr mkt_seg_cd cdhp_ind); 
	by mbr_sys_id; 
	retain min_rx_cov_date 
				 max_rx_cov_date 
				 cov_thru_date 
				 cov_win 
				 cov_win_ben_nbr_now 
				 cov_win_mkt_seg_cd_now 
				 cov_win_cdhp_ind_now 
				 fst_cov_win_ben_nbr 
				 fst_cov_win_seg_cd 
				 fst_cov_win_cdhp_ind
				 snd_cov_win_ben_nbr 
				 snd_cov_win_seg_cd 
				 snd_cov_win_cdhp_ind
				 pln_f2s_days_to_discontinuation 
				 pln_f2s_discontinuation_month;
	cov_thru_date 						= lag(fill_date); 
	cov_win_ben_nbr_now 			= lag(rx_ben_pln_nbr);
	cov_win_mkt_seg_cd_now 		= lag(mkt_seg_cd);
	cov_win_cdhp_ind_now			=	lag(cdhp_ind);
	if first.mbr_sys_id then do; min_rx_cov_date = &cur_st.; cov_win = 0; fst_cov_win_cdhp_ind = ''; fst_cov_win_ben_nbr = ''; fst_cov_win_seg_cd = ''; snd_cov_win_cdhp_ind = ''; snd_cov_win_ben_nbr = ''; snd_cov_win_seg_cd = ''; pln_f2s_days_to_discontinuation = .; pln_f2s_discontinuation_month = .; end;
  if lag(mbr_sys_id) 				= mbr_sys_id 
  	and lag(rx_ben_pln_nbr) ne rx_ben_pln_nbr then do;  	
  	max_rx_cov_date 				= cov_thru_date; 
  	cov_win_ben_nbr 				= cov_win_ben_nbr_now;   
  	cov_win_seg_cd					=	cov_win_mkt_seg_cd_now;
  	cov_win_cdhp_ind				= cov_win_cdhp_ind_now;
 		cov_win+1;
  	output; 
  	min_rx_cov_date 				= cov_thru_date+1;
  	end;
  if lag(mbr_sys_id) 				= mbr_sys_id 
  	and lag(rx_ben_pln_nbr) ne rx_ben_pln_nbr 
  	and cov_win =1 then do;  	
  	fst_cov_win_ben_nbr 		= cov_win_ben_nbr_now;
  	fst_cov_win_seg_cd			=	cov_win_mkt_seg_cd_now;
  	fst_cov_win_cdhp_ind		=	cov_win_cdhp_ind_now;
  	snd_cov_win_ben_nbr			=	rx_ben_pln_nbr;
  	snd_cov_win_seg_cd			=	mkt_seg_cd;
  	snd_cov_win_cdhp_ind		=	cdhp_ind;
 		pln_f2s_days_to_discontinuation = datdif(&cur_st.,cov_thru_date,'act/act');
 		pln_f2s_discontinuation_month		= month(cov_thru_date);
		end;
  if last.mbr_sys_id then do;
 		max_rx_cov_date 				= &cur_end.; 
 		cov_win									+ 1;      				
 		cov_win_ben_nbr 				= rx_ben_pln_nbr;
 		cov_win_seg_cd 					= mkt_seg_cd;
 		cov_win_cdhp_ind				=	cdhp_ind;
 		output; 
  end;
  keep mbr_sys_id min_rx_cov_date max_rx_cov_date cov_win cov_win_ben_nbr cov_win_cdhp_ind cov_win_seg_cd pln_f2s_days_to_discontinuation pln_f2s_discontinuation_month fst_cov_win_cdhp_ind snd_cov_win_cdhp_ind fst_cov_win_ben_nbr fst_cov_win_seg_cd snd_cov_win_ben_nbr snd_cov_win_seg_cd;
  format min_rx_cov_date max_rx_cov_date mmddyy10.;  	
run; 
ods excel options(sheet_name="30" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,byvars=pln_f2s_discontinuation_month,qa_dsn=inp.t&vz.30_yr&yr_num._rx_plan_windows); %util_dummy_sheet;	

data inp.t&vz.31_yr&yr_num._rx_plan_windows; 
	set inp.t&vz.30_yr&yr_num._rx_plan_windows(rename=(cov_win_ben_nbr = rx_ben_pln_nbr cov_win_seg_cd = mkt_seg_cd cov_win_cdhp_ind=cdhp_ind));
run;  

/*-----------------------------------------------------------------*/
/*---> PLAN SWITCHERS <--------------------------------------------*/
/**/

data inp.t&vz.32_yr&yr_num._rx_plan_windows; 
	set inp.t&vz.30_yr&yr_num._rx_plan_windows; 
	by mbr_sys_id; if last.mbr_sys_id and pln_f2s_days_to_discontinuation>1 then output; 
	keep mbr_sys_id pln_f2s_days_to_discontinuation pln_f2s_discontinuation_month fst_cov_win_ben_nbr snd_cov_win_ben_nbr fst_cov_win_seg_cd snd_cov_win_seg_cd fst_cov_win_cdhp_ind snd_cov_win_cdhp_ind; 
run; 
ods excel options(sheet_name="32" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

*FIRST PLAN STATS;

*APPLY PLAN INFORMATION;
*GRAB ALL PLANS ASSOCIATED WITH CLAIM RX_BEN_PLN_NBR;
proc sql; 
	create table inp.t&vz.33_yr&yr_num._rx_plan_windows as (
	select 	s.mbr_sys_id
				, s.fst_cov_win_ben_nbr																					as rx_ben_pln_nbr
				, s.fst_cov_win_seg_cd																					as mkt_seg_cd
				, s.fst_cov_win_cdhp_ind																				as cdhp_ind
				, pln.business_segment 																			as business_segment           
				,	put(pln.funding_arrangment,$pln_funding_arrangment_fmt.) 	as funding_arrangment              
				, pln.cpn_ben_plan_prt 															as cpn_ben_plan_prt
				, pln.deductible_accum 																as deductible_accum   
				, pln.oop_max_accum 															as oop_max_accum
				, pln.fam_deductible 																				as fam_deductible
				, pln.indv_deductible 																			as indv_deductible
				, pln.fam_oop 																							as fam_oop
				, pln.indv_oop 																							as indv_oop
	from inp.t&vz.32_yr&yr_num._rx_plan_windows s 
	left outer join inp.r&vz.01_final_phbit pln
		on s.fst_cov_win_ben_nbr = pln.rx_ben_pln_nbr
	);
quit; 

*IF MULTIPLE PLANS, SELECT PLAN WITH MATCHING PLN_BUSINESS_SEGMENT;
*IF NO MATCHING BUSINESS SEGMENT THEN NULLIFY PLAN DATA;
proc sort data=inp.t&vz.33_yr&yr_num._rx_plan_windows; by mbr_sys_id fam_deductible; run;
data inp.t&vz.34_yr&yr_num._rx_plan_windows(sortedby=mbr_sys_id);  
	set inp.t&vz.33_yr&yr_num._rx_plan_windows; 
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
data inp.t&vz.35_yr&yr_num._rx_plan_windows(sortedby=mbr_sys_id); 
	length	pln_fst_business_segment            $1
					pln_fst_funding_arrangment          $3
					pln_fst_cpn_ben_plan_prt 		$1
					pln_fst_deductible_accum			$1
					pln_fst_oop_max_accum			$1
					pln_fst_cdhp_ind										$1;	
	set inp.t&vz.34_yr&yr_num._rx_plan_windows(rename=(&pln_vars_fst_rn.)); 
	format pln_fst_fam_deductible pln_fst_indv_deductible pln_fst_fam_oop pln_fst_indv_oop dollar12.2; 
	keep mbr_sys_id &pln_fst_vars.;
run;
ods excel options(sheet_name="35" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

*SECOND PLAN STATS; 

*APPLY PLAN INFORMATION;
*GRAB ALL PLANS ASSOCIATED WITH CLAIM RX_BEN_PLN_NBR;
proc sql; 
	create table inp.t&vz.36_yr&yr_num._rx_plan_windows as (
	select 	s.mbr_sys_id
				, s.snd_cov_win_ben_nbr																					as rx_ben_pln_nbr
				, s.snd_cov_win_seg_cd																					as mkt_seg_cd
				, s.snd_cov_win_cdhp_ind																				as cdhp_ind
				, pln.business_segment 																			as business_segment           
				,	put(pln.funding_arrangment,$pln_funding_arrangment_fmt.) 	as funding_arrangment              
				, pln.cpn_ben_plan_prt 															as cpn_ben_plan_prt
				, pln.deductible_accum 																as deductible_accum   
				, pln.oop_max_accum 															as oop_max_accum
				, pln.fam_deductible 																				as fam_deductible
				, pln.indv_deductible 																			as indv_deductible
				, pln.fam_oop 																							as fam_oop
				, pln.indv_oop 																							as indv_oop
	from inp.t&vz.32_yr&yr_num._rx_plan_windows s 
	left outer join inp.r&vz.01_final_phbit pln
		on s.snd_cov_win_ben_nbr = pln.rx_ben_pln_nbr
	);
quit; 

*IF MULTIPLE PLANS, SELECT PLAN WITH MATCHING PLN_BUSINESS_SEGMENT;
*IF NO MATCHING BUSINESS SEGMENT THEN NULLIFY PLAN DATA;
proc sort data=inp.t&vz.36_yr&yr_num._rx_plan_windows; by mbr_sys_id fam_deductible; run;
data inp.t&vz.37_yr&yr_num._rx_plan_windows(sortedby=mbr_sys_id);  
	set inp.t&vz.36_yr&yr_num._rx_plan_windows; 
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
data inp.t&vz.38_yr&yr_num._rx_plan_windows(sortedby=mbr_sys_id); 
	length	pln_snd_business_segment            $1
					pln_snd_funding_arrangment          $3
					pln_snd_cpn_ben_plan_prt 		$1
					pln_snd_deductible_accum			$1
					pln_snd_oop_max_accum			$1
					pln_snd_cdhp_ind										$1;	
	set inp.t&vz.37_yr&yr_num._rx_plan_windows(rename=(&pln_vars_snd_rn.)); 
	format pln_snd_fam_deductible pln_snd_indv_deductible pln_snd_fam_oop pln_snd_indv_oop dollar12.2; 
	keep mbr_sys_id &pln_snd_vars.;
run;
ods excel options(sheet_name="36" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
        
*COMBINED FIRST, SECOND PLAN STATS;
data inp.t&vz.39_yr&yr_num._rx_plan_windows(sortedby=mbr_sys_id); 
	merge inp.t&vz.32_yr&yr_num._rx_plan_windows(keep=mbr_sys_id pln_f2s_days_to_discontinuation pln_f2s_discontinuation_month)
				inp.t&vz.35_yr&yr_num._rx_plan_windows 
				inp.t&vz.38_yr&yr_num._rx_plan_windows;
	by mbr_sys_id;
run;
ods excel options(sheet_name="39" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

/*-----------------------------------------------------------------*/
/*---> PROCESS MX  <-----------------------------------------------*/
/**/

title "inp.t&vz.28_yr&yr_num._mx_claims_raw";
proc freq data=inp.t&vz.28_yr&yr_num._mx_claims_raw nlevels; tables mbr_sys_id / noprint; run;
data inp.t&vz.40_yr&yr_num._mx_claims_adj_a; 
	length	prd_clm_flag
					clm_flag clm_flag_1-clm_flag_&prdnum.
					clm_flag_99 
	        mx_claim				 3
 					service_from_date 
 					paid_date 			 4
 					clm_dtl			  	$21;
	set inp.t&vz.28_yr&yr_num._mx_claims_raw;
	mx_claim = 1;
	clm_flag = 1; 
	clm_dtl = claim_id!!dtl_ln_nbr;
	if ndc in (&all_ndc_codes.) or proc_code in (&all_proc_codes.) then prd_clm_flag = 1; else prd_clm_flag=0;
	drop claim_id dtl_ln_nbr; 
	format service_from_date paid_date mmddyy10. amt_allowed amt_coin amt_deductbl amt_copay_1-amt_copay_&prdnum. amt_copay_99 amt_allowed_1-amt_allowed_&prdnum. amt_allowed_99 amt_coin_1-amt_coin_&prdnum. amt_coin_99 amt_deductbl_1-amt_deductbl_&prdnum. amt_deductbl_99 amt_copay_1-amt_copay_&prdnum. amt_copay_99 dollar12.2;
run;
ods excel options(sheet_name="40" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

proc sort data=inp.t&vz.40_yr&yr_num._mx_claims_adj_a; by clm_dtl; run;
* LINK MX CLAIMS WITH RX PLAN WINDOWS TO OBTAIN RX BENEFIT PLANS;
proc sql; 
	create table inp.t&vz.41_yr&yr_num._mx_plan_window_a as 
	select mx.clm_dtl
			 , mx.service_from_date
			 , win.min_rx_cov_date
			 , win.max_rx_cov_date
			 , win.rx_ben_pln_nbr
			 , win.mkt_seg_cd
			 , win.cdhp_ind 
	from inp.t&vz.40_yr&yr_num._mx_claims_adj_a mx 
	left outer join inp.t&vz.31_yr&yr_num._rx_plan_windows win 
		on mx.mbr_sys_id = win.mbr_sys_id; 
quit; 

data inp.t&vz.42_yr&yr_num._mx_claims_adj; 
	set inp.t&vz.41_yr&yr_num._mx_plan_window_a; 
	if min_rx_cov_date <= service_from_date <= max_rx_cov_date then output;
	if missing(min_rx_cov_date) then output;
	drop min_rx_cov_date max_rx_cov_date;
run;

proc sort data=inp.t&vz.42_yr&yr_num._mx_claims_adj; by clm_dtl; run;
data inp.t&vz.43_yr&yr_num._mx_claims_adj; merge inp.t&vz.42_yr&yr_num._mx_claims_adj inp.t&vz.40_yr&yr_num._mx_claims_adj_a; by clm_dtl; run;
ods excel options(sheet_name="42" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

/*-----------------------------------------------------------------*/
/*---> COMBINE RX, MX  <-------------------------------------------*/
/**/

proc sql; create table inp.t&vz.44_yr&yr_num._claims_mx_adj as (
	select mx.*, mbr.family_id
	from inp.t&vz.43_yr&yr_num._mx_claims_adj mx 
	inner join inp.t&vz.23_yr&yr_num._all_family_mbrs mbr 
		on mx.mbr_sys_id = mbr.mbr_sys_id); 
quit; 
ods excel options(sheet_name="44" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

proc sql; create table inp.t&vz.45_yr&yr_num._claims_rx_adj as (
	select rx.*, mbr.family_id
	from inp.t&vz.29_yr&yr_num._rx_claims_adj rx 
	inner join inp.t&vz.23_yr&yr_num._all_family_mbrs mbr 
		on rx.mbr_sys_id = mbr.mbr_sys_id); 
quit; 
ods excel options(sheet_name="45" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

data inp.t&vz.46_yr&yr_num._claims_adj; 
	length amt_tot_oop_99 8 clm_nbr 6 service_date 4 service_month paid_month 3; 
	array clm_oop_vars{*} amt_tot_oop_1-amt_tot_oop_&prdnum.;
	array clm_coin_vars{*} amt_coin_1-amt_coin_&prdnum.;
	array clm_copay_vars{*} amt_copay_1-amt_copay_&prdnum.;
	array clm_deductbl_vars{*} amt_deductbl_1-amt_deductbl_&prdnum.;
	set inp.t&vz.44_yr&yr_num._claims_mx_adj	(
				rename=(	service_from_date 		= service_date) 
				drop = clm_dtl) 
			inp.t&vz.45_yr&yr_num._claims_rx_adj	(
				rename=(	&sum_rx_vars_rn.
									fill_date 						= service_date) 
				); 
    	amt_tot_oop = sum(amt_coin,amt_copay,amt_deductbl);
    	do i = 1 to dim(clm_oop_vars); clm_oop_vars{i}=clm_coin_vars{i}+clm_copay_vars{i}+clm_deductbl_vars{i}; end; 
    	service_month = month(service_date);                                                                            
    	paid_month = month(paid_date);                                                                                 
    	clm_nbr+1;                                                                                                  
    	drop days_supply;			
run;
ods excel options(sheet_name="46" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

proc datasets nolist; delete t&vz.:; quit;

/*-----------------------------------------------------------------*/
/*---> LENGTH OF THERAPY  <----------------------------------------*/
/**/

proc sort data=inp.t&vz.29_yr&yr_num._rx_claims_adj; by mbr_sys_id fill_date; run;
data inp.t&vz.47_yr&yr_num._rx_ln_of_t; merge inp.t&vz.29_yr&yr_num._rx_claims_adj inp.t&vz.18_yr&yr_num._ch_mbrs(keep=mbr_sys_id prd_idx_date_1-prd_idx_date_&prdnum.); by mbr_sys_id; run;
data inp.t&vz.48_yr&yr_num._rx_ln_of_t(sortedby=mbr_sys_id); 
	length	prd_therapy_length_rx_1-prd_therapy_length_rx_&prdnum. 3
	        therapy_thru_rx_1-therapy_thru_rx_&prdnum. 4;
	set inp.t&vz.47_yr&yr_num._rx_ln_of_t; 
	by mbr_sys_id fill_date;
	array idx{*} prd_idx_date_1-prd_idx_date_&prdnum.;	
	array prd_flags{*} clm_flag_1-clm_flag_&prdnum.;
	array therapy_thru{*} therapy_thru_rx_1-therapy_thru_rx_&prdnum.;
	array therapy_length{*} prd_therapy_length_rx_1-prd_therapy_length_rx_&prdnum.;	
	retain therapy_thru_rx_1-therapy_thru_rx_&prdnum.;
	if first.mbr_sys_id then do i = 1 to dim(therapy_thru); therapy_thru{i}=0; therapy_length{i}=0; end;
	do i=1 to dim(idx); if prd_flags{i} then therapy_thru{i} = fill_date; end;
	if last.mbr_sys_id then do; do i=1 to dim(idx); if therapy_thru{i}>0 and idx{i} ne '31Dec1899'd and not(missing(idx{i})) then therapy_length{i} = datdif(idx{i},therapy_thru{i},'act/act'); else therapy_length{i}=0; end; output; end;
	keep mbr_sys_id prd_therapy_length_rx_1-prd_therapy_length_rx_&prdnum. therapy_thru_rx_1-therapy_thru_rx_&prdnum.; 
	format therapy_thru_rx_1-therapy_thru_rx_&prdnum. mmddyy10.;
run;
ods excel options(sheet_name="29" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

proc sort data=inp.t&vz.40_yr&yr_num._mx_claims_adj_a; by mbr_sys_id service_from_date; run;
data inp.t&vz.49_yr&yr_num._mx_ln_of_t; merge inp.t&vz.40_yr&yr_num._mx_claims_adj_a inp.t&vz.18_yr&yr_num._ch_mbrs(keep=mbr_sys_id prd_idx_date_1-prd_idx_date_&prdnum.); by mbr_sys_id; run;
data inp.t&vz.50_yr&yr_num._mx_ln_of_t(sortedby=mbr_sys_id); 
	length	prd_therapy_length_mx_1-prd_therapy_length_mx_&prdnum. 3
	        therapy_thru_mx_1-therapy_thru_mx_&prdnum. 4;
	set inp.t&vz.49_yr&yr_num._mx_ln_of_t; 
	by mbr_sys_id service_from_date;
	array idx{*} 	prd_idx_date_1-prd_idx_date_&prdnum.;	
	array prd_flags{*} clm_flag_1-clm_flag_&prdnum.;
	array therapy_thru{*} therapy_thru_mx_1-therapy_thru_mx_&prdnum.;
	array therapy_length{*} prd_therapy_length_mx_1-prd_therapy_length_mx_&prdnum.;	
	retain therapy_thru_mx_1-therapy_thru_mx_&prdnum.;
	if first.mbr_sys_id then do i = 1 to dim(therapy_thru); therapy_thru{i}=0; therapy_length{i}=0; end;
	do i=1 to dim(idx); if prd_flags{i} then therapy_thru{i} = service_from_date; end;
	if last.mbr_sys_id then do; do i=1 to dim(idx); if therapy_thru{i}>0 and idx{i} ne '31Dec1899'd and not(missing(idx{i})) then therapy_length{i} = datdif(idx{i},therapy_thru{i},'act/act'); else therapy_length{i}=0; end; output; end;
	keep mbr_sys_id prd_therapy_length_mx_1-prd_therapy_length_mx_&prdnum. therapy_thru_mx_1-therapy_thru_mx_&prdnum.; 
	format therapy_thru_mx_1-therapy_thru_mx_&prdnum. mmddyy10.;
run;
ods excel options(sheet_name="40" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

data inp.t&vz.51_yr&yr_num._ln_of_t(sortedby=mbr_sys_id); 
	length prd_therapy_length_1-prd_therapy_length_&prdnum. 3;
	merge inp.t&vz.48_yr&yr_num._rx_ln_of_t
				inp.t&vz.50_yr&yr_num._mx_ln_of_t;
	by mbr_sys_id;
	array prd_therapy_length_rx{*} prd_therapy_length_rx_1-prd_therapy_length_rx_&prdnum.;	
	array prd_therapy_length_mx{*} prd_therapy_length_mx_1-prd_therapy_length_mx_&prdnum.;	
	array therapy_length{*} prd_therapy_length_1-prd_therapy_length_&prdnum.;	
	do i=1 to dim(therapy_length); therapy_length{i} = max(prd_therapy_length_mx{i},prd_therapy_length_rx{i}); end;
	keep mbr_sys_id prd_therapy_length_1-prd_therapy_length_&prdnum.;
run;
ods excel options(sheet_name="51" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

/*-----------------------------------------------------------------*/
/*---> BENEFIT PLAN INFORMATION  <---------------------------------*/
/**/

*APPLY PLAN INFORMATION TO CLAIMS;
*GRAB ALL PLANS ASSOCIATED WITH CLAIM RX_BEN_PLN_NBR;
proc sql; 
	create table inp.t&vz.52_yr&yr_num._claims_adj_pa as (
	select 	clm.clm_nbr
				, clm.mkt_seg_cd																					as mkt_seg_cd
				, clm.cdhp_ind																						as cdhp_ind
				, pln.rx_ben_pln_nbr																			as rx_ben_pln_nbr
				, pln.business_segment           													as business_segment
				,	put(pln.funding_arrangment,$pln_funding_arrangment_fmt.) as funding_arrangment              
				, pln.cpn_ben_plan_prt 																		as cpn_ben_plan_prt
				, pln.deductible_accum    																as deductible_accum
				, pln.oop_max_accum                                       as oop_max_accum
				, pln.fam_deductible                                      as fam_deductible
				, pln.indv_deductible                                     as indv_deductible
				, pln.fam_oop                                             as fam_oop
				, pln.indv_oop                                            as indv_oop
	from inp.t&vz.46_yr&yr_num._claims_adj clm 
	left outer join inp.r&vz.01_final_phbit pln
		on clm.rx_ben_pln_nbr = pln.rx_ben_pln_nbr
	);
quit; 

*IF MULTIPLE PLANS, SELECT PLAN WITH MATCHING PLN_BUSINESS_SEGMENT;
*IF NO MATCHING BUSINESS SEGMENT THEN NULLIFY PLAN DATA;
proc sort data=inp.t&vz.52_yr&yr_num._claims_adj_pa; by clm_nbr fam_deductible; run;
data inp.t&vz.53_yr&yr_num._claims_plan(sortedby=clm_nbr);  
	set inp.t&vz.52_yr&yr_num._claims_adj_pa; 
	by clm_nbr; 
	array plan_vars 3 &pln_vars_plan_multi.;
	retain im_out;
	if first.clm_nbr then do; im_out=0; end;
	if first.clm_nbr and last.clm_nbr then do; im_out=1; output; end;
	if mkt_seg_cd = business_segment and im_out ne 1 then do; im_out = 1; output; end; 
	if last.clm_nbr and mkt_seg_cd ne business_segment and im_out ne 1 then do; 
		do over plan_vars; plan_vars = 'U'; 
			fam_deductible = .; indv_deductible = .; fam_oop = .; indv_oop = .; 
			im_out = 1; 
			end; 
		output; 
		end;		
	drop im_out;
	format fam_deductible indv_deductible fam_oop indv_oop dollar12.2;
run; 
data inp.t&vz.54_yr&yr_num._claims_plan(sortedby=clm_nbr); 
	length	pln_a_business_segment            $1
					pln_a_funding_arrangment          $3
					pln_a_cpn_ben_plan_prt 		$1
					pln_a_deductible_accum			$1
					pln_a_oop_max_accum			$1
					pln_a_cdhp_ind										$1;	
	set inp.t&vz.53_yr&yr_num._claims_plan(rename=(&pln_vars_a_rn.)); 
	format pln_a_fam_deductible pln_a_indv_deductible pln_a_fam_oop pln_a_indv_oop dollar12.2; 
	keep clm_nbr &pln_a_vars.;
run;

data inp.t&vz.55_yr&yr_num._claims_plan; merge inp.t&vz.46_yr&yr_num._claims_adj inp.t&vz.54_yr&yr_num._claims_plan; by clm_nbr; if missing(pln_a_cpn_ben_plan_prt) then pln_a_cpn_ben_plan_prt = 'O'; run;

proc sql; create table inp.t&vz.56_yr&yr_num._claims_plan as (select distinct family_id, count(distinct pln_a_rx_ben_pln_nbr) as count_rx_plans from inp.t&vz.55_yr&yr_num._claims_plan group by family_id); quit; 
proc sql; create table inp.t&vz.57_yr&yr_num._claims_plan as (select distinct clm.mbr_sys_id, fam.count_rx_plans from inp.t&vz.55_yr&yr_num._claims_plan clm inner join inp.t&vz.56_yr&yr_num._claims_plan fam on clm.family_id = fam.family_id group by clm.mbr_sys_id); quit; 
proc sort data=inp.t&vz.57_yr&yr_num._claims_plan; by mbr_sys_id; run;

*REMOVE PLAN SWITCHERS;
proc sort data=inp.t&vz.55_yr&yr_num._claims_plan; by family_id paid_date clm_nbr; run;
data inp.t&vz.56_yr&yr_num._claims_plan; merge inp.t&vz.55_yr&yr_num._claims_plan inp.t&vz.56_yr&yr_num._claims_plan; by family_id; if count_rx_plans>1 then delete; drop count_rx_plans; run;
																							 
/*-----------------------------------------------------------------*/
/*---> OUT-OF-POCKET ANALYSES - FAMILY FIRST <---------------------*/
/**/

proc sort data=inp.t&vz.56_yr&yr_num._claims_plan; by mbr_sys_id; run;
proc sort data=inp.t&vz.23_yr&yr_num._all_family_mbrs; by mbr_sys_id; run;	
data inp.t&vz.57_yr&yr_num._claims_plan(sortedby=mbr_sys_id); 
	merge inp.t&vz.23_yr&yr_num._all_family_mbrs(keep=mbr_sys_id ch_mem in=ch)
				inp.t&vz.56_yr&yr_num._claims_plan(in=clms);
	by mbr_sys_id; if ch and clms;
run;

* FAMILY CLAIM SUMMARIES;
proc sort data=inp.t&vz.57_yr&yr_num._claims_plan; by family_id paid_date clm_nbr; run;
data inp.t&vz.58_yr&yr_num._fam_claim_sum(sortedby=family_id); 
	length &sum_fam_count_vars. 3; 
	set inp.t&vz.57_yr&yr_num._claims_plan; 
	by family_id;
  array oop_vars{*} &oop_vars.;
  array count_vars{*} &count_vars.;
  array sum_oop_vars{*} &sum_fam_oop_vars.;
	array sum_count_vars{*} &sum_fam_count_vars.;
	retain &sum_fam_oop_vars. &sum_fam_count_vars.;
	if first.family_id then do; 
		do i=1 to dim(sum_oop_vars); sum_oop_vars{i}=0; end; 
		do i=1 to dim(sum_count_vars); sum_count_vars{i}=0; end; 
		end;	
	do i=1 to dim(sum_oop_vars); sum_oop_vars{i}+oop_vars{i};	end;
	do i=1 to dim(sum_count_vars); sum_count_vars{i}+count_vars{i};	end;
  keep family_id paid_date clm_nbr pln_: sum_fam_:;
  format &sum_fam_oop_vars. dollar12.2 &sum_fam_count_vars. comma4.;
run; 
ods excel options(sheet_name="58" &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=family_id); %util_dummy_sheet;

*DEDUCTIBLES MET - FAMILY;																																				
proc sort data=inp.t&vz.58_yr&yr_num._fam_claim_sum; by family_id paid_date clm_nbr; run;
data inp.t&vz.59_yr&yr_num._fam_p_ded_met (sortedby=family_id)      																					 /*MET POTENTIAL GHOST DEDUCTIBLE*/   
		 inp.t&vz.59_yr&yr_num._fam_g_ded_met(sortedby=family_id)                                                  /*MET TRUE GHOST DEDUCTIBLE*/   
		 inp.t&vz.59_yr&yr_num._fam_ded_met (sortedby=family_id);                                                  /*MET ACTUAL DEDUCTIBLE*/         
	length resp_met resp_days resp_month 3;                                                                         
	set inp.t&vz.58_yr&yr_num._fam_claim_sum; 
	by family_id paid_date clm_nbr;
	retain ptl_ghost_met_now true_ghost_met_now met_now;
	resp_met 										= 0;
	resp_days 									= 0;
	resp_month 									= 0;
	if first.family_id then do; met_now = 0; true_ghost_met_now = 0; ptl_ghost_met_now = 0; end;  
	if pln_a_deductible_accum in ('Y') then do;
		if sum_fam_amt_deductbl+sum_fam_amt_cpn_calc >= pln_a_fam_deductible and ptl_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			ptl_ghost_met_now				= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act'); 
			resp_month							=	month(paid_date);
			output inp.t&vz.59_yr&yr_num._fam_p_ded_met;
			end;	
		if sum_fam_amt_deductbl+sum_fam_amt_manf_cpn >= pln_a_fam_deductible and true_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			true_ghost_met_now			= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act'); 
			resp_month							=	month(paid_date);
			output inp.t&vz.59_yr&yr_num._fam_g_ded_met;
			end;	
		if sum_fam_amt_deductbl 	>= pln_a_fam_deductible and met_now ne 1 then do;
			resp_met 								= 1; 	
			met_now 								= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act'); 
			resp_month							=	month(paid_date);
			output inp.t&vz.59_yr&yr_num._fam_ded_met;
			end;	
		end;
	if pln_a_deductible_accum in ('N') and pln_a_oop_max_accum in ('Y') then do;
		if (sum_fam_amt_tot_oop+sum_fam_amt_cpn_calc) >= pln_a_fam_oop and ptl_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			ptl_ghost_met_now				= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act');   
			resp_month							=	month(paid_date);       
			output inp.t&vz.59_yr&yr_num._fam_p_ded_met;
			end;	
		if (sum_fam_amt_tot_oop+sum_fam_amt_manf_cpn) >= pln_a_fam_oop and true_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			true_ghost_met_now			= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act');   
			resp_month							=	month(paid_date);       
			output inp.t&vz.59_yr&yr_num._fam_g_ded_met;
			end;	
		if (sum_fam_amt_tot_oop) 	>= pln_a_fam_oop and met_now ne 1 then do;
			resp_met 								= 1; 	
			met_now			 						= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act');   
			resp_month							=	month(paid_date);       
			output inp.t&vz.59_yr&yr_num._fam_ded_met;
			end;	
		end;
	if last.family_id and ptl_ghost_met_now ne 1 then do; 
			resp_met 								= 0; 
			resp_days								= datdif(&cur_st.,&cur_end.,'act/act'); 
			resp_month 							=	month(&cur_end.); 
			output inp.t&vz.59_yr&yr_num._fam_p_ded_met; 
			end;
	if last.family_id and true_ghost_met_now ne 1 then do; 
			resp_met 								= 0; 
			resp_days								= datdif(&cur_st.,&cur_end.,'act/act'); 
			resp_month 							=	month(&cur_end.); 
			output inp.t&vz.59_yr&yr_num._fam_g_ded_met; 
			end;
	if last.family_id and met_now ne 1 then do; 
			resp_met 								= 0; 
			resp_days								= datdif(&cur_st.,&cur_end.,'act/act'); 
			resp_month 							=	month(&cur_end.); 
			output inp.t&vz.59_yr&yr_num._fam_ded_met; 
			end;
	keep family_id paid_date clm_nbr resp_: pln_: sum_:;
run;
/*POTENTIAL GHOST RESULTS QA - DEDUCTIBLE*/
ods excel options(sheet_name="59.1" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.59_yr&yr_num._fam_p_ded_met,unq=family_id,
						byvars=pln_a_deductible_accum sum_fam_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_fam_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_fam_deductible sum_fam_amt_deductbl sum_fam_amt_cpn_calc); %util_dummy_sheet;
/*TRUE GHOST RESULTS QA - DEDUCTIBLE*/					
ods excel options(sheet_name="59.3" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.59_yr&yr_num._fam_g_ded_met,unq=family_id,
						byvars=pln_a_deductible_accum sum_fam_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_fam_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_fam_deductible sum_fam_amt_deductbl sum_fam_amt_manf_cpn); %util_dummy_sheet;
/*ACTUAL DEDUCTIBLE RESULTS QA - DEDUCTIBLE*/														
ods excel options(sheet_name="59.5" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.59_yr&yr_num._fam_ded_met,unq=family_id,
						byvars=pln_a_deductible_accum sum_fam_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_fam_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_fam_deductible sum_fam_amt_deductbl); %util_dummy_sheet;

/*POTENTIAL GHOST RESULTS QA - OOP MAX*/
ods excel options(sheet_name="59.2" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.59_yr&yr_num._fam_p_ded_met,unq=family_id,
						byvars=pln_a_oop_max_accum sum_fam_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_fam_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_fam_oop sum_fam_amt_tot_oop sum_fam_amt_coin sum_fam_amt_copay sum_fam_amt_deductbl sum_fam_amt_cpn_calc); %util_dummy_sheet;
/*TRUE GHOST RESULTS QA - OOP MAX*/	
ods excel options(sheet_name="59.4" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.59_yr&yr_num._fam_g_ded_met,unq=family_id,
						byvars=pln_a_oop_max_accum sum_fam_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_fam_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_fam_oop sum_fam_amt_tot_oop sum_fam_amt_coin sum_fam_amt_copay sum_fam_amt_deductbl sum_fam_amt_manf_cpn); %util_dummy_sheet;
/*ACTUAL DEDUCTIBLE RESULTS QA - OOP MAX*/		
ods excel options(sheet_name="59.6" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.59_yr&yr_num._fam_ded_met,unq=family_id,
						byvars=pln_a_oop_max_accum sum_fam_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_fam_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_fam_oop sum_fam_amt_tot_oop sum_fam_amt_coin sum_fam_amt_copay sum_fam_amt_deductbl); %util_dummy_sheet;					 		

/*-----------------------------------------------------------------*/
/*---> OUT-OF-POCKET ANALYSES - ME LAST <--------------------------*/
/**/

%local nine_only clm_whr mem_only; 
%do i=1 %to 2;
	%if &i = 2 %then %do; %let nine_only = 9O; %let clm_whr = and service_month<10; %let mem_only = if last.mbr_sys_id then output; %end;
	* INDIVIDUAL CLAIM SUMMARIES - ALL CLAIMS, THEN NINE MONTHS ONLY;
	proc sort data=inp.t&vz.57_yr&yr_num._claims_plan; by mbr_sys_id paid_date clm_nbr; run;
	data inp.t&vz.60_yr&yr_num._indv_claim_sum&nine_only.(sortedby=mbr_sys_id); 
		length &sum_indv_count_vars. 3; 
		set inp.t&vz.57_yr&yr_num._claims_plan(where=(ch_mem=1 &clm_whr.)); 
		by mbr_sys_id;
	  array oop_vars{*} &oop_vars.;
	  array count_vars{*} &count_vars.;
	  array sum_oop_vars{*} &sum_indv_oop_vars.;
		array sum_count_vars{*} &sum_indv_count_vars.;
		retain &sum_indv_oop_vars. &sum_indv_count_vars.;
		if first.mbr_sys_id then do; 
			do i=1 to dim(sum_oop_vars); sum_oop_vars{i}=0; end; 
			do i=1 to dim(sum_count_vars); sum_count_vars{i}=0; end; 
			end;
		do i=1 to dim(sum_oop_vars); sum_oop_vars{i}+oop_vars{i};	end;
		do i=1 to dim(sum_count_vars); sum_count_vars{i}+count_vars{i};	end;
		&mem_only.;		
	  keep family_id mbr_sys_id paid_date clm_nbr pln_: sum_indv_:;
	  format &sum_indv_oop_vars. dollar12.2 &sum_indv_count_vars. comma4.;
	run; 
	ods excel options(sheet_name="60&nine_only." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
%end;

*DEDUCTIBLES MET - INDIVIDUAL;																																				
proc sort data=inp.t&vz.60_yr&yr_num._indv_claim_sum; by mbr_sys_id paid_date clm_nbr; run;
data inp.t&vz.61_yr&yr_num._indv_p_ded_met(sortedby=mbr_sys_id keep=family_id mbr_sys_id paid_date clm_nbr resp_: pln_: sum_:) 		 	/*MET POTENTIAL GHOST DEDUCTIBLE*/
		 inp.t&vz.61_yr&yr_num._indv_g_ded_met(sortedby=mbr_sys_id keep=family_id mbr_sys_id paid_date clm_nbr resp_: pln_: sum_:) 		 	/*MET TRUE GHOST DEDUCTIBLE*/
		 inp.t&vz.61_yr&yr_num._indv_ded_met (sortedby=mbr_sys_id keep=family_id mbr_sys_id  paid_date clm_nbr resp_: pln_: sum_:)  		/*MET DEDUCTIBLE*/
		 inp.t&vz.61_yr&yr_num._indv_tot_clm_stats(sortedby=mbr_sys_id keep=mbr_sys_id 			 paid_date clm_nbr resp_: pln_: sum_:); 		/*TOTAL ANALYSIS WINDOW*/
	set inp.t&vz.60_yr&yr_num._indv_claim_sum; 
	by mbr_sys_id paid_date clm_nbr;
	retain ptl_ghost_met_now true_ghost_met_now met_now;
	resp_met 										= 0;
	resp_days 									= 0;
	resp_month 									= 0;
	if first.mbr_sys_id then do; ptl_ghost_met_now = 0; true_ghost_met_now = 0; met_now = 0; end;  
	if pln_a_deductible_accum in ('Y') then do;
		if sum_indv_amt_deductbl+sum_indv_amt_cpn_calc >= pln_a_indv_deductible and ptl_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			ptl_ghost_met_now				= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act'); 
			resp_month							=	month(paid_date);
			output inp.t&vz.61_yr&yr_num._indv_p_ded_met;
			end;	
		if sum_indv_amt_deductbl+sum_indv_amt_manf_cpn >= pln_a_indv_deductible and true_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			true_ghost_met_now			= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act'); 
			resp_month							=	month(paid_date);
			output inp.t&vz.61_yr&yr_num._indv_g_ded_met;
			end;	
		if sum_indv_amt_deductbl 	>= pln_a_indv_deductible and met_now ne 1 then do;
			resp_met 								= 1; 	
			met_now 								= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act'); 
			resp_month							=	month(paid_date);
			output inp.t&vz.61_yr&yr_num._indv_ded_met;
			end;	
		end;
	if pln_a_deductible_accum in ('N') and pln_a_oop_max_accum in ('Y') then do;
		if (sum_indv_amt_tot_oop+sum_indv_amt_cpn_calc) >= pln_a_indv_oop and ptl_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			ptl_ghost_met_now				= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act');   
			resp_month							=	month(paid_date);       
			output inp.t&vz.61_yr&yr_num._indv_p_ded_met;
			end;	
		if (sum_indv_amt_tot_oop+sum_indv_amt_manf_cpn) >= pln_a_indv_oop and true_ghost_met_now ne 1 then do;
			resp_met 								= 1; 	
			true_ghost_met_now			= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act');   
			resp_month							=	month(paid_date);       
			output inp.t&vz.61_yr&yr_num._indv_g_ded_met;
			end;	
		if (sum_indv_amt_tot_oop)	>= pln_a_indv_oop and met_now ne 1 then do;
			resp_met 								= 1; 	
			met_now 								= 1; 
			resp_days 							= datdif(&cur_st.,paid_date,'act/act');   
			resp_month							=	month(paid_date);       
			output inp.t&vz.61_yr&yr_num._indv_ded_met;
			end;	
		end;
	if last.mbr_sys_id and ptl_ghost_met_now ne 1 then do; 
			resp_met 								= 0; 
			resp_days								= datdif(&cur_st.,&cur_end.,'act/act'); 
			resp_month 							=	month(&cur_end.);  
			output inp.t&vz.61_yr&yr_num._indv_p_ded_met; 
			end;
	if last.mbr_sys_id and true_ghost_met_now ne 1 then do; 
			resp_met 								= 0; 
			resp_days								= datdif(&cur_st.,&cur_end.,'act/act'); 
			resp_month 							=	month(&cur_end.);  
			output inp.t&vz.61_yr&yr_num._indv_g_ded_met; 
			end;
	if last.mbr_sys_id and met_now ne 1 then do; 
			resp_met = 0; resp_days	= datdif(&cur_st.,&cur_end.,'act/act'); 
			resp_month 							=	month(&cur_end.);  
			output inp.t&vz.61_yr&yr_num._indv_ded_met; 
			end;  
	if last.mbr_sys_id then 
			output inp.t&vz.61_yr&yr_num._indv_tot_clm_stats;  
run;

/*POTENTIAL GHOST RESULTS QA - DEDUCTIBLE*/
ods excel options(sheet_name="61.1" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_p_ded_met,unq=mbr_sys_id,
						byvars=pln_a_deductible_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_deductible sum_indv_amt_deductbl sum_indv_amt_cpn_calc); %util_dummy_sheet;
/*TRUE GHOST RESULTS QA - DEDUCTIBLE*/					
ods excel options(sheet_name="61.2" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_g_ded_met,unq=mbr_sys_id,
						byvars=pln_a_deductible_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_deductible sum_indv_amt_deductbl sum_indv_amt_manf_cpn); %util_dummy_sheet;
/*ACTUAL DEDUCTIBLE RESULTS QA - DEDUCTIBLE*/														
ods excel options(sheet_name="61.3" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_ded_met,unq=mbr_sys_id,
						byvars=pln_a_deductible_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_deductible sum_indv_amt_deductbl); %util_dummy_sheet;
/*TOTAL CLAIM SUMMARY RESULTS QA - DEDUCTIBLE*/														
ods excel options(sheet_name="61.4" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_tot_clm_stats,unq=mbr_sys_id,
						byvars=pln_a_oop_max_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_deductible sum_indv_amt_deductbl sum_indv_amt_cpn_calc sum_indv_amt_manf_cpn); %util_dummy_sheet;

/*POTENTIAL GHOST RESULTS QA - OOP MAX*/
ods excel options(sheet_name="61.5" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_p_ded_met,unq=mbr_sys_id,
						byvars=pln_a_oop_max_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_oop sum_indv_amt_tot_oop sum_indv_amt_coin sum_indv_amt_copay sum_indv_amt_deductbl sum_indv_amt_cpn_calc); %util_dummy_sheet;
/*TRUE GHOST RESULTS QA - OOP MAX*/					
ods excel options(sheet_name="61.6" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_g_ded_met,unq=mbr_sys_id,
						byvars=pln_a_oop_max_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_oop sum_indv_amt_tot_oop sum_indv_amt_coin sum_indv_amt_copay sum_indv_amt_deductbl sum_indv_amt_manf_cpn); %util_dummy_sheet;
/*ACTUAL DEDUCTIBLE RESULTS QA - OOP MAX*/														
ods excel options(sheet_name="61.7" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_ded_met,unq=mbr_sys_id,
						byvars=pln_a_oop_max_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_oop sum_indv_amt_tot_oop sum_indv_amt_coin sum_indv_amt_copay sum_indv_amt_deductbl); %util_dummy_sheet;	 	
/*TOTAL CLAIM SUMMARY RESULTS QA - OOP MAX*/														
ods excel options(sheet_name="61.8" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.61_yr&yr_num._indv_tot_clm_stats,unq=mbr_sys_id,
						byvars=pln_a_oop_max_accum sum_indv_cpn_flag pln_a_cpn_ben_plan_prt resp_met,
						fmtvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt sum_indv_cpn_flag,fmtlst=$yes_no_fmt. $yes_no_fmt. cpn_flag_fmt.,
						qa_printvars=paid_date pln_a_indv_oop sum_indv_amt_tot_oop sum_indv_amt_coin sum_indv_amt_copay sum_indv_amt_deductbl); %util_dummy_sheet;	 	

/*DEDUCTIBLE MEETING CONTEST - WHO MEETS FIRST?  INDIVIDUAL OR FAMILY?*/
/*STAGE DEDUCTIBLE MEETING CONTEST BETWEEN INDIVIDUAL AND FAMILY			*/

/*ACTUAL*/
proc sql; create table inp.t&vz.62_yr&yr_num._ded_met_contest as (
	select 	mbr.family_id
				, mbr.mbr_sys_id
				, mbr.resp_met  as indv_resp_met
				, mbr.paid_date as indv_paid_date
				, mbr.clm_nbr		as indv_clm_nbr
				, fam.clm_nbr		as fam_clm_nbr
				, fam.paid_date as fam_paid_date
				, fam.resp_met	as fam_resp_met
	from inp.t&vz.61_yr&yr_num._indv_ded_met mbr 
	inner join inp.t&vz.59_yr&yr_num._fam_ded_met fam
	on mbr.family_id = fam.family_id);
quit;

/*TRUE GHOST*/
proc sql; create table inp.t&vz.62_yr&yr_num._g_ded_met_contest as (
	select 	mbr.family_id
				, mbr.mbr_sys_id
				, mbr.resp_met  as indv_resp_met
				, mbr.paid_date as indv_paid_date
				, mbr.clm_nbr		as indv_clm_nbr
				, fam.clm_nbr		as fam_clm_nbr
				, fam.paid_date as fam_paid_date
				, fam.resp_met	as fam_resp_met
	from inp.t&vz.61_yr&yr_num._indv_g_ded_met mbr 
	inner join inp.t&vz.59_yr&yr_num._fam_g_ded_met fam
	on mbr.family_id = fam.family_id);
quit;

/*POTENTIAL GHOST*/
proc sql; create table inp.t&vz.62_yr&yr_num._p_ded_met_contest as (                                                   
	select 	mbr.family_id                                                                                                
				, mbr.mbr_sys_id                                                                                               
				, mbr.resp_met  as indv_resp_met                                                                               
				, mbr.paid_date as indv_paid_date                                                                              
				, mbr.clm_nbr		as indv_clm_nbr                                                                                
				, fam.clm_nbr		as fam_clm_nbr                                                                                 
				, fam.paid_date as fam_paid_date                                                                               
				, fam.resp_met	as fam_resp_met                                                                                
	from inp.t&vz.61_yr&yr_num._indv_p_ded_met mbr                                                                       
	inner join inp.t&vz.59_yr&yr_num._fam_p_ded_met fam                                                                  
	on mbr.family_id = fam.family_id);                                                                                   
quit;                                                                                                                  

/*DEDUCTIBLE MEETING CONTEST BETWEEN INDIVIDUAL AND FAMILY - NORMAL DEDUCTIBLE, THEN GHOST DEDUCTIBLE*/
%let lp_nbr = 1;
%do %until (&lp_nbr.=4);
		%let a_type 					 = ;
		%let a_indv_oop_ren 	 = ;  
		%let a_indv_count_ren  = ;
		%let a_fam_oop_ren  	 = ;
		%let a_fam_count_ren   = ;
		%let a_misc_ren 			 = ;
		%let a_qa_indv_printme = ;
		%let a_qa_fam_printme	 = ;
	%if &lp_nbr. = 2 %then %do; 
		%let a_type 					 = g_;
		%let a_indv_oop_ren 	 = rename=(&g_sum_indv_oop_vars_rn.	 );   
		%let a_indv_count_ren  = rename=(&g_sum_indv_count_vars_rn.);
		%let a_fam_oop_ren  	 = rename=(&g_sum_fam_oop_vars_rn.	 );
		%let a_fam_count_ren   = rename=(&g_sum_fam_count_vars_rn. );
		%let a_misc_ren 			 = rename=(&g_misc_oop_vars_rn.); 
		%let a_qa_indv_printme = g_sum_indv_amt_manf_cpn;
		%let a_qa_fam_printme	 = g_sum_fam_amt_manf_cpn;		
	%end;
	%if &lp_nbr. = 3 %then %do; 
		%let a_type 					 = p_;
		%let a_indv_oop_ren 	 = rename=(&p_sum_indv_oop_vars_rn.	 );   
		%let a_indv_count_ren  = rename=(&p_sum_indv_count_vars_rn.);
		%let a_fam_oop_ren  	 = rename=(&p_sum_fam_oop_vars_rn.	 );
		%let a_fam_count_ren   = rename=(&p_sum_fam_count_vars_rn. );
		%let a_misc_ren 			 = rename=(&p_misc_oop_vars_rn.); 
		%let a_qa_indv_printme = p_sum_indv_amt_cpn_calc;
		%let a_qa_fam_printme	 = p_sum_fam_amt_cpn_calc;		
	%end;		

	proc sort data=inp.t&vz.58_yr&yr_num._fam_claim_sum; by clm_nbr; run;
	proc sort data=inp.t&vz.59_yr&yr_num._fam_&a_type.ded_met; by clm_nbr; run;	
	proc sort data=inp.t&vz.60_yr&yr_num._indv_claim_sum; by clm_nbr; run;
	proc sort data=inp.t&vz.61_yr&yr_num._indv_&a_type.ded_met; by clm_nbr; run;
	
	/*SCENARIOS COVERED:																											*/
	/*INDIVIDUAL MET, FAMILY NOT MET																	  - 1 0	*/
	/*INDIVIDUAL MET AND FAMILY MET, INDIVIDUAL MET FIRST OR					  - 1 1	*/	
	/*INDIVIDUAL MET AND FAMILY MET ON SAME DAY													- 1 1	*/
	/*INDIVIDUAL NOT MET AND FAMILY NOT MET 														- 0 0	*/	
	/*DATA REPORTED:																													*/
	/*USE INDIVIDUAL CLAIM, TAKE FAMILY SUMMARY DATA FROM THAT SAME CLAIM		 	*/	
	data inp.t&vz.63_yr&yr_num._&a_type.ded_met_contest_imet; 
		length fam_paid_date indv_paid_date 4 clm_nbr 6 &a_type.first_event $2;
		set inp.t&vz.62_yr&yr_num._&a_type.ded_met_contest;
		if indv_resp_met then do; 
			if fam_resp_met = 0 then do; clm_nbr = indv_clm_nbr; &a_type.first_event = 'I'; output; end;
			if fam_resp_met and indv_paid_date <= fam_paid_date then do; clm_nbr = indv_clm_nbr; &a_type.first_event = 'I'; output; end;
			end;
		if indv_resp_met=0 and fam_resp_met=0 then do; clm_nbr = indv_clm_nbr; &a_type.first_event = 'N'; output; end; 	
		keep family_id mbr_sys_id clm_nbr &a_type.first_event;
		format indv_paid_date fam_paid_date mmddyy10.;
	run;
	proc sort data=inp.t&vz.63_yr&yr_num._&a_type.ded_met_contest_imet; by clm_nbr; run;
	ods excel options(sheet_name="63&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
	
	data inp.t&vz.64_yr&yr_num._&a_type.ded_met_contest_imet;
		merge inp.t&vz.63_yr&yr_num._&a_type.ded_met_contest_imet(in=event)
					inp.t&vz.58_yr&yr_num._fam_claim_sum (keep=clm_nbr &sum_fam_oop_vars. 	 	&a_fam_oop_ren.		)
					inp.t&vz.58_yr&yr_num._fam_claim_sum (keep=clm_nbr &sum_fam_count_vars.  &a_fam_count_ren.	)					
					inp.t&vz.60_yr&yr_num._indv_claim_sum(keep=clm_nbr pln_: pln_a_rx_ben_pln_nbr 	&sum_indv_oop_vars. 	&a_indv_oop_ren.)
					inp.t&vz.60_yr&yr_num._indv_claim_sum(keep=clm_nbr &sum_indv_count_vars. &a_indv_count_ren.)			 
					inp.t&vz.61_yr&yr_num._indv_&a_type.ded_met(keep=clm_nbr paid_date resp_: &a_misc_ren.);				
		by clm_nbr; if event;
	run;
	ods excel options(sheet_name="64&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

	/*SCENARIOS COVERED:																												  */
	/*FAMILY MET, INDIVIDUAL NOT MET																			  - 0 1 */
	/*FAMILY MET AND INDIVIDUAL MET, FAMILY MET FIRST 										  - 1 1 */	
	/*DATA REPORTED:																														  */
	/*USE FAMILY CLAIM, TAKE INDIV. SUMMARY DATA FROM NEAREST INDIVIDUAL CLAIM	  */	
	data inp.t&vz.65_yr&yr_num._&a_type.ded_met_contest_fmet;  
		length event_date 4;
		set inp.t&vz.62_yr&yr_num._&a_type.ded_met_contest;
		if fam_resp_met then do; 
			if indv_resp_met = 0 then do; event_date = fam_paid_date; &a_type.first_event = 'F'; output; end;
			if indv_resp_met and fam_paid_date < indv_paid_date then do; event_date = fam_paid_date; &a_type.first_event = 'F'; output; end;
			end;
		keep family_id mbr_sys_id event_date &a_type.first_event fam_clm_nbr;
		format event_date mmddyy10.;
	run;
	proc sort data=inp.t&vz.65_yr&yr_num._&a_type.ded_met_contest_fmet; by family_id mbr_sys_id event_date; run;
	ods excel options(sheet_name="65&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

	proc sql; create table inp.t&vz.66_yr&yr_num._&a_type.ded_met_contest_fmet as 
		(select event.family_id
					,	event.mbr_sys_id
					, event.event_date
					, event.&a_type.first_event
					, event.fam_clm_nbr
					, clms.paid_date
					, clms.clm_nbr as indv_clm_nbr 
	from inp.t&vz.65_yr&yr_num._&a_type.ded_met_contest_fmet 		event 
			 inner join inp.t&vz.60_yr&yr_num._indv_claim_sum clms 
			 	on event.mbr_sys_id = clms.mbr_sys_id); 
	quit;
	ods excel options(sheet_name="66&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

	data inp.t&vz.67_yr&yr_num._&a_type.ded_met_contest_fmet;
		length clm2event 3; 
		set inp.t&vz.66_yr&yr_num._&a_type.ded_met_contest_fmet; 
		clm2event = abs(datdif(paid_date,event_date,'act/act'));
	run;
	ods excel options(sheet_name="67&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;

	proc sort data=inp.t&vz.67_yr&yr_num._&a_type.ded_met_contest_fmet; by mbr_sys_id clm2event; run;
	data inp.t&vz.68_yr&yr_num._&a_type.ded_met_contest_fmet(sortedby=mbr_sys_id); 
		set inp.t&vz.67_yr&yr_num._&a_type.ded_met_contest_fmet; 	
		by mbr_sys_id;
		if first.mbr_sys_id then output;
		keep family_id mbr_sys_id indv_clm_nbr fam_clm_nbr &a_type.first_event;
	run;	
	ods excel options(sheet_name="68&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
	
	proc sort data=inp.t&vz.68_yr&yr_num._&a_type.ded_met_contest_fmet; by indv_clm_nbr; run;
	data inp.t&vz.69_yr&yr_num._&a_type.ded_met_cont_fmet_i;
		merge inp.t&vz.68_yr&yr_num._&a_type.ded_met_contest_fmet				(rename=(indv_clm_nbr=clm_nbr) in=event)
					inp.t&vz.60_yr&yr_num._indv_claim_sum			(keep=clm_nbr &sum_indv_oop_vars. 	&a_indv_oop_ren.	)
					inp.t&vz.60_yr&yr_num._indv_claim_sum			(keep=clm_nbr pln_: pln_a_rx_ben_pln_nbr 	&sum_indv_count_vars. &a_indv_count_ren.);			 
		by clm_nbr; if event;
	run;
	ods excel options(sheet_name="68i&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
	
	proc sort data=inp.t&vz.68_yr&yr_num._&a_type.ded_met_contest_fmet; by fam_clm_nbr; run;
	data inp.t&vz.69_yr&yr_num._&a_type.ded_met_cont_fmet_f;
		merge inp.t&vz.68_yr&yr_num._&a_type.ded_met_contest_fmet				(rename=(fam_clm_nbr=clm_nbr) in=event)
					inp.t&vz.58_yr&yr_num._fam_claim_sum 			(keep=clm_nbr &sum_fam_oop_vars. 		&a_fam_oop_ren.		)
					inp.t&vz.58_yr&yr_num._fam_claim_sum 			(keep=clm_nbr &sum_fam_count_vars. 	&a_fam_count_ren.	)					
					inp.t&vz.59_yr&yr_num._fam_&a_type.ded_met(keep=clm_nbr paid_date resp_: &a_misc_ren.);				
		by clm_nbr; if event;
	run;
	ods excel options(sheet_name="68f&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
	
	proc sort data=inp.t&vz.69_yr&yr_num._&a_type.ded_met_cont_fmet_i; by mbr_sys_id; run;
	proc sort data=inp.t&vz.69_yr&yr_num._&a_type.ded_met_cont_fmet_f; by mbr_sys_id; run;
	data inp.t&vz.69_yr&yr_num._&a_type.ded_met_contest_fmet;
		merge inp.t&vz.69_yr&yr_num._&a_type.ded_met_cont_fmet_i 
					inp.t&vz.69_yr&yr_num._&a_type.ded_met_cont_fmet_f;
		by mbr_sys_id;
	run;
	
	ods excel options(sheet_name="69&a_type." &ex_op.);
	%util_ds_qa(tgt_dsn=_last_,unq=mbr_sys_id,nosum=0,noco=0); %util_dummy_sheet;
	
	/*COHORT DEDUCTIBLE CONTEST RESULS ADS - NORMAL, GHOST*/
	data inp.t&vz.70_yr&yr_num._&a_type.cohort_ads;
		set inp.t&vz.64_yr&yr_num._&a_type.ded_met_contest_imet
				inp.t&vz.69_yr&yr_num._&a_type.ded_met_contest_fmet;
		drop clm_nbr fam_clm_nbr indv_clm_nbr;
	run;	
	proc sort data=inp.t&vz.70_yr&yr_num._&a_type.cohort_ads; by mbr_sys_id; run;

	ods excel options(sheet_name="70&a_type..1" &ex_op.);
		%util_ds_qa(tgt_dsn=inp.t&vz.70_yr&yr_num._&a_type.cohort_ads,unq=mbr_sys_id,nosum=1,
						byvars=&a_type.first_event &a_type.resp_met,
						qa_dsn=inp.t&vz.62_yr&yr_num._&a_type.ded_met_contest); %util_dummy_sheet;

	ods excel options(sheet_name="70&a_type..2" &ex_op.);
		%util_ds_qa(tgt_dsn=inp.t&vz.70_yr&yr_num._&a_type.cohort_ads,unq=mbr_sys_id,nosum=1,
							byvars=&a_type.first_event &a_type.resp_met,
							qa_printvars=pln_a_deductible_accum pln_a_indv_deductible &a_type.sum_indv_amt_deductbl &a_qa_indv_printme pln_a_fam_deductible &a_type.sum_fam_amt_deductbl &a_qa_fam_printme); %util_dummy_sheet;
	
	ods excel options(sheet_name="70&a_type..2" &ex_op.);
		%util_ds_qa(tgt_dsn=inp.t&vz.70_yr&yr_num._&a_type.cohort_ads,unq=mbr_sys_id,nosum=1,
							byvars=&a_type.first_event &a_type.resp_met,
							qa_printvars=pln_a_oop_max_accum pln_a_indv_oop &a_type.sum_indv_amt_tot_oop &a_qa_indv_printme pln_a_fam_oop &a_type.sum_fam_amt_tot_oop &a_qa_fam_printme); %util_dummy_sheet;

	%let lp_nbr = %eval(&lp_nbr.+1);

%end;

/*-----------------------------------------------------------------*/
/*---> FINAL ANNUAL ADS <------------------------------------------*/
/**/
%no_stage:;
data inp.t&vz.71_yr&yr_num._final_ch_ads;
	length tot_has_clms pln_f2s_plan_switcher pln_l_has_left_plan ab_demo_cohort prd_flag_1-prd_flag_8 
				 &pln_l2f_vars. &pln_f2s_vars. aa_mbr_nbr 3 prd_date 4 
				 g_clm_nbr pln_l_clm_nbr 6 pln_a_cpn_ben_plan_prt_gp pln_l_cpn_ben_plan_prt_gp $1 ab_demo_mbr_age_group $12.;	
	merge inp.t&vz.26_yr&yr_num._ch_mbrs							(in=ch)																					/* COHORT	WITH FAMILY STATS 								*/
				inp.t&vz.51_yr&yr_num._ln_of_t	            					 																			/* LENGTH OF THERAPY	 		  								*/
				inp.t&vz.70_yr&yr_num._cohort_ads						(in=clms)  																			/* ACTUAL DEDUCTIBLE CLAIM STATS  					*/		
				inp.t&vz.70_yr&yr_num._g_cohort_ads 				(drop=family_id)																/* TRUE GHOST DEDUCTIBLE CLAIM STATS	  		*/
				inp.t&vz.70_yr&yr_num._p_cohort_ads 				(drop=family_id)																/* POTENTIAL GHOST DEDUCTIBLE CLAIM STATS		*/						
				inp.t&vz.60_yr&yr_num._indv_claim_sum9O 		(rename=(&nino_sum_indv_oop_vars_rn.						/* TOT CLAIM STATS - NINE ONLY							*/	    
																														 &nino_sum_indv_count_vars_rn.) 
																										 drop=clm_nbr pln_: paid_date)                    								
				inp.t&vz.61_yr&yr_num._indv_tot_clm_stats		(rename=(paid_date=tot_paid_date 								/* TOT CLAIM STATS				  								*/	    
																														 &tot_sum_indv_oop_vars_rn. 						
																														 &tot_sum_indv_cnt_vars_rn.) 
																										 drop=clm_nbr resp_: pln_:)	    
				inp.t&vz.17_yr&yr_num._rx_plans_left				(in=lp)			  																	/* LEFT-SIDE RX PLANS	 		  								*/	
				inp.t&vz.39_yr&yr_num._rx_plan_windows			(in=switch);																		/* PLAN SWITCHERS					  								*/
	by mbr_sys_id; 
  array pln_a_vars{*}								&pln_a_vars_nof.;            
  array pln_l_vars{*}								&pln_l_vars_nof.;  
  array pln_fst_vars{*}							&pln_fst_vars_nof.;  
  array pln_snd_vars{*}							&pln_snd_vars_nof.;  
  array pln_l2f_vars{*}							&pln_l2f_vars.;    
  array pln_f2s_vars{*}							&pln_f2s_vars.;    
	array sum_fam_oop_vars{*}   	 	  &sum_fam_oop_vars.;		  	  
  array sum_fam_count_vars{*} 	 	  &sum_fam_count_vars.;	 
  array sum_indv_oop_vars{*} 	 	 	  &sum_indv_oop_vars.;		
  array sum_indv_count_vars{*}  	  &sum_indv_count_vars.;	
  array misc_oop_vars{*}  	  			&misc_oop_vars.;	
	array g_sum_indv_oop_vars{*}   	  &g_sum_fam_oop_vars.;		  	  
  array g_sum_indv_count_vars{*} 	  &g_sum_fam_count_vars.;	 
  array g_sum_fam_oop_vars{*} 	 	  &g_sum_indv_oop_vars.;		
  array g_sum_fam_count_vars{*}  	  &g_sum_indv_count_vars.;	   
  array g_misc_oop_vars{*}  	  		&g_misc_oop_vars.;	
	array gdl_sum_indv_oop_vars{*}    &gdl_sum_fam_oop_vars.;		  	  
  array gdl_sum_indv_count_vars{*}  &gdl_sum_fam_count_vars.;	 
  array gdl_sum_fam_oop_vars{*} 	  &gdl_sum_indv_oop_vars.;		
  array gdl_sum_fam_count_vars{*}   &gdl_sum_indv_count_vars.;
  array gdl_misc_oop_vars{*}  	  	&gdl_misc_oop_vars.;	
	array p_sum_indv_oop_vars{*}   	  &p_sum_fam_oop_vars.;		  	  
  array p_sum_indv_count_vars{*} 	  &p_sum_fam_count_vars.;	 
  array p_sum_fam_oop_vars{*} 	 	  &p_sum_indv_oop_vars.;		
  array p_sum_fam_count_vars{*}  	  &p_sum_indv_count_vars.;	   
  array p_misc_oop_vars{*}  	  		&p_misc_oop_vars.;	
	array pdl_sum_indv_oop_vars{*}    &pdl_sum_fam_oop_vars.;		  	  
  array pdl_sum_indv_count_vars{*}  &pdl_sum_fam_count_vars.;	 
  array pdl_sum_fam_oop_vars{*} 	  &pdl_sum_indv_oop_vars.;		
  array pdl_sum_fam_count_vars{*}   &pdl_sum_indv_count_vars.;
  array pdl_misc_oop_vars{*}  	  	&pdl_misc_oop_vars.;	
  array prd_dates{*} 								prd_idx_date_1-prd_idx_date_8;
  array prd_flags{*} 								prd_flag_1-prd_flag_8;     
	if ch;
	if ch 		then ab_demo_cohort	= 1; 
	if switch then pln_f2s_plan_switcher 	= 1;
	if clms 	then tot_has_clms 			= 1;
	if lp 		then pln_l_has_left_plan 			= 1;
	aa_mbr_nbr+1;
  /*TRUE GHOST DELTAS*/
  do i = 1 to dim(gdl_sum_indv_oop_vars)	; if pln_a_cpn_ben_plan_prt in ('Y') then gdl_sum_indv_oop_vars{i} 	= sum_fam_oop_vars{i}		- g_sum_indv_oop_vars{i}   ; end;	   
  do i = 1 to dim(gdl_sum_indv_count_vars); if pln_a_cpn_ben_plan_prt in ('Y') then gdl_sum_indv_count_vars{i} = sum_fam_count_vars{i}  - g_sum_indv_count_vars{i}; end;	
  do i = 1 to dim(gdl_sum_fam_oop_vars)	  ; if pln_a_cpn_ben_plan_prt in ('Y') then gdl_sum_fam_oop_vars{i} 	 	= sum_indv_oop_vars{i} 	- g_sum_fam_oop_vars{i} 	 ; end;   
  do i = 1 to dim(gdl_sum_fam_count_vars) ; if pln_a_cpn_ben_plan_prt in ('Y') then gdl_sum_fam_count_vars{i}  = sum_indv_count_vars{i} - g_sum_fam_count_vars{i} ; end;	
  do i = 1 to dim(gdl_misc_oop_vars) 			; if pln_a_cpn_ben_plan_prt in ('Y') then gdl_misc_oop_vars{i}  = misc_oop_vars{i} - g_misc_oop_vars{i} ; end;	
  /*POTENTIAL GHOST DELTAS*/
  do i = 1 to dim(pdl_sum_indv_oop_vars)	; if pln_a_cpn_ben_plan_prt in ('Y') then pdl_sum_indv_oop_vars{i} 	= sum_fam_oop_vars{i}		- p_sum_indv_oop_vars{i}   ; end;	   
  do i = 1 to dim(pdl_sum_indv_count_vars); if pln_a_cpn_ben_plan_prt in ('Y') then pdl_sum_indv_count_vars{i} = sum_fam_count_vars{i}  - p_sum_indv_count_vars{i}; end;	
  do i = 1 to dim(pdl_sum_fam_oop_vars)	  ; if pln_a_cpn_ben_plan_prt in ('Y') then pdl_sum_fam_oop_vars{i} 	 	= sum_indv_oop_vars{i} 	- p_sum_fam_oop_vars{i} 	 ; end;   
  do i = 1 to dim(pdl_sum_fam_count_vars) ; if pln_a_cpn_ben_plan_prt in ('Y') then pdl_sum_fam_count_vars{i}  = sum_indv_count_vars{i} - p_sum_fam_count_vars{i} ; end;	
  do i = 1 to dim(pdl_misc_oop_vars) 			; if pln_a_cpn_ben_plan_prt in ('Y') then pdl_misc_oop_vars{i}  = misc_oop_vars{i} - p_misc_oop_vars{i} ; end;	
 	/*INDEX PRODUCT DATE FLAGS, OVERALL COUPON FLAG, CLEANUP FOR MONTH FORMATTING*/
  do i = 1 to dim(prd_dates); if prd_dates{i} = '31Dec2999'd then prd_flags{i} = 0; else prd_flags{i} = 1; 					 end;  
  do i = 1 to dim(prd_dates); if prd_dates{i} = '31Dec2999'd then prd_dates{i} = .; else prd_dates{i} = prd_dates{i}; end;
  prd_date = min(of prd_dates{*});
  /*CLEANUP COUPON PLAN PROTECTION PLAN CHARACTERISTIC PRIOR TO 2018*/
  pln_l_cpn_ben_plan_prt = 'N'; if &cur_st_yrn. < 2018 then pln_a_cpn_ben_plan_prt = 'N'; 
  /*LEFT-SIDE RX PLAN SWITCHING VARS*/
  do i=1 to dim(pln_a_vars); if pln_a_vars{i} ne pln_l_vars{i} then pln_l2f_vars{i}=1; end;
	/*FIRST-TO-SECOND RX PLAN SWITCHING VARS*/
  do i=1 to dim(pln_snd_vars); if pln_snd_vars{i} ne pln_fst_vars{i} then pln_f2s_vars{i}=1; end;
  /*MISC REPORTING VARS AND FORMATTING*/
  pln_a_cpn_ben_plan_prt_gp = put(pln_a_cpn_ben_plan_prt,$yes_no_fmt.);
	pln_l_cpn_ben_plan_prt_gp = put(pln_l_cpn_ben_plan_prt,$yes_no_fmt.);
	ab_demo_mbr_age_group												 = put(ab_demo_mbr_age,age_cht_fmt.);
  array nums _numeric_; do over nums; if nums=. then nums=0; if nums<0 then nums=0; end;
  array chars _character_; do over chars; if missing(chars) then chars='U'; end;  
  format &gdl_sum_fam_oop_vars. &gdl_sum_indv_oop_vars. &pdl_sum_fam_oop_vars. &pdl_sum_indv_oop_vars. &nino_sum_indv_oop_vars. dollar12.2 
  			 &gdl_sum_fam_count_vars. &gdl_sum_indv_count_vars. &pdl_sum_fam_count_vars. &pdl_sum_indv_count_vars. &nino_sum_indv_count_vars. comma4. 
  			 prd_idx_date_1-prd_idx_date_8 prd_date month.
  			 &pln_vars_resp. ded_fmt.;			
	drop ch_mem i;	       
run;

/*ALPHABETICAL ADS, FINAL RENAMING*/
data inp.t&vz.72_yr&yr_num._final_abc_ch_ads; 
	set inp.t&vz.71_yr&yr_num._final_ch_ads(
	rename=(
	&dda_sum_indv_oop_vars_rn. 
  &dda_sum_indv_cnt_vars_rn.
	&dda_sum_fam_oop_vars_rn. 
  &dda_sum_fam_cnt_vars_rn.
  &dda_misc_oop_vars_rn.
	first_event		= dda_deductible_event_type
	g_first_event	= g_deductible_event_type
	p_first_event	= p_deductible_event_type
));
run;
%goto skipqa;
/*INDIVIDUAL POTENTIAL, TRUE GHOST DEDUCTIBLE QA*/ 														
ods excel options(sheet_name="72.1d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_paid_date g_resp_met g_resp_days p_paid_date p_resp_met p_resp_days dda_paid_date dda_resp_met dda_resp_days); %util_dummy_sheet;		
ods excel options(sheet_name="72.1dc1" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_dsn=inp.t&vz.62_yr&yr_num._ded_met_contest); %util_dummy_sheet;		
ods excel options(sheet_name="72.1dc2" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_dsn=inp.t&vz.62_yr&yr_num._g_ded_met_contest); %util_dummy_sheet;	
ods excel options(sheet_name="72.1dc3" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_dsn=inp.t&vz.62_yr&yr_num._p_ded_met_contest); %util_dummy_sheet;													
ods excel options(sheet_name="72.2d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=pln_a_indv_deductible g_sum_indv_amt_deductbl p_sum_indv_amt_deductbl dda_sum_indv_amt_deductbl pdl_sum_indv_amt_deductbl gdl_sum_indv_amt_deductbl); %util_dummy_sheet;	 
ods excel options(sheet_name="72.3d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_indv_amt_cpn_calc p_sum_indv_amt_cpn_calc dda_sum_indv_amt_cpn_calc pdl_sum_indv_amt_cpn_calc gdl_sum_indv_amt_cpn_calc); %util_dummy_sheet;
ods excel options(sheet_name="72.4d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_indv_amt_manf_cpn p_sum_indv_amt_manf_cpn dda_sum_indv_amt_manf_cpn pdl_sum_indv_amt_manf_cpn gdl_sum_indv_amt_manf_cpn); %util_dummy_sheet;
ods excel options(sheet_name="72.5d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_indv_cpn_flag p_sum_indv_cpn_flag dda_sum_indv_cpn_flag pdl_sum_indv_cpn_flag gdl_sum_indv_cpn_flag); %util_dummy_sheet;											 												 

/*INDIVIDUAL POTENTIAL, TRUE GHOST OOP QA*/ 														
ods excel options(sheet_name="72.1o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_paid_date g_resp_met g_resp_days p_paid_date p_resp_met p_resp_days dda_paid_date dda_resp_met dda_resp_days); %util_dummy_sheet;		
ods excel options(sheet_name="72.1dc1" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_dsn=inp.t&vz.62_yr&yr_num._ded_met_contest); %util_dummy_sheet;	
ods excel options(sheet_name="72.1dc2" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_dsn=inp.t&vz.62_yr&yr_num._g_ded_met_contest); %util_dummy_sheet;	
ods excel options(sheet_name="72.1dc3" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_dsn=inp.t&vz.62_yr&yr_num._p_ded_met_contest); %util_dummy_sheet;								
ods excel options(sheet_name="72.2o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=pln_a_indv_oop g_sum_indv_amt_tot_oop p_sum_indv_amt_tot_oop dda_sum_indv_amt_tot_oop pdl_sum_indv_amt_tot_oop gdl_sum_indv_amt_tot_oop); %util_dummy_sheet;	 
ods excel options(sheet_name="72.3o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_indv_amt_cpn_calc p_sum_indv_amt_cpn_calc dda_sum_indv_amt_cpn_calc pdl_sum_indv_amt_cpn_calc gdl_sum_indv_amt_cpn_calc); %util_dummy_sheet;
ods excel options(sheet_name="72.4o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_indv_amt_manf_cpn p_sum_indv_amt_manf_cpn dda_sum_indv_amt_manf_cpn pdl_sum_indv_amt_manf_cpn gdl_sum_indv_amt_manf_cpn); %util_dummy_sheet;
ods excel options(sheet_name="72.5o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_indv_cpn_flag p_sum_indv_cpn_flag dda_sum_indv_cpn_flag pdl_sum_indv_cpn_flag gdl_sum_indv_cpn_flag); %util_dummy_sheet;			

/*FAMILY POTENTIAL, TRUE GHOST DEDUCTIBLE QA*/ 														
ods excel options(sheet_name="72.1d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_paid_date g_resp_met g_resp_days p_paid_date p_resp_met p_resp_days dda_paid_date dda_resp_met dda_resp_days); %util_dummy_sheet;		
ods excel options(sheet_name="72.2d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=pln_a_fam_deductible g_sum_fam_amt_deductbl p_sum_fam_amt_deductbl dda_sum_fam_amt_deductbl pdl_sum_fam_amt_deductbl gdl_sum_fam_amt_deductbl); %util_dummy_sheet;	 
ods excel options(sheet_name="72.3d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_fam_amt_cpn_calc p_sum_fam_amt_cpn_calc dda_sum_fam_amt_cpn_calc pdl_sum_fam_amt_cpn_calc gdl_sum_fam_amt_cpn_calc); %util_dummy_sheet;
ods excel options(sheet_name="72.4d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_fam_amt_manf_cpn p_sum_fam_amt_manf_cpn dda_sum_fam_amt_manf_cpn pdl_sum_fam_amt_manf_cpn gdl_sum_fam_amt_manf_cpn); %util_dummy_sheet;
ods excel options(sheet_name="72.5d" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_deductible_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_deductible_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_fam_cpn_flag p_sum_fam_cpn_flag dda_sum_fam_cpn_flag pdl_sum_fam_cpn_flag gdl_sum_fam_cpn_flag); %util_dummy_sheet;											 												 

/*FAMILY POTENTIAL, TRUE GHOST OOP QA*/ 														
ods excel options(sheet_name="72.1o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_paid_date g_resp_met g_resp_days p_paid_date p_resp_met p_resp_days dda_paid_date dda_resp_met dda_resp_days); %util_dummy_sheet;		
ods excel options(sheet_name="72.2o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=pln_a_fam_oop g_sum_fam_amt_tot_oop p_sum_fam_amt_tot_oop dda_sum_fam_amt_tot_oop pdl_sum_fam_amt_tot_oop gdl_sum_fam_amt_tot_oop); %util_dummy_sheet;	 
ods excel options(sheet_name="72.3o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_fam_amt_cpn_calc p_sum_fam_amt_cpn_calc dda_sum_fam_amt_cpn_calc pdl_sum_fam_amt_cpn_calc gdl_sum_fam_amt_cpn_calc); %util_dummy_sheet;
ods excel options(sheet_name="72.4o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_fam_amt_manf_cpn p_sum_fam_amt_manf_cpn dda_sum_fam_amt_manf_cpn pdl_sum_fam_amt_manf_cpn gdl_sum_fam_amt_manf_cpn); %util_dummy_sheet;
ods excel options(sheet_name="72.5o" &ex_op.);
	%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=family_id,nosum=1,                                         
						byvars=pln_a_oop_max_accum pln_a_cpn_ben_plan_prt_gp p_resp_met g_resp_met dda_resp_met,
						fmtvars=pln_a_oop_max_accum,fmtlst=$yes_no_fmt.,
						qa_printvars=g_sum_fam_cpn_flag p_sum_fam_cpn_flag dda_sum_fam_cpn_flag pdl_sum_fam_cpn_flag gdl_sum_fam_cpn_flag); %util_dummy_sheet;		

/*PLAN SWITCHING QA*/
ods excel options(sheet_name="72.22" &ex_op.);
%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,byvars=&pln_f2s_vars.,bylp=1,qa_dsn=inp.t&vz.39_yr&yr_num._rx_plan_windows); %util_dummy_sheet;			 		
ods excel options(sheet_name="72.24" &ex_op.);
%util_ds_qa(tgt_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads,unq=mbr_sys_id,nosum=1,byvars=&pln_l2f_vars.,bylp=1,qa_dsn=inp.t&vz.72_yr&yr_num._final_abc_ch_ads(keep=mbr_sys_id pln_l_: pln_a_:)); %util_dummy_sheet;			 		
%skipqa:;
proc contents data=inp.t&vz.72_yr&yr_num._final_abc_ch_ads out=t&vz._alpha(keep=name) noprint;
run;

data _null_;
	length vars1 vars2 vars3 vars4 $32767.;
  set t&vz._alpha end=last;
  retain vars1 vars2 vars3 vars4;
  i+1;
  call symput('var'||trim(left(put(i,8.))),trim(name));
	if find(name,'_99')>0 then do;	
		vars1=trim(vars1)!!' '!!name; 
		vars2=trim(vars2)!!' '!!tranwrd(name,'_99',''); 
		do j = 1 to 8; 
		vars3=trim(vars3)!!' '!!trim(tranwrd(name,'_99','_'))!!trim(left(put(j,8.))); end;
	end;
	if find(name,'amt_tot_oop')>0 then do;	
		vars4=trim(vars4)!!' '!!name; 
	end;
  if last then do; 
  	call symput('total',trim(left(put(i,8.))));
  	call symput('vars_99',vars1);
  	call symput('vars_tot',vars2);
  	call symput('vars_1toprdnum',vars3); 
  	call symput('vars_amt_tot_oop',vars4);
  	end;  	
run;

	data t&vz.73_yr&yr_num._final_abc_ch_ads; 
		set inp.t&vz.72_yr&yr_num._final_abc_ch_ads(rename=(&ded_mask_vars_rn.));
		length &ded_mask_vars. $15.;
		array ded_mask_vars{*} &ded_mask_vars.; 
		array raw_ded_mask_vars{*} &raw_ded_mask_vars.;
		do i = 1 to dim(ded_mask_vars); ded_mask_vars{i}=put(raw_ded_mask_vars{i},ded_fmt.); end;
		drop i;
	run;		 

  data inp.t&vz.73_yr&yr_num._final_abc_ch_ads;
    retain %do j=1 %to &total;
             &&var&j
	   %end;;
    set t&vz.73_yr&yr_num._final_abc_ch_ads;    
  run;
ods excel options(sheet_name="73" &ex_op.);
*%util_ds_qa(tgt_dsn=_last_,unq=aa_mbr_nbr,nosum=0,noco=0);			 		
  
  				    				    
/*-----------------------------------------------------------------*/
/*---> QA REPORTING OUTPUT <---------------------------------------*/
/**/

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

/*-----------------------------------------------------------------*/
/*---> YOY LOOP <--------------------------------------------------*/
/**/

%let yr_num = %eval(&yr_num+1); %end;

/*-----------------------------------------------------------------*/
/*---> INITIALIZE EXCEL FOR QA OUTPUTS <---------------------------*/
/**/ 
%let rp_hcp = "&om_data./05_out_rep/Janssen_&vz._yr1and2_ADS_OOP_QA_Reporting.xls";
%let ex_op = sheet_interval='none' embedded_titles='yes';
* GRAPHICS ON;
ods listing close;
ods listing gpath="&om_data./05_out_rep/";
ods output; ods graphics on;
ods excel file=&rp_hcp. style=XL&vz.sansPrinter; 

/*-----------------------------------------------------------------*/
/*---> FINAL, COMBINED ADS <---------------------------------------*/
/**/

data inp.t&vz.75_final_abc_ch_ads; 
	length aa_analysis_year 3;
	set inp.t&vz.73_yr1_final_abc_ch_ads(in=yr1) 
			inp.t&vz.73_yr2_final_abc_ch_ads(in=yr2);
	array vars_99{*}   							&vars_99;
	array vars_tot{*}  							&vars_tot;
	array vars_1toprdnum{*} 				&vars_1toprdnum;
	retain j varnum var_1toprdnum; 
	/*CREATE _99, CORRECT TOTAL VARS AS NEEDED, CPN VARS JANSSEN ONLY*/
	varnum=0;
	do i = 1 to dim(vars_99);
		var_1toprdnum=.; 
		do j = 1+(varnum*8) to &prdnum+(varnum*8); var_1toprdnum = sum(var_1toprdnum,vars_1toprdnum{j}); end;
		if vars_tot{i} < var_1toprdnum then vars_tot{i} = var_1toprdnum;  
		vars_99{i}=vars_tot{i}-var_1toprdnum;
		if find(vname(vars_99{i}),'cpn') then do; vars_99{i}=0; vars_tot{i} = var_1toprdnum; end;  		
		varnum+1;
	end;
	if yr1 then aa_analysis_year = 2017; else aa_analysis_year = 2018;
	drop j varnum var_1toprdnum i;
run;
ods excel options(sheet_name="75" &ex_op.);
*%util_ds_qa(tgt_dsn=_last_,unq=aa_mbr_nbr,nosum=0,noco=0);			 		
data rep.final_janssen_oop_ads_&cur_end_yrmo.; 
	set inp.t&vz.75_final_abc_ch_ads;
	drop mbr_sys_id family_id pln_a_rx_ben_pln_nbr ab_demo_mbr_age g_: p_: gdl_: pdl_: pln_fst_: 
			 tot_sum_indv_p_: dda_sum_indv_p_: dda_sum_fam_p_: dda_sum_fam_amt_cpn_calc: dda_sum_indv_amt_cpn_calc: 
			 tot_sum_indv_amt_cpn_calc: pln_a_business_segment pln_a_business_segment pln_a_business_segment pln_a_business_segment 
			 pln_f2s_business_segment pln_l2f_business_segment pln_l_business_segment pln_snd_business_segment pln_l_clm_nbr pln_l_rx_ben_pln_nbr 
			 pln_a_cpn_ben_plan_prt_gp pln_l_cpn_ben_plan_prt_gp pln_snd_rx_ben_pln_nbr &raw_ded_mask_vars. ab_demo_mbr_enrollment_min_date ab_demo_mbr_enrollment_max_date
			 prd_idx_left_enr_1-prd_idx_left_enr_&prdnum. &nino_sum_indv_oop_vars. &nino_sum_indv_count_vars. &vars_amt_tot_oop.;
run;
ods excel options(sheet_name="final_janssen_oop_ads" &ex_op.);
*%util_ds_qa(tgt_dsn=_last_,unq=aa_mbr_nbr,nosum=0,noco=0);			 		

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
%if &no_rep %then %goto no_rep;

/*-----------------------------------------------------------------*/
/*---> INITIALIZE EXCEL FOR REPORTING OUTPUTS <--------------------*/
/**/

/*PRODUCT GROUPINGS AND ALL DATA GROUP LOOPS*/
%do r = 1 %to 2;
%if &r = 1 %then %do; 	
	%let prd_pfx = Oncology; %let all_products = Darzalex Erleada Zytiga; %let prd_nbrs = 1 2 8; %let prdnum_tmp = 3; %let dx_case = tot_mbr_earliest_o_dx; %let ther_vars = prd_therapy_length_1 prd_therapy_length_2 prd_therapy_length_8;
	data t&vz._rpt_data_pg(sortedby=mbr_sys_id); set inp.t&vz.75_final_abc_ch_ads(where=(sum(prd_flag_1,prd_flag_2,prd_flag_8)>0)); run;
%end;
%if &r = 2 %then %do; 
	%let prd_pfx = Immunology; %let all_products = Remicade Simponi_Aria Simponi Stelara Tremfya;  %let prd_nbrs = 3 4 5 6 7;  %let prdnum_tmp = 5; %let dx_case = tot_mbr_earliest_i_dx; %let ther_vars = prd_therapy_length_3-prd_therapy_length_7;
	data t&vz._rpt_data_pg(sortedby=mbr_sys_id); set inp.t&vz.75_final_abc_ch_ads(where=(sum(prd_flag_3,prd_flag_4,prd_flag_5,prd_flag_6,prd_flag_7)>0)); run;	
%end;
%if &r = 3 %then %do; 
	%let prd_pfx =; %let all_products = Darzalex Erleada Remicade Simponi_Aria Simponi Stelara Tremfya Zytiga;  %let prd_nbrs = 1 2 3 4 5 6 7 8;  %let prdnum_tmp = 8; %let dx_case = tot_mbr_earliest_dx; %let ther_vars = prd_therapy_length_1-prd_therapy_length_8;
	data t&vz._rpt_data_pg(sortedby=mbr_sys_id); set inp.t&vz.75_final_abc_ch_ads; run;	
%end;
                                                                                                                 
%let rp_hcp = "&om_data./05_out_rep/Janssen_OOP_Slides_Reporting_&prd_pfx._20190123.xls";                          
%let ex_op = sheet_interval='none' embedded_titles='yes';                                                        
* GRAPHICS ON;                                                                                                   
ods listing close;                                                                                               
ods listing gpath="&om_data./05_out_rep/";                                                                       
ods output; ods graphics on;                                                                                     
ods excel file=&rp_hcp. style=XL&vz.sansPrinter;                                                                 

/*-----------------------------------------------------------------*/
/*---> SLIDES REPORTING  <-----------------------------------------*/
/**/
%if &rpt_go %then %goto rpt_go; 
/*9*/
ods excel options(sheet_name="9" &ex_op.); 
	title "&prd_pfx. Waterfall";
		proc sql; create table t&vz._rpt as ( 
		/*ALL CLAIMS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i);  
			select aa_analysis_year
					 , "All Funding Arrangements" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "01_All Claims" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and prd_flag_&prd_nbr group by 1			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "All Funding Arrangements" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "01_All Claims" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018  group by 1
		  union all
 		/*ALL CLAIMS, LESS SWITCHERS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "All Funding ArrangementS" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accums
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "02_All Claims - No Plan Switchers" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and prd_flag_&prd_nbr group by 1			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "All Funding ArrangementS" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "02_All Claims - No Plan Switchers" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0  group by 1
			union all
 		/*KNOWN FUNDING ARRANGEMENT*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accums
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "03_Known Funding Arrangement" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI') and prd_flag_&prd_nbr group by 1,2			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "03_Known Funding Arrangement" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI')  group by 1,2
			union all
 		/*PLANS WITH OOP MAX, WITH AND WITHOUT DEDUCTIBLES*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "04_Healthplans with OOP Max, With and Without Deductibles" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI') and pln_a_oop_max_accum in ('Y') and prd_flag_&prd_nbr group by 1,2,3			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "04_Healthplans with OOP Max, With and Without Deductibles" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI') and pln_a_oop_max_accum in ('Y')  group by 1,2,3
			union all
 		/*KNOWN OOP ACCUMULATOR PROGRAM STATUS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "05_Known OOP Accumulator Program Type" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr group by 1,2,3,4			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "05_Known OOP Accumulator Program Type" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018.  group by 1,2,3,4		  
		); 
		quit;
		proc print data=t&vz._rpt noobs; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet;

/*9*/
ods excel options(sheet_name="9a" &ex_op.); 
	title "&prd_pfx. Member Counts by Product and Plan Type";
		proc sql; create table t&vz._rpt as ( 
 		/*KNOWN OOP ACCUMULATOR PROGRAM STATUS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr group by 1,2,3,4			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018.  group by 1,2,3,4		  
		); 
		quit;
		proc print data=t&vz._rpt noobs; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet;

/*10*/
ods excel options(sheet_name="10" &ex_op.); 
	title "&prd_pfx. Waterfall";
		proc sql; create table t&vz._rpt as ( 
		/*ALL CLAIMS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i);  
			select aa_analysis_year
					 , "All Funding Arrangements" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "01_All Claims" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and prd_flag_&prd_nbr group by 1			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "All Funding Arrangements" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "01_All Claims" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018  group by 1
		  union all
 		/*ALL CLAIMS, LESS SWITCHERS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "All Funding ArrangementS" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accums
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "02_All Claims - No Plan Switchers" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and prd_flag_&prd_nbr group by 1			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "All Funding ArrangementS" as pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "02_All Claims - No Plan Switchers" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0  group by 1
			union all
 		/*KNOWN FUNDING ARRANGEMENT*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accums
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "03_Known Funding Arrangement" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI') and prd_flag_&prd_nbr group by 1,2			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , "All Plan Types" as pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "03_Known Funding Arrangement" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI')  group by 1,2
			union all
 		/*PLANS WITH OOP MAX, WITH AND WITHOUT DEDUCTIBLES*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "04_Healthplans with OOP Max, With and Without Deductibles" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI') and pln_a_oop_max_accum in ('Y') and prd_flag_&prd_nbr group by 1,2,3			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , "All OOP Accumulator Program Types" as pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "04_Healthplans with OOP Max, With and Without Deductibles" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg where aa_analysis_year = 2018 and tot_has_clms and pln_f2s_plan_switcher=0 and pln_a_funding_arrangment in ('ASO','FI') and pln_a_oop_max_accum in ('Y')  group by 1,2,3
			union all
 		/*KNOWN OOP ACCUMULATOR PROGRAM STATUS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "05_Known OOP Accumulator Program Type" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr group by 1,2,3,4			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "All Prior Year Affiliate Plan" as pln_l_has_left_plan
					 , "05_Known OOP Accumulator Program Type" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018.  group by 1,2,3,4		  
			union all
 		/*KNOWN LEFT-SIDE PLAN STATUS*/
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , case when pln_l_has_left_plan = 1 then 'Y' else 'N' end as pln_l_has_left_plan
					 , "06_Known Prior Year Affiliate Plan" as waterfall_level
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr group by 1,2,3,4,5			
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , case when pln_l_has_left_plan = 1 then 'Y' else 'N' end as pln_l_has_left_plan
					 , "06_Known Prior Year Affiliate Plan" as waterfall_level
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018.  group by 1,2,3,4,5
		); 
		quit;
		proc print data=t&vz._rpt noobs; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet;

/*18*/
ods excel options(sheet_name="18" &ex_op.); 
	title "&prd_pfx Health Plan Distribution";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , put(pln_a_deductible_accum,$yes_no_fmt.) as pln_a_deductible_accum
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr group by 1,2,3	
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , put(pln_a_deductible_accum,$yes_no_fmt.) as pln_a_deductible_accum
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018.  group by 1,2,3						
		); 
		quit;
		proc sort data=_last_; by pln_a_funding_arrangment product pln_a_deductible_accum; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_funding_arrangment product pln_a_deductible_accum; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run;
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet;

/*19*/
ods excel options(sheet_name="19" &ex_op.); 
	title "&prd_pfx Distribution of OOP Accumulator by Insurance Plan";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , put(pln_a_deductible_accum,$yes_no_fmt.) as pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_funding_arrangment
					 , put(pln_a_deductible_accum,$yes_no_fmt.) as pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018.  group by 1,2,3,4						
		); 
		quit;
		proc sort data=_last_; by pln_a_funding_arrangment pln_a_deductible_accum product pln_a_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_funding_arrangment pln_a_deductible_accum product pln_a_cpn_ben_plan_prt; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run;
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*19All_1*/
ods excel options(sheet_name="19All_1" &ex_op.); 
	title "&prd_pfx Health Plan Distribution";
		proc sql; create table t&vz._rpt as ( 
			select "2018" as aa_analysis_year
					 , pln_l_funding_arrangment
					 , put(pln_l_deductible_accum,$yes_no_fmt.) as pln_l_deductible_accum
					 , "All Commercial" as product
					 , count(distinct mbr_sys_id) as members
			from inp.t&vz.17a_yr2_rx_plans_left where pln_l_oop_max_accum in ('Y') and pln_l_funding_arrangment in ('ASO','FI') and pln_l_deductible_accum in ('Y','N') and pln_l_cpn_ben_plan_prt in ('Y','N') group by 1,2,3						
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
	title "&prd_pfx Distribution of OOP Accumulator by Insurance Plan";
		proc sql; create table t&vz._rpt as ( 
			select "2018" as aa_analysis_year
					 , pln_l_funding_arrangment
					 , put(pln_l_deductible_accum,$yes_no_fmt.) as pln_l_deductible_accum
					 , pln_l_cpn_ben_plan_prt
					 , "All Commercial" as product
					 , count(distinct mbr_sys_id) as members
			from inp.t&vz.17a_yr2_rx_plans_left where pln_l_oop_max_accum in ('Y') and pln_l_funding_arrangment in ('ASO','FI') and pln_l_deductible_accum in ('Y','N') and pln_l_cpn_ben_plan_prt in ('Y','N') group by 1,2,3,4						
		); 
		quit;
		proc sort data=_last_; by pln_l_funding_arrangment pln_l_deductible_accum pln_l_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_l_funding_arrangment pln_l_deductible_accum pln_l_cpn_ben_plan_prt; retain grp_nbr; if first.pln_l_deductible_accum then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma18.; run;
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*20*/
ods excel options(sheet_name="20" &ex_op.); 
	title "&prd_pfx Individual Deductible Level Distribution";
	title2 "Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_deductible,ded_fmt_tmp.) as individual_deductible
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_deductible,ded_fmt_tmp.) as individual_deductible
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. group by 1,2,3,4				
		); 
		quit;
		proc sort data=_last_; by pln_a_cpn_ben_plan_prt product individual_deductible; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_cpn_ben_plan_prt product individual_deductible; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 

	title "&prd_pfx Individual Deductible Level Means";
	title2 "Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
					 , put(mean(raw_pln_a_indv_deductible),dollar12.) as mean_individual_deductible
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
					 , put(mean(raw_pln_a_indv_deductible),dollar12.) as mean_individual_deductible
			from t&vz._rpt_data_pg &all_whr_2018. &ded. group by 1,2,3				
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 			
		proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*21*/
ods excel options(sheet_name="21" &ex_op.); 
	title "&prd_pfx Individual Out of Pocket Maximum Distribution";
	title2 "No Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_oop,ded_fmt_tmp.) as individual_oop_max
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_oop,ded_fmt_tmp.) as individual_oop_max
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &oop. group by 1,2,3,4						
		); 
		quit;
		proc sort data=_last_; by pln_a_cpn_ben_plan_prt product individual_oop_max; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_cpn_ben_plan_prt product individual_oop_max; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 

	title "&prd_pfx Individual Out of Pocket Maximum Means";
	title2 "No Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
					 , put(mean(raw_pln_a_indv_oop),dollar12.) as mean_individual_oop_max
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
					 , put(mean(raw_pln_a_indv_oop),dollar12.) as mean_individual_oop_max
			from t&vz._rpt_data_pg &all_whr_2018. &oop. group by 1,2,3						
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
		proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*22*/
ods excel options(sheet_name="22" &ex_op.); 
	title "&prd_pfx Distribution of OOP Accumulator Patients";
	title2 "Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and prd_flag_&prd_nbr group by 1,2,3,4		
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. group by 1,2,3,4
		); 
		quit;
		proc sort data=_last_; by pln_a_deductible_accum product pln_a_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_deductible_accum product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run;

	title "&prd_pfx Distribution of Coupon Usage";
	title2 "Deductible Plans with OOP Accumulator";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , case when tot_sum_indv_cpn_flag_&prd_nbr>0 then 1 else 0 end as tot_sum_indv_cpn_flag
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and pln_a_cpn_ben_plan_prt in ('Y') and prd_flag_&prd_nbr group by 1,2,3,4		
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , case when tot_sum_indv_cpn_flag>0 then 1 else 0 end as tot_sum_indv_cpn_flag
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and pln_a_cpn_ben_plan_prt in ('Y') group by 1,2,3,4
		); 
		quit;
		proc sort data=_last_; by pln_a_deductible_accum product pln_a_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_deductible_accum product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run;

	title "&prd_pfx Distribution of Coupon Usage";
	title2 "Deductible Plans without OOP Accumulator";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , case when tot_sum_indv_cpn_flag_&prd_nbr>0 then 1 else 0 end as tot_sum_indv_cpn_flag
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and pln_a_cpn_ben_plan_prt in ('N') and prd_flag_&prd_nbr group by 1,2,3,4		
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , pln_a_deductible_accum
					 , pln_a_cpn_ben_plan_prt
					 , case when tot_sum_indv_cpn_flag>0 then 1 else 0 end as tot_sum_indv_cpn_flag
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and pln_a_cpn_ben_plan_prt in ('N') group by 1,2,3,4
		); 
		quit;
		proc sort data=_last_; by pln_a_deductible_accum product pln_a_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_deductible_accum product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run;

proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*24*/ 
%let mbr_groups = Y N;
ods excel options(sheet_name="24" &ex_op.); 
	title "&prd_pfx Deductible Fulfillment Status";
	title2 "Deductible Plans";
	proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_Y outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('Y') &ded.  ; run;
	proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_N outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('N') &ded.  ; run;
	proc sql; create table t&vz._rpt_a as (
		%do i = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&i); 
			select dda_resp_met
					 , put(count,comma15.) as members
					 , put(cum_freq,comma15.) as cum_mbrs
					 , put(percent/100,percent9.1) as percent
					 , put(cum_pct/100,percent9.1) as cum_pct
					 , "&mbr_group." as oop_accum_program 
					 , "All &prd_pfx Products" as product
			from t&vz._lilt_&mbr_group.
		 %if &i ne 2 %then %str(union all);
		%end; 
		); 
	quit;	
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_Y outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('Y') &ded. and prd_flag_&prd_nbr; run;
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_N outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('N') &ded. and prd_flag_&prd_nbr; run;
		proc sql; create table t&vz._rpt_a&i as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;				 
	data t&vz._rpt; set t&vz._rpt_a %do i = 1 %to &prdnum_tmp.; t&vz._rpt_a&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;
	proc datasets nolist; delete t&vz._rpt; run; 

	title2 "No-Deductible Plans";
	proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_Y outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('Y') &oop.  ; run;
	proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_N outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('N') &oop.  ; run;
	proc sql; create table t&vz._rpt_a as (
		%do i = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&i); 
			select dda_resp_met
					 , put(count,comma15.) as members
					 , put(cum_freq,comma15.) as cum_mbrs
					 , put(percent/100,percent9.1) as percent
					 , put(cum_pct/100,percent9.1) as cum_pct
					 , "&mbr_group." as oop_accum_program 
					 , "All &prd_pfx Products" as product
			from t&vz._lilt_&mbr_group.
		 %if &i ne 2 %then %str(union all);
		%end; 
		); 
	quit;	
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_Y outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('Y') &oop. and prd_flag_&prd_nbr; run;
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_N outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('N') &oop. and prd_flag_&prd_nbr; run;
		proc sql; create table t&vz._rpt_a&i as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;				 
	data t&vz._rpt; set t&vz._rpt_a %do i = 1 %to &prdnum_tmp.; t&vz._rpt_a&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;
	proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*25*/
%let mbr_groups = Y N;
ods excel options(sheet_name="25" &ex_op.); 
	title "&prd_pfx Deductible Fulfillment Status";
	title2 "Deductible Plans";
	title3 "Members Not Meeting 2018 Deductible - 2017 Deductible Status (thru Sept)";	
	title4 "Continuing Members";
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_Y outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('Y') &ded. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_N outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('N') &ded. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc sql; create table t&vz._rpt_a&i as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;				 
	data t&vz._rpt; set %do i = 1 %to &prdnum_tmp.; t&vz._rpt_a&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;

	proc sort data=t&vz._rpt_data_pg; by mbr_sys_id aa_analysis_year; run;
	data t&vz._rpt_data_pg_yoy; length dda_resp_met_yoy 3; retain dda_resp_met_yoy; 
		set t&vz._rpt_data_pg; by mbr_sys_id; 
		if first.mbr_sys_id then dda_resp_met_yoy=0;
		if first.mbr_sys_id and dda_resp_met and dda_resp_month<=9 then dda_resp_met_yoy=1;
	run;		
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') and dda_resp_met=0 &ded. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') and dda_resp_met=0 &ded. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc sql; create table t&vz._rpt_b&i. as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met_yoy
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;		
	data t&vz._rpt; set %do i = 1 %to &prdnum_tmp.; t&vz._rpt_b&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;

	title2 "No-Deductible Plans";
	title3 "Members Not Meeting 2018 OOP Max - 2017 OOP Max Status (thru Sept)";	
	title4 "Continuing Members";
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_Y outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('Y') &oop. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc freq data=t&vz._rpt_data_pg order=formatted noprint; tables dda_resp_met / out=t&vz._lilt_N outcum; &all_whr_2018.  and pln_a_cpn_ben_plan_prt in ('N') &oop. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc sql; create table t&vz._rpt_a&i as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;				 
	data t&vz._rpt; set %do i = 1 %to &prdnum_tmp.; t&vz._rpt_a&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;

	proc sort data=t&vz._rpt_data_pg; by mbr_sys_id aa_analysis_year; run;
	data t&vz._rpt_data_pg_yoy; length dda_resp_met_yoy 3; retain dda_resp_met_yoy; 
		set t&vz._rpt_data_pg; by mbr_sys_id; 
		if first.mbr_sys_id then dda_resp_met_yoy=0;
		if first.mbr_sys_id and dda_resp_met and dda_resp_month<=9 then dda_resp_met_yoy=1;
	run;		
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') and dda_resp_met=0 &oop. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') and dda_resp_met=0 &oop. and prd_flag_&prd_nbr and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0; run;
		proc sql; create table t&vz._rpt_b&i. as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met_yoy
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;		
	data t&vz._rpt; set %do i = 1 %to &prdnum_tmp.; t&vz._rpt_b&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;
	proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*26*/
ods excel options(sheet_name="26" &ex_op.); 
	title "&prd_pfx Individual Deductible Level Distribution";
	title2 "Deductible Plans. Meeting, Not Meeting Deductible";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "Members Meeting Deductible" as deductible_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_deductible,ded_fmt_tmp.) as individual_deductible
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. and dda_resp_met group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "Members Meeting Deductible" as deductible_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_deductible,ded_fmt_tmp.) as individual_deductible
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and dda_resp_met group by 1,2,3,4				
		union all	
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "Members Not Meeting Deductible" as deductible_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_deductible,ded_fmt_tmp.) as individual_deductible
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. and dda_resp_met=0 group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "Members Not Meeting Deductible" as deductible_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_deductible,ded_fmt_tmp.) as individual_deductible
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded. and dda_resp_met=0 group by 1,2,3,4					
		); 
		quit;
		proc sort data=_last_; by deductible_status pln_a_cpn_ben_plan_prt product individual_deductible; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by deductible_status pln_a_cpn_ben_plan_prt product individual_deductible; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*27*/
ods excel options(sheet_name="27" &ex_op.); 
	title "&prd_pfx Average Number of Days to Deductible Fulfillment";
	title2 "Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(dda_resp_days),comma12.) as sum_dda_resp_days
					 , put(mean(dda_resp_days),comma4.) as mean_dda_resp_days
			from t&vz._rpt_data_pg &all_whr_2018.  and prd_flag_&prd_nbr &ded. group by 1,2,3
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(dda_resp_days),comma12.) as sum_dda_resp_days
					 , put(mean(dda_resp_days),comma4.) as mean_dda_resp_days
			from t&vz._rpt_data_pg &all_whr_2018.   &ded. group by 1,2,3						
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*28to30*/ 
data t&vz._rpt_data_pg_df; set t&vz._rpt_data_pg; if aa_analysis_year = 2018 and dda_resp_month > 9 then dda_resp_month = 9; if dda_resp_met = 0 then dda_resp_month = 99; run; 
%let mbr_groups = Y N;
ods excel options(sheet_name="28to30" &ex_op.); 
	title "&prd_pfx Month of Deductible Fulfillment";
	title2 "Deductible Plans";
	proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') &ded. ; run;
	proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') &ded. ; run;
	proc sql; create table t&vz._rpt_a as (
		%do i = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&i); 
			select dda_resp_month
					 , put(count,comma15.) as members
					 , put(cum_freq,comma15.) as cum_mbrs
					 , put(percent/100,percent9.1) as percent
					 , put(cum_pct/100,percent9.1) as cum_pct
					 , "&mbr_group." as oop_accum_program 
					 , "All &prd_pfx Products" as product
			from t&vz._lilt_&mbr_group.
		 %if &i ne 2 %then %str(union all);
		%end; 
		); 
	quit;
		
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') &ded. and prd_flag_&prd_nbr ; run;
		proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') &ded. and prd_flag_&prd_nbr ; run;
		proc sql; create table t&vz._rpt_&i as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_month
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;				 
	data t&vz._rpt; set t&vz._rpt_a %do i = 1 %to &prdnum_tmp.; t&vz._rpt_&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;

proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*32*/
ods excel options(sheet_name="32" &ex_op.); 
	title "&prd_pfx Total Number of Prescriptions";
	title2 "YoY thru September";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "Deductible Plans" as plan_type
					 , "&prd_nm" as product
				 	 , pln_a_cpn_ben_plan_prt
					 , sum(ab_demo_cohort) as members					
					 , sum(nino_sum_indv_clm_flag_&prd_nbr) as sum_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr. and prd_flag_&prd_nbr &ded. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "Deductible Plans" as plan_type
					 , "All &prd_pfx Products" as product
				 	 , pln_a_cpn_ben_plan_prt
					 , sum(ab_demo_cohort) as members					
					 , sum(nino_sum_indv_prd_clm_flag) as sum_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr. &ded.  group by 1,2,3,4			
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "No Deductible Plans" as plan_type
					 , "&prd_nm" as product
				 	 , pln_a_cpn_ben_plan_prt
					 , sum(ab_demo_cohort) as members					
					 , sum(nino_sum_indv_clm_flag_&prd_nbr) as sum_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr. and prd_flag_&prd_nbr &oop. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "No Deductible Plans" as plan_type
					 , "All &prd_pfx Products" as product
				 	 , pln_a_cpn_ben_plan_prt
					 , sum(ab_demo_cohort) as members					
					 , sum(nino_sum_indv_prd_clm_flag) as sum_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr. &oop.  group by 1,2,3,4					
		); 
		quit;
		proc sort data=_last_; by aa_analysis_year plan_type product pln_a_cpn_ben_plan_prt; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by aa_analysis_year plan_type product pln_a_cpn_ben_plan_prt; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(sum_tot_sum_indv_prd_clm_flag) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(sum_tot_sum_indv_prd_clm_flag/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format sum_tot_sum_indv_prd_clm_flag grp_nbr_denom comma15.; run; 
		proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*33*/
ods excel options(sheet_name="33" &ex_op.); 
	title "&prd_pfx Average Number of Prescriptions";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_prd_clm_flag),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_prd_clm_flag),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. &ded.  group by 1,2						
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "No Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_prd_clm_flag),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_prd_clm_flag),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. &oop.  group by 1,2						
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*34*/
ods excel options(sheet_name="34" &ex_op.); 
	title "&prd_pfx Average Number of Prescriptions - Continuing Members";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*35*/
ods excel options(sheet_name="35" &ex_op.); 
	title "&prd_pfx Average Number of Prescriptions";
	title2 "Meeting, Not Meeting Deductible";
	title3 "Utilization Status: New, Continuing, Unknown";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*36*/
data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms prd_: pln_a_:); array therapy_length{*} &ther_vars; prd_therapy_length = max(of therapy_length{*}); run;  
ods excel options(sheet_name="36" &ex_op.); 
	title "&prd_pfx Average Duration of Treatment";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data &all_whr_2018. &ded.  group by 1,2
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "No Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data &all_whr_2018. &oop.  group by 1,2
		); 
		quit;		
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*37*/
data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=dda_resp_met aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms prd_: pln_a_:); array therapy_length{*} &ther_vars; prd_therapy_length = max(of therapy_length{*}); run;  
ods excel options(sheet_name="37" &ex_op.); 
	title "&prd_pfx Average Duration of Treatment";
	title2 "Meeting, Not Meeting Deductible";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data &all_whr_2018. &ded. group by 1,2,3,4,5
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data &all_whr_2018. &oop. group by 1,2,3,4,5
		); 
		quit;		
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*38*/
data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms prd_: pln_a_:); array therapy_length{*} &ther_vars; prd_therapy_length = max(of therapy_length{*}); run;  
ods excel options(sheet_name="38" &ex_op.); 
	title "&prd_pfx Average Duration of Treatment - Continuing Members ";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 group by 1,2
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;		
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*39*/
data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms prd_: pln_a_:); array therapy_length{*} &ther_vars; prd_therapy_length = max(of therapy_length{*}); run;  
ods excel options(sheet_name="39" &ex_op.); 
	title "&prd_pfx Average Duration of Treatment";
	title2 "Meeting, Not Meeting Deductible";
	title3 "Utilization Status: New, Continuing, Unknown";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(prd_therapy_length_&prd_nbr),comma15.) as tot_days_prd_therapy_length
					 , put(mean(prd_therapy_length_&prd_nbr),comma4.1) as mean_prd_therapy_length
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;		
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*41*/
ods excel options(sheet_name="41" &ex_op.); 
	title "&prd_pfx Manufacturer Coupon Use";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , pln_a_cpn_ben_plan_prt
					 , case when dda_sum_indv_cpn_flag_&prd_nbr>0 then 1 else 0 end as coupon_use
					 , "Deductible Plans" as plan_type
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , pln_a_cpn_ben_plan_prt
					 , case when dda_sum_indv_cpn_flag>0 then 1 else 0 end as coupon_use
					 , "Deductible Plans" as plan_type
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &ded.  group by 1,2,3,4,5,6					
		  union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , pln_a_cpn_ben_plan_prt
					 , case when dda_sum_indv_cpn_flag_&prd_nbr>0 then 1 else 0 end as coupon_use
					 , "No Deductible Plans" as plan_type
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status											
					 , pln_a_cpn_ben_plan_prt																																						
					 , case when dda_sum_indv_cpn_flag>0 then 1 else 0 end as coupon_use
					 , "No Deductible Plans" as plan_type
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &oop.  group by 1,2,3,4,5,6					
		); 
		quit;
		proc sort data=_last_; by deductible_oop_max_status pln_a_cpn_ben_plan_prt plan_type product coupon_use; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by deductible_oop_max_status pln_a_cpn_ben_plan_prt plan_type product coupon_use; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; %util_dummy_sheet; 

/*42and44*/ 
data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms dda_: prd_: pln_a_: rename=(&t_dda_sum_fam_cpn_vars_rn. &t_dda_sum_indv_cpn_vars_rn.)); length &dda_sum_fam_cpn_vars. &dda_sum_indv_cpn_vars. $23; array t_cpn_vars{*} &t_dda_sum_fam_cpn_vars. &t_dda_sum_indv_cpn_vars.; array cpn_vars{*} &dda_sum_fam_cpn_vars. &dda_sum_indv_cpn_vars.; do i = 1 to dim(cpn_vars); cpn_vars{i}=put(t_cpn_vars{i},spend_fmt_rup.); end; drop &t_dda_sum_fam_cpn_vars. &t_dda_sum_indv_cpn_vars.; run;  
ods excel options(sheet_name="42and44" &ex_op.); 
	title "&prd_pfx Manufacturer Coupon Spend";
	title2 "Deductible Plans - Distribution";
	title3 "Meeting, Not Meeting Deductible";	
	title4 "10K+ Rollup View";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , dda_sum_indv_amt_manf_cpn_&prd_nbr as dda_sum_indv_amt_manf_cpn
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data &all_whr_2018. and dda_sum_indv_cpn_flag_&prd_nbr>0 and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , dda_sum_indv_amt_manf_cpn
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data &all_whr_2018. and dda_sum_indv_cpn_flag>0 &ded.  group by 1,2,3,4,5
		); 
		quit;
		proc sort data=_last_; by deductible_oop_max_status pln_a_cpn_ben_plan_prt product dda_sum_indv_amt_manf_cpn; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by deductible_oop_max_status pln_a_cpn_ben_plan_prt product dda_sum_indv_amt_manf_cpn; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run;

data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms dda_: prd_: pln_a_: rename=(&t_dda_sum_fam_cpn_vars_rn. &t_dda_sum_indv_cpn_vars_rn.)); length &dda_sum_fam_cpn_vars. &dda_sum_indv_cpn_vars. $23; array t_cpn_vars{*} &t_dda_sum_fam_cpn_vars. &t_dda_sum_indv_cpn_vars.; array cpn_vars{*} &dda_sum_fam_cpn_vars. &dda_sum_indv_cpn_vars.; do i = 1 to dim(cpn_vars); cpn_vars{i}=put(t_cpn_vars{i},spend_fmt.); end; drop &t_dda_sum_fam_cpn_vars. &t_dda_sum_indv_cpn_vars.; run;  
	title "&prd_pfx Manufacturer Coupon Spend";
	title2 "Deductible Plans - Distribution";
	title3 "Meeting, Not Meeting Deductible";	
	title4 "Full Detail View";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , dda_sum_indv_amt_manf_cpn_&prd_nbr as dda_sum_indv_amt_manf_cpn
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data &all_whr_2018. and dda_sum_indv_cpn_flag_&prd_nbr>0 and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , dda_sum_indv_amt_manf_cpn
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data &all_whr_2018. and dda_sum_indv_cpn_flag>0 &ded.  group by 1,2,3,4,5
		); 
		quit;
		proc sort data=_last_; by deductible_oop_max_status pln_a_cpn_ben_plan_prt product dda_sum_indv_amt_manf_cpn; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by deductible_oop_max_status pln_a_cpn_ben_plan_prt product dda_sum_indv_amt_manf_cpn; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 

data t&vz._rpt_data; set t&vz._rpt_data_pg(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms dda_: prd_: pln_a_: rename=(&t_dda_sum_fam_cpn_vars_rn. &t_dda_sum_indv_cpn_vars_rn.)); length &dda_sum_fam_cpn_vars. &dda_sum_indv_cpn_vars. $23; array t_cpn_vars{*} &t_dda_sum_fam_cpn_vars. &t_dda_sum_indv_cpn_vars.; array cpn_vars{*} &dda_sum_fam_cpn_vars. &dda_sum_indv_cpn_vars.; do i = 1 to dim(cpn_vars); cpn_vars{i}=put(t_cpn_vars{i},spend_fmt.); end; drop &t_dda_sum_fam_cpn_vars. &t_dda_sum_indv_cpn_vars.; run;  
	title "&prd_pfx Manufacturer Coupon Spend";
	title2 "Deductible Plans - Distribution";
	title3 "All Patients";	
	title4 "Full Detail View";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , dda_sum_indv_amt_manf_cpn_&prd_nbr as dda_sum_indv_amt_manf_cpn
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data &all_whr_2018. and dda_sum_indv_cpn_flag_&prd_nbr>0 and prd_flag_&prd_nbr &ded. group by 1,2,3
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all 
			select aa_analysis_year
					 , dda_sum_indv_amt_manf_cpn
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data &all_whr_2018. and dda_sum_indv_cpn_flag>0 &ded.  group by 1,2,3
		); 
		quit;
		proc sort data=_last_; by product dda_sum_indv_amt_manf_cpn; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by product dda_sum_indv_amt_manf_cpn; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; %util_dummy_sheet; 

/*43*/ 
ods excel options(sheet_name="43" &ex_op.); 
	title "&prd_pfx Manufacturer Coupon Spend";
	title2 "Deductible Plans - Totals, Means";
	title3 "Meeting, Not Meeting Deductible";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(dda_sum_indv_amt_manf_cpn_&prd_nbr),dollar15.2) as sum_cpn_spend
					 , put(mean(dda_sum_indv_amt_manf_cpn_&prd_nbr),dollar15.2) as mean_mbr_cpn_spend
					 , put(sum(dda_sum_indv_cpn_flag_&prd_nbr),comma15.) as sum_cpns
					 , put(sum(dda_sum_indv_cpn_flag_&prd_nbr)/sum(ab_demo_cohort),comma15.1) as mean_mbr_cpns					 
					 , put(sum(dda_sum_indv_amt_manf_cpn_&prd_nbr)/sum(dda_sum_indv_cpn_flag_&prd_nbr),dollar12.2) as mean_cpn_amt
			from t&vz._rpt_data_pg &all_whr_2018. and dda_sum_indv_cpn_flag_&prd_nbr>0 and prd_flag_&prd_nbr &ded. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(dda_sum_indv_amt_manf_cpn),dollar15.2) as sum_cpn_spend
					 , put(mean(dda_sum_indv_amt_manf_cpn),dollar15.2) as mean_mbr_cpn_spend
					 , put(sum(dda_sum_indv_cpn_flag),comma15.) as sum_cpns
					 , put(sum(dda_sum_indv_cpn_flag)/sum(ab_demo_cohort),comma15.1) as mean_mbr_cpns					 
					 , put(sum(dda_sum_indv_amt_manf_cpn)/sum(dda_sum_indv_cpn_flag),dollar12.2) as mean_cpn_amt
			from t&vz._rpt_data_pg &all_whr_2018. and dda_sum_indv_cpn_flag>0 &ded.  group by 1,2,3,4
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; %util_dummy_sheet; 

/*CF*/ 
ods excel options(sheet_name="CF" &ex_op.); 
	title "&prd_pfx Manufacturer Coupon Spend - Counterfactual";
	title2 "Deductible Plans - Totals, Means";
	title3 "Meeting, Not Meeting Deductible";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when g_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(g_sum_indv_amt_manf_cpn_&prd_nbr),dollar15.2) as sum_cpn_spend
					 , put(mean(g_sum_indv_amt_manf_cpn_&prd_nbr),dollar15.2) as mean_mbr_cpn_spend
					 , put(sum(gdl_sum_indv_amt_manf_cpn_&prd_nbr),dollar15.2) as sum_delta_cpn_spend
					 , put(mean(gdl_sum_indv_amt_manf_cpn_&prd_nbr),dollar15.2) as mean_delta_mbr_cpn_spend					 
					 , put(sum(g_sum_indv_cpn_flag_&prd_nbr),comma15.) as sum_cpns
					 , put(sum(g_sum_indv_amt_manf_cpn_&prd_nbr)/sum(g_sum_indv_cpn_flag_&prd_nbr),dollar12.2) as mean_cpn_amt
					 , put(sum(gdl_sum_indv_cpn_flag_&prd_nbr),comma15.) as sum_delta_cpns
					 , put(mean(gdl_sum_indv_cpn_flag_&prd_nbr),comma15.) as mean_delta_mbr_cpns					 
			from t&vz._rpt_data_pg &all_whr_2018. and dda_sum_indv_cpn_flag_&prd_nbr>0 and prd_flag_&prd_nbr &ded. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all 
			select aa_analysis_year
					 , case when g_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(g_sum_indv_amt_manf_cpn),dollar15.2) as sum_cpn_spend
					 , put(mean(g_sum_indv_amt_manf_cpn),dollar15.2) as mean_mbr_cpn_spend
					 , put(sum(gdl_sum_indv_amt_manf_cpn),dollar15.2) as sum_delta_cpn_spend
					 , put(mean(gdl_sum_indv_amt_manf_cpn),dollar15.2) as mean_delta_mbr_cpn_spend					 
					 , put(sum(g_sum_indv_cpn_flag),comma15.) as sum_cpns
					 , put(sum(g_sum_indv_amt_manf_cpn)/sum(g_sum_indv_cpn_flag),dollar12.2) as mean_cpn_amt
					 , put(sum(gdl_sum_indv_cpn_flag),comma15.) as sum_delta_cpns
					 , put(mean(gdl_sum_indv_cpn_flag),comma15.1) as mean_delta_mbr_cpns					 
			from t&vz._rpt_data_pg &all_whr_2018. and dda_sum_indv_cpn_flag>0 &ded.  group by 1,2,3,4
		); 
		quit;		
	proc print data=t&vz._rpt noobs; run;
	proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 
	
/*91*/
%let mbr_groups = Y N;
ods excel options(sheet_name="91and128" &ex_op.); 
	title "&prd_pfx OOP Max Fulfillment Status";
	title2 "No-Deductible Plans";
	title3 "Members Not Meeting 2018 OOP Max - 2017 OOP Max Status (thru Sept)";		
	proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') and dda_resp_met=0 &oop.; run;
	proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') and dda_resp_met=0 &oop.; run;
	proc sql; create table t&vz._rpt_b as (
		%do i = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&i); 
			select dda_resp_met_yoy
					 , put(count,comma15.) as members
					 , put(cum_freq,comma15.) as cum_mbrs
					 , put(percent/100,percent9.1) as percent
					 , put(cum_pct/100,percent9.1) as cum_pct
					 , "&mbr_group." as oop_accum_program 
					 , "All &prd_pfx Products" as product
			from t&vz._lilt_&mbr_group.
		 %if &i ne 2 %then %str(union all);
		%end; 
		); 
	quit;	
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') and dda_resp_met=0 &oop. and prd_flag_&prd_nbr; run;
		proc freq data=t&vz._rpt_data_pg_yoy order=formatted noprint; tables dda_resp_met_yoy / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') and dda_resp_met=0 &oop. and prd_flag_&prd_nbr; run;
		proc sql; create table t&vz._rpt_b&i. as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_met_yoy
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;		
	data t&vz._rpt; set t&vz._rpt_b %do i = 1 %to &prdnum_tmp.; t&vz._rpt_b&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;
	proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 	

/*92*/
ods excel options(sheet_name="92" &ex_op.); 
	title "&prd_pfx Individual Out of Pocket Maximum Distribution";
	title2 "No Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "Members Meeting OOP Max" as oop_max_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_oop,ded_fmt_tmp.) as individual_oop_max
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr and dda_resp_met &oop. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all)
		%end;
			union all
			select aa_analysis_year
					 , "Members Meeting OOP Max" as oop_max_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_oop,ded_fmt_tmp.) as individual_oop_max
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. &oop. and dda_resp_met group by 1,2,3,4						
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , "Members Not Meeting OOP Max" as oop_max_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_oop,ded_fmt_tmp.) as individual_oop_max
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr and dda_resp_met=0 &oop. group by 1,2,3,4
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , "Members Not Meeting OOP Max" as oop_max_status	
					 , pln_a_cpn_ben_plan_prt
					 , put(raw_pln_a_indv_oop,ded_fmt_tmp.) as individual_oop_max
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data_pg &all_whr_2018. and dda_resp_met=0 &oop. group by 1,2,3,4									
		); 
		quit;
		proc sort data=_last_; by oop_max_status pln_a_cpn_ben_plan_prt product individual_oop_max; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by oop_max_status pln_a_cpn_ben_plan_prt product individual_oop_max; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*93*/
ods excel options(sheet_name="93" &ex_op.); 
	title "&prd_pfx Average Number of Days to OOP Max Fulfillment";
	title2 "No-Deductible Plans";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(dda_resp_days),comma12.) as sum_dda_resp_days
					 , put(mean(dda_resp_days),comma4.) as mean_dda_resp_days
			from t&vz._rpt_data_pg &all_whr_2018.  and prd_flag_&prd_nbr &oop. group by 1,2,3
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members					
					 , put(sum(dda_resp_days),comma12.) as sum_dda_resp_days
					 , put(mean(dda_resp_days),comma4.) as mean_dda_resp_days
			from t&vz._rpt_data_pg &all_whr_2018.   &oop. group by 1,2,3						
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*94to96*/ 
%let mbr_groups = Y N;
ods excel options(sheet_name="94to96" &ex_op.); 
	title "&prd_pfx Month of OOP Max Fulfillment";
	title2 "No-Deductible Plans";
	proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') &oop. ; run;
	proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') &oop. ; run;
	proc sql; create table t&vz._rpt_a as (
		%do i = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&i); 
			select dda_resp_month
					 , put(count,comma15.) as members
					 , put(cum_freq,comma15.) as cum_mbrs
					 , put(percent/100,percent9.1) as percent
					 , put(cum_pct/100,percent9.1) as cum_pct
					 , "&mbr_group." as oop_accum_program 
					 , "All &prd_pfx Products" as product
			from t&vz._lilt_&mbr_group.
		 %if &i ne 2 %then %str(union all);
		%end; 
		); 
	quit;
		
	%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 	
		proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_Y outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('Y') &oop. and prd_flag_&prd_nbr ; run;
		proc freq data=t&vz._rpt_data_pg_df order=formatted noprint; tables dda_resp_month / out=t&vz._lilt_N outcum; &all_whr_2018. and pln_a_cpn_ben_plan_prt in ('N') &oop. and prd_flag_&prd_nbr ; run;
		proc sql; create table t&vz._rpt_&i as (
			%do j = 1 %to 2; %let mbr_group = %scan(&mbr_groups.,&j.); 
				select dda_resp_month
						 , put(count,comma15.) as members
						 , put(cum_freq,comma15.) as cum_mbrs
					 	 , put(percent/100,percent9.1) as percent
						 , put(cum_pct/100,percent9.1) as cum_pct
					 	 , "&mbr_group." as oop_accum_program 
						 , "&prd_nm" as product
				from t&vz._lilt_&mbr_group.
			 %if &j ne 2 %then %str(union all);
			%end; 
			); 
		quit;   
	%end;				 
	data t&vz._rpt; set t&vz._rpt_a %do i = 1 %to &prdnum_tmp.; t&vz._rpt_&i %if &i = &prdnum_tmp %then %str(;); %end; run; 
	proc print data=t&vz._rpt noobs; run;

proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*97*/
ods excel options(sheet_name="97" &ex_op.); 
	title "&prd_pfx Average Number of Prescriptions";
	title2 "Meeting, Not Meeting Deductible";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_prd_clm_flag),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_prd_clm_flag),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. &ded.  group by 1,2,3,4,5						
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_prd_clm_flag),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_prd_clm_flag),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. &oop.  group by 1,2,3,4,5				
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*98*/
ods excel options(sheet_name="98" &ex_op.); 
	title "&prd_pfx Average Number of Prescriptions";
	title2 "Meeting, Not Meeting OOP Max";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_prd_clm_flag),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_prd_clm_flag),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. &oop.  group by 1,2,3,4,5						
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_prd_clm_flag),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_prd_clm_flag),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. &oop.  group by 1,2,3,4,5				
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*99*/
ods excel options(sheet_name="99" &ex_op.); 
	title "&prd_pfx Average Number of Prescriptions";
	title2 "Meeting, Not Meeting OOP Max";
	title3 "Utilization Status: New, Continuing, Unknown";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , sum(ab_demo_cohort) as members					
					 , put(sum(tot_sum_indv_clm_flag_&prd_nbr),comma15.) as sum_tot_sum_indv_prd_clm_flag
					 , put(mean(tot_sum_indv_clm_flag_&prd_nbr),comma4.1) as mean_tot_sum_indv_prd_clm_flag
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;
		proc print data=t&vz._rpt noobs; format members comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*FillDist*/
ods excel options(sheet_name="FillDist" &ex_op.); 
	title "&prd_pfx Distribution of the Number of Prescriptions";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , put(tot_sum_indv_clm_flag_&prd_nbr,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "Deductible Plans" as plan_type
					 , put(tot_sum_indv_prd_clm_flag,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. &ded.  group by 1,2,3,4,5					
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , put(tot_sum_indv_clm_flag_&prd_nbr,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "All &prd_pfx Products" as product
					 , "No Deductible Plans" as plan_type
					 , put(tot_sum_indv_prd_clm_flag,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. &oop.  group by 1,2,3,4,5		
		); 
		quit;
		proc sort data=_last_; by pln_a_cpn_ben_plan_prt plan_type product tot_sum_indv_prd_clm_flag; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_cpn_ben_plan_prt plan_type product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*FillDistCont*/
ods excel options(sheet_name="FillDistCont" &ex_op.); 
	title "&prd_pfx Distribution of the Number of Prescriptions - Continuing Members";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , put(tot_sum_indv_clm_flag_&prd_nbr,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , put(tot_sum_indv_prd_clm_flag,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. and prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 group by 1,2,3,4,5
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;
		proc sort data=_last_; by pln_a_cpn_ben_plan_prt plan_type product tot_sum_indv_prd_clm_flag; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_cpn_ben_plan_prt plan_type product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*FillDistDedContStatus*/
ods excel options(sheet_name="FillDistDedContStatus" &ex_op.); 
	title "&prd_pfx Distribution of the Number of Prescriptions";
	title2 "Meeting, Not Meeting Deductible";
	title3 "Utilization Status: New, Continuing, Unknown";	
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , put(tot_sum_indv_clm_flag_&prd_nbr,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5,6,7
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
				 	 , pln_a_cpn_ben_plan_prt
					 , "&prd_nm" as product
					 , "No Deductible Plans" as plan_type
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , case when prd_idx_left_enr_&prd_nbr and prd_idx_left_cln_&prd_nbr=0 then 'Cont' when prd_idx_left_cln_&prd_nbr then 'New' else 'Unk' end as utilization_status
					 , put(tot_sum_indv_prd_clm_flag,fill_fmt.) as tot_sum_indv_prd_clm_flag
					 , sum(ab_demo_cohort) as members					
			from t&vz._rpt_data_pg &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6,7
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
		); 
		quit;
		proc sort data=_last_; by pln_a_cpn_ben_plan_prt plan_type deductible_oop_max_status utilization_status product tot_sum_indv_prd_clm_flag; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_cpn_ben_plan_prt plan_type deductible_oop_max_status utilization_status product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 
%rpt_go:;
/*ProdSpend*
data t&vz._rpt_data1; set t&vz._rpt_data_pg; 
	array amt_tot_oop_vars{*} 	dda_sum_indv_amt_tot_oop_1-dda_sum_indv_amt_tot_oop_8;  
	array amt_copay_vars{*} 		dda_sum_indv_amt_coin_1-dda_sum_indv_amt_coin_8;          
	array amt_coin_vars{*} 			dda_sum_indv_amt_copay_1-dda_sum_indv_amt_copay_8;        
	array amt_deductbl_vars{*} 	dda_sum_indv_amt_deductbl_1-dda_sum_indv_amt_deductbl_8;
	do i = 1 to 8; amt_tot_oop_vars{i}=amt_copay_vars{i}+amt_coin_vars{i}+amt_deductbl_vars{i}; end;
	dda_sum_indv_amt_tot_oop=sum(of amt_tot_oop_vars{*});
	drop i;   
run;                            
data t&vz._rpt_data; set t&vz._rpt_data1(keep=aa_analysis_year ab_demo_cohort pln_f2s_plan_switcher tot_has_clms dda_: prd_: pln_a_: rename=(&t_dda_sum_fam_oop_vars_rn. &t_dda_sum_indv_oop_vars_rn.)); length &dda_sum_fam_oop_vars. &dda_sum_indv_oop_vars. $23; array t_oop_vars{*} &t_dda_sum_fam_oop_vars. &t_dda_sum_indv_oop_vars.; array oop_vars{*} &dda_sum_fam_oop_vars. &dda_sum_indv_oop_vars.; do i = 1 to dim(oop_vars); oop_vars{i}=put(t_oop_vars{i},oop_spend_fmt.); end; drop &t_dda_sum_fam_oop_vars. &t_dda_sum_indv_oop_vars.; run;  
ods excel options(sheet_name="ProdSpend" &ex_op.); 
	title "&prd_pfx Member Out-of-Pocket Product Spend - By OOP, Deductible Status and Manufacturer Coupon Use";
		proc sql; create table t&vz._rpt as ( 
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , pln_a_cpn_ben_plan_prt
					 , case when dda_sum_indv_cpn_flag_&prd_nbr>0 then 1 else 0 end as coupon_use
					 , dda_sum_indv_amt_tot_oop_&prd_nbr as dda_sum_indv_amt_tot_oop
					 , "Deductible Plans" as plan_type
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data &all_whr_2018. and prd_flag_&prd_nbr &ded. group by 1,2,3,4,5,6,7
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , pln_a_cpn_ben_plan_prt
					 , case when dda_sum_indv_cpn_flag>0 then 1 else 0 end as coupon_use
					 , dda_sum_indv_amt_tot_oop as dda_sum_indv_amt_tot_oop
					 , "Deductible Plans" as plan_type
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data &all_whr_2018. &ded.  group by 1,2,3,4,5,6,7					
		  union all
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status
					 , pln_a_cpn_ben_plan_prt
					 , case when dda_sum_indv_cpn_flag_&prd_nbr>0 then 1 else 0 end as coupon_use
					 , dda_sum_indv_amt_tot_oop_&prd_nbr as dda_sum_indv_amt_tot_oop
					 , "No Deductible Plans" as plan_type
					 , "&prd_nm" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data &all_whr_2018. and prd_flag_&prd_nbr &oop. group by 1,2,3,4,5,6,7
			%if &i ne &prdnum_tmp %then %str(union all);
		%end;
			union all
			select aa_analysis_year
					 , case when dda_resp_met=1 then 'Y' else 'N' end as deductible_oop_max_status											
					 , pln_a_cpn_ben_plan_prt																																						
					 , case when dda_sum_indv_cpn_flag>0 then 1 else 0 end as coupon_use
					 , dda_sum_indv_amt_tot_oop as dda_sum_indv_amt_tot_oop
					 , "No Deductible Plans" as plan_type
					 , "All &prd_pfx Products" as product
					 , sum(ab_demo_cohort) as members
			from t&vz._rpt_data &all_whr_2018. &oop.  group by 1,2,3,4,5,6,7					
		); 
		quit;
		proc sort data=_last_; by pln_a_cpn_ben_plan_prt plan_type deductible_oop_max_status plan_type coupon_use product dda_sum_indv_amt_tot_oop; run;
		data t&vz._rpt_2(sortedby=grp_nbr); length grp_nbr 3; set t&vz._rpt; by pln_a_cpn_ben_plan_prt plan_type deductible_oop_max_status plan_type coupon_use product; retain grp_nbr; if first.product then grp_nbr+1; run; 
		proc sql; create table t&vz._rpt_3 as (select grp_nbr, sum(members) as grp_nbr_denom from t&vz._rpt_2 group by grp_nbr); quit;
		proc sort data=t&vz._rpt_3; by grp_nbr; run;
		data t&vz._rpt; merge t&vz._rpt_2 t&vz._rpt_3; by grp_nbr; grp_percent = put(members/grp_nbr_denom,percent9.2); run; 
		proc print data=t&vz._rpt noobs; format members grp_nbr_denom comma15.; run; 
proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 

/*ProdSpendDtl*/
data t&vz._rpt_data; set t&vz._rpt_data_pg; 
	array amt_tot_oop_vars{*} 	dda_sum_indv_amt_tot_oop_1-dda_sum_indv_amt_tot_oop_8;  
	array amt_copay_vars{*} 		dda_sum_indv_amt_coin_1-dda_sum_indv_amt_coin_8;          
	array amt_coin_vars{*} 			dda_sum_indv_amt_copay_1-dda_sum_indv_amt_copay_8;        
	array amt_deductbl_vars{*} 	dda_sum_indv_amt_deductbl_1-dda_sum_indv_amt_deductbl_8;
	do i = 1 to 8; amt_tot_oop_vars{i}=amt_copay_vars{i}+amt_coin_vars{i}+amt_deductbl_vars{i}; end;
	dda_sum_indv_amt_tot_oop=sum(of amt_tot_oop_vars{*});
	drop i;   
run;                            
		%do i = 1 %to &prdnum_tmp; %let prd_nm = %scan(&all_products.,&i); %let prd_nbr = %scan(&prd_nbrs.,&i); 
		title "&prd_pfx &prd_nm. &prd_nbr. Member Out-of-Pocket Product: No-Spender Detail";
		proc sql; create table t&vz._&prd_pfx._&prd_nbr._mbrs as (select mbr_sys_id from t&vz._rpt_data &all_whr_2018. and prd_flag_&prd_nbr and dda_sum_indv_amt_tot_oop_&prd_nbr=0); quit;
		proc print data=t&vz._&prd_pfx._&prd_nbr._mbrs; run;		
		%end;	

proc datasets nolist; delete t&vz._rpt; run; %util_dummy_sheet; 
	
%skiprest:;
/*-----------------------------------------------------------------*/
/*---> SLIDES REPORTING OUTPUT  <----------------------------------*/
/**/

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

proc print data=inp.t&vz.57_yr2_claims_plan; where mbr_sys_id in (151537798,	151578434,	151877077,	151977314,	153535460,	154690112,	154695214,	156576852,	156627594,	156783318); run;

/*PRODUCT GROUPINGS AND ALL DATA GROUP LOOPS*/
%end;
%no_rep:;
proc datasets nolist; delete t&vz.:; run;
%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/ 

%data_oop_claims(no_dx=1,no_pull=1,no_stage=1,testobs=,no_rep=0,rpt_go=1);

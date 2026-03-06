 /*----------------------------------------------------------------*\
 | MACRO TO CREATE DATE VARS																				|
 | AUTHOR: Michael Edwards 2019-02-27                          			|
  \*---------------------------------------------------------------*/													
/**/

%macro util_dates(start_dt=,yr_num=,months=);
%global cur_st cur_end cur_st_yrn cur_st_db2 cur_end_db2 cur_end_yrmo 
				cur_st_long cur_end_long cur_st_lb cur_st_lb_db2 cur_st_wb_long 
				cur_st_wb cur_st_wb_db2; 
data _null_;
	cur_st 				= intnx('year',&start_dt.,&yr_num.-1,'beg');
	cur_end 			= intnx('month',cur_st,&months.-1,'end');
	cur_st_mon		= put(input(cats(month(cur_st)),3.),z2.);
	cur_end_mon		= put(input(cats(month(cur_end)),3.),z2.);
	cur_st_yrn		= put(input(cats(year(cur_st)),4.),z4.);
	cur_end_yrn		= put(input(cats(year(cur_end)),4.),z4.);
	cur_st_dyn		= put(input(cats(day(cur_st)),3.),z2.);
	cur_end_dyn		= put(input(cats(day(cur_end)),3.),z2.);
	cur_st_db2		=	"'"!!cur_st_yrn!!"-"!!cur_st_mon!!"-"!!cur_st_dyn!!"'";
	cur_end_db2		=	"'"!!cur_end_yrn!!"-"!!cur_end_mon!!"-"!!cur_end_dyn!!"'";
	cur_end_yrmo	= cur_end_yrn!!cur_end_mon;	
	cur_st_lb 		= intnx('year',&start_dt.,-1,'beg');
	cur_st_lb_mon	= put(input(cats(month(cur_st_lb)),3.),z2.);
	cur_st_lb_yrn	= put(input(cats(year(cur_st_lb)),4.),z4.);
	cur_st_lb_dyn	= put(input(cats(day(cur_st_lb)),3.),z2.);
	cur_st_lb_db2	=	"'"!!cur_st_lb_yrn!!"-"!!cur_st_lb_mon!!"-"!!cur_st_lb_dyn!!"'";
	cur_st_wb 		= intnx('year',&start_dt.,-5,'beg');
	cur_st_wb_mon	= put(input(cats(month(cur_st_wb)),3.),z2.);
	cur_st_wb_yrn	= put(input(cats(year(cur_st_wb)),4.),z4.);
	cur_st_wb_dyn	= put(input(cats(day(cur_st_wb)),3.),z2.);
	cur_st_wb_db2	=	"'"!!cur_st_wb_yrn!!"-"!!cur_st_wb_mon!!"-"!!cur_st_wb_dyn!!"'";
	call symput("cur_st",cur_st);				
	call symput("cur_end",cur_end);  
	call symput("cur_st_yrn",cur_st_yrn);  
	call symput("cur_st_db2",cur_st_db2	);  
	call symput("cur_end_db2",cur_end_db2 );  
	call symput("cur_end_yrmo", cur_end_yrmo);
	call symput("cur_st_long",trim(left((put(intnx('month',cur_st,0,'beg'),WORDDATE20.)))));
	call symput("cur_end_long",trim(left((put(intnx('month',cur_end,0,'end'),WORDDATE20.)))));		
	call symput("cur_st_lb",cur_st_lb);				
	call symput("cur_st_lb_db2",cur_st_lb_db2	);  
	call symput("cur_st_wb_long",trim(left((put(intnx('year',cur_st_lb,-5,'beg'),WORDDATE20.)))));
	call symput("cur_st_wb",cur_st_wb);				
	call symput("cur_st_wb_db2",cur_st_wb_db2	);  
run; 		

%put NOTE: yr_num 				= &yr_num.				;
%put NOTE: cur_st_db2     = &cur_st_db2     ;
%put NOTE: cur_end_db2    = &cur_end_db2    ;
%put NOTE: cur_lb_db2     = &cur_st_lb_db2  ;
%put NOTE: cur_wb_db2     = &cur_st_wb_db2  ;
%put;

%mend;
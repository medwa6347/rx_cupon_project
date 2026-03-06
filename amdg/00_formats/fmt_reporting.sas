 /*----------------------------------------------------------------*\
 | REPORTING FORMATS																						  	|
 | AUTHOR: MICHAEL EDWARDS 2018-01-25 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/

proc format; 
	value	$phbit_bus_seg_fmt 											'Key Account'										= 'M'
																								'Small Group'										= 'S'
																								'National Accounts'							=	'N'
																								'KA-International'							=	'M';
	value	$claims_bus_seg_fmt											'M'															=	'M'
																								'S'															=	'S'
																								'K'															= 'M'
																								'N'															= 'N'
																								'E'															= 'S'
																								'G'															=	'S';																							
	value $pln_funding_arrangment_fmt							'Fully Insured'									=	'FI'									
																								'Self Insured (ASO)'						=	'ASO';
	value	$pln_oop_med_rx_type_fmt								'Deductible and Out Of Pocket'	= 'DOP'
																								'Other'													= 'OTH'
																								'Out Of Pocket Only'						=	'OOP';
	value	$yes_no_fmt															'N'															= 'N'
																								'Y'															= 'Y'
																								other														=	'N';
 	value age_cht_fmt															low-<18													= 'Less than 18'	  
 																								18-34   												= '18 to 34'
 																								35-49   												= '35 to 49'
 																								50-64   												= '50 to 64'
 																								65-79   												= '65 to 79'
 																								80-high 												=	'80+';	
 	value cpn_flag_fmt														low-0														= 0  
 																								1-high 													=	1;	
	value $cdhp_fmt																'1'															= 'N'
																								'2'                             = 'Y'
																								'3'                             = 'Y'
																								'4'                             = 'Y'
																								'5'                             = 'Y'
																								'6'                             = 'Y'
																								'7'                             = 'Y'
																								'8'                             = 'Y'
																								'9'                             = 'N'
																								'A'                             = 'Y'
																								'B'                             = 'Y'
																								other                           = 'U';
 value	ded_fmt																	low-<1													=	'$0'
 																								1-1499													= '$1-$1,499'  
 																								1500-2999												= '$1,500-$2,999'   																								
 																								3000-5999												=	'$3,000-$5,999'
 																								6000-9999												= '$6,000-$9,999'
 																								10000-high											=	'>$10,000';
 value	ded_fmt_tmp															low-<1													=	'd00__$0'
 																								1-999														= 'd01__$1-$999'  
 																								1000-1999												= 'd02__$1,000-$1,999'   																								
 																								2000-2999												=	'd03__$2,000-$2,999'
 																								3000-3999												= 'd04__$3,000-$3,999'
 																								4000-4999												= 'd05__$4,000-$4,999'
 																								5000-5999												= 'd06__$5,000-$5,999'
 																								6000-high												=	'd07__>=$6,000';
 value	spend_fmt_rup														low-<1													=	'd00__$0'
 																								1-1999													= 'd01__$1-$1,999'
 																								2000-3999												= 'd02__$2,000-$3,999'
 																								4000-5999												= 'd03__$4,000-$5,999'
 																								6000-9999												=	'd04__$6,000-$9,999'
 																								10000-high											=	'd05__$10,000+';
 value	spend_fmt																low-<1													=	'd00__$0'
 																								1-1999													= 'd01__$1-$1,999'
 																								2000-3999												= 'd02__$2,000-$3,999'
 																								4000-5999												= 'd03__$4,000-$5,999'
 																								6000-7999												=	'd04__$6,000-$7,999'
 																								8000-9999												=	'd05__$8,000-$9,999'
 																								10000-11999											=	'd06__$10,000-$11,999'
 																								12000-13999											=	'd07__$12,000-$13,999'
 																								14000-15999											=	'd08__$14,000-$15,999'
 																								16000-high											=	'd09__$16,000+';
 value	oop_spend_fmt														low-<1													=	'd00__$0'
 																								1-249.999												= 'd01__$1-$249'
 																								250-499.99											= 'd02__$250-$499'
 																								500-749.99											= 'd03__$500-$749'
 																								750-999.99											= 'd04__$750-$999'
 																								1000-1999.99										= 'd05__$1,000-$1,999'
 																								2000-2999.99										= 'd06__$2,000-$2,999'
 																								3000-3999.99										=	'd07__$3,000-$3,999'
 																								4000-high												=	'd08__$4,000+';
 value fam_fmt																	low-<2													= '1 Family Member'									
 																								2                               = '2 Family Members'
 																								3                               = '3 Family Members'
 																								4                               = '4 Family Members'
 																								5-high                          = '5 or more Family Members';
 value fill_fmt																	low-<3		                      = 'f01__1-2 Product Fills'
 																								3-4				                      = 'f02__3-4 Product Fills' 	
 																								5-6															= 'f03__5-6 Product Fills'
 																								7-8															= 'f04__7-8 Product Fills'
 																								9-high													= 'f05__9 or More Product Fills';										
 value $reg_fmt																	'S' 														= 'South'            																								
 																								'W'                             = 'West'             
 																								'NE'                            = 'Northeast'        
 																								'MW'                            = 'Midwest'          
 																								'N'                             = 'Non-Census Region';
run;


* APPLIES TO GRAPHS;
ods path(prepend) work.templat(update);
proc format;
   picture pctfmt (round) 0-high='000%';
run;
* EXCEL FORMATS;
ods path(prepend) work.templat(update);
proc template;
	define style styles.XL&vz.sansPrinter; 						/* <== DECLARE EXCEL STYLE TO APPLY TO ALL EXCEL OUTPUTS */
		parent = styles.sansPrinter;      						
		class systemtitle /               						
		fontsize = 10pt;																/* <== FONT, COLOR OPTIONS FOR TITLE STMTS AND PROC PRINT OUTPUTS */
		style header from header /
		foreground = cxFFFFFF
		background = cx63666A;                         
end; run;	



/*-----------------------------------------------------------------*\
 | CODES INPUT AND FORMATTING STATEMENT								      				 |
 | AUTHOR: MICHAEL W EDWARDS 10-15-18 AMDG                           |
 \*-----------------------------------------------------------------*/
/**/

*CODESET INPUT.  MATCHES PROC FORMAT CNTLIN= SYNTAX;
*FMTNAME = THREE-LETER ALPHA DESIGNATION FOR GROUPING 
*(I.E. "RA" = RHEUMATOID ARTHRITIS);
*TYPE = FORMAT TYPE;
*START = CODES;
*LABEL = FORMAT VALUE;
data t&vz._rawcodes(drop=line); 
input line $char23.;
fmtname=put(scan(line,1,'|'),$7.); 
start=put(scan(line,2,'|'),$11.); 
cards;   
dar_ndc|57894050205	              
dar_ndc|57894050220	              
rem_ndc|57894003001					   
sim_ndc|57894007002	           
sim_ndc|57894007101	           
sim_ndc|57894007102	           
sim_ndc|57894007001	           
ste_ndc|57894006103	                 
ste_ndc|57894006003	                 
ste_ndc|57894006002	                 
ste_ndc|57894005427	                       											 
tre_ndc|57894064001	                 
erl_ndc|59676060012	           
sia_ndc|57894035001	                 
zyt_ndc|57894015012	                 
zyt_ndc|57894019506
;
run;

*FORMATS FOR ALL CODE GROUPS;
proc sort data=t&vz._rawcodes nodupkey; by fmtname start; run;
data t&vz._fmt;
   retain type 'n';
   set t&vz._rawcodes;
   by fmtname;
   label=1; hlo=' '; output;
   if last.fmtname then do; hlo='o'; start=''; label=0; output; end;
run;
proc format cntlin=t&vz._fmt library=work; run;

*FORMAT TO RETURN ANY CODE GROUP PROVIDED GIVEN CODE;
data t&vz._fmt2;
   retain fmtname 'all_ndc_codes' type 'c';
   set t&vz._fmt(where=(hlo='') rename=(fmtname=label) 
           drop=type label) end=last;
   output;
   if last then do; start=''; hlo='o'; label='X'; output; end;
run;
proc format cntlin=t&vz._fmt2 library=work; run;

*PLACE EACH CODE GROUPING AND ALL CODES INTO RESPECTIVE MACRO VARS FOR DB2 SQL;
data _null_; 
set t&vz._rawcodes(keep=fmtname start) end=last;
by fmtname; 
length codes $32767 all_codes $32767; 
retain codes all_codes; 
if first.fmtname then codes = ''; 
codes = trim(codes)!!"'"!!trim(start)!!"',"; 
all_codes = trim(all_codes)!!"'"!!trim(start)!!"',"; 
if last.fmtname then do;
	codes = trim(codes)!!"'"!!trim(start)!!"'"; 
	call symput(fmtname,codes);
	end;
if last then do; 
	all_codes = trim(all_codes)!!"'"!!trim(start)!!"'"; 
	call symput("all_ndc_codes",all_codes); 
	end;
run;




/*------------------------------------------------------------------*\
 | CODES INPUT AND FORMATTING STATEMENT								      |
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
input line $char18.;
fmtname=put(scan(line,1,'|'),$8.); 
start=put(scan(line,2,'|'),$5.); 
cards;                                    
dar_proc|C9476				    
dar_proc|J9145 			    
rem_proc|J1745 			    
sim_proc|J1602 			    
ste_proc|C9261          
ste_proc|J3357          
ste_proc|Q9989            
ste_proc|C9487            
ste_proc|J3358            
tre_proc|C9029
;
run;

*FORMATS FOR ALL CODE GROUPS;
proc sort data=t&vz._rawcodes nodupkey; by fmtname start; run;
data t&vz._fmt;
   retain type 'c';
   set t&vz._rawcodes;
   by fmtname;
   label=1; hlo=' '; output;
   if last.fmtname then do; hlo='o'; start=''; label=0; output; end;
run;
proc format cntlin=t&vz._fmt library=work; run;

*FORMAT TO RETURN ANY CODE GROUP PROVIDED GIVEN CODE;
data t&vz._fmt2;
   retain fmtname 'all_proc_codes' type 'c';
   set t&vz._fmt(where=(hlo='') rename=(fmtname=label) 
           drop=type label) end=last;    
   output;
   if last then do; start=''; hlo='o'; label='X'; output; end;
run;
proc format cntlin=t&vz._fmt2 library=work; run;

*PLACE EACH CODE GROUPING AND ALL CODES INTO RESPECTIVE MACRO VARS FOR DB2 SQL;
proc sort data=t&vz._rawcodes; by fmtname; run;
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
	call symput("all_proc_codes",all_codes); 
	end;
run;




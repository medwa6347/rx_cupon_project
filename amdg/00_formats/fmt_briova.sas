/*-----------------------------------------------------------------*\
 | CODES INPUT AND FORMATTING STATEMENT								     |
 | AUTHOR: MICHAEL W EDWARDS 10-15-18 AMDG                          |
 \*----------------------------------------------------------------*/
/**/

*CODESET INPUT.  MATCHES PROC FORMAT CNTLIN= SYNTAX;
*FMTNAME = THREE-LETER ALPHA DESIGNATION FOR GROUPING 
*(I.E. "RA" = RHEUMATOID ARTHRITIS);
*TYPE = FORMAT TYPE;
*START = CODES;
*LABEL = FORMAT VALUE;
data t&vz._rawcodes(drop=line); 
input line $char16.;
fmtname=put(scan(line,1,'|'),$8.); 
start=put(scan(line,2,'|'),$7.); 
cards;           
brx_nabp|131754
brx_nabp|4436615
brx_nabp|2521640
brx_nabp|5054349
brx_nabp|1719941
brx_nabp|1160136
brx_nabp|2006890
brx_nabp|2243412
brx_nabp|2992750
brx_nabp|1937121
brx_nabp|1098979
brx_nabp|1564930
brx_nabp|5623031
brx_nabp|5642930
brx_nabp|3338969
brx_nabp|4539079
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
   retain fmtname 'all_brx_codes' type 'c';
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
	call symput("all_brx_codes",all_codes); 
	end;
run;




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
input line $char9.;
fmtname=put(scan(line,1,'|'),$2.); 
type=put(scan(line,2,'|'),$1.); 
start=put(scan(line,3,'|'),$2.); 
label=put(scan(line,4,'|'),3.); 
cards;    
S |c|AL|1          
W |c|AK|1         
W |c|AZ|1         
S |c|AR|1		     
W |c|CA|1         
W |c|CO|1         
NE|c|CT|1         
S |c|DE|1         
S |c|DC|1         
S |c|FL|1         
S |c|GA|1         
W |c|HI|1         
W |c|ID|1               											 
MW|c|IL|1         
MW|c|IN|1         
MW|c|IA|1
MW|c|KS|1
S |c|KY|1
S |c|LA|1
NE|c|ME|1
S |c|MD|1
NE|c|MA|1
MW|c|MI|1
MW|c|MN|1
S |c|MS|1
MW|c|MO|1
W |c|MT|1
MW|c|NE|1
W |c|NV|1
NE|c|NH|1
NE|c|NJ|1
W |c|NM|1
NE|c|NY|1
S |c|NC|1
MW|c|ND|1
MW|c|OH|1
S |c|OK|1
W |c|OR|1
NE|c|PA|1
NE|c|RI|1
S |c|SC|1
MW|c|SD|1
S |c|TN|1
S |c|TX|1
W |c|UT|1
NE|c|VT|1
S |c|VA|1
W |c|WA|1
S |c|WV|1
MW|c|WI|1
W |c|WY|1
N |c|PR|1
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
   retain fmtname 'all_st_codes' type 'c';
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
	call symput("all_st_codes",all_codes); 
	end;
run;




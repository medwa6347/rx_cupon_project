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
input line $char36.;
fmtname=put(scan(line,1,'|'),$18.); 
type=put(scan(line,2,'|'),$1.); 
start=put(scan(line,3,'|'),$2.); 
label=trim(tranwrd(scan(line,4,'|'),"'",""));
cards;    
East_South_Central|c|AL|1        
Pacific           |c|AK|1       
Mountain          |c|AZ|1       
West_South_Central|c|AR|1	     
Pacific           |c|CA|1       
Mountain          |c|CO|1       
New_England       |c|CT|1        
South_Atlantic    |c|DE|1       
South_Atlantic    |c|DC|1       
South_Atlantic    |c|FL|1       
South_Atlantic    |c|GA|1       
Pacific           |c|HI|1       
Mountain          |c|ID|1             											 
East_North_Central|c|IL|1        
East_North_Central|c|IN|1        
West_North_Central|c|IA|1
West_North_Central|c|KS|1
East_South_Central|c|KY|1
West_South_Central|c|LA|1
New_England       |c|ME|1
South_Atlantic    |c|MD|1
New_England       |c|MA|1
East_North_Central|c|MI|1
West_North_Central|c|MN|1
East_South_Central|c|MS|1
West_North_Central|c|MO|1
Mountain          |c|MT|1
West_North_Central|c|NE|1
Mountain          |c|NV|1
New_England       |c|NH|1
Middle_Atlantic   |c|NJ|1
Mountain          |c|NM|1
Middle_Atlantic   |c|NY|1
South_Atlantic    |c|NC|1
West_North_Central|c|ND|1
East_North_Central|c|OH|1
West_South_Central|c|OK|1
Pacific           |c|OR|1
Middle_Atlantic   |c|PA|1
New_England       |c|RI|1
South_Atlantic    |c|SC|1
West_North_Central|c|SD|1
East_South_Central|c|TN|1
West_South_Central|c|TX|1
Mountain          |c|UT|1
New_England       |c|VT|1
South_Atlantic    |c|VA|1
Pacific           |c|WA|1
South_Atlantic    |c|WV|1
East_North_Central|c|WI|1
Mountain          |c|WY|1
No_Census_Region  |c|PR|1
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
   retain fmtname 'all_st2_codes' type 'c';
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
	call symput("all_st2_codes",all_codes); 
	end;
run;


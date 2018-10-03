Only add rows when new information dynamic regualr expressions prx

github
https://tinyurl.com/yb58s4w3
https://github.com/rogerjdeangelis/utl-only-add-rows-when-new-information-dynamic-regualr-expressions-prx

Ingenious use of regular expressions

  STEPS

     1.  Build regular expressions where missing are 'd+' ie (1 4 . 4) -> /1_4_\d+_4/
         Split complete cases(no missing) and complete plus missing into separate tables..
     2.  Perform cartesian to indentify rows that have no new informat. Full data
         has data in wildcard match.
     3.  Merge full data missing and non missing with matche(no new info).
         Rows in full that are not in matched.

see
https://tinyurl.com/yatrpka2
https://stackoverflow.com/questions/52600455/keep-duplicates-id-only-if-there-is-no-new-information

Amazing solution by Sanek Zhitnik
https://stackoverflow.com/users/5353177/sanek-zhitnik


INPUT
=====
                                  | RULES
 WORK.HAVE total obs=7            |
                                  |
  Ob ID    VAR1    VAR2    VAR3   |
                                  |
   1  1      2       3       4*   |  Prime the pmp
   2  1      4       .       4*   |  New information var1=4

   3  1      6       5       4*   |  New information var1=6 and var2=5

                                     Var1 =(2,4,6) var2=(3,5) var3=4
   4  1      .       3       .    |
                                     No new information var2=3 is in old var2=(3,5)
   5  1      2       4       4*   |
                                     New information  var2=4
   6  1      6       .       4    |
                                     No new information
   7  1      .       8       4*   |
                                     New information  var2=8

EXAMPLE OUTPUT
--------------

 WORK.WANT

     ID    VAR1    VAR2    VAR3

      1      4       .       4   -> ob 2 above
      1      .       8       4   -> ob 7 above
      1      2       3       4   -> ob 1 above
      1      2       4       4   -> ob 5 above

    1      6       5       4   -> ob 3 above

PROCESS
=======

data hav2nd missing;
/*incase this strings if you have big values*/
length res $ 200 addedEl $ 10;
    set have;
    array num _NUMERIC_;

    /*add flag  to determine is there missin in row*/
    flag=0;
    do i=1 to dim(num);
        addedEl=compress(put(num(i),8.));
        if num(i)=. then
            do;
                flag=1;
                /*template for number. If you have comma separated vars then replace on \d+\.\d*        */
                addedEl="\d+";
            end;
        /*add delimeter to row parse, if you have more than one digits in vars =)*/
        res=catx("_",res,addedEl);
    end;

    if flag=0 then  output;
    else    do;
        res=catt("/",res,"/");
        output missing;
    end;

    drop i flag addedEl;
run;



40 obs from HAV2ND total obs=3

   RES      ID    VAR1    VAR2    VAR3

 1_2_3_4     1      2       3       4
 1_6_5_4     1      6       5       4
 1_2_4_4     1      2       4       4


40 obs from MISSING total obs=7

 RES              ID    VAR1    VAR2    VAR3

 1_2_3_4           1      2       3       4
 /1_4_\d+_4/       1      4       .       4
 1_6_5_4           1      6       5       4
 /1_\d+_3_\d+/     1      .       3       .
 1_2_4_4           1      2       4       4
 /1_6_\d+_4/       1      6       .       4
 /1_\d+_8_4/       1      .       8       4


/*determine rows that dublicates*/
proc sql noprint;
create table matched as
  select  B.*
          ,prxparse(B.res) as prxm
          ,A.*
  from  hav2nd as A
        ,missing as B
  where prxmatch(calculated prxm,A.res)
  order by B.res;
quit;
run;

p to 40 obs WORK.MATCHED total obs=2

bs         RES         ID    VAR1    VAR2    VAR3    PRXM

1     /1_6_\d+_4/       1      6       .       4       3
2     /1_\d+_3_\d+/     1      .       3       .       2


/*pre-merge sort*/
proc sort data=missing;
    by res;
run;

/*
Up to 40 obs WORK.MISSING total obs=7

Obs    RES              ID    VAR1    VAR2    VAR3

 1     /1_4_\d+_4/       1      4       .       4
 2     /1_6_\d+_4/       1      6       .       4
 3     /1_\d+_3_\d+/     1      .       3       .
 4     /1_\d+_8_4/       1      .       8       4
 5     1_2_3_4           1      2       3       4
 6     1_2_4_4           1      2       4       4
 7     1_6_5_4           1      6       5       4
*/

/*delete rows that are in second dataset*/
data miss_correctred;
    merge missing(in=mss)
        matched(in=mtch)
    ;
    by res;

    if mss=1 and mtch=0;
run;

/*
Up to 40 obs WORK.MISS_CORRECTRED total obs=5

Obs    RES            ID    VAR1    VAR2    VAR3    PRXM

 1     /1_4_\d+_4/     1      4       .       4       .
 2     /1_\d+_8_4/     1      .       8       4       .
 3     1_2_3_4         1      2       3       4       .
 4     1_2_4_4         1      2       4       4       .
 5     1_6_5_4         1      6       5       4       .
*/

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

data have;
input id var1 var2 var3 ;
array vars var1-var3;
cards4;
1 2 3 4
1 4 . 4
1 6 5 4
1 . 3 .
1 2 4 4
1 6 . 4
1 . 8 4
;;;;
run;quit;





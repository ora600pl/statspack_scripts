#!/bin/bash

export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

for i in `seq $1 $2`; do
  esnap=$i
  bsnap=$((i-1))

sqlplus "/ as sysdba" << !
define report_name=${bsnap}_${esnap}.txt
define begin_snap=${bsnap}
define end_snap=${esnap}
@?/rdbms/admin/spreport
exit
!

done



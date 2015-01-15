#! /bin/bash

imjd=56857
fmjd=0.49983
python -c "import bpepy.gpstime, sys
s,d = bpepy.gpstime.jd2gd ($imjd,$fmjd)
if s != 0 : sys.exit (1)
d.strftime ('%Y %j %m %d')
sys.exit (0)"
echo "$DATE_STR $?" 


YEAR=2014
DOY=221

DATES_STR=`python -c "import bpepy.gpstime, sys
gpsweek,dow = bpepy.gpstime.yd2gpsweek ($YEAR,$DOY)
if gpsweek == -999 : sys.exit (1)
month,dom = bpepy.gpstime.yd2month ($YEAR,$DOY)
if month == -999 : sys.exit (1)
print '%04i %1i %02i %02i' %(gpsweek,dow,month,dom)
sys.exit (0);" 2>/dev/null`
    
# check for error
if test $? -ne 0 ; then
  echo "***ERROR! Failed to resolve the date"
  exit 1
fi

GPSW=`echo $DATES_STR | awk '{print $1}'`;
DOW=`echo $DATES_STR | awk '{print $2}'`;
MONTH=`echo $DATES_STR | awk '{print $3}'`;
DOM=`echo $DATES_STR | awk '{print $4}'`;
echo "$GPSW $DOW $MONTH $DOM"

AC=cod
SOL_TYPE=f
SAT_SYS=gps
echo "| ${AC} | ${SOL_TYPE}    | ${SAT_SYS} "
sp3=`/bin/grep --ignore-case "| ${AC} | ${SOL_TYPE}    | ${SAT_SYS} " <<EOF | awk '{print $8}'
 +---- +------+-------+-----------------------+
 | AC  | TYPE | GNSS  | FILE (as in datapool) |
 +---- +------+-------+-----------------------+
 | igs | f    | gps   | igswwwwd.sp3          |
 | igs | r    | gps   | igrwwwwd.sp3          |
 | igs | u    | gps   | iguwwwwd.sp3          |
 | igs | f    | mixed | igswwwwd.sp3          |
 | igs | r    | mixed | -                     |
 | igs | u    | mixed | igvwwwwd.sp3          |
 +---- +------+-------+-----------------------|
 | cod | f    | mixed | codwwwwd.sp3          |
 | cod | r    | mixed | corwwwwd.sp3          |
 | cod | u    | mixed | couwwwwd.sp3          |
 +---- +------+-------+-----------------------+
EOF`
echo $sp3
if test ${#sp3} -ne 12  ; then
  echo "*** Failed to resolve sp3 file"
  exit 1
fi

if test -z $sp3; then echo "ERROR sp3"; exit 1; fi

if test ${#sp3} -ne 12  ; then
  echo "*** Failed to resolve sp3 file"
  exit 1
fi

echo ${sp3/wwww/${GPSW}}

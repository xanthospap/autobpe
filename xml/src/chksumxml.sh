#! /bin/bash

##  argv[1] -> CHK${YR2}${DOY}0.OUT
##  this scripts expects that it will also find a file
##+ named CHK${YR2}${DOY}0.SUM in the same folder as the 
##+ output file given.

############################################################
## IF A PROBLEM IS FOUND, THE RETURN STATUS IS SET TO 100 ##
############################################################

if [ "$#" -ne 1 ]
then
  echo "ERROR! Need to provide file CHK${YR2}${DOY}0.OUT."
  echo "Refusing to make chksum.xml"
  exit 1
  if ! test -f $1
  then
    echo "Failed to locate file $1"
    echo "Refusing to make chksum.xml"
    exit 1
  fi
fi

OUTF=${1/%.OUT/.SUM}
if ! test -f ${OUTF}
then
  echo "Failed to locate file ${OUTF}"
  echo "Refusing to make chksum.xml"
  exit 1
fi

if [ -z ${XML_TEMPLATES} ] || [ -z ${tmpd} ]
then
  echo "Either XML_TEMPLATES or tmpd variables not defined"
  echo "Refusing to make chksum.xml"
  exit 1
fi

## write the header from the template
head -n 3 ${XML_TEMPLATES}/procsum-chksum.xml > ${tmpd}/xml/chksum.xml

## extract information from the OUT file
PROG=`cat $1 | grep Program | awk '{print $3}'`
PROBLEM=1
if grep "NO SPECIAL EVENTS FOUND IN THIS SOLUTION" ${1} &>/dev/null
then
  PROBLEM=0
  STATUS=0
else
  STATUS=100
fi
## write some information
echo "<section><title>Detection of misbehaving stations/satellites</title>" >> ${tmpd}/xml/chksum.xml

if test "${PROBLEM}" -eq 0
then
  echo "<note>No special events found in this solution</note>" >> ${tmpd}/xml/chksum.xml
else
  echo "<warning>Special events found in this solution!</warning>" >> ${tmpd}/xml/chksum.xml
fi

## start the table
echo "<table><title>Satellite Statistics</title>" >> ${tmpd}/xml/chksum.xml
echo "<tgroup cols='11'>" >> ${tmpd}/xml/chksum.xml
for i in `seq 1 11`
do
  echo "<colspec colname='c${i}'/>" >> ${tmpd}/xml/chksum.xml
done

## write first row (header)
echo "<thead><row>" >> ${tmpd}/xml/chksum.xml
echo "<entry>PRN</entry>" >> ${tmpd}/xml/chksum.xml
echo "<entry namest='c2' nameend='c3'>% observations</entry>" >> ${tmpd}/xml/chksum.xml
echo "<entry namest='c4' nameend='c5'>difference</entry>" >> ${tmpd}/xml/chksum.xml
echo "<entry namest='c6' nameend='c7'># observations</entry>" >> ${tmpd}/xml/chksum.xml
echo "<entry namest='c8' nameend='c9'>difference</entry>" >> ${tmpd}/xml/chksum.xml

echo "<entry namest='c10' nameend='c11'>rms</entry>" >> ${tmpd}/xml/chksum.xml
echo "</row>" >> ${tmpd}/xml/chksum.xml

## write second row (header)
echo "<row>" >> ${tmpd}/xml/chksum.xml
echo "<entry></entry><entry>before</entry><entry>after</entry><entry>abs</entry><entry>rel</entry><entry>before</entry><entry>after</entry><entry>abs</entry><entry>rel</entry><entry>before</entry><entry>after</entry></row>" >> ${tmpd}/xml/chksum.xml
echo "</thead>" >> ${tmpd}/xml/chksum.xml

## write the footer
echo "<tfoot>" >> ${tmpd}/xml/chksum.xml
LN=()
IFS=' ' read -a LN <<< `tail -n 5 ${OUTF} | grep TOT | sed 's/|//g'`
echo "<row>" >> ${tmpd}/xml/chksum.xml
for j in "${LN[@]}"
do
  echo "<entry>${j}</entry>" >> ${tmpd}/xml/chksum.xml
done
echo "</row></tfoot>" >> ${tmpd}/xml/chksum.xml

## write body
tail -n+5 ${OUTF} | grep -v TOT | grep -v "^--" | sed 's/|//g' > ${tmpd}/chk.tmp
echo "<tbody>" >> ${tmpd}/xml/chksum.xml
LINES=`cat ${tmpd}/chk.tmp | wc -l`
for i in `seq 1 ${LINES}`
do
  echo "<row>" >> ${tmpd}/xml/chksum.xml
  LN=()
  IFS=' ' read -a LN <<< `sed -n "${i}p" ${tmpd}/chk.tmp`
  for j in "${LN[@]}"
  do
    echo "<entry>${j}</entry>" >> ${tmpd}/xml/chksum.xml
  done
  echo "</row>" >> ${tmpd}/xml/chksum.xml
done
echo "</tbody>" >> ${tmpd}/xml/chksum.xml

## close table and section
echo "</tgroup>" >> ${tmpd}/xml/chksum.xml
echo "</table>" >> ${tmpd}/xml/chksum.xml
echo "</section>" >> ${tmpd}/xml/chksum.xml

## write the rest of the template
tail -n 1 ${XML_TEMPLATES}/procsum-chksum.xml >> ${tmpd}/xml/chksum.xml

## return status
exit ${STATUS}

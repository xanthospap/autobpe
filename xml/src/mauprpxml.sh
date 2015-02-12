#! /bin/bash

##
##  This script will populate the template file 'xml/procsum-mauprp.xml'
##  The changes made to the template, are:
##  1. a table will be inserted, with phase preprocessing statistics
##
##  This script is not meant to be used in 'standalone' mode. 
##+ It is ignited by 'ddprocess'
##
##  For this script to work, it is expected that the user provides a
##+ a MAUPRP summary file as command line arguments (this file is created
##+ by RNX2SNX via MAUPRPXTR, placed under the 'OUT' directory and named
##+ as MPR${YR2}${DOY}0.SUM
##
##  Expectations:
##  The following variables need to be set (i.e. exported by parent 
##+ process)
##   * tmpd
##   * XML_TEMPLATES
##  The (xml) template to be used:
##   * ${XML_TEMPLATES}/procsum-mauprp.xml
##
##  FEB-2015
##


## argv[1] - >mauprp.sum
if [ "$#" -ne 1 ]
then
  echo "Failed to pass MAUPRP summary file! Refusing to create mauprp.xml"
  exit 1
fi

## check the variables; thry should be set
if [ -z ${XML_TEMPLATES} ] || [ -z ${tmpd} ]
then
  echo "Either XML_TEMPLATES or tmpd variables not defined"
  echo "Refusing to create mauprp.xml"
  exit 1
fi

## check that the xml template exists
if ! test -f ${XML_TEMPLATES}/procsum-mauprp.xml
then
  echo "Failed to locate template ${XML_TEMPLATES}/procsum-mauprp.xml"
  echo "Refusing to create mauprp.xml"
  exit 1
fi

## copy the first part of the template
head -n 30 ${XML_TEMPLATES}/procsum-mauprp.xml > ${tmpd}/xml/mauprp.xml

## start the table
echo "<table><title>Pre-processing Information</title>" \
  >> ${tmpd}/xml/mauprp.xml
echo "<tgroup cols='15'>" >> ${tmpd}/xml/mauprp.xml

NCOLS=16
## actual number of baselines, ommiting header and footer
LINES=`cat $1 | wc -l`

## read and export the header
echo "<thead>" >> ${tmpd}/xml/mauprp.xml
echo "<row>" >> ${tmpd}/xml/mauprp.xml
IFS=' ' read -a LN <<< `sed -n '4p' ${1}`
j=0
for i in "${LN[@]}"
do
  if test "$j" -lt 15
  then
    echo "<entry>${i}</entry>" >> ${tmpd}/xml/mauprp.xml
  else
    echo "<entry>${i} ${LN[15]}</entry>" >> ${tmpd}/xml/mauprp.xml
    break
  fi
  let j=j+1
done
echo "</row>" >> ${tmpd}/xml/mauprp.xml
echo "</thead>" >> ${tmpd}/xml/mauprp.xml

## read and export the last line, i.e. summary
echo "<tfoot>" >> ${tmpd}/xml/mauprp.xml
IFS=' ' read -a LN <<< `sed -n "${LINES}p" ${1}`
if test "${#LN[@]}" -ne 13
then
  echo "Error reading last line of ${1}"
  echo "Expected 13 fields, found ${#LN[@]}. Refusing to create mauprp.xml"
  exit 1
fi
ITERATOR=0
j=0
for i in `seq 1 ${NCOLS}`
do
  if [ "${ITERATOR}" -ge 2 ] && [ "${ITERATOR}" -lt 5 ]
  then
    echo "<entry></entry>" >> ${tmpd}/xml/mauprp.xml
  else
    echo "<entry>${LN[${j}]}</entry>" >> ${tmpd}/xml/mauprp.xml
    let j=j+1
  fi
  let ITERATOR=ITERATOR+1
done
echo "</tfoot>" >> ${tmpd}/xml/mauprp.xml

## read and export the baseline lines
let LN=LINES-2
echo "<tbody>" >> ${tmpd}/xml/mauprp.xml
for l in `seq 6 $LN`
do
  echo "<row>" >> ${tmpd}/xml/mauprp.xml
  LN=()
  IFS=' ' read -a LN <<< `sed -n "${l}p" ${1}`
  ##  decide on the background color
  RMS="${LN[7]}"
  if test "${RMS}" -gt 20
  then
    BGCOLOR=CC0000
  else
    if test "${RMS}" -gt 17
    then
      BGCOLOR=CC6600
    else
      if test "${RMS}" -gt 15
      then
        BGCOLOR=CCCC00
      else
        BGCOLOR=CCFFFF
      fi
    fi
  fi
  if test "${RMS}" -lt 12
  then
    BGCOLOR=FFFFFF
  fi
  echo "<?dbhtml bgcolor='#${BGCOLOR}' ?><?dbfo bgcolor='#${BGCOLOR}' ?>" \
    >> ${tmpd}/xml/mauprp.xml
  for i in "${LN[@]}"
  do
    echo "<entry>${i}</entry>" >> ${tmpd}/xml/mauprp.xml
  done
  echo "</row>" >> ${tmpd}/xml/mauprp.xml
done
echo "</tbody>" >> ${tmpd}/xml/mauprp.xml

## close the table
echo "</tgroup>" >> ${tmpd}/xml/mauprp.xml
echo "</table>" >> ${tmpd}/xml/mauprp.xml

## copy last part of template
tail -n 2 ${XML_TEMPLATES}/procsum-mauprp.xml >> ${tmpd}/xml/mauprp.xml

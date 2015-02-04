#! /bin/bash

## argv[1] - >mauprp.sum
if [ "$#" -ne 1 ]
then
  echo "Failed to pass MAUPRP summary file! Refusing to create mauprp.xml"
  exit 1
fi

## write the forst part from the template
if [ -z ${XML_TEMPLATES} ] || [ -z ${tmpd} ]
then
  echo "Either XML_TEMPLATES or tmpd variables not defined"
  echo "Refusing to create mauprp.xml"
  exit 1
fi
head -n 6 ${XML_TEMPLATES}/procsum-mauprp.xml > ${tmpd}/xml/mauprp.xml

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

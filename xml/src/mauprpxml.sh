#! /bin/bash

## argv[1] - >mauprp.sum
if [ "$#" -ne 1 ]
then
  echo "Failed to pass MAUPRP summary file! Refusing to create mauprp.xml"
  exit 1
fi

NCOLS=16

## actual number of baselines, ommiting header and footer
LINES=`cat $1 | wc -l`

## read and export the header
echo "<thead>"
echo "<row>"
IFS=' ' read -a LN <<< `sed -n '4p' ${1}`
j=0
for i in "${LN[@]}"
do
  if test "$j" -lt 15
  then
    echo "<entry>${i}</entry>"
  else
    echo "<entry>${i} ${LN[15]}</entry>"
    break
  fi
  let j=j+1
done
echo "</row>"
echo "</thead>"

## read and export the last line, i.e. summary
echo "<tfoot>"
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
    echo "<entry></entry>"
  else
    echo "<entry>${LN[${j}]}</entry>"
    let j=j+1
  fi
  let ITERATOR=ITERATOR+1
done
echo "</tfoot>"

## read and export the baseline lines
let LN=LINES-2
echo "<tbody>"
for l in `seq 6 $LN`
do
  echo "<row>"
  LN=()
  IFS=' ' read -a LN <<< `sed -n "${l}p" ${1}`
  for i in "${LN[@]}"
  do
    echo "<entry>${i}</entry>"
  done
done
echo "</tbody>"

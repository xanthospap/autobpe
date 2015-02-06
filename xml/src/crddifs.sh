#! /bin/bash

## argv[1] -> xs.diffs (output from extract Stations.sh)
if test "$#" -ne 1
then
  echo "Failed to pass xs.diffs summary file! Refusing to create crddifs.xml"
  exit 1
else
  if ! test -f $1
  then
    echo "Failed to locate file ${1}. Refusing to create crddifs.xml"
    exit 1
  fi
fi

## write the forst part from the template
if [ -z ${XML_TEMPLATES} ] || [ -z ${tmpd} ]
then
  echo "Either XML_TEMPLATES or tmpd variables not defined"
  echo "Refusing to create mauprp.xml"
  exit 1
fi
head -n 5 ${XML_TEMPLATES}/procsum-crddifs.xml > ${tmpd}/xml/crddifs.xml
echo "created file ${tmpd}/xml/crddifs.xml"

## Compute some statistics
NUM_OF_STA=`cat $1 | wc -l`
AVERAGES=()
for i in `seq 1 $NUM_OF_STA`
do
    A=`awk '{ total += $i; count++ } END { printf "%+06.3f", total/count }' ${1}`
    AVERAGES+=(${A})
done

## start the table
echo "<table><title>Coordinate Differences in meters</title>" \
   >> ${tmpd}/xml/crddifs.xml
echo "<tgroup cols='7'>" >> ${tmpd}/xml/crddifs.xml

## write the header
echo "<thead>" >> ${tmpd}/xml/crddifs.xml
echo "<row>" >> ${tmpd}/xml/crddifs.xml
echo "<entry>Station</entry><entry>DX</entry><entry>DY</entry><entry>DZ</entry><entry>DN</entry><entry>DE</entry><entry>DU</entry>" \
  >> ${tmpd}/xml/crddifs.xml
echo "</row></thead>" >> ${tmpd}/xml/crddifs.xml

## write the footer
echo "<tfoot><row>" >> ${tmpd}/xml/crddifs.xml
echo "<entry>${NUM_OF_STA}</entry>" >> ${tmpd}/xml/crddifs.xml
for i in `seq 1 6`
do
  echo "<entry>${AVERAGES[i]}</entry>" >> ${tmpd}/xml/crddifs.xml
done
echo "</row></tfoot>" >> ${tmpd}/xml/crddifs.xml

## write the body
echo "<tbody>" >> ${tmpd}/xml/crddifs.xml
for i in `seq 1 ${NUM_OF_STA}`
do
  sed -n "${i}p" ${1} | awk '{print "<row><entry>"$1"_rh_"$3"_rh_"$4"_rh_"$5"_rh_"$6"_rh_"$7"_rh_"$8"</entry></row>"}' \
    | sed 's|_rh_|</entry><entry>|g' >> ${tmpd}/xml/crddifs.xml
done
echo "</tbody>" >> ${tmpd}/xml/crddifs.xml

## close the table
echo "</tgroup>" >> ${tmpd}/xml/crddifs.xml
echo "</table>" >> ${tmpd}/xml/crddifs.xml

## copy last part of template
tail -n 3 ${XML_TEMPLATES}/procsum-crddifs.xml >> ${tmpd}/xml/crddifs.xml

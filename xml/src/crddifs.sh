#! /bin/bash

##
##  This script will populate the template file 
##+ 'xml/procsum-crddifs.xml'
##  The changes made to the template, are:
##  1. a table will be inserted, with coordinate differences
##
##  This script is not meant to be used in 'standalone' mode.
##+ It is ignited by 'ddprocess'
##
##  Expectations:
##  The following variables need to be set (i.e. exported by parent 
##+  process)
##   * tmpd
##   * XML_TEMPLATES
##  The (xml) template to be used:
##   * ${XML_TEMPLATES}/procsum-crddifs.xml
##  The table to be paste in the xml, which is provided
##+ as command line argument (argv[1])
##   * ${tmpd}/xs.diffs
##  Final coordinate estimates file (i.e. .CRD) to extract
##+ processing flags. Provide as command line argument (argv[2])
##
##  Note that 'xs.diffs', i.e. the coordinate differences
##+ information is NOT created by this script, but run independently.
##+ It should exist for this script to run succesefuly. It is normally
##+ produced by a call to extractStations.
##
##  FEB-2015
##

## argv[1] -> xs.diffs (output from extract Stations.sh)
if test "$#" -ne 2
then
  echo "Failed to pass xs.diffs or coordinate summary file! Refusing to create crddifs.xml"
  exit 1
else
  if ! test -f $1
  then
    echo "Failed to locate file ${1}. Refusing to create crddifs.xml"
    exit 1
  fi
fi

## write the first part from the template
if [ -z ${XML_TEMPLATES} ] || [ -z ${tmpd} ]
then
  echo "Either XML_TEMPLATES or tmpd variables not defined"
  echo "Refusing to create mauprp.xml"
  exit 1
fi
head -n 15 ${XML_TEMPLATES}/procsum-crddifs.xml > ${tmpd}/xml/crddifs.xml

FCF=$2
if ! test -f $FCF
then
  echo "Could not find coordinate file $FCF"
  echo "Refusing to make crddfifs.xml"
  exit 1
fi

## re-write xs.diffs with meters translated to mm ommiting the part 'diffs:'
cat $1 | awk '{printf "%4s %+05.1f %+05.1f %+05.1f %+05.1f %+05.1f %+05.1f\n",$1,$3*1000,$4*1000,$5*1000,$6*1000,$7*1000,$8*1000}' \
  > ${tmpd}/xs-mm.diffs
## add the flags at a last column
NUM_OF_STA=`cat ${tmpd}/xs-mm.diffs | wc -l`
for i in `seq 1 ${NUM_OF_STA}`
do
  LN=`sed -n "${i}p" ${tmpd}/xs-mm.diffs`
  sta=`sed -n "${i}p" ${tmpd}/xs-mm.diffs | awk '{print $1}'`
  FLAG=U
  FLAG=`grep -i ${sta} ${FCF} | awk '{print substr ($0,70,10)}' | sed 's/ //g'`
  sed -i "s/${LN}/${LN} ${FLAG}/g" ${tmpd}/xs-mm.diffs
done
II=${tmpd}/xs-mm.diffs

## find the station with max overall differences
MAX_W=`awk 'BEGIN {maxds=-100} { if ($8 == "W" ) {ds=sqrt($2*$2+$3*$3+$4*$4); if (ds > maxds) {maxds=ds; sta=$1}} } END {print sta}' ${tmpd}/xs-mm.diffs`
MAX_A=`awk 'BEGIN {maxds=-100} { if ($8 == "A" ) {ds=sqrt($2*$2+$3*$3+$4*$4); if (ds > maxds) {maxds=ds; sta=$1}} } END {print sta}' ${tmpd}/xs-mm.diffs`
## print that in xml format
echo "<important><para>Stations with biggest discrepancies: " >> ${tmpd}/xml/crddifs.xml
echo "<itemizedlist mark='opencircle'>" >> ${tmpd}/xml/crddifs.xml
echo "<listitem><para>from those used in Reference Frame Allignment : $MAX_W </para></listitem>" >> ${tmpd}/xml/crddifs.xml
echo "<listitem><para>from those processed as &ldquo;free&rdquo; : $MAX_A </para></listitem>" >> ${tmpd}/xml/crddifs.xml
echo "</itemizedlist></para></important>" >> ${tmpd}/xml/crddifs.xml

## Compute some statistics
AVERAGES=()
RMSS=()
for i in `seq 2 7`
do
    A=`awk -v c="$i" '{ total += $c; count++ } END { printf "%+06.1f", total/count }' ${II}`
    ## B=`awk -v c="$i" '{ total += ($c)*($c); count++ } END { printf "%+06.1f", total/sqrt(count-1) }' ${II}`
    B=`awk -v c="$i" '{sum += $c; sumsq += ($c)^2; count++} END {printf ("%4.1f",sqrt((sumsq-sum^2/count)/count))}' ${II}`
    AVERAGES+=(${A})
    RMSS+=(${B})
done

## start the table
echo "<table><title>Coordinate Differences (in mm) </title>" \
   >> ${tmpd}/xml/crddifs.xml
echo "<tgroup cols='8'>" >> ${tmpd}/xml/crddifs.xml

## write the header
echo "<thead>" >> ${tmpd}/xml/crddifs.xml
echo "<row>" >> ${tmpd}/xml/crddifs.xml
echo "<entry>Station</entry><entry>DX</entry><entry>DY</entry><entry>DZ</entry><entry>DN</entry><entry>DE</entry><entry>DU</entry><entry>Flag<footnote><para>This is the same flag used in the <xref linkend='rinex_table' /></para></footnote></entry>" \
  >> ${tmpd}/xml/crddifs.xml
echo "</row></thead>" >> ${tmpd}/xml/crddifs.xml

## write the footer
echo "<tfoot><row>" >> ${tmpd}/xml/crddifs.xml
echo "<entry>${NUM_OF_STA}</entry>" >> ${tmpd}/xml/crddifs.xml
for i in `seq 0 5`
do
  echo "<entry>${AVERAGES[i]} (${RMSS[i]})</entry>" >> ${tmpd}/xml/crddifs.xml
done
echo "</row></tfoot>" >> ${tmpd}/xml/crddifs.xml

## write the body
echo "<tbody>" >> ${tmpd}/xml/crddifs.xml
for i in `seq 1 ${NUM_OF_STA}`
do
  sta=`sed -n "${i}p" ${II} | awk '{print $1}'`
  flag=
  FLAG=`grep -i ${sta} ${FCF} | awk '{print substr ($0,70,10)}' | sed 's/ //g'`
  if test ${FLAG} == "A"; then flag="A (free)"; fi
  if test ${FLAG} == "W"; then flag="W (used for allignment)"; fi
  if test ${FLAG} == "F"; then flag="F (fixed)"; fi
  sed -n "${i}p" ${II} | awk -v f="$flag" '{print "<row><entry>"$1"_rh_"$2"_rh_"$3"_rh_"$4"_rh_"$5"_rh_"$6"_rh_"$7"_rh_"f"</entry></row>"}' \
    | sed 's|_rh_|</entry><entry>|g' >> ${tmpd}/xml/crddifs.xml
done
echo "</tbody>" >> ${tmpd}/xml/crddifs.xml

## close the table
echo "</tgroup>" >> ${tmpd}/xml/crddifs.xml
echo "</table>" >> ${tmpd}/xml/crddifs.xml

## copy last part of template
tail -n 3 ${XML_TEMPLATES}/procsum-crddifs.xml >> ${tmpd}/xml/crddifs.xml

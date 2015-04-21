#! /bin/bash

##
## Script to compile docbook after a sucesseful run of ddprocess
##
## ARGV[1] = file with variables to be sourced
##

if test "$#" -ne 1
then
    echo "ERROR. Usage makedocbook <source_file>"
    exit 1
fi

## Define the source file
SOURCE_FILE="${1}"
if ! test -f $SOURCE_FILE
then
    echo "ERROR. Failed to locate source file for xml output"
    exit 1
fi

## Source the variables
export CRD_META=`awk -F"=" '/CRD_META/ {print $2}' ${SOURCE_FILE}`
export tmpd=`awk -F"=" '/tmpd/ {print $2}' ${SOURCE_FILE}`
export XML_TEMPLATES=`awk -F"=" '/XML_TEMPLATES/ {print $2}' ${SOURCE_FILE}`
export V_DOY=`awk -F"=" '/V_DOY/ {print $2}' ${SOURCE_FILE}`
export V_TROPO=`awk -F"=" '/V_TROPO/ {print $2}' ${SOURCE_FILE}`
export V_TODAY=`awk -F"=" '/V_TODAY/ {print $2}' ${SOURCE_FILE}`
export V_DATE_PROCCESSED=`awk -F"=" '/V_DATE_PROCCESSED/ {print $2}' ${SOURCE_FILE}`
export V_NETWORK=`awk -F"=" '/V_NETWORK/ {print $2}' ${SOURCE_FILE}`
export V_USER_N=`awk -F"=" '/V_USER_N/ {print $2}' ${SOURCE_FILE}`
export V_HOST_N=`awk -F"=" '/V_HOST_N/ {print $2}' ${SOURCE_FILE}`
export V_SYSTEM_INFO=`awk -F"=" '/V_SYSTEM_INFO/ {print $2}' ${SOURCE_FILE}`
export V_COMMAND=`awk -F"=" '/V_COMMAND/ {print $2}' ${SOURCE_FILE}`
export V_SCRIPT=`awk -F"=" '/V_SCRIPT/ {print $2}' ${SOURCE_FILE}`
export V_BERN_INFO=`awk -F"=" '/V_BERN_INFO/ {print $2}' ${SOURCE_FILE}`
export V_GEN_UPD=`awk -F"=" '/V_GEN_UPD/ {print $2}' ${SOURCE_FILE}`
export V_ID=`awk -F"=" '/V_ID/ {print $2}' ${SOURCE_FILE}`
export PCF_FILE=`awk -F"=" '/PCF_FILE/ {print $2}' ${SOURCE_FILE}`
export V_ELEVATION=`awk -F"=" '/V_ELEVATION/ {print $2}' ${SOURCE_FILE}`
export V_SOL_TYPE=`awk -F"=" '/V_SOL_TYPE/ {print $2}' ${SOURCE_FILE}`
export V_AC_CENTER=`awk -F"=" '/V_AC_CENTER/ {print $2}' ${SOURCE_FILE}`
export V_SAT_SYS=`awk -F"=" '/V_SAT_SYS/ {print $2}' ${SOURCE_FILE}`
export V_STA_PER_CLU=`awk -F"=" '/V_STA_PER_CLU/ {print $2}' ${SOURCE_FILE}`
export V_UPDATE_CRD=`awk -F"=" '/V_UPDATE_CRD/ {print $2}' ${SOURCE_FILE}`
export V_UPDATE_STA=`awk -F"=" '/V_UPDATE_STA/ {print $2}' ${SOURCE_FILE}`
export V_UPDATE_NET=`awk -F"=" '/V_UPDATE_NET/ {print $2}' ${SOURCE_FILE}`
export V_MAKE_PLOTS=`awk -F"=" '/V_MAKE_PLOTS/ {print $2}' ${SOURCE_FILE}`
export V_SAVE_DIR=`awk -F"=" '/V_SAVE_DIR/ {print $2}' ${SOURCE_FILE}`
export V_ATX=`awk -F"=" '/V_ATX/ {print $2}' ${SOURCE_FILE}`
export V_LOG=`awk -F"=" '/V_LOG/ {print $2}' ${SOURCE_FILE}`
export V_YEAR=`awk -F"=" '/V_YEAR/ {print $2}' ${SOURCE_FILE}`
export AVAIL_RNX=`awk -F"=" '/AVAIL_RNX/ {print $2}' ${SOURCE_FILE}`
export V_IGS_RNX=`awk -F"=" '/V_IGS_RNX/ {print $2}' ${SOURCE_FILE}`
export V_EPN_RNX=`awk -F"=" '/V_EPN_RNX/ {print $2}' ${SOURCE_FILE}`
export V_REG_RNX=`awk -F"=" '/V_REG_RNX/ {print $2}' ${SOURCE_FILE}`
export V_RNX_MIS=`awk -F"=" '/V_RNX_MIS/ {print $2}' ${SOURCE_FILE}`
export V_RNX_TOT=`awk -F"=" '/V_RNX_TOT/ {print $2}' ${SOURCE_FILE}`
export ORB_META=`awk -F"=" '/ORB_META/ {print $2}' ${SOURCE_FILE}`
export ERP_META=`awk -F"=" '/ERP_META/ {print $2}' ${SOURCE_FILE}`
export ION_META=`awk -F"=" '/ION_META/ {print $2}' ${SOURCE_FILE}`
export TRO_META=`awk -F"=" '/TRO_META/ {print $2}' ${SOURCE_FILE}`
export DCB_META=`awk -F"=" '/DCB_META/ {print $2}' ${SOURCE_FILE}`
export SCRIPT_SECOND=`awk -F"=" '/SCRIPT_SECONDS/ {print $2}' ${SOURCE_FILE}`
export VBPE_SECONDS=`awk -F"=" '/VBPE_SECONDS/ {print $2}' ${SOURCE_FILE}`
export V_MONTH=`awk -F"=" '/V_MONTH/ {print $2}' ${SOURCE_FILE}`
export V_DAY_OF_MONTH=`awk -F"=" '/V_DAY_OF_MONTH/ {print $2}' ${SOURCE_FILE}`
export SOL_ID=`awk -F"=" '/V_SOL_ID/ {print $2}' ${SOURCE_FILE}`

if ! test -d $tmpd
then
    echo "ERROR. Failed to locate temp folder. Unable to create xml output"
    echo "Possible failure of loading the source file"
    exit 1
fi

echo "Making XML DocBook ..."
mkdir -p ${tmpd}/xml/figures

DOY="${V_DOY}"
YEAR="${V_YEAR}"
YR2=${YEAR:2:2}
CAMPAIGN="${V_NETWORK}"
MONTH="${V_MONTH}"
DOM="${V_DAY_OF_MONTH}"

## sat-sys identifier for script plot-amb-sum
if [ "$SAT_SYS" == "gps" ] || [ "$SAT_SYS" == "GPS" ]
then
    sats=gps
else
    sats="gps,glo,mixed"
fi
## Make ambiguity plot
echo "  Making ambiguity plot (plot-amb-sum)"
if ! /usr/local/bin/plot-amb-sum \
    --ambiguity-file=${P}/${CAMPAIGN^^}/OUT/AMB${YR2}${DOY}0.SUM \
    --output-file=${tmpd}/xml/figures/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps \
    --satellite-system="${sats}"
then
    echo "ERROR. Failed to create ambiguity plot! Unable to create xml output"
    echo "Command was: [/usr/local/bin/plot-amb-sum \
        --ambiguity-file=${P}/${CAMPAIGN^^}/OUT/AMB${YR2}${DOY}0.SUM \
        --output-file=${tmpd}/xml/figures/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps \
        --satellite-system=${sats}]"
    exit 1
fi
## convert ps to png (ambiguity plot)
amb_png=${tmpd}/xml/figures/ambiguity.png
/usr/lib/gmt/bin/ps2raster \
    ${tmpd}/xml/figures/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps -Tg -P -F"${amb_png%%.png}" \
    &>/dev/null
if ! test -f $amb_png
then
    ## TODO This often fails. Why ??
    echo "Failed to convert ps image to png for ambiguity plot. Input file: \
        ${tmpd}/xml/figures/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps"
    echo "Unable to create xml output"
    ## exit 1
fi

##  note that here we are interested in all stations NOT just the ones
##+ to be updated. This file should have been created by ddprocess
echo "  Extracting station diffs (extractStations)"
if ! test -f ${tmpd}/all.stations
then
    echo "ERROR. File ${tmpd}/all.stations not found. Should have been"
    echo "created by ddprocess."
    exit 1
fi
/usr/local/bin/extractStations \
    --station-file ${tmpd}/all.stations \
    --solution-summary ${P}/${CAMPAIGN^^}/OUT/${SOL_ID}${YR2}${DOY}0.OUT \
    --save-dir ${STA_TS_DIR} \
    --quiet \
    --only-report \
    1>${tmpd}/xs.diffs
cat ${tmpd}/xs.diffs | grep -v "##" > ${tmpd}/xs.diffs.tmp
mv ${tmpd}/xs.diffs.tmp ${tmpd}/xs.diffs

## Create xml table for the ambiguity resolution info
echo "  Creating ambiguity resolution xml table (ambsum2xml)"
if ! test -f ${P}/${CAMPAIGN}/OUT/AMB${YR2}${DOY}0.SUM
then
    echo "ERROR. Ambiguity summary file not found"
    echo "Missing: ${P}/${CAMPAIGN}/OUT/AMB${YR2}${DOY}0.SUM"
    exit 1
fi
/usr/local/bin/ambsum2xml \
  ${P}/${CAMPAIGN}/OUT/AMB${YR2}${DOY}0.SUM \
  1>${tmpd}/amb.xml

## Create xml output for available rinex
echo "  Creating rinex xml table/info (rnxsum2xml)"
if ! test -f ${tmpd}/rnx.av
then
    echo "ERROR. File ${tmpd}/rnx.av found. Should have been"
    echo "created by ddprocess."
    exit 1
fi
if ! /usr/local/bin/rnxsum2xml \
  ${CAMPAIGN} \
  ${tmpd}/rnx.av \
  ${tmpd}/xs.diffs \
  ${YEAR} \
  ${DOY} \
  ${MONTH} \
  ${DOM} \
  ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
  1>${tmpd}/rnx.xml
then
    echo "ERROR. Failed to make rinex xml output."
    echo "Command [/usr/local/bin/rnxsum2xml \
        ${CAMPAIGN} \
        ${tmpd}/rnx.av \
        ${tmpd}/xs.diffs \
        ${YEAR} \
        ${DOY} \
        ${MONTH} \
        ${DOM} \
        ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
        1>${tmpd}/rnx.xml"
    exit 1
fi

## Run plotsolsta to make maps for processed stations
SOLT=${V_SOL_TYPE:0:1}
echo "  Making maps for processed stations/baselines (plotsolsta)"
if ! /home/bpe2/src/autobpe/utl/plotsolsta.sh \
    ${YEAR} \
    ${DOY} \
    ${P}/${CAMPAIGN}/OUT/AMB${YR2}${DOY}0.SUM \
    ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
    ${P}/${CAMPAIGN}/OUT/${SOL_ID}${YR2}${DOY}0.OUT \
    ${CAMPAIGN} \
    ${SOLT,,} \
    ${tmpd}
then
    echo "ERROR. Failed to run plotsolsta."
    echo "Command [/home/bpe2/src/autobpe/utl/plotsolsta.sh ${YEAR} ${DOY} \
        ${P}/${CAMPAIGN}/OUT/${SOL_ID}${YR2}${DOY}0.SUM \
        ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
        ${P}/${CAMPAIGN}/OUT/${SOL_ID}${YR2}${DOY}0.OUT \
        ${CAMPAIGN} \
        ${SOL_TYPE} \
        ${tmpd}"
    exit 1
fi

echo "  Compiling individual xml chapters"
## evaluate xml templates
for i in procsum-main.xml \
    procsum-info.xml \
    procsum-options.xml
do
    if ! test -f ${XML_TEMPLATES}/${i}
    then
        echo "ERROR. Missing xml template ${i}"
        echo "Cannot find it in ${XML_TEMPLATES}/"
        exit 1
    fi
done
eval "echo \"$(< ${XML_TEMPLATES}/procsum-main.xml)\"" \
    > ${tmpd}/xml/main.xml
eval "echo \"$(< ${XML_TEMPLATES}/procsum-info.xml)\"" \
    > ${tmpd}/xml/info.xml
eval "echo \"$(< ${XML_TEMPLATES}/procsum-options.xml)\"" \
    > ${tmpd}/xml/options.xml

## Create the individual xml files (chapters)
echo "    Creating options.xml"
if ! /home/bpe2/src/autobpe/xml/src/makeoptionsxml.sh
then
    echo "Failed to create options.xml; No docbook created"
    exit 1
fi

echo "    Creating rinex.xml"
if ! /home/bpe2/src/autobpe/xml/src/makerinexxml.sh
then
    echo "Failed to create rinex.xml; No docbook created"
    exit 1
fi

echo "    Creating ambiguities.xml"
if ! /home/bpe2/src/autobpe/xml/src/makeambxml.sh
then
    echo "Failed to create ambiguities.xml; No docbook created"
    exit 1
fi

echo "    Creating mauprp.xml"
if ! /home/bpe2/src/autobpe/xml/src/mauprpxml.sh \
    ${P}/${CAMPAIGN^^}/OUT/MPR${YR2}${DOY}0.SUM
then
    echo "Failed to create mauprp.xml; No docbook created"
    exit 1
fi

echo "    Creating crddifs.xml"
if ! /home/bpe2/src/autobpe/xml/src/crddifs.sh \
    ${tmpd}/xs.diffs \
    ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD
then
    echo "Failed to create crddifs.xml; No docbook created"
    exit 1
fi

echo "    Creating chksum.xml"
if ! /home/bpe2/src/autobpe/xml/src/chksumxml.sh \
    ${P}/${CAMPAIGN^^}/OUT/CHK${YR2}${DOY}0.OUT
then
    echo "Failed to create chksum.xml; No docbook created"
    exit 1
fi

echo "    Creating savedfiles.xml"
if ! /home/bpe2/src/autobpe/xml/src/savedfiles.sh \
    ${tmpd}/saved.files \
    ${tmpd}/ts.update ${tmpd}/crd.update
then
    echo "Failed to create savedfiles.xml; No docbook created"
    exit 1
fi

## Individual files done. No compile the docbook
echo "  Runing xsltproc to compile the docbook"
mkdir ${tmpd}/xml/html

if cd ${tmpd}/xml && \
    xsltproc /usr/share/xml/docbook/stylesheet/nwalsh/xhtml/chunk.xsl main.xml
then
    :
else
    echo "ERROR. Failed to compile the DocBook"
    exit 1
fi

mv ${tmpd}/xml/*.html ${tmpd}/xml/html/ 

mkdir ${tmpd}/xml/html/figures

cp ${amb_png} ${tmpd}/xml/html/figures/ambiguity.png

## All done
echo "XML done. DocBook created at ${tmpd}/xml/html"
exit 0

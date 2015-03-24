V_TODAY=`date`
V_DATE_PROCCESSED=`echo "${YEAR}-${MONTH}-${DOM} (DOY: ${DOY})"`
V_NETWORK=${CAMPAIGN}
V_USER_N=`echo $USER`
V_HOST_N=`echo $HOSTNAME`
V_SYSTEM_INFO=`uname -a`
V_SCRIPT="${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
V_COMMAND=${XML_SENTENCE}
V_BERN_INFO=`cat /home/bpe2/bern52/info/bern52_release. | tail -1`
V_GEN_UPD=`cat /home/bpe2/bern52/info/bern52_GEN_upd. | tail -1`
V_ID="${SOL_ID} (preliminery: ${SOL_ID%?}P, size-reduced: ${SOL_ID%?}R)"
PCF_FILE=${PCF_FILE}
V_ELEVATION=${ELEV}
V_TROPO=VMF1
if test "${SOL_TYPE}" == "f"
then
    V_SOL_TYPE=FINAL
else
    V_SOL_TYPE="RAPID/ULTRA_RAPID"
fi
V_AC_CENTER=${AC^^}
V_SAT_SYS=${SAT_SYS}
V_STA_PER_CLU=${STA_PER_CLU}
V_UPDATE_CRD=${UPD_CRD}
V_UPDATE_STA=${UPD_STA}
V_UPDATE_NET=${UPD_NTW}
V_MAKE_PLOTS=${MAKE_PLOTS}
V_SAVE_DIR=${SAVE_DIR}
V_ATX=${TABLES}/pcv/${PCV}.${CLBR}
V_LOG=${LOGFILE}
V_YEAR=${YEAR}
V_DOY=${DOY}
AVAIL_RNX="${#RINEX_AV[@]}"
V_IGS_RNX="${#AVIGS[@]}"
V_EPN_RNX="${#AVEPN[@]}"
V_REG_RNX="${#AVREG[@]}"
V_RNX_MIS="${#RINEX_MS[@]}"
V_RNX_TOT="${#STATIONS[@]}"
CRD_META=${tmpd}/crd.meta
SCRIPT_SECONDS=$(($STOP_PROCESS_SECONDS-$START_PROCESS_SECONDS))
SCRIPT_SECONDS=`echo $SCRIPT_SECONDS | \
    awk '{printf "%10i seconds (or %5i min and %2i sec)",$1,$1/60.0,$1%60}'`
BPE_SECONDS=$(($STOP_BPE_SECONDS-$START_BPE_SECONDS))
BPE_SECONDS=`echo $BPE_SECONDS | \
    awk '{printf "%10i seconds (or %5i min and %2i sec)",$1,$1/60.0,$1%60}'`
{
echo "export CRD_META=${CRD_META}"
echo "export tmpd=${tmpd}"
echo "export XML_TEMPLATES=${XML_TEMPLATES}"
echo "export V_DOY=${V_DOY}"
echo "export V_TROPO=${V_TROPO}"
echo "export V_TODAY=${V_TODAY}"
echo "export V_DATE_PROCCESSED=${V_DATE_PROCCESSED}"
echo "export V_NETWORK=${V_NETWORK}"
echo "export V_USER_N=${V_USER_N}"
echo "export V_HOST_N=${V_HOST_N}"
echo "export V_SYSTEM_INFO=${V_SYSTEM_INFO}"
echo "export V_COMMAND=${V_COMMAND}"
echo "export V_SCRIPT=${V_SCRIPT}"
echo "export V_BERN_INFO=${V_BERN_INFO}"
echo "export V_GEN_UPD=${V_GEN_UPD}"
echo "export V_ID=${V_ID}"
echo "export PCF_FILE=${PCF_FILE}"
echo "export V_ELEVATION=${V_ELEVATION}"
echo "export V_SOL_TYPE=${V_SOL_TYPE}"
echo "export V_AC_CENTER=${V_AC_CENTER}"
echo "export V_SAT_SYS=${V_SAT_SYS}"
echo "export V_STA_PER_CLU=${V_STA_PER_CLU}"
echo "export V_UPDATE_CRD=${V_UPDATE_CRD}"
echo "export V_UPDATE_STA=${V_UPDATE_STA}"
echo "export V_UPDATE_NET=${V_UPDATE_NET}"
echo "export V_MAKE_PLOTS=${V_MAKE_PLOTS}"
echo "export V_SAVE_DIR=${V_SAVE_DIR}"
echo "export V_ATX=${V_ATX}"
echo "export V_LOG=${V_LOG}"
echo "export V_YEAR=${V_YEAR}"
echo "export AVAIL_RNX=${AVAIL_RNX}"
echo "export V_IGS_RNX=${V_IGS_RNX}"
echo "export V_EPN_RNX=${V_EPN_RNX}"
echo "export V_REG_RNX=${V_REG_RNX}"
echo "export V_RNX_MIS=${V_RNX_MIS}"
echo "export V_RNX_TOT=${V_RNX_TOT}"
echo "export ORB_META=${ORB_META}"
echo "export ERP_META=${ERP_META}"
echo "export ION_META=${ION_META}"
echo "export TRO_META=${TRO_META}"
echo "export DCB_META=${DCB_META}"
echo "export SCRIPT_SECONDS=${SCRIPT_SECONDS}"
echo "export BPE_SECONDS=${BPE_SECONDS}"
} >> ${tmpd}/variables


echo "Making XML DocBook"
mkdir -p ${tmpd}/xml/figures

source ${tmpd}/variables

## sat-sys identifier for script plot-amb-sum
if test "$SAT_SYS" == "gps"
then
    sats=gps
else
    sats="gps,glo,mixed"
fi
## Make ambiguity plot
/usr/local/bin/plot-amb-sum \
    --ambiguity-file=${P}/${CAMPAIGN^^}/OUT/AMB${YR2}${DOY}0.SUM \
    --output-file=${tmpd}/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps \
    --satellite-system="${sats}"

## convert ps to png (ambiguity plot)
amb_png=${tmpd}/xml/figures/ambiguity.png
/usr/lib/gmt/bin/ps2raster \
    ${tmpd}/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps -Tg -P
mv ${tmpd}/${CAMPAIGN,,}${YEAR}${DOY}-amb.png ${amb_png}

##  note that here we are interested in all stations NOT just the ones
##+ to be updated
>${tmpd}/xml/all.stations
for i in ${STATIONS[@]}
do
  echo -ne "$i " >> ${tmpd}/all.stations
done
/usr/local/bin/extractStations \
    --station-file ${tmpd}/all.stations \
    --solution-summary ${P}/${CAMPAIGN^^}/OUT/${SOL_ID}${YR2}${DOY}0.OUT \
    --save-dir ${STA_TS_DIR} \
    --quiet \
    --only-report \
    1>${tmpd}/xs.diffs

/usr/local/bin/ambsum2xml \
  ${P}/${CAMPAIGN}/OUT/AMB${YR2}${DOY}0.SUM \
  1>${tmpd}/amb.xml

>${tmpd}/rnx.av
for i in "${RINEX_AV[@]}"
do
  echo -ne "${i} " >> ${tmpd}/rnx.av
done
/usr/local/bin/rnxsum2xml \
  ${CAMPAIGN} \
  ${tmpd}/rnx.av \
   ${tmpd}/xs.diffs \
  ${YEAR} \
  ${DOY} \
  ${MONTH} \
  ${DOM} \
  ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
  1>/${tmpd}/rnx.xml

/home/bpe2/src/autobpe/utl/plotsolsta.sh ${YEAR} ${DOY} \
  ${P}/${CAMPAIGN}/OUT/${SOL_ID}${YR2}${DOY}0.SUM \
  ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
  ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.OUT \
  ${CAMPAIGN} \
  ${SOL_TYPE} \
  ${tmpd}

eval "echo \"$(< ${XML_TEMPLATES}/procsum-main.xml)\"" \
    > ${tmpd}/xml/main.xml
eval "echo \"$(< ${XML_TEMPLATES}/procsum-info.xml)\"" \
    > ${tmpd}/xml/info.xml
eval "echo \"$(< ${XML_TEMPLATES}/procsum-options.xml)\"" \
    > ${tmpd}/xml/options.xml

echo "Creating options.xml"
if ! test /home/bpe2/src/autobpe/xml/src/makeoptionsxml.sh
then
    echo "Failed to create options.xml; No docbook created"
    exit 1
fi

echo "Creating rinex.xml"
if ! test /home/bpe2/src/autobpe/xml/src/makerinexxml.sh
then
    echo "Failed to create rinex.xml; No docbook created"
    exit 1
fi

echo "Creating ambiguities.xml"
if ! test /home/bpe2/src/autobpe/xml/src/makeambxml.sh
then
    echo "Failed to create ambiguities.xml; No docbook created"
    exit 1
fi

echo "Creating mauprp.xml"
if ! test /home/bpe2/src/autobpe/xml/src/mauprpxml.sh \
    ${P}/${CAMPAIGN^^}/OUT/MPR${YR2}${DOY}0.SUM
then
    echo "Failed to create mauprp.xml; No docbook created"
    exit 1
fi

echo "Creating crddifs.xml"
if ! test /home/bpe2/src/autobpe/xml/src/crddifs.sh \
    ${tmpd}/xs.diffs \
    ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD
then
    echo "Failed to create crddifs.xml; No docbook created"
    exit 1
fi

echo "Creating chksum.xml"
if ! test /home/bpe2/src/autobpe/xml/src/chksumxml.sh \
    ${P}/${CAMPAIGN^^}/OUT/CHK${YR2}${DOY}0.OUT
then
    echo "Failed to create chksum.xml; No docbook created"
    exit 1
fi

echo "Creating savedfiles.xml"
if ! test /home/bpe2/src/autobpe/xml/src/savedfiles.sh \
    ${tmpd}/saved.files \
    ${tmpd}/ts.update ${tmpd}/crd.update
then
    echo "Failed to create savedfiles.xml; No docbook created"
    exit 1
fi

mkdir ${tmpd}/xml/html
cd ${tmpd}/xml/ && xsltproc /usr/share/xml/docbook/stylesheet/nwalsh/xhtml/chunk.xsl main.xml
mv ${tmpd}/xml/*.html ${tmpd}/xml/html/
mkdir ${tmpd}/xml/html/figures
cp ${amb_png} ${tmpd}/xml/html/figures/ambiguity.png

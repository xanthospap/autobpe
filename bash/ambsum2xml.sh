#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : ambsum2xml.sh
                           NAME=ambsum2xml
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : ambsum2xml AMBIGUITYFILE
## exit code(s)          : 0 -> sucess
##                         1 -> failure
## discription           : This file will read an ambiguity summary file and report
##                         the information in XML format (i.e. as an XML table).
##                         The format of the summary file is very stringent and applies
##                         to output from Bernese v5.2 RNX2SNX output.
##                         The xml output is directed to stdout.
## uses                  : sed, head, read, awk, block_amb_read
## needs                 : 
## notes                 : You can see an ambiguity summary file at :
##                         ftp://bpe2@147.102.110.69~/templates/dd/AMBYYDDD0.SUM
## TODO                  : DIRECT L1 / L2 not tested
##                         MaxRMS L3 in QIF is not reported
##                         Only total number of baselines and total average baseline length reported
## WARNING               : No help message provided.
## detailed update list  : 
                           LAST_UPDATE=JAN-20145
##
################################################################################

# //////////////////////////////////////////////////////////////////////////////
# DISPLAY VERSION
# //////////////////////////////////////////////////////////////////////////////
function dversion {
  echo "${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
  exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# WATCHOUT FOR THE -v OPTION
# //////////////////////////////////////////////////////////////////////////////
if test "${1}" == "-v" ; then dversion ; exit 0; fi

AMBFILE=${1}
if ! test -f ${AMBFILE}; then
  echo "***ERROR! Ambiguity file provided is not valid : $AMBFILE"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# EXTRACT INFORMATION FOR ALL METHODS USING A TEMP FILE
# //////////////////////////////////////////////////////////////////////////////

## read and write the Code-Based WL
if ! /usr/local/bin/block_amb_read --summary-file=$AMBFILE --method=cbwl &>.tmp.cwl ; then
  echo "***ERROR! Failed to read Code-Based WL from file : $AMBFILE"
  exit 254
fi

## read and write the Code-Based NL
if ! /usr/local/bin/block_amb_read --summary-file=$AMBFILE --method=cbnl &>.tmp.cnl ; then
  echo "***ERROR! Failed to read Code-Based NL from file : $AMBFILE"
  exit 254
fi

## read and write the Phase-Based WL
if ! /usr/local/bin/block_amb_read --summary-file=$AMBFILE --method=pbwl &>.tmp.pwl ; then
  echo "***ERROR! Failed to read Phase-Based WL from file : $AMBFILE"
  exit 254
fi

## read and write the Phase-Based NL
if ! /usr/local/bin/block_amb_read --summary-file=$AMBFILE --method=pbnl &>.tmp.pnl ; then
  echo "***ERROR! Failed to read Phase-Based NL from file : $AMBFILE"
  exit 254
fi

## read and write the QIF
if ! /usr/local/bin/block_amb_read --summary-file=$AMBFILE --method=qif &>.tmp.qif ; then
  echo "***ERROR! Failed to read QIF from file : $AMBFILE"
  exit 254
fi

## read and write the DIRECT
if ! /usr/local/bin/block_amb_read --summary-file=$AMBFILE --method=dir &>.tmp.dir ; then
  echo "***ERROR! Failed to read DIRECT L1/L2 from file : $AMBFILE"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# STATISTICS & VERIFICATION
# //////////////////////////////////////////////////////////////////////////////
NO_CWL=`cat .tmp.cwl | grep "<!-- ## Number of baselines" | awk '{print $7}'`
NO_CNL=`cat .tmp.cnl | grep "<!-- ## Number of baselines" | awk '{print $7}'`
NO_PWL=`cat .tmp.pwl | grep "<!-- ## Number of baselines" | awk '{print $7}'`
NO_PNL=`cat .tmp.pnl | grep "<!-- ## Number of baselines" | awk '{print $7}'`
NO_QIF=`cat .tmp.qif | grep "<!-- ## Number of baselines" | awk '{print $7}'`
NO_DIR=`cat .tmp.dir | grep "<!-- ## Number of baselines" | awk '{print $7}'`

if test ${NO_CWL} -ne ${NO_CNL} ; then
  echo "***ERROR! Code-Based ambiguites unequal"
  exit 254
fi

if test ${NO_PWL} -ne ${NO_PNL} ; then
  echo "***ERROR! Phase-Based ambiguites unequal"
  exit 254
fi

LN_CWL=`cat .tmp.cwl | grep "<!-- ## Mean baseline length" | awk '{print $7}'`
LN_CNL=`cat .tmp.cnl | grep "<!-- ## Mean baseline length" | awk '{print $7}'`
LN_PWL=`cat .tmp.pwl | grep "<!-- ## Mean baseline length" | awk '{print $7}'`
LN_PNL=`cat .tmp.pnl | grep "<!-- ## Mean baseline length" | awk '{print $7}'`
LN_QIF=`cat .tmp.qif | grep "<!-- ## Mean baseline length" | awk '{print $7}'`
LN_DIR=`cat .tmp.dir | grep "<!-- ## Mean baseline length" | awk '{print $7}'`

## total number of baselines
TOT_BSL=`python -c "print ( ${NO_CWL}+${NO_PWL}+${NO_QIF}+${NO_DIR})"`
## average baseline length
MEAN_LENGTH=`python -c "print ( (${NO_CWL}/${TOT_BSL})*${LN_CWL} + \
                                (${NO_PWL}/${TOT_BSL})*${LN_PWL} + \
                                (${NO_QIF}/${TOT_BSL})*${LN_QIF} + \
                                (${NO_DIR}/${TOT_BSL})*${LN_DIR} ) "`


# //////////////////////////////////////////////////////////////////////////////
# WRITE INFO TO AS STRUCTURED XML
# //////////////////////////////////////////////////////////////////////////////
DATE_STAMP=`date`
echo "<!-- THE FOLLOWING TABLE IS AUTOMATICALLY CREATED VIA"
echo "     THE PROGRAM ${NAME}v${VERSION} - ${RELEASE}     "
echo "     INPUT FILE : ${1}                               "
echo "     RAN AT ${DATE_STAMP}                            "
echo "-->"

echo "<table>"
echo "<title>Ambiguity Resolution Summary</title>"
echo "<tgroup cols=\"14\">"
for i in `seq 0 14`
do
  echo "<colspec colname=\"c${i}\" />"
done
echo "<spanspec spanname=\"hspan12\" namest=\"c1\" nameend=\"c2\" align=\"center\" />"
echo "<spanspec spanname=\"hspan45\" namest=\"c4\" nameend=\"c5\" align=\"center\" />"
echo "<spanspec spanname=\"hspan67\" namest=\"c6\" nameend=\"c7\" align=\"center\" />"
echo "<spanspec spanname=\"hspan01\" namest=\"c10\" nameend=\"c11\" align=\"center\" />"

echo "<thead>"
echo "<row>"
echo "<entry>Method</entry>"
echo "<entry>Station 1</entry>"
echo "<entry>Station 2</entry>"
echo "<entry>Length</entry>"
echo "<entry spanname=\"hspan45\">Before</entry>"
echo "<entry spanname=\"hspan67\">After</entry>"
echo "<entry>Resolved</entry>"
echo "<entry>Sat. System</entry>"
echo "<entry spanname=\"hspan01\">Max/RMS L5</entry>"
echo "<entry>Receiver 1</entry>"
echo "<entry>Receiver 2</entry>"
echo "</row>"
echo "<row>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry>(km)</entry>"
echo "<entry>#Amb</entry>"
echo "<entry>(mm)</entry>"
echo "<entry>#Amb</entry>"
echo "<entry>(mm)</entry>"
echo "<entry>(%)</entry>"
echo "<entry></entry>"
echo "<entry spanname=\"hspan01\">(L5 Cycles)</entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "</row>"
echo "</thead>"

echo "<tfoot>"
echo "<row>"
echo "<entry></entry>"
echo "<entry spanname=\"hspan12\">${TOT_BSL}</entry>"
echo "<entry>${MEAN_LENGTH}</entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "</row>"
echo "</tfoot>"

echo "<tbody>"

## AMBIGUITY INFO
echo "<!-- Code-Based Wide Lane -->"
#echo "<entry morerows=\"${NO_CWL}\" valign=\"middle\"><para>Code-Based Wide Lane</para></entry>"
cat .tmp.cwl
echo "<!-- Code-Based Narrow Lane -->"
#echo "<entry morerows=\"${NO_CNL}\" valign=\"middle\"><para>Code-Based Narrow Lane</para></entry>"
cat .tmp.cnl
echo "<!-- Phase-Based Wide Lane -->"
#echo "<entry morerows=\"${NO_PWL}\" valign=\"middle\"><para>Phase-Based Wide Lane</para></entry>"
cat .tmp.pwl
echo "<!-- Phase-Based Narrow lane -->"
#echo "<entry morerows=\"${NO_PNL}\" valign=\"middle\"><para>Phase-Based Narrow Lane</para></entry>"
cat .tmp.pnl
echo "<!-- Q I F -->"
#echo "<entry morerows=\"${NO_QIF}\" valign=\"middle\"><para>QIF</para></entry>"
cat .tmp.qif
echo "<!-- Direct L1 / L2 -->"
#echo "<entry morerows=\"${NO_DIR}\" valign=\"middle\"><para>Direct L1 / L2</para></entry>"
cat .tmp.dir


echo "</tbody>"

echo "</tgroup>"
echo "</table>"

echo "<!-- TABLE DONE -->"

# //////////////////////////////////////////////////////////////////////////////
# REMOVE TEMPORARY FILE AND EXIT
# //////////////////////////////////////////////////////////////////////////////
rm .tmp .tmp.??? 2>/dev/null
exit 0

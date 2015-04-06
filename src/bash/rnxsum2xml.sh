#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : rnxsum2xml.sh
                           NAME=rnxsum2xml
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 :
## exit code(s)          : 0 -> sucess
##                         1 -> failure
## discription           :
## uses                  : sed, head, read, awk
## needs                 :
## notes                 :
## TODO                  :
## WARNING               : No help message provided.
## detailed update list  :
                           LAST_UPDATE=JAN-20015
##
################################################################################

# //////////////////////////////////////////////////////////////////////////////
# DISPLAY VERSION
# //////////////////////////////////////////////////////////////////////////////
function dversion {
  echo "${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
  exit 0
}

function echoerr
{
    echo "$@" 1>&2
}

# //////////////////////////////////////////////////////////////////////////////
# WATCHOUT FOR THE -v OPTION
# //////////////////////////////////////////////////////////////////////////////
if test "${1}" == "-v" ; then dversion ; exit 0; fi

##  ARGV[1] -> network name
NETWORK=${1,,}

##  ARGV[2] -> file with available rinex/stations (e.g. from ddprocess);
##+ seperator = ' '
AVLB=${2}

## ARGV[3] -> extractStations report. 
## **** Note ****
## Use the switch for extractStations report
XSTA=${3}

## ARGV[4] -> year
YEAR=${4}
YR2=${YEAR:2:2}

## ARGV[5] -> doy (3digit)
DOY=${5}

## ARGV[6] -> month (2digit)
MONTH=${6}

## ARGV[7] -> day of month (2digit)
DOM=${7}

##  ARGV[8] -> (final) coordinate files from processing
##+ needed for flags
FCF=${8}

## We will also need:
POOL=/home/bpe2/data/GPSDATA/DATAPOOL  ## RINES FILES
TABLES=/home/bpe2/tables               ## NETWORK FILES
TMP=/home/bpe2/tmp                     ## QC PLOTS

if ! test -f "$AVLB"
then
  echoerr "(rnxsum2xml) ERROR! Failed to locate file $AVLB"
  exit 1
fi

if ! test -f "$XSTA"
then
  echoerr "(rnxsum2xml) ERROR! Failed to locate file $XSTA"
  exit 1
fi

if ! test -f "$FCF"
then
  echoerr "(rnxsum2xml) ERROR! Failed to locate file $FCF (coordinate file)"
  exit 1
fi

## make a list with all stations/rinex that should be here for this network
>.tmp
for i in igs epn reg
do

  ## Check that the network files exist
  if ! test -f ${TABLES}/crd/${NETWORK}.${i}
  then
    echoerr "(rnxsum2xml) ERROR! Failed to locate file ${TABLES}/crd/${NETWORK}.${i}"
    exit 1
  fi

  ## Make a list with all stations that should exist
  array=()
  IFS=' ' read -a array <<< `cat ${TABLES}/crd/${NETWORK}.${i}`

  ## For every stations (that should exist)
  for j in ${array[@]}
  do

    ## Check if the station is available (using the input file)
    avlb=no
    if grep -i ${j} ${AVLB} &>/dev/null
    then
      avlb=yes
    fi

    ##  Check if the station was processed (using the input file) and set the
    ##+ crd differences
    prc=no
    difs="- - - - - -"
    flag=
    if grep -i ${j} ${XSTA} &>/dev/null
    then
      prc=yes
      difs=`grep -i ${j} ${XSTA} | awk '{print $3,$4,$5,$6,$7,$8}'`
    fi
    if test $prc == "yes"
    then
        FLAG=`grep -i ${j} ${FCF} | awk '{print substr ($0,70,10)}' | sed 's/ //g'`
        if test "${FLAG}" == "A"; then flag="A (free)"; fi
        if test "${FLAG}" == "W"; then flag="W (used for allignment)"; fi
        if test "${FLAG}" == "F"; then flag="F (fixed)"; fi
    fi

    ## Search for the rinex file in the datapool area
    rnx="-"
    if ls ${POOL}/${j}${DOY}0.${YR2}o &>/dev/null; then rnx=${POOL}/${j}${DOY}0.${YR2}o; fi
    if ls ${POOL}/${j^^}${DOY}0.${YR2}O &>/dev/null; then rnx=${POOL}/${j^^}${DOY}0.${YR2}O; fi
    if test "${rnx}" != "-"
    then
        rnx=`echo $rnx | sed 's|/home/bpe2/data/GPSDATA/DATAPOOL/||g'`
    else
        rnx=
    fi

    ## Search for the multipath plot
    mplot=
    if ls ${TMP}/${j^^}-${YEAR}${MONTH}${DOM}-cf2sky.ps &>/dev/null
    then
      mplot=${TMP}/${j^^}-${YEAR}${MONTH}${DOM}-cf2sky.ps
      mplot=`echo $mplot | sed 's|/home/bpe2/tmp/|http://dionysos.survey.ntua.gr/mirror/bpe2/tmp/|g'`
      mplot="<ulink url=\'${mplot}\'>${j}.ps</ulink>"
    fi

    ## Search for the qc summary file
    qcs=
    if ls ${TMP}/${j}${DOY}0.${YR2}S &>/dev/null; then qcs=${TMP}/${j}${DOY}0.${YR2}S; fi
    if ls ${TMP}/${j^^}${DOY}0.${YR2}S &>/dev/null; then qcs=${TMP}/${j^^}${DOY}0.${YR2}S; fi
    if test "${qcs}" != ""
    then
        qcs=`echo $qcs | sed 's|/home/bpe2/tmp/|http://dionysos.survey.ntua.gr/mirror/bpe2/tmp/|g'`
        f=`basename $qcs`
        qcs="<ulink url=\'${qcs}\'>${f}</ulink>"
    fi

    ## print result
    #echo "$rnx $j $i $avlb $prc $mplot $qcs $difs" >> .tmp
    printf "<row><entry>$rnx</entry><entry>$j</entry><entry>$i</entry><entry>$avlb</entry><entry>$prc</entry><entry>$flag</entry><entry>$mplot</entry><entry>$qcs</entry></row>\n"

  done
done

echo "Exiting rnxsum2xml; xml output should be ok"
exit 0

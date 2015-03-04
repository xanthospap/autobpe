#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : marksolsta2.sh
                           NAME=marksolsta2
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAR-2015
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
##                       : 2 -> warning
## discription           : extract processed stations and baselines for each network from a
##                         solution summary file (e.g. FG[YEAR][DOY]0.SUM).
##                         Output is printed in stdout
## uses                  : awk, grep, yz2flh, printf
## notes                 :
## TODO                  :
## detailed update list  : 
                           LAST_UPDATE=MAR-2015
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
# HELP FUNCTION
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Extract processed station for each network"
  echo ""
  echo " Usage   : marksolsta.sh -y [year] | -d [doy] | -n [network] | -t [TYPE] | "
  echo ""
  echo " Switches: -y --year= specify year (4-digit)"
  echo "           -d --doy= specify the day of year"
  echo "           -g --igs-file= coordinate file for the igs stations"
  echo "            default is /home/bpe2/data/GPSDATA/CAMPAIGN52/GREECE/STA/IGB08_R.CRD"
  echo "           -c --coordinate-file= coordinate file for all stations"
  echo "            or at least the non-igs ones."
  echo "           -s --summary-file= specify the processing summary file"
  echo "            This file can be compressed"
  echo "           -x --xs-diffs= specify a file containing the processed stations"
  echo "            and the corresponding coordinate differences. (Note 1)"
  echo "           -f --estcrd-file= specify the final, estimated coordinates file"
  echo "            This file is used to check if the stations were fixed or estimated"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status: >0 -> error"
  echo " Exit Status:  0  -> sucesseful exit"
  echo ""
  echo " Note 1"
  echo " This file can be created via the extractStations script. The format must be:"
  echo "PAT0 diff: +00.00919 +00.00340 +00.00811 +00.00029 -00.00025 +00.01271"
  echo "NOA1 diff: +00.00893 +00.00077 +00.00193 -00.00371 -00.00290 +00.00786"
  echo " for each station processed"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo "/******************************************************************************/"
  exit 0
}


# //////////////////////////////////////////////////////////////////////////////
# VARIABLES
# //////////////////////////////////////////////////////////////////////////////

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then 
    help
fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null

if [ $? -eq 4 ]
then
  # GNU enhanced getopt is available
  ARGS=`getopt -o y:d:g:c:s:x:f:vh \
  -l year:,doy:,igs-file:,coordinate-file:,summary-file:,xs-diffs:,estcrd-file:,help,version \
  -n 'marksolsta' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt y:d:g:c:s:x:f:vh "$@"`
fi

# check for getopt error
if [ $? -ne 0 ]
then 
    echo "getopt error code : $status ;Terminating..." >&2
    exit 1
fi

eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -y|--year)
      YEAR="${2}"
      shift;;
    -d|--doy)
      DOY="${2}"
      shift;;
    -g|--igs-file)
      IGS_FILE="${2}"
      shift;;
    -c|--coordinate-file)
      CRD_FILE="${2}"
      shift;;
    -s|--summary-file)
      SUM_FILE="${2}"
      shift;;
    -x|--xs-diffs)
      DIF_FILE="${2}"
      shift;;
    -f|--estcrd-file)
      EST_FILE="${2}"
      shift;;
    -h|--help)
      help
      exit 0;;
    -v|--version)
      dversion
      exit 0;;
    --) # end of options
      shift
      break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 254 ;;
  esac
  shift 
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK COMMAND LINE OPTIONS
# //////////////////////////////////////////////////////////////////////////////
if test -z "$YEAR"
then
  echo "*** Need to provide a valid year [1950-2015]"
  exit 1
fi
YR2=${YEAR:2:2}

if test -z "$DOY"
then
  echo "*** Need to provide a valid doy [1-366]"
  exit 1
fi
DOY=$(printf "%03d" $DOY)

IGS_FILE=${IGS_FILE:-/home/bpe2/data/GPSDATA/CAMPAIGN52/GREECE/STA/IGB08_R.CRD}
if ! test -f $IGS_FILE
then
    echo "ERROR. Failed to locate igs coordinate file: $IGS_FILE"
    exit 1
fi

if ! test -f $CRD_FILE
then
    echo "ERROR. Failed to locate coordinate file: $CRD_FILE"
    exit 1
fi

if test -z "$DIF_FILE"
then
    echo "ERROR. Must specify the diffs file"
    exit 1
else
    if ! test -f "$DIF_FILE"
    then
        echo "if ! test -f $DIF_FILE"
        echo "ERROR. Failed to locate diffs file: $DIF_FILE"
        exit 1
    fi
fi

RM_SUM_FILE=NO
if ! test -f $SUM_FILE
then
    echo "ERROR. Failed to locate summary file: $SUM_FILE"
    exit 1
fi
if test ${SUM_FILE:(-2)} == ".Z"
then
    cp $SUM_FILE ${SUM_FILE##*/}
    uncompress -f ${SUM_FILE##*/}
    SUM_FILE=${SUM_FILE##*/}
    SUM_FILE=${SUM_FILE/.Z/}
    RM_SUM_FILE=YES
fi

USE_EST_FILE=NO
RM_EST_FILE=YES
if ! test -z "$EST_FILE"
then
  if ! test -f "$EST_FILE"
  then
    echo "ERROR. Cannot locate estimated coordinates file $EST_FILE"
    exit 1
  else
    echo "## Using file $EST_FILE for crd flags"
    USE_EST_FILE=YES
    if test ${EST_FILE:(-2)} == ".Z"
    then
      cp $EST_FILE ${EST_FILE##*/}
      uncompress -f ${EST_FILE##*/}
      EST_FILE=${EST_FILE##*/}
      EST_FILE=${EST_FILE/.Z/}
    fi
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# WRITE TO OUTPUT THE PROCESSED STATIONS CRDs
# //////////////////////////////////////////////////////////////////////////////
#echo "## Station Coordinates for network: $NETWORK"
#echo "## File with network's crds: $CRD_FILE"
#echo "## Type of solution: $TYPE"
#echo "## Input Solution File: $SUM_FILE"
echo -ne "## Date compiled:  "; date;
echo "## Automaticaly created by routine: marksolsta.sh"
echo "##  name dx      dy      dz      rms_x  rms_y  rms_z  typ  Longtitude Latitude   Height"
echo "##* **** ******* ******* ******* ****** ****** ****** ***  ********** ********** ******"

## First find where line starting with 'stat. ' is in the file
## Loop for 150 iterations or stop when an empty line is encountered
## Fir every non-empty line, print line to LOGFILE

## we also need a new crd file containing all regional and isg coordinates
cat $CRD_FILE > .tcrd
cat $IGS_FILE >>.tcrd
CRD_FILE=.tcrd

# //////////////////////////////////////////////////////////////////////////////
# WRITE TO OUTPUT THE PROCESSED STATIONS CRDs --- NEW AMIGUITY SUMMARY FILE
# //////////////////////////////////////////////////////////////////////////////

# pre-set status
STATUS=0

ITERATOR=1
ARRAY=$(awk '{ printf "%4s ",$1 }' $DIF_FILE)
for i in ${ARRAY[@]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        iter=$ITERATOR
        xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7,$8}'`
        diffs=`grep $i $DIF_FILE | awk '{print $3,$4,$5,$6,$7,$8, "EST"}'`
        iter=$(printf "%02d" $ITERATOR)
        if test "$USE_EST_FILE" == "YES"
        then
            FLAG=`grep -i $i $EST_FILE | awk '{print substr ($0,69,3)}' | sed 's| ||g'`
            #if test "$FLAG" == "A"; then FLAG=EST; fi
            if test "$FLAG" == "W"
            then
              diffs=`echo $diffs | sed 's|EST|HLM|g'`
            fi
            if test "$FLAG" == "F"
            then
              diffs=`echo $diffs | sed 's|EST|FIX|g'`
            fi
        fi
        echo $iter $i $diffs $flh
        let ITERATOR=ITERATOR+1
    else
        echo "## WARNING : Station $i not found in crd file!"
        STATUS=2
    fi
done

# //////////////////////////////////////////////////////////////////////////////
# WRITE TO OUTPUT THE PROCESSED BASELINES
# //////////////////////////////////////////////////////////////////////////////

NR_OF_BASELINES=0
MEAN_BSL_LENGTH=0
MEAN_AMB_RESOLVED=0
DEN_B=0
DEN_P=0
int='^[0-9]+$'
flt='^[0-9]+([.][0-9]+)?$'
for i in "#AR_NL" "#AR_L3" "#AR_QIF" "#AR_L12"
do
  MORE=`grep "Tot:" $SUM_FILE | grep ${i} | awk '{print $2}'`
  if test "x$MORE" == "x"; then MORE=0; fi
  if [[ $MORE =~ $int ]]
  then
    let NR_OF_BASELINES=NR_OF_BASELINES+$MORE
  else
    echo "ERROR. Cannot extract number of baselines!"
    echo "Found string [$MORE] instead of integer"
    exit 1
  fi
  LENGTH=`grep "Tot:" $SUM_FILE | grep ${i} | awk '{print $3}'`
  if test "x$LENGTH" == "x"; then LENGTH=0; fi
  if [[ $LENGTH =~ $flt ]]
  then
    NUM_B=$(awk -v num=$NUM_B -v l=$LENGTH -v m=$MORE 'BEGIN { print num + (l*m) }')
    let DEN_B=DEN_B+$MORE
  else
    echo "ERROR. Cannot extract mean baseline length!"
    echo "Found string [$LENGTH] instead of float"
    exit 1
  fi
  PERC=`grep "Tot:" $SUM_FILE | grep ${i} | awk '{print $8}'`
  if test "x$PERC" == "x"; then PERC=0; fi
  if [[ $PERC =~ $flt ]]
  then
    NUM_P=$(awk -v num=$NUM_P -v p=$PERC -v m=$MORE 'BEGIN { print num + (p*m) }')
    let DEN_P=DEN_P+$MORE
  else
    echo "ERROR. Cannot extract mean baseline percent!"
    echo "Found string [$PERC] instead of float"
    exit 1
  fi
done
MEAN_BSL_LENGTH=$(echo "${NUM_B}/${DEN_B}" | bc)
MEAN_AMB_RESOLVED=$(echo "${NUM_P}/${DEN_P}" | bc)
echo "## NUMBER OF BASELINES : $NR_OF_BASELINES"
echo "## MEAN BASELINE LENGTH: $MEAN_BSL_LENGTH"
echo "## MEAN AMB. RESOLVED  : $MEAN_AMB_RESOLVED"

ITERATOR=0

## we are going to need 4 temp files
>.tmp1
>.tmp2
>.logf

## First Code-Based Narrowlane

## Phase-Based Narrowlane L3
grep "#AR_L3" $SUM_FILE | head -n -1 | awk '{print $2,$3,$9}' > .logf
ARRAY1=$(awk '{ printf "%4s ", $1 }' .logf) ## base stations
ARRAY2=$(awk '{ printf "%4s ", $2 }' .logf) ## second stations
for i in ${ARRAY1[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5 }'`
        flh=`echo $xyz | xyz2flh -ud | awk '{ print $6,$7 }'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp1
    else
        echo "## WARNING(1) : Station $i not found in crd file!"
        STATUS=2
    fi
    let ITERATOR=ITERATOR+1
done

for i in ${ARRAY2[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5 }'`
        flh=`echo $xyz | xyz2flh -ud | awk '{ print $6,$7 }'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp2
    else
        echo "## WARNING(2) : Station $i not found in crd file!"
        STATUS=2
    fi
done
paste .tmp1 .tmp2 .logf | awk '{print "BL",$1,$2,$3,$4,$7,"W/N"}'

>.tmp1
>.tmp2
>.logf
## Quasi-Ionosphere-Fre (QIF)
grep "#AR_QIF" $SUM_FILE | head -n -1 | awk '{print $2,$3,$9}' > .logf
ARRAY1=$(awk '{ printf "%4s ", $1 }' .logf)
ARRAY2=$(awk '{ printf "%4s ", $2 }' .logf)
for i in ${ARRAY1[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7}'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp1
    else
        echo "## WARNING(1) : Station $i not found in crd file!"
        STATUS=2
    fi
    let ITERATOR=ITERATOR+1
done

for i in ${ARRAY2[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7}'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp2
    else
        echo "## WARNING(2) : Station $i not found in crd file!"
        STATUS=2
    fi
done
paste .tmp1 .tmp2 .logf | awk '{print "BL",$1,$2,$3,$4,$7,"QIF"}'

>.tmp1
>.tmp2
>.logf
## Direct L1/L2 Ambiguity Resolution
grep "#AR_L12" $SUM_FILE | head -n -1 | awk '{print $2,$3,$9}' > .logf
ARRAY1=$(awk '{ printf "%4s ", $1 }' .logf)
ARRAY2=$(awk '{ printf "%4s ", $2 }' .logf)
for i in ${ARRAY1[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7}'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp1
    else
        echo "## WARNING(1) : Station $i not found in crd file!"
        STATUS=2
    fi
    let ITERATOR=ITERATOR+1
done

for i in ${ARRAY2[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7}'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp2
    else
        echo "## WARNING(2) : Station $i not found in crd file!"
        STATUS=2
    fi
done
paste .tmp1 .tmp2 .logf | awk '{print "BL",$1,$2,$3,$4,$7,"L12"}'

>.tmp1
>.tmp2
>.logf
## Code-Based Narrowlane
grep "#AR_NL" $SUM_FILE | head -n -1 | awk '{print $2,$3,$9}' > .logf
ARRAY1=$(awk '{ printf "%4s ", $1 }' .logf)
ARRAY2=$(awk '{ printf "%4s ", $2 }' .logf)
for i in ${ARRAY1[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7}'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp1
    else
        echo "## WARNING(1) : Station $i not found in crd file!"
        STATUS=2
    fi
    let ITERATOR=ITERATOR+1
done

for i in ${ARRAY2[*]}
do
    if grep -i $i $CRD_FILE &>/dev/null
    then
        xyz=`grep -i $i $CRD_FILE | awk '{print $3,$4,$5}'`
        flh=`echo $xyz | xyz2flh -ud | awk '{print $6,$7}'`
        #line1=`grep $i .logf`
        echo $flh >> .tmp2
    else
        echo "## WARNING(2) : Station $i not found in crd file!"
        STATUS=2
    fi
done
paste .tmp1 .tmp2 .logf | awk '{print "BL",$1,$2,$3,$4,$7,"CNL"}'

## Check the iterator to see how many baselines we translated
if test "$ITERATOR" -ne "$NR_OF_BASELINES"
then
  echo "## !! WARNING: $ITERATOR out of $NR_OF_BASELINES baselines translated!"
  STATUS=2
fi

# //////////////////////////////////////////////////////////////////////////////
## REMOVE LOGFILE AND TEMPORARIES
# //////////////////////////////////////////////////////////////////////////////
rm .logf .tmp1 .tmp2 .tcrd 2>/dev/null
if test "$RM_SUM_FILE" == "YES"
then
    rm $SUM_FILE
fi
if test "$USE_EST_FILE" == "YES"
then
  if test "$RM_EST_FILE" == "YES"
  then
    rm $EST_FILE
  fi
fi

## EXIT
exit $STATUS

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

function echoerr
{
    echo "$@" 1>&2
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
  echo "           -s --summary-file= specify the ambiguity summary file"
  echo "            This file can be compressed"
  echo "           -o --output-summary= specify the processing summary file"
  echo "            This file can be compressed"
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
  ARGS=`getopt -o y:d:g:c:s:x:f:o:vh \
  -l year:,doy:,igs-file:,coordinate-file:,summary-file:,xs-diffs:,estcrd-file:,output-summary:,help,version \
  -n 'marksolsta' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt y:d:g:c:s:x:f:o:vh "$@"`
fi

# check for getopt error
if [ $? -ne 0 ]
then 
    echoerr "getopt error code : $status ;Terminating..." >&2
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
    -f|--estcrd-file)
      EST_FILE="${2}"
      shift;;
    -o|--output-summary)
      OUT_FILE="${2}"
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
      echoerr "*** Invalid argument $1 ; fatal" ; exit 254 ;;
  esac
  shift 
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK COMMAND LINE OPTIONS
# //////////////////////////////////////////////////////////////////////////////
if test -z "$YEAR"
then
  echoerr "*** Need to provide a valid year [1950-2015]"
  exit 1
fi
YR2=${YEAR:2:2}

if test -z "$DOY"
then
  echoerr "*** Need to provide a valid doy [1-366]"
  exit 1
else
    DOY=`echo $DOY | sed 's/^0*//g'`
fi
DOY=$(printf "%03d" $DOY)

IGS_FILE=${IGS_FILE:-/home/bpe2/data/GPSDATA/CAMPAIGN52/GREECE/STA/IGB08_R.CRD}
if ! test -f $IGS_FILE
then
    echoerr "ERROR. Failed to locate igs coordinate file: $IGS_FILE"
    exit 1
fi

if ! test -f $CRD_FILE
then
    echoerr "ERROR. Failed to locate coordinate file: $CRD_FILE"
    exit 1
fi

RM_SUM_FILE=NO
if ! test -f $SUM_FILE
then
    echoerr "ERROR. Failed to locate summary file: $SUM_FILE"
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
RM_EST_FILE=NO
if ! test -z "$EST_FILE"
then
  if ! test -f "$EST_FILE"
  then
    echoerr "ERROR. Cannot locate estimated coordinates file $EST_FILE"
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
      RM_EST_FILE=YES
    fi
  fi
fi

RM_OUT_FILE=NO
if test -z "$OUT_FILE"
then
  echoerr "ERROR. Need to specify output summary file"
  exit 1
else
  if ! test -f "$OUT_FILE"
  then
    echoerr "ERROR. Output summary file: $OUT_FILE does not exist"
    exit 1
  else
    if test ${OUT_FILE:(-2)} == ".Z"
    then
      cp $OUT_FILE ${OUT_FILE##*/}
      uncompress -f ${OUT_FILE##*/}
      OUT_FILE=${OUT_FILE##*/}
      OUT_FILE=${OUT_FILE/.Z/}
      RM_OUT_FILE=YES
    fi
  fi
fi

if ! extractStations --use-all --solution-summary ${OUT_FILE} \
  --only-report --ellipsoid 1>.essum ## 2>/dev/null
then
  echoerr "ERROR. Failed to run script 'extractStations'; Fatal"
  exit 1
fi
DIF_FILE=.essum
if test -z "$DIF_FILE"
then
    echoerr "ERROR. Must specify the diffs file"
    exit 1
else
    if ! test -f "$DIF_FILE"
    then
        echoerr "if ! test -f $DIF_FILE"
        echoerr "ERROR. Failed to locate diffs file: $DIF_FILE"
        exit 1
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

if ! /usr/local/bin/amb_unique_bsl $SUM_FILE $EST_FILE 1>.tmp1 2>.logf
then
    echoerr "ERROR in marksolsta3, caused by amb_unique_bsl"
    echoerr "REPORT:"
    cat .logf 1>&2
    exit 1
fi
cat .tmp1 | head -n3
cat .tmp1 | awk 'NF==9{print "BL",$6,$7,$8,$9,$4,$5}'

# //////////////////////////////////////////////////////////////////////////////
# REMOVE LOGFILE AND TEMPORARIES
# //////////////////////////////////////////////////////////////////////////////
rm .logf .tmp1 .tmp2 .tcrd $DIF_FILE 2>/dev/null
if test "$RM_SUM_FILE" == "YES"
then
    rm $SUM_FILE
fi
if test "$RM_OUT_FILE" == "YES"
then
  rm $OUT_FILE
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

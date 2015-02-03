#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : updatecrd.sh
                           NAME=updatecrd
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : DEC-2014
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : 
## uses                  : 
## notes                 :
## TODO                  : 
## detailed update list  : 
                           LAST_UPDATE=JAN-2015
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
  echo " Purpose : Update a Bernese v5.2 .CRD files using onother as reference"
  echo ""
  echo " Usage   : "
  echo ""
  echo " Switches: -u --update-file= .CRD file to be updated"
  echo "           -r --reference-file= .CRD file to be used as reference for"
  echo "            updating"
  echo "           -s --station-file= file with list of stations, whose coordinates"
  echo "            should be updated. This should be a file, with one line, and"
  echo "            station names should be whitespace seperated"
  echo "           -f --flags= only update stations flaged with specific characters"
  echo "            in the reference file. Comma seperated list, e.g. --flags=W,A"
  echo "            If this switch is not specified, all matching stations will be"
  echo "            updated regardless of their flags"
  echo "           -l --limit the final output CRD file, will only contain the "
  echo "            stations specified in the station file (either updated or not)"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status: >=0  -> sucesseful exit, actual number is the number of stations"
  echo " updated".
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
REF_CRD=  ## Reference .CRD file
UPD_CRD=  ## Updated .CRD file
FLAG_STR= ## Flags (input string)
FLAGS=()  ## list of flags to be considered
STA_FILE= ## file with list of stations
STATIONS=()
LIMIT=NO

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi
## Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  ## GNU enhanced getopt is available
  ARGS=`getopt -o hvu:r:s:f:l \
  -l  help,version,update-file:,reference-file:,station-file:,flags:,limit \
  -n 'ddprocess' -- "$@"`
else
  ## Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvu:r:s:f:l "$@"`
fi
## check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

## extract options and their arguments into variables.
while true ; do
  case "$1" in
    -u|--update-file)
      UPD_CRD="$2"; shift;;
    -r|--reference-file)
      REF_CRD="$2"; shift;;
    -s|--station-file)
      STA_FILE="$2"; shift;;
    -f|--flags)
      FLAG_STR="$2"; shift;;
    -l|--limit)
      LIMIT=YES;;
    -h|--help)
      help; exit 0;;
    -v|--version)
      dversion; exit 0;;
    --) # end of options
      shift; break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 254 ;;
  esac
  shift 
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if ! test -f ${UPD_CRD}
then
  echo "ERROR. Cannot find crd file ${UPD_CRD}"
  exit 254
fi

if ! test -f ${REF_CRD}
then
  echo "ERROR. Cannot find crd file ${REF_CRD}"
  exit 254
fi

if ! test -f ${STA_FILE}
then
  echo "ERROR. Cannot find file ${STA_FILE}"
  exit 254
else
  read -a STATIONS <<< `cat $STA_FILE`
  if test ${#STATIONS[@]} -eq 0
  then
    echo "ERROR. Could not read any stations from file $STA_FILE"
    exit 254
  fi
fi

if test -z ${FLAG_STR}
then
  FLAGS+=("ALL")
else
  IFS=',' read -a FLAGS <<<"$FLAG_STR"
fi

# //////////////////////////////////////////////////////////////////////////////
# PROCESS
# //////////////////////////////////////////////////////////////////////////////

##----------------------------------------------------------------------------------
##RNX2SNX_150320: Final coordinate/troposphere results             02-FEB-15 21:58
##--------------------------------------------------------------------------------
##LOCAL GEODETIC DATUM: IGb08             EPOCH: 2015-02-01 12:00:00
##
##NUM  STATION NAME           X (M)          Y (M)          Z (M)     FLAG
##
##  1  ADE2             -3939182.64541  3467075.35755 -3613220.07085
##  2  AIRA             -3530185.74895  4118797.26259  3344036.81124
##  3  AKYR              4745189.13130  2203912.65100  3636387.39550
##  4  ALBH             -2341333.05495 -3539049.51837  4745791.27570
##  5  ALGO               918129.21438 -4346071.30464  4561977.90066
##----------------------------------------------------------------------------------

## First 6 lines are directly copied from reference
#cat ${REF_CRD} | head -6 > .tmp
>.tmp

## Print rest of updated file (skipping header)
tail -n+7 ${UPD_CRD} >> .tmp

##  we have now printed the header of the refernce file and all records
##+ of the update file. For every station to be updated, if it has a
##+ record line in the reference file, change it with the one in the
##+ updated file
UPDATED=0
for s in "${STATIONS[@]}"
do
  if grep -i $s $REF_CRD &>/dev/null
  then
    # echo "station $s found in reference"
    LNR=`grep -i $s ${REF_CRD}`

    FLG=`echo "$LNR" | awk '{print substr ($0,69,10)}' | sed 's/^ *//'`
    FLAG_ACCEPTED=NO
    if test "${FLAGS[0]}" == "ALL"; then FLAG_ACCEPTED=YES; fi
    for f in "${FLAGS[@]}"
    do
      if test "${FLG}" == $f
      then
        FLAG_ACCEPTED=YES
        break
      fi
    done

    if test "${FLAG_ACCEPTED}" == "YES"
    then

      if grep -i $s $UPD_CRD &>/dev/null
      then
        LNU=`grep -i $s ${UPD_CRD}`
        sed -i "s|${LNU}|${LNR}|g" .tmp
        echo "# Replaced record for station $s"
        let UPDATED=UPDATED+1
      fi
    fi
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# REMOVE REDUNDANT STATIONS
# //////////////////////////////////////////////////////////////////////////////
if test "$LIMIT" == "YES"
then
  ## First 6 lines are directly copied from reference
  #cat .tmp | head -6 > .tmp2
  for s in "${STATIONS[@]}"
  do
    if grep -i $s .tmp &>/dev/null
    then
      grep -i $s .tmp >> .tmp2
    fi
  done
  mv .tmp2 .tmp
else
  :
  #mv .tmp ${UPD_CRD}
fi

# //////////////////////////////////////////////////////////////////////////////
# SORT THE FILE & ADD HEADER
# //////////////////////////////////////////////////////////////////////////////
sort -k 2 .tmp > .tmp2
awk '{printf("%3d %s\n", NR,substr($0,5,100))}' .tmp2 > .tmp
cat ${REF_CRD} | head -6 > .tmp2
cat .tmp >> .tmp2
mv .tmp2 .tmp

# //////////////////////////////////////////////////////////////////////////////
# REMOVE TEMPORARY FILE; CHANGE TEMP WITH UPDATED CRD
# //////////////////////////////////////////////////////////////////////////////
mv .tmp ${UPD_CRD}
rm .tmp .tmp2 2>/dev/null

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit $UPDATED
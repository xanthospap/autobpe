#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : makecluster.sh
                           NAME=makecluster
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : DEC-2014
## usage                 : 
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : 
## uses                  : 
## dependancies          : 
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
  echo "/******************************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Create a cluster file for Bernese v52 processing."
  echo ""
  echo " Usage   :"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches: -a --abbreviation-file= specify the abbrevioation file to be used"
  echo "            for this campaign/session (Bernese-specific format, .ABB)."
  echo "           -n --stations-per-cluster= specify the number of stations to be"
  echo "            included in each cluster. Positive integer."
  echo "           -f --station-file= specify a station file. This file should contain"
  echo "            the names of all stations to be included in the cluster file. The"
  echo "            names of the stations should appear as their 4char ids, exactly as"
  echo "            reported in the corresponding .ABB file provided(see -a switch)."
  echo "            The 4char ids can be either lowercase or uppercase. Use a one-line"
  echo "            whitespace seperated list (e.g. ankr dyng mate ...)"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
  echo ""
  echo " A sample cluster file is given below: "
  echo " ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "   Example for a station cluster file                               18-OCT-03 15:14"
  echo " --------------------------------------------------------------------------------"
  echo " "
  echo " STATION NAME      CLU"
  echo " ****************  ***"
  echo " AUT1 12619M002    1"
  echo " COST 11407M001    1"
  echo " DUB2 11901M002    1"
  echo " DUTH 12621M001    2"
  echo " LAMP 12706M002    2"
  echo " ..."
  echo " USAL 19527M001    7"
  echo " ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo " Note that some, all, or none of the stations can have a radome number (the number following"
  echo " the 4char id). This depends on how the station is found in the abbreviation file."
  echo ""
  echo " WARNING !! The long options are only available if the GNU-enhanced version of getopt is"
  echo "            available; else, the user must only use short options"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo "/******************************************************************************************/"
  exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
ABB=           ## abbreviation file
STA_PER_CLU=   ## stations per cluster
STA_FILE=      ## station file

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o a:n:hvf: \
  -l abbreviation-file:,stations-per-cluster:,help,version,station-file: \
  -n 'makecluster' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt a:n:hvf: "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -a|--abbreviation-file)
      ABB="${2}"; shift;;
    -n|--stations-per-cluster)
      STA_PER_CLU="${2}"; shift;;
    -f|--station-file)
      STA_FILE="${2}"; shift;;
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
# CHECK AND VALIDATE ARGV
# //////////////////////////////////////////////////////////////////////////////
if test -z $ABB ; then
  echo "***ERROR! Need to specify the abbreviation file"
  exit 254
else
  if ! test -f $ABB; then
    echo "***ERROR! Abbreviation file does not exist : $ABB"
    exit 254
  fi
fi

if test -z $STA_FILE ; then
  echo "***ERROR! Need to specify the station file"
  exit 254
else
  if ! test -f $STA_FILE; then
    echo "***ERROR! Station file does not exist : $STA_FILE"
    exit 254
  fi
fi

if [[ $STA_PER_CLU =~ ^[0-9]+$ ]]; then
  :
else
  echo "***ERROR! Stations per cluster must be a positive integer"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# FIN THE FULL STATION NAMES
# //////////////////////////////////////////////////////////////////////////////

## dump the station file in an array
STARRAY=( $( cat "$STA_FILE" ) )
if [ ${#STARRAY[*]} -eq 0 ]; then
  echo "***ERROR! No stations found in station file"
  exit 254
fi

NAMARRAY=()
##  for every station in the array, find it full name using the abb file (i.e.
##+ match the 4char id with the full station name.
for i in "${STARRAY[@]}" ; do

  # these are the ids; they should be 4char
  if test ${#i} -ne 4 ; then
    echo "***ERROR! Invalid station id: $i"
    exit 254
  fi
  
  ##  grep the abbreviation file to match the full name
  ##+ this file looks like:
  ##Station name             4-ID    2-ID    Remark                                 
  ##****************         ****     **     ***************************************
  ##AUT1 12619M002           AUT1     AU     Added by SR updabb                     
  NAME=`/bin/grep --ignore-case ".* $i  .*" $ABB | awk '{print substr ($0,0,16)}' 2>/dev/null`
  if test ${#NAME} -ne 15 ; then
    echo "***ERROR! Failed to match station : $i"
    exit 254
  fi
  NAMARRAY+=("$NAME")

done

## Note that now all station names are stored in the NAMARRAY array

# //////////////////////////////////////////////////////////////////////////////
# COMPILE THE CLUSTER FILE
# //////////////////////////////////////////////////////////////////////////////

## get the time stamp and write the header of the cluster file
STAMP=`/bin/date +"%d-%b-%g %R"`
echo "Cluster file automaticaly created by makecluster                $STAMP"
echo "--------------------------------------------------------------------------------"
echo ""
echo "STATION NAME      CLU"
echo "****************  ***"

j=1
CLUSTER=1
for i in "${NAMARRAY[@]}" ; do
  echo "$i   $CLUSTER"
  let j=j+1
  if test ${j} -gt $STA_PER_CLU ; then
    let CLUSTER=CLUSTER+1
    j=1
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0

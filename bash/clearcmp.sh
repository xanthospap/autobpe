#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : clearcmp.sh
                           NAME=clearcmp
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : 
## exit code(s)          : 
## discription           : 
## uses                  :
## needs                 : 
## notes                 :
## TODO                  : 
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
# HELP FUNCTION
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Remove unneeded files after dd processing in the campaign directories."
  echo ""
  echo " Usage   : "
  echo ""
  echo " Switches: -a --analysis-center= specify the analysis center."
  echo "           -b --bernese-loadvar= specify the Bernese LOADGPS.setvar file; this"
  echo "            is needed to resolve the Bernese-related path variables"
  echo "           -c --campaign= specify the name of the campaign; this script will"
  echo "            remove files using the root directory \${P}/campaign/."
  echo "           -d --doy= day of year [1-366] to download (e.g. -d 35)"
  echo "           -e --exclude= specify a COMMA seperated list of files to be excluded"
  echo "            from removal. The folder they reside in should also be specified."
  echo "            E.g. to not remove the file COD18016.ION found under \${P}/campaign/ATM,"
  echo "            use --exclude=ATM/COD18016.ION,..."
  echo "           -i --ids= specify a COMMA seperated list of solution ids, used to"
  echo "            identify the files. E.g. -i FFG,FRG,FZG will remove files named"
  echo "            as FFGYYDDD0.OUT, FRGYYDDD0.OUT, FZGYYDDD0.OUT among others."
  echo "           -y --year= 4-digit year of date to download (e.g. -y 2010)"
  echo "           -h --help print help message and exit"
  echo "           -v --version print version and exit"
  echo ""
  echo " Exit Status: Success 0"
  echo "            : Error   255-1"
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
AC=                ## analysis center
LOADVAR=           ## the bernese loadvar file
YEAR=              ## the year; 4-digit
DOY=               ## the doy
CAMPAIGN=          ## name of the campaign
EXCLUDE=           ## string with exclude files; comma seperated
EXCLUDE_LIST=()    ## list of files to exclude
IDS=               ## string with ids; comma seperated
ID_LIST=()         ## list of ids

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o a:b:c:d:e:i:y:hv \
  -l analysis-center:,bernese-loadvar:,campaign:,doy:,exclude:,ids:,year:,help,version \
  -n 'clearcmp' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt a:b:c:d:e:i:y:hv "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -a|--analysis-center)
      AC="${2}"; shift;;
    -b|--bernese-loadvar)
      LOADVAR="${2}"; shift;;
    -c|--campaign)
      BCAMPAIGN="${2}"; shift;;
    -i|--ids)
      IDS="${2}"; shift;;
    -e|--exclude)
      EXCLUDE="${2}"; shift;;
    -y|--year)
      YEAR="${2}"; shift;;
    -d|--doy)
      DOY="${2}"; shift;;
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
# CHECK & LOAD THE LOADVAR FILE
# //////////////////////////////////////////////////////////////////////////////
if test -z $LOADVAR ; then
  echo "***ERROR! Need to specify the Bernese LOADGPS.setvar file"
  exit 254
fi
if ! test -f $LOADVAR ; then
  echo "***ERROR! Cannot locate file $LOADVAR"
  exit 254
fi
. $LOADVAR
if test -z $VERSION ; then
  echo "***ERROR! Cannot load the source file: $LOADVAR"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK IF THE CAMPAIGN EXISTS
# //////////////////////////////////////////////////////////////////////////////
if ! test -d ${P}/${CAMPAIGN} ; then
  echo "***ERROR! Cannot locate campaign: ${P}/${CAMPAIGN}"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK DATE VARIABLES
# //////////////////////////////////////////////////////////////////////////////
if [[ $YEAR =~ ^[0-9]+$ ]]; then
  YR2=${YEAR:2:2}
else
  echo "***ERROR! Invalid year : $YEAR"
  exit 254
fi

DOY=`echo $DOY | /bin/sed 's/^0*//'`
if [[ $DOY =~ ^[0-9]+$ ]]; then
  DOY3=$DOY
  if [ $DOY -lt 100 ]; then DOY3=0${DOY3}; fi
  if [ $DOY -lt 10 ];  then DOY3=0${DOY3}; fi
else
  echo "***ERROR! Invalid day of year : $DOY"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# CREATE ARRAY OF SOLUTION IDs
# //////////////////////////////////////////////////////////////////////////////
if ! test -z $IDS ; then 
  IFS=',' read -a ID_LIST <<< "$IDS"
fi

# //////////////////////////////////////////////////////////////////////////////
# CREATE ARRAY OF EXCLUDED FILES
# //////////////////////////////////////////////////////////////////////////////
if ! test -z $EXCLUDE ; then 
  IFS=',' read -a EXCLUDE_LIST <<< "$EXCLUDE"
fi
# remove leading '/' characters (if any)
for i in "${!EXCLUDE_LIST[@]}"; do
  EXCLUDE_LIST[i]=${EXCLUDE_LIST[i]##/}
done

# //////////////////////////////////////////////////////////////////////////////
# GO TO THE CAMPAIGN DIRECTORY FOR SAFETY
# //////////////////////////////////////////////////////////////////////////////
if ! cd ${P}/${CAMPAIGN} ; then
  echo "***ERROR! Failed to change into ${P}/${CAMPAIGN}"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# REMOVE FILES FROM EVERY FOLDER
# //////////////////////////////////////////////////////////////////////////////

#
DOY=$DOY3
#

#
# ATM FOLDER
#
RM_LIST=()
for i in "${ID_LIST[@]}" ; do
  for j in TRO TRP; do
    file=ATM/${i}${YR2}${DOY}0.${j}
    addit=1
    for k in "${EXCLUDE_LIST[@]}"; do
      if test "${k}" == "${file}" ; then
        addit=0
      fi
    done
    if test $addit -eq 1
    then 
      RM_LIST+=($file) 
    fi
  done
done
# echo "Removing from ATM -> ${RM_LIST[@]}"
for i in "${RM_LIST[@]}"; do rm ${i}; done;

#
# BPE FOLDER
#
rm BPE/*

#
# GRD FOLDER
#
rm GRD/*

#
# LOG FOLDER
#
rm LOG/*

#
# OBS FOLDER
# WARNING not checked for exclude files
rm OBS/????${DOY}0.???

#
# ORB FOLDER
# WARNING not checked for exclude files
rm ORB/${AC}${YR2}${DOY}0.???

#
# OUT FOLDER
# WARNING not checked for exclude files
rm OUT/*

# RAW FOLDER
# WARNING not checked for exclude files
rm RAW/????${DOY}0.${YR2}?

#
# SOL FOLDER
#
RM_LIST=()
for i in "${ID_LIST[@]}" ; do
  for j in SNX NQ0; do
    file=SOL/${i}${YR2}${DOY}0.${j}
    addit=1
    for k in "${EXCLUDE_LIST[@]}"; do
      if test "${k}" == "${file}" ; then
        addit=0
      fi
    done
    if test $addit -eq 1
    then 
      RM_LIST+=($file) 
    fi
  done
done
# echo "Removing from SOL -> ${RM_LIST[@]}"
for i in "${RM_LIST[@]}"; do rm ${i}; done;

#
# STA FOLDER
#
RM_LIST=()
for i in ${YR2}${DOY}???.CLB \
         APR${YR2}${DOY}0.CRD \
         ???${YR2}${DOY}0.BSL \
         REF${YR2}${DOY}0.CRD \
         REG${YR2}${DOY}0.CRD ; do
    addit=1
    for k in "${EXCLUDE_LIST[@]}"; do
      if test "${k}" == "${i}" ; then
        addit=0
      fi
    done
    if test $addit -eq 1
    then 
      RM_LIST+=($i) 
    fi
done

for i in "${ID_LIST[@]}" ; do
  file=${i}${YR2}${DOY}0.CRD
  addit=1
  for k in "${EXCLUDE_LIST[@]}"; do
    if test "${k}" == "${file}" ; then
      addit=0
    fi
  done
  if test $addit -eq 1
  then 
    RM_LIST+=($i) 
  fi
done
# echo "Removing from STA -> ${RM_LIST[@]}"
for i in "${RM_LIST[@]}"; do rm ${i}; done;

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0

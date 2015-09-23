#! /bin/bash

# //////////////////////////////////////////////////////////////////////////////
# FUNCTIONS
# //////////////////////////////////////////////////////////////////////////////

##  echo to stderr
echoerr () { echo "$@" 1>&2; }

##  print help message
help () 
{
echo "
/******************************************************************************/
Program Name : $NAME
Version      : $VERSION
Last Update  : $LAST_UPDATE

Purpose : Process a network using DD approach via a given PCF file

Usage   :

Switches: -a --analysis-center= specify the analysis center; this can be e.g.
           * igs, or
           * cod (default)

          -b --bern-loadgps= specify the Bernese LOADGPS.setvar file; this
           is needed to resolve the Bernese-related path variables; it will be
           sourced.

          -c --campaign= specify the campaign name; the argument passed will be
           truncated to uppercase (thus passing 'greece' is the same as 'GREECE'
           --see Note 3

          -d --doy= specify doy

          -e --elevation-angle specify the elevation angle (degrees, integer)
           default value is 3 degrees

          -f --ion-products= specify (a-priori) ionospheric correction file identifier.
           If more than one, use a comma-seperated list (e.g. -f FFG,RFG) --see Note 5

          -g --tables-dir specify the TABLES directory

          -i --solution-id= specify solution id (e.g. FFG) --see Note 1

          -l --stations-per-cluster= specify the number of stations per cluster
           (default is 5)

          -m --calibration-model he extension (model) used for antenna calibration.
           This can be e.g. I01, I05 or I08. What you enter here, will be appended to
           the pcv filename (provided via the -f switch) and all calibration-dependent
           Bernese processing files (e.g. SATELLITE.XXX). --see Note 2

          -p --pcv-file= specify the .PCV file to be used --see Note 2

          -r --save-dir= specify directory where the solution will be saved; note that
           if the directory does not exist, it will be created

          -s --satellite-system specify the satellite system; this can be
           * gps, or
           * mixed (for gps + glonass)
           uppercase or lowercase. Default value is 'gps'

          -t --solution-type specify the dolution type; this can be:
           * final, or
           * urapid

          -u --update= specify which records/files should be updated; valid values are:
           * crd update the default network crd file
           * sta update station-specific files, i.e. time-series records for the stations
           * ntw update update network-specific records
           * all both the above
           More than one options can be provided, in a comma seperated string e.g. 
           --update=crd,sta
           See Note 6 for this option

          -y --year= specify year (4-digit)

          -x --xml-output produce an xml (actually docbook) output summary

          --force-remove-previous remove any files from the specified save directory (-r --save-dir=)
           prior to start of processing.

          --debug set debugging mode

          --add-suffix= add a suffix (e.g. _GPS) to saved products of the processing

          -h --help display (this) help message and exit

          -v --version display version and exit
/******************************************************************************/"

}

## validate entries in the TABLES_DIR directory
## argv1 -> TABLES_DIR
## argv2 -> CAMPAIGN NAME
check_tables () {
  for f in ${1}/pcv/${2} \
           ${1}/blq/${2}.BLQ \
           ${1}/atl/${2}.ATL \
           ${1}/atl/${2}52.STA; do
    if ! test -f $i ; then
      echoerr "Missing file: $i"
      return 1
    fi
  done

  return 0
}

# //////////////////////////////////////////////////////////////////////////////
# GLOBAL VARIABLES
# //////////////////////////////////////////////////////////////////////////////
DEBUG_MODE=NO

## following variables should be set via cmd arguments (else error!)
# YEAR=
# DOY=
# B_LOADGPS=
# CAMPAIGN=

## optional parameters; may be changes via cmd arguments
SAT_SYS=GPS
TABLES_DIR=${HOME}/tables

# //////////////////////////////////////////////////////////////////////////////
# GET/EXPAND COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////

##  we nee to have at least some cmd arguments
if test $# -eq "0"; then help; fi

##  Call getopt to validate the provided input. This depends on the
##+ getopt version available.
getopt -T > /dev/null ## check getopt version

if test $? -eq 4; then
  ##  GNU enhanced getopt is available
  ARGS=`getopt -o hvy:d:b:c:s:g: \
-l  help,version,year:,doy:,debug,bern-loadgps:,campaign:,satellite-system:,tables-dir: \
-n 'ddprocess' -- "$@"`
else
  ##  Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvy:d:b:c:s: "$@"`
fi

##  check for getopt error
if test $? -ne 0; then
  echoerr "getopt error code : $status ;Terminating..." >&2
  exit 1
fi

eval set -- $ARGS

##  extract options and their arguments into variables.
while true
do
  case "$1" in

    -b|--bern-loadgps)
      B_LOADGPS="${2}"
      shift
      ;;
    -c|--campaign)
      CAMPAIGN="${2}"
      shift
      ;;
    --debug)
      DEBUG_MODE=YES
      ;;
    -d|--doy) ## remove any leading zeros
      DOY=`echo "${2}" | sed 's|^0||g'`
      shift
      ;;
    -g|--tables-dir)
      TABLES_DIR="${2}"
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -s|--satellite-system)
      SAT_SYS="${2^^}"
      shift
      ;;
    -v|--version)
      dversion
      exit 0
      ;;
    -y|--year)
      YEAR="${2}"
      shift
      ;;
    --) # end of options
      shift
      break
      ;;
     *)
      echoerr "*** Invalid argument $1 ; fatal" 
      exit 1
      ;;

  esac
  shift
done

# //////////////////////////////////////////////////////////////////////////////
# VALIDATE COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////

##  year must be set
if test -z ${YEAR+x}; then
  echoerr "ERROR. Year must be set!"
  exit 1
fi

##  doy must be set
if test -z ${DOY+x}; then
  echoerr "ERROR. Day of year must be set!"
  exit 1
fi

##  bernese-variable file must be set; if it is, check that it exists and source
##+ it.
if test -z ${B_LOADGPS+x}; then
  echoerr "ERROR. LOADGPS.setvar must be set!"
  exit 1
else
  if test -f ${B_LOADGPS} && . ${B_LOADGPS} ; then
    if test "${VERSION}" != "52"; then
      echoerr "ERROR. Invalid Bernese version: ${VERSION}"
      exit 1
    fi
  else
    echoerr "ERROR. Failed to load variable file: ${B_LOADGPS}"
    exit 1
  fi
fi

##  campaign must exist in campaign directory
if test -z ${CAMPAIGN+x}; then
  echoerr "ERROR. Campaign must be set!"
  exit 1
else
  CAMPAIGN=${CAMPAIGN^^}
  if ! test -d "${P}/${CAMPAIGN}"; then
    echoerr "ERROR. Cannot find campaign directory: ${P}/${CAMPAIGN}"
    exit 1
  fi
fi

if test ${SAT_SYS} != "GPS" && test ${SAT_SYS} != "MIXED" ; then
  echoerr "ERROR. Invalid satellite system : ${SAT_SYS}"
  exit 1
fi

##  check the tables dir and its entries
if ! test -d "${TABLES_DIR}" ; then
  echoerr "ERROR. Cannot find tables directory: $TABLES_DIR"
  exit 1
else
  if ! check_tables ${TABLES_DIR} ${CAMPAIGN}; then
    exit 1
  fi
fi

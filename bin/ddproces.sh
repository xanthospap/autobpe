#! /bin/bash

# //////////////////////////////////////////////////////////////////////////////
# FUNCTIONS
# //////////////////////////////////////////////////////////////////////////////

##  echo to stderr
echoerr () { echo "$@" 1>&2; }

##  print help message
help () 
{
  echo "/******************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Process a network using DD approach via a given PCF file"
  echo ""
  echo " Usage   : "
  echo ""
  echo " Switches: -a --analysis-center= specify the analysis center; this can be e.g."
}

# //////////////////////////////////////////////////////////////////////////////
# GLOBAL VARIABLES
# //////////////////////////////////////////////////////////////////////////////
DEBUG_MODE=NO

## following variables should be set via cmd arguments (else error!)
# YEAR=
# DOY=
# B_LOADGPS=

## optional parameters; may be changes via cmd arguments

# //////////////////////////////////////////////////////////////////////////////
# GET/EXPAND COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////

##  we nee to have at least some cmd arguments
if test $# -eq "0"; then help; fi

##  Call getopt to validate the provided input. This depends on the
##+ getopt version available.
getopt -T > /dev/null ## check getopt version

if test $? -eq 4; then
  ## GNU enhanced getopt is available
  ARGS=`getopt -o hvy:d:b: \
-l  help,version,year:,doy:,debug,:bernese-loadgps \
-n 'ddprocess' -- "$@"`
else
  ## Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvy:d:b: "$@"`
fi

## check for getopt error
if test $? -ne 0; then
  echoerr "getopt error code : $status ;Terminating..." >&2
  exit 1
fi

eval set -- $ARGS

## extract options and their arguments into variables.
while true
do
  case "$1" in

    --debug)
      DEBUG_MODE=YES
      ;;
    -y|--year)
      YEAR="${2}"
      shift
      ;;
    -d|--doy) ## remove any leading zeros
      DOY=`echo "${2}" | sed 's|^0||g'`
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -v|--version)
      dversion
      exit 0
      ;;
    --) # end of options
      shift
      break
      ;;
     *)
      echoerr "*** Invalid argument $1 ; fatal" ; exit 1 ;;

  esac
  shift
done

# //////////////////////////////////////////////////////////////////////////////
# VALIDATE COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////

## year must be set
if test -z ${YEAR+x}; then
  echoerr "ERROR. Year must be set!"
  exit 1
fi

## doy must be set
if test -z ${DOY+x}; then
  echoerr "ERROR. Day of year must be set!"
  exit 1
fi

## bernese-variable file must be set
if test -z ${B_LOADGPS+x}; then
  echoerr "ERROR. LOADGPS.setvar must be set!"
  exit 1
else
  if ! ( test -f "${B_LOADGPS}" && . "${B_LOADGPS}" ); then
    echoerr "ERROR. Failed to load variable file: ${B_LOADGPS}"
  fi
fi

exit 0
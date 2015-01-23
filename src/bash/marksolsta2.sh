#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : marksolsta.sh
                           NAME=marksolsta
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : DEC-2013
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : extract processed stations and baselines for each network from a
##                         solution summary file (e.g. FG[YEAR][DOY]0.SUM). Will need the
##                         following files:
##                         * FG[YEAR][DOY]0.SUM, placed in /media/Seagate/solutions52/[YEAR]/[DOY]
##                         * /home/bpe2/crd/[NETWORK].crd
##                         * /home/bpe2/data/GPSDATA/CAMPAIGN52/GREECE/STA/IGB08_R.CRD
##                         Networks available are:  greece, uranus, santorini, metrica
##                         Output is printed in stdout
## uses                  : * awk, grep, [/home/bpe2/unix-geo-tools/bin/x]yz2flh
## notes                 :
## TODO                  :
## detailed update list  : DEC-2013 added help function and header
##                         DEC-2014 major revision
                           LAST_UPDATE=DEC-2014
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
  echo " Purpose : Extract processed stations and baselines given a solution summary file"
  echo ""
  echo " Usage   : marksolsta.sh -y [year] | -d [doy] | -n [network] | -t [TYPE] | "
  echo ""
  echo " Switches: "
  echo "           -s --solution-file= specify the solution summary file."
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status: >0 -> error"
  echo " Exit Status:  0  -> sucesseful exit"
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
SOLUTION_FILE=

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi
# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o hvs: \
  -l  help,version,solution-file: \
  -n 'marksolsta' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvs: "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -s|--solution-file)
      SOLUTION_FILE="${2}"; shift;;
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
# CHECK THAT AT LEAST THE NEEDED VARIABLES ARE SET & VALID
# //////////////////////////////////////////////////////////////////////////////
if test -z $SOLUTION_FILE ; then
  echo "ERROR! Need to specify solution summary file"
  exit 1
fi
if ! test -f $SOLUTION_FILE ; then
  echo "ERROR! Cannot find specified summary file $SOLUTION_FILE"
  exit 1
fi


#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : updsta.sh
                           NAME=updsta
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
  echo " Purpose : Update station specific time-series files using a Bernese .OUT file."
  echo "           This script will do the following:"
  echo "           * extract coordinates and corresponding rms values from a Bernese GPSEST"
  echo "             .OUT file, for the given list of stations."
  echo "           * search for the appropriate time-series files, to write the collected"
  echo "             info. For 'final' solution, it will search for the file:"
  echo "             \${some_path}/\${station}/\${station}.[c|g].cts, whereas for"
  echo "             rapid/ultra-rapid solution, it will search for the file:"
  echo "            \${some_path}/\${station}/\${station}.[c|g].ctsR"
  echo "          * If the file is found, the script will perform two tasks:"
  echo "            [1] it will apend a record with the info exctracted from the .OUT"
  echo "            file, which will have the form:"
  echo ""
  echo " Usage   :"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches: -f --station-file= specify a station file. This file should contain"
  echo "            the names of all stations to be updates in a whitespace seperated"
  echo "            line."
  echo "           -t --type= specify the type of the solution; this can be either"
  echo "              * f for final, or"
  echo "              * u for ultra-rapid/rapid"
  echo "            Depending on this option, the corresponding time-series file will"
  echo "            be updated"
  echo "           -p --path= specify path to station-specific folders"
  echo "           -o --output-file= specify the Bernese .OUT file, from which to extract"
  echo "            coordinate and rms information"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
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
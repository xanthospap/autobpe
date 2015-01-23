#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : meta2xml.sh
                           NAME=meta2xml
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : meta2xml AMBIGUITYFILE
## exit code(s)          : 0 -> sucess
##                         1 -> failure
## discription           : This file will read product meta files and compile a
##                         report in xml format. The format and structure of the
##                         meta files must match _exactly_ the guidelines specified
##                         below.
## uses                  : sed, head, read, awk, block_amb_read
## needs                 : 
## notes                 : 
## TODO                  : DIRECT L1 / L2 not tested
## WARNING               : No help message provided.
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

#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : syncwbern_52.sh
                           NAME=syncwbern_52
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAY-2013
## usage                 : syncwbern_52.sh
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : update the local GEN directory with the remote one on CODE.
##                         (i.e. from aiub/BSWUSER52/GEN/ remote directory). If successeful,
##                         the timestamp will be written in file: ${HOME}/bern52_GEN_upd.
## uses                  : getopt, lftp
## notes                 : 
## TODO                  :
## detailed update list  :
##                       : MAY-2013 Fixed silent mode
##                         DEC-2013 Added header
##                         NOV-2014 Major revision
                           LAST_UPDATE=NOV-2014
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
  echo " Purpose : mirror the aiub/BSWUSER52/GEN/ remote directory"
  echo ""
  echo " Usage   : syncwbern.sh -t -l"
  echo ""
  echo " Switches: "
  echo "           -t --target-directory= specify target directory in local host"
  echo "           -b --bernese-loadvar= specify a Bernese source file (i.e. the file"
  echo "            BERN52/GPS/EXE/LOADGPS.setvar) which can be sourced; if such a file"
  echo "            is set, then the local target directory is defined by the variable"
  echo "            \$X\GEN"
  echo "           -o --logfile= specify log file"
  echo "           -q --quite do not show progress on screen"
  echo "           -s --stamp-file= specify a file where the time stamp of current run"
  echo "            will be written, so that the user can keep track of when the last"
  echo "            mirroring was done"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status: 1 -> error"
  echo " Exit Status: 0 -> sucess"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo " Note that if both -t and -b switches are used, the target directory is the one specified"
  echo " by the -b option (i.e. using the LOADGPS.setvar file)."
  echo " The file DE200.EPH is excluded from synchronization."
  echo ""
  echo " WARNING !! The long options are only available if the GNU-enhanced version of getopt is"
  echo "            available; else, the user must only use short options"
  echo ""
  echo "/******************************************************************************************/"
  exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
TARGET=
LOADVAR=
SOURCE_FTP=ftp.unibe.ch
SOURCE_DIR=aiub/BSWUSER52/GEN/
LOG_FILE=
QUITE_MODE=NO
STAMP_FILE=/dev/null

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi
# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o t:b:o:qs:hv \
  -l target-directory:,bernese-loadvar:,logfile:,quite,stamp-file:,help,version \
  -n 'syncwbern_52.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt t:b:o:qs:hv "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 1 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -t|--target-directory)
      TARGET="$2";     shift;;
    -b|--bernese-loadvar)
      LOADVAR="$2";    shift;;
    -o|--logfile)
      LOGFILE="$2";    shift;;
    -q|--quite)
      QUITE_MODE=YES;;
    -s|--stamp-file)
      STAMP_FILE="$2"; shift;;
    -h|--help)
      help;            exit 0;;
    -v|--version)
      dversion;        exit 0;;
    --) # end of options
      shift; break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 1 ;;
  esac
  shift 
done

# //////////////////////////////////////////////////////////////////////////////
# IF LOADVAR IS SET, TRY SOURCING THE FILE
# //////////////////////////////////////////////////////////////////////////////
if [ ! -z "$LOADVAR" ]; then
  if [ ! -f "$LOADVAR" ]; then
    echo "*** Error sourcing the Bernese LOADVAR file: $LOADVAR ; fatal"
    exit 1
  else
    . $LOADVAR
    TARGET=${X}/GEN
  fi
fi
if [ ! -d $TARGET ]; then
  echo "*** Target directory $TARGET does not exist; fatal"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT lftp EXISTS
# //////////////////////////////////////////////////////////////////////////////
hash lftp 2>/dev/null || { echo "*** Routine lftp not available; fatal"; exit 1; }

# //////////////////////////////////////////////////////////////////////////////
# CHECK LOG FILE; IF DEFINED CREATE, ELSE SET TO /dev/null
# //////////////////////////////////////////////////////////////////////////////
if [ ! -z "$LOGFILE" ]; then
  if [ ! -f $LOG_FILE ]; then
    > $LOGFILE 2>/dev/null
    if [ "$?" -ne 0 ]; then
      if [ "$QUITE_MODE" == "NO" ]; then echo "Warning! Could not create log file: $LOGFILE"; fi
      LOGFILE=/dev/null
    fi
  fi
else
  LOGFILE=/dev/null
fi

# //////////////////////////////////////////////////////////////////////////////
# MIRROR SOURCE TO TARGET
# //////////////////////////////////////////////////////////////////////////////
if [ "$QUITE_MODE" == "NO" ]; then echo "Synchronizing $TARGET WITH ${SOURCE_DIR} @ ${SOURCE_FTP}"; fi

if [ "$QUITE_MODE" = "NO" ]; then
  lftp $SOURCE_FTP << EOF
cd ${SOURCE_DIR}
mirror --only-newer --exclude DE200.EPH --log=$LOG_FILE ./ ${TARGET}
EOF
  STATUS=`echo $?`

else
    lftp $SOURCE_FTP << EOF > /dev/null
cd $SOURCE_DIR
mirror --only-newer --exclude DE200.EPH --log=$LOG_FILE ./ $TARGET
EOF
  STATUS=`echo $?`
fi

# //////////////////////////////////////////////////////////////////////////////
# WRITE THE DATE OF LAST UPDATE
# //////////////////////////////////////////////////////////////////////////////
if [ $STATUS -eq 0 ]; then
  TODAY=`date +%d-%b-%Y`
  echo "$TODAY (syncwbern_52.sh)" > $STAMP_FILE
fi

# //////////////////////////////////////////////////////////////////////////////
# RETURN THE STATUS (OF mirror)
# //////////////////////////////////////////////////////////////////////////////
exit $STATUS

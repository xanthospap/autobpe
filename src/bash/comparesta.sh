#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : comparesta.sh
                           NAME=comparesta
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAY-2013
## usage                 : <comparesta.sh>
## exit code(s)          : 0 -> Success
##                       : 1 -> Error
##                       : 2 -> Some of the stations differ
## discription           : Compare two .STA (station information) files. In case
##                         differences are found, a file will be created for the
##                         the station in [STATION].diff
## uses                  : egrep, diff, awk, wget
## notes                 :
## TODO                  :
## detailed update list  : DEC-2013 Header added
##                         DEC-2014 Major revision
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
# HELPMESSAGE
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Compare two Bernese(52)-formated .STA (station information) files."
  echo ""
  echo " Usage   : <comparesta.sh> "
  echo ""
  echo " Switches:"
  echo "           -s --stations specify stations to compare seperated by "
  echo "            whitespace (e.g -s penc pdel ...)"
  echo "           -f --station-file give a file specifying stations to be compared"
  echo "            File must have one line, where each station is seperated"
  echo "            by a whitespace character."
  echo "           -r --reference-sta name of the reference .STA file to compare."
  echo "            This file will be downloaded from AIUB ftp directory (e.g. EUREF.STA, ...)."
  echo "            Default option is EUREF_FULL.STA"
  echo "           -c --local-sta the (local) .sta file to be compared against the reference"
  echo "            .sta file"
  echo "           -l --log-dir specify directory to output the [station].diff files; default"
  echo "            is ./"
  echo "           -n --name-mismatch do not report any naming mismatch, i.e. if names in one"
  echo "            of the .STA files is reported as 'NAME NUBMER' and in the ohter as 'NAME'"
  echo "           -h --help print help message and exit"
  echo "           -v --version print version and exit"
  echo ""
  echo " Exit Status:  1 -> Error"
  echo " Exit Status:  0 -> Station records are the same"
  echo " Exit Status:  2 -> Some of the stations differ"
  echo ""
  echo " Note that if a station is reported in the two .STA files with different naming convention"
  echo " i.e as 'NAME NUMER' and 'NAME', then this will only produce a warning message (can be"
  echo " suppressed using the -n option) and will not triger an exit status of 1."
  echo " If a station is missing from one or both of the .STA files, no comparisson is made, and"
  echo " exit status is not set to 1."
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
# DEFAULT VARIABLES
# //////////////////////////////////////////////////////////////////////////////
REFERENCE_STA=EUREF_FULL.STA
LOCAL_STA=
STATIONS=()
ST_FILE=0
LOGS=
PRINT_NAME_MIS=YES

# //////////////////////////////////////////////////////////////////////////////
# COMMAND LINE ARGUMENTS:
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" -eq 0 ]; then
  echo "*** Must at least specify a station information file"
  help
  exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--stations)
      shift
      while [ $# -gt 0 ]
      do
        j=$1
        if [ ${j:0:1} == "-" ]
        then
          break
        else
          STATIONS+=($j)
          shift
        fi
      done
      ;;
    -f|--station-file)
      ST_FILE=${2}
      shift 2;;
    -r|--reference-sta)
      REFERENCE_STA=${2}
      shift 2;;
    -l|--log-dir)
      LOGS=${2}
      shift 2;;
    -c|--local-sta)
      LOCAL_STA=${2}; shift 2 ;;
    -h|--help)
      help
      exit 0
      ;;
    -v|--version)
      dversion
      exit 0
      ;;
    -n|--name-mismatch)
      PRINT_NAME_MIS=NO; shift ;;
    *)
      echo "Unknown command line option: $1"
      help
      exit 1
  esac
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT /home/bpe2/logs EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $LOGS ]; then
  echo "*** ERROR! Directory $LOGS does not exist"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT LOCAL .STA DOES EXIST
# //////////////////////////////////////////////////////////////////////////////
if [ ! -f ${LOCAL_STA} ]; then
  echo "*** Cannot locate .sta file to compare: ${LOCAL_STA}"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# IF FILE IS GIVEN, ADD ITS ENTRIES TO THE STATION LIST
# //////////////////////////////////////////////////////////////////////////////
if [ "$ST_FILE" != "0" ]; then
  if [ -f "$ST_FILE" ]; then
    STATIONS2=()
    IFS=' ' read -a STATIONS2 <<< `cat $ST_FILE | tr 'a-z' 'A-Z'`
    for i in "${STATIONS2[@]}"
    do
      STATIONS+=(${i})
    done
  else
    echo "*** File ${ST_FILE} does not exist!"
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# DOWNLOAD REFERENCE STA FILE
# //////////////////////////////////////////////////////////////////////////////
wget -q -O ${REFERENCE_STA} ftp://ftp.unibe.ch/aiub/BSWUSER52/STA/${REFERENCE_STA}
if [ "$?" -ne 0 ]; then
  echo "*** Failed to download reference .sta file: ${REFERENCE_STA}"
  rm ${REFERENCE_STA} 2>/dev/null
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# MAKE TEMPORARY .STA FILES TO COMPARE
# THESE FILES ONLY SPAN TYPE 001 UP TO TYPE 003
# //////////////////////////////////////////////////////////////////////////////
EXIT_STATUS=0
awk '/TYPE 001:/{f=1;print;next}f&&/TYPE 003:/{exit}f' ${REFERENCE_STA} \
 | sed 's|EUREF.SNX||g' | sed 's|STN||g' \
 | sed 's|IGS.SNX||g' > .rs.tmp
awk '/TYPE 001:/{f=1;print;next}f&&/TYPE 003:/{exit}f' ${LOCAL_STA} \
 | sed 's|EUREF.SNX||g' | sed 's|STN||g' \
 | sed 's|IGS.SNX||g' > .ls.tmp
cat .rs.tmp | awk '{print substr($0,0,204)}' > .koko && mv .koko .rs.tmp
cat .ls.tmp | awk '{print substr($0,0,204)}' > .koko && mv .koko .ls.tmp

for station in ${STATIONS[*]}; do
  STATION=${station^^}
  if [ -z "$LOGS" ]; then
    STA_LOG=${STATION}.diff
  else
    STA_LOG=${LOGS}/${STATION}.diff
  fi
  rm ${STA_LOG} 2>/dev/null
  egrep "${STATION} +" .rs.tmp 1>.${STATION}.rs 2>/dev/null
  egrep "${STATION} +" .ls.tmp 1>.${STATION}.ls 2>/dev/null
  if [ ! -s .${STATION}.rs ]; then
    echo "## Station ${STATION} missing from reference .sta file: ${REFERENCE_STA}"
    cat .${STATION}.ls > .${STATION}.rs
  fi
  if [ ! -s .${STATION}.ls ]; then
    echo "## Station ${STATION} missing from local .sta file: ${LOCAL_STA}"
    cat .${STATION}.rs > .${STATION}.ls
  fi
  diff -q .${STATION}.rs .${STATION}.ls &>/dev/null
  if [ $? -ne 0 ]; then
    ## check if the only differ in the naming convention, e.g.
    ## 22 1c1$
    ## 23 < ANKR 20805M002        001  1995 06 21 00 00 00                       ANKR*~~~~~~~~~~~~~~~~~$
    ## 24 ---$
    ## 25 > ANKR                  001  1995 06 21 00 00 00                       ANKR*~~~~~~~~~~~~~~~~~$
    diff .${STATION}.rs .${STATION}.ls >.tmp
    RESL=`cat .tmp | wc -l `
    RESE=`cat .tmp | egrep " 1c1$"`
    if [[ $RESL -eq 4 && $RESE -eq 0 ]]; then
      echo "## Possible naming mis-match in TYPE 001 for station: $STATION"
      if [ "$PRINT_NAME_MIS" == "YES" ]; then
        echo "--------------------------------------------------------------------"
        cat .tmp
        echo "--------------------------------------------------------------------"
      fi
    else
      echo "Station $station differs!"
      echo "** ${REFERENCE_STA} FILE CONTAINS: " > ${STA_LOG};
      cat .${STATION}.rs >> ${STA_LOG}
      echo "** ${LOCAL_STA} FILE CONTAINS: " >> ${STA_LOG};
      cat .${STATION}.ls >> ${STA_LOG}
      echo "** DIFF RESULT: " >> ${STA_LOG};
      diff .${STATION}.rs .${STATION}.ls >> ${STA_LOG};
      EXIT_STATUS=2
    fi
    rm .tmp
  fi
  rm .${STATION}.rs .${STATION}.ls
  if [ ! -s ${STA_LOG} ]; then rm ${STA_LOG} 2>/dev/null ; fi
done

# //////////////////////////////////////////////////////////////////////////////
# REMOVE THE DOWNLOADED REFERENCE STA
# //////////////////////////////////////////////////////////////////////////////
rm ${REFERENCE_STA} .rs.tmp .ls.tmp

# //////////////////////////////////////////////////////////////////////////////
# SUCCESEFUL EXIT
# //////////////////////////////////////////////////////////////////////////////
exit $EXIT_STATUS

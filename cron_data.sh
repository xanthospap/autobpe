#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : cron_data.sh
                           NAME=cron_data
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : 
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           :
## uses                  :
## dependancies          :
## notes                 : The script will download data for networks
##                         greece, uranus specified by the files
##                         \${TABLES}/crd/\${network}.[reg|epn|igs]
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
  echo " Purpose : Download GNSS data for automatic processing."
  echo ""
  echo " Usage   : cron_data"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches :"
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

##  Where is the DATAPOOL area?
POOL=/home/bpe2/data/GPSDATA/DATAPOOL

## Log file
LOG=/home/bpe2/log/cron_data$(/bin/date '+%Y-%m-%d')
>${LOG}

## Tables area
TBL=/home/bpe2/tables

##  All data will be placed at the DATAPOOL area

##  We will download data for yesterday and -20 days before.
##  First of all, we need to resolve the two dates, i.e. yesterday and -20 days.
##  Go ahead and do that.
YESTERDAY_STR=`/bin/date -d "1 day ago" '+%Y-%m-%d-%j-%w'`
YESTERDAY=()
IFS='-' read -a YESTERDAY <<< "${YESTERDAY_STR}"
if test ${#YESTERDAY[@]} -ne 5
then
  echo "ERROR. FAILED TO RESOLVE YESTERDAY'S DATE"
  exit 1
fi

M20DAYS_STR=`/bin/date -d "20 days ago" '+%Y-%m-%d-%j-%w'`
M20DAYS=()
IFS='-' read -a M20DAYS <<< "${M20DAYS_STR}"
if test ${#M20DAYS[@]} -ne 5
then
  echo "ERROR. FAILED TO RESOLVE -20 DAYS DATE"
  exit 1
fi

##  Now we have two arrays containing the dates we want as
##  [YEAR(0),MONTH(1),DOM(2),DOY(3),DOW(4)]

##  NETWORK : GREECE
## ------------------------------------------------------------------
NTW=greece
NSG=0
/usr/local/bin/wgetigsrnx --station-file ${TBL}/crd/${NTW}.igs \
                          --year ${YESTERDAY[0]} \
                          --doy ${YESTERDAY[3]} \
                          --output-directory ${POOL} \
                          --force-remove \
                          --decompress \
                          &>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE IGS STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

/usr/local/bin/wgetepnrnx --station-file ${TBL}/crd/${NTW}.epn \
                          --year ${YESTERDAY[0]} \
                          --doy ${YESTERDAY[3]} \
                          --output-directory ${POOL} \
                          --force-remove \
                          --decompress \
                          &>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE EPN STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

/usr/local/bin/wgetregrnx --station-file ${TBL}/crd/${NTW}.reg \
                          --year ${YESTERDAY[0]} \
                          --doy ${YESTERDAY[3]} \
                          --output-directory ${POOL} \
                          --force-remove \
                          --decompress \
                          --fix-header \
                          &>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE REG STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

echo "DOWNLOADED $NSG STATIONS FOR NETWOK GREECE FOR YESTERDAY"

##  Download the data for -20 days; do not force remove old data, most
##+ should already be here.
NSG=0
/usr/local/bin/wgetigsrnx --station-file ${TBL}/crd/${NTW}.igs \
                          --year ${M20DAYS[0]} \
                          --doy ${M20DAYS[3]} \
                          --output-directory ${POOL} \
                          --decompress \
                          &>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE IGS STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

/usr/local/bin/wgetepnrnx --station-file ${TBL}/crd/${NTW}.epn \
                          --year ${M20DAYS[0]} \
                          --doy ${M20DAYS[3]} \
                          --output-directory ${POOL} \
                          --decompress \
                          &>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE EPN STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

/usr/local/bin/wgetregrnx --station-file ${TBL}/crd/${NTW}.reg \
                          --year ${M20DAYS[0]} \
                          --doy ${M20DAYS[3]} \
                          --output-directory ${POOL} \
                          --decompress \
                          --fix-header \
                          &>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE REG STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

echo "DOWNLOADED $NSG STATIONS FOR NETWOK GREECE FOR FINAL"

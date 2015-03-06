#!/bin/bash

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

## Export the full PATH
export PATH="${PATH}:/usr/local/bin"

##  Where is the DATAPOOL area?
POOL=/home/bpe2/data/GPSDATA/DATAPOOL

## Temp area
TMP=/home/bpe2/tmp

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
                          &>>${LOG}
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
                          &>>${LOG}
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
                          &>>${LOG}
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
                          &>>${LOG}
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
                          &>>${LOG}
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
                          &>>${LOG}
STATUS=$?
if test $STATUS -gt 250
then
  echo "ERROR DOWNLOADING GREECE REG STATIONS"
  exit 1
fi
NSG=$((NSG + STATUS))

echo "DOWNLOADED $NSG STATIONS FOR NETWOK GREECE FOR FINAL"

## DECOMPRESS THE RINEX : HATANAKA -> PLAIN RINEX
for crx in ${POOL}/????${M20DAYS[3]}0.${M20DAYS[0]:2:2}d
do
  /usr/local/bin/crx2rnx $crx 2>/dev/null
  if test $? -eq 0
  then
    rm $crx
  else
    echo "Failed to decompress (Hatanaka) rinex $crx" >> ${LOG}
  fi
done

for crx in ${POOL}/????${YESTERDAY[3]}0.${YESTERDAY[0]:2:2}d 
do
  /usr/local/bin/crx2rnx $crx 2>/dev/null
  if test $? -eq 0
  then
    rm $crx
  else
    echo "Failed to decompress (Hatanaka) rinex $crx" >> ${LOG}
  fi
done

## MAKE MULTIPATH PLOTS IN $HOME/TMP DIRECTORY
## get broadcast ephemeris
brdc=brdc${M20DAYS[3]}0.${M20DAYS[0]:2:2}n
wget -q -O ${POOL}/${brdc}.Z ftp://cddis.gsfc.nasa.gov/gnss/data/daily/${M20DAYS[0]}/${M20DAYS[3]}/${M20DAYS[0]:2:2}n/${brdc}.Z
if test $? -ne 0
then
  brdc=NO
  echo "Failed to get brdc file ftp://cddis.gsfc.nasa.gov/gnss/data/daily/${M20DAYS[0]}/${M20DAYS[3]}/${M20DAYS[0]:2:2}n/${brdc}.Z" >> ${LOG}
fi

if test "${brdc}" != "NO"
then
    uncompress -f ${POOL}/${brdc}.Z
    for rnx in ${POOL}/????${M20DAYS[3]}0.${M20DAYS[0]:2:2}o
    do
        TRNX=`basename $rnx`
        sta=${TRNX:0:4}
        if ! test -f /home/bpe2/tmp/${sta^^}-${M20DAYS[0]}${M20DAYS[1]}${M20DAYS[2]}-cf2sky.ps
        then
          /usr/local/bin/teqc +qc $rnx &>${TMP}/${sta^^}-${M20DAYS[0]}${M20DAYS[1]}${M20DAYS[2]}-qc
          /usr/local/bin/skyplot -r ${POOL}/${brdc} -c 3 -x ${rnx} -o /home/bpe2/tmp &>>${LOG}
          rnx_ne=${rnx/${M20DAYS[0]:2:2}o/}
          for k in iod ion mp1 mp2 sn1 sn2
          do
            mv ${rnx_ne}.${k} ${TMP} 2>/dev/null
          done
          mv ${rnx/%o/S} ${TMP} 2>/dev/null
        fi
    done
fi
if ! test -s ${TMP}/${sta^^}-${M20DAYS[0]}${M20DAYS[1]}${M20DAYS[2]}-cf2sky.ps
then
  echo "[WARNING] Plot file ${TMP}/${sta^^}-${M20DAYS[0]}${M20DAYS[1]}${M20DAYS[2]}-cf2sky.ps has zero size"
  echo "[WARNING] Deleting plot file"
  rm ${TMP}/${sta^^}-${M20DAYS[0]}${M20DAYS[1]}${M20DAYS[2]}-cf2sky.ps
fi

brdc=brdc${YESTERDAY[3]}0.${YESTERDAY[0]:2:2}n
wget -q -O ${POOL}/${brdc}.Z ftp://cddis.gsfc.nasa.gov/gnss/data/daily/${YESTERDAY[0]}/${YESTERDAY[3]}/${YESTERDAY[0]:2:2}n/${brdc}.Z
if test $? -ne 0
then
  brdc=NO
  echo "Failed to get brdc file ftp://cddis.gsfc.nasa.gov/gnss/data/daily/${YESTERDAY[0]}/${YESTERDAY[3]}/${YESTERDAY[0]:2:2}n/${brdc}.Z" >> ${LOG}
fi

if test "${brdc}" != "NO"
then
    uncompress -f ${POOL}/${brdc}.Z
    for rnx in ${POOL}/????${YESTERDAY[3]}0.${YESTERDAY[0]:2:2}o
    do
        TRNX=`basename $rnx`
        sta=${TRNX:0:4}
        if ! test -f /home/bpe2/tmp/${sta^^}-${YESTERDAY[0]}${YESTERDAY[1]}${YESTERDAY[2]}-cf2sky.ps
        then
          /usr/local/bin/teqc +qc $rnx &>${TMP}/${sta^^}-${YESTERDAY[0]}${YESTERDAY[1]}${YESTERDAY[2]}-qc
          /usr/local/bin/skyplot -r ${POOL}/${brdc} -c 3 -x ${rnx} -o /home/bpe2/tmp &>>${LOG}
          rnx_ne=${rnx/${YESTERDAY[0]:2:2}o/}
          for k in iod ion mp1 mp2 sn1 sn2
          do
            mv ${rnx_ne}.${k} ${TMP} 2>/dev/null
          done
          mv ${rnx/%o/S} ${TMP} 2>/dev/null
        fi
    done
fi
if ! test -s ${TMP}/${sta^^}-${YESTERDAY[0]}${YESTERDAY[1]}${YESTERDAY[2]}-cf2sky.ps
then
  echo "[WARNING] Plot file ${TMP}/${sta^^}-${YESTERDAY[0]}${YESTERDAY[1]}${YESTERDAY[2]}-cf2sky.ps has zero size"
  echo "[WARNING] Deleting plot file"
  rm ${TMP}/${sta^^}-${YESTERDAY[0]}${YESTERDAY[1]}${YESTERDAY[2]}-cf2sky.ps
fi

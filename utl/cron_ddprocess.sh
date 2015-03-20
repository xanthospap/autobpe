#!/bin/bash

export PATH="${PATH}:/usr/local/bin"

YESTERDAY_STR=`/bin/date -d "1 day ago" '+%Y-%m-%d-%j-%w'`
YESTERDAY=()
IFS='-' read -a YESTERDAY <<< "${YESTERDAY_STR}"
if test ${#YESTERDAY[@]} -ne 5
then
  echo "ERROR. FAILED TO RESOLVE YESTERDAY'S DATE"
  exit 1
fi

/usr/local/bin/ddprocess \
  --analysis-center=cod \
  --bernese-loadvar=/home/bpe2/bern52/BERN52/GPS/EXE/LOADGPS.setvar \
  --campaign=GREECE \
  --doy="${YESTERDAY[3]}" \
  --elevation-angle=7 \
  --ion-products=FFG,FRG \
  --solution-id=UFG \
  --stations-per-cluster=4 \
  --calibration-model=I08 \
  --pcv-file=PCV_GRE \
  --save-dir=/media/Seagate/solutions52/${YESTERDAY[0]}/${YESTERDAY[3]} \
  --satellite-system=gps \
  --solution-type=urapid \
  --update=all \
  --year=${YESTERDAY[0]} \
  --xml-output \
  --force-remove-previous

## synchronize the remote server
/home/bpe2/cron/syncweb.sh

M20DAYS_STR=`/bin/date -d "20 days ago" '+%Y-%m-%d-%j-%w'`
M20DAYS=()
IFS='-' read -a M20DAYS <<< "${M20DAYS_STR}"
if test ${#M20DAYS[@]} -ne 5
then
  echo "ERROR. FAILED TO RESOLVE -20 DAYS DATE"
  exit 1
fi

/usr/local/bin/ddprocess \
  --analysis-center=cod \
  --bernese-loadvar=/home/bpe2/bern52/BERN52/GPS/EXE/LOADGPS.setvar \
  --campaign=GREECE \
  --doy="${M20DAYS[3]}" \
  --elevation-angle=7 \
  --ion-products=FFG,FRG \
  --solution-id=FFG \
  --stations-per-cluster=4 \
  --calibration-model=I08 \
  --pcv-file=PCV_GRE \
  --save-dir=/media/Seagate/solutions52/${M20DAYS[0]}/${M20DAYS[3]} \
  --satellite-system=gps \
  --solution-type=final \
  --update=all \
  --year=${M20DAYS[0]} \
  --xml-output

## synchronize the remote server
/home/bpe2/cron/syncweb.sh

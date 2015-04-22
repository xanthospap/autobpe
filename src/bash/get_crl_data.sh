#! /bin/bash

##
## Give a year and a doy, this script will download CRL raw data from
## GeoAzur ftp and then translate them to RINEX
##
## We need two command line arguments:
## ARGV[1] = YEAR (4-digit)
## ARGV[2] = DOY

if test $# -ne 2
then
    echo "ERROR (get_crl_data). Need both year and doy" >&2
    exit 1
fi

## Year and doy
YEAR=$1
DOY=$2

## Check year and dooy are ints
re='^[0-9]+$'
if ! [[ $YEAR =~ $re ]]
then
    echo "ERROR (get_crl_data). Year must be an int" >&2
    exit 1
else
    if ! [[ $DOY =~ $re ]]
    then
        echo "ERROR (get_crl_data). Doy must be an int" >&2
    fi
fi

## FTP server
HOST='omiv.unice.fr'
USER='crlabguest'
PASSWD='corinthegnss'

## List of CRL stations
VALID_STATIONS=(koun eypa lamb lido triz krin meso rod3 xili psar)

## Compute month and day-of-month
MONTH=`date -d "${YEAR}-01-01 +${DOY} days -1 day" "+%m" 2>/dev/null`
DOM=`date -d "${YEAR}-01-01 +${DOY} days -1 day" "+%d" 2>/dev/null`
if test $? -ne 0
then
    echo "ERROR (get_crl_data). Failed to compute month/day-of-month" >&2
    exit 1
fi

## Compile the raw data files we will request
## Place all data files in a whitespace-seperated string
DATA_FILES=()
FILE_STRING=
for i in "${VALID_STATIONS[@]}"
do
    raw=${i}${MONTH}${DOM}0.tps
    DATA_FILES+=("${raw}")
    FILE_STRING="${FILE_STRING} ${raw}"
done

ftp -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
cd raw/$YEAR
binary
prompt
mget $FILE_STRING
bye
quit
END_SCRIPT


## Exit
exit 0

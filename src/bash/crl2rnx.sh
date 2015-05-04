#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : crl2rnx.sh
                           NAME=crl2rnx.sh
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : APR-2015
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : 
## uses                  : 
## notes                 :
## TODO                  : 
## detailed update list  : 
                           LAST_UPDATE=APR-2015
##
##
################################################################################

# //////////////////////////////////////////////////////////////////////////////
# DISPLAY VERSION
# //////////////////////////////////////////////////////////////////////////////
function dversion {
  echo "${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
  exit 0
}

# ////////////////////////////////////////////////////////////////////////////
# HELP
# ////////////////////////////////////////////////////////////////////////////
function help {
    echo "/*****************************************************************/"
    echo " Program Name : $NAME"
    echo " Version      : $VERSION"
    echo " Last Update  : $LAST_UPDATE"
    echo ""
    echo " Purpose      : Transform raw data files from CRL network to RINEX."
    echo ""
    echo " Usage        : User must specify at least year and day of year (doy)."
    echo "                If no stations specified (via the -s option) then the"
    echo "                script will search for any of the crl stations (i.e"
    echo "                koun eypa lamb lido triz krin meso rod3 xili psar) and"
    echo "                translate all raw data files that belong to the given"
    echo "                date. If the files are located in a different (from"
    echo "                current) directory, you can specify the path via the"
    echo "                -p option. If the user only wants a selected set of "
    echo "                data files to be translated, then these can be specified"
    echo "                using the -s switch."
    echo ""
    echo " Switches     : -y --year= Specify year (2-digit or 4-digit)"
    echo "                -d --doy=  Specify day of year"
    echo "                -s --stations= Specify stations; comma seperated list"
    echo "                 e.g. --stations=koun,eypa,psar[,...]"
    echo "                 Do not use paths, only station names. The path (if any)"
    echo "                 can be specified via the '-d' switch"
    echo "                -p --path= Specify the path where the raw data"
    echo "                 files are located (absolute or relative)"
    echo ""
    echo " Examples     : crl2rnx.sh -y 15 -d 110 -p /home/xanthos/crl"
    echo "                will search through the /home/xanthos/crl directory"
    echo "                and translate all raw data files, e.g."
    echo "                Translated raw data file /home/xanthos/crl/koun04200.tps \/" 
    echo "                to /home/xanthos/crl/koun1100.15o"
    echo "                crl2rnx.sh -y 15 -d 110 -p /home/xanthos/crl -s koun,lido"
    echo "                will only translate the raw data files: "
    echo "                /home/xanthos/crl/koun04200.tps and"
    echo "                /home/xanthos/crl/lido04200.tps, if found"
    echo ""
    echo " Exit Status  : 1 -> Error"
    echo " Exit Status  : 0 -> Sucess"
    echo ""
    echo " Bugs         : Please send any bugs to xanthos@mail.ntua.gr"
    echo "                                     or  danast@mail.ntua.gr"
    echo ""
    echo "/*****************************************************************/"
    exit 0
}

function station_sentence ()
{
    sta=${1^^}
    sntc=`awk -F',' -v st="$sta" '$1 ~ st { print $0 }' <<EOF
KOUN,Kounina,0767,JPSLEGANT_E,T225236,'TPS GB-1000',4651613.,1883702.,3924106.
EYPA,Efpalion,2766,JPSLEGANT_E,T225125,'TPS GB-1000',4641300.,1868463.,3942786.
LAMB,Lambiri,308-1234,TPSPG_A1,T225083,'TPS GB-1000',4646522.,1874784.,3933432.
LIDO,Lidoriki,0979,JPSLEGANT_E,xxxxxx,'TPS GB-1000',4626107.,1887975.,3951918.
TRIZ,Trizonia,0767,JPSLEGANT_E,618-02648,'TPS NET-G3A',4640396.,1881698.,3937360.
KRIN,Krini,374-1274,TPSPG_A1,T225915,'TPS GB-1000',4655852.,1877291.,3922477.
MESO,Mesologhi,308-5579,TPSPG_A1,T225231,'TPS GB-1000',4659694.,1833149.,3937429.
ROD3,Rodini3,308-0000,TPSPG_A1,T225045,'TPS GB-1000',4650274.,1868671.,3932631.
XILI,Xiliadou,308-6026,TPSPG_A1,618-02631,'TPS NET-G3A',4644380.,1868139.,3939073.
PSAR,Psaromita,308-3529,TPSPG_A1,T225081,'TPS GB-1000',4639531.,1891875.,3933580.
EOF`

    if test "${sntc:0:4}" != "${sta}" ## also check NF
    then
        return 1  ## error
    else
        echo "${sntc}"
        return 0  ## sucess
    fi
}

# ////////////////////////////////////////////////////////////////////////////
# CRL STATIONS
# ////////////////////////////////////////////////////////////////////////////
VALID_STATIONS=(koun eypa lamb lido triz krin meso rod3 xili psar)

# ////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# ////////////////////////////////////////////////////////////////////////////

if test "$#" -eq 0 ## Need to provide at least year and doy
then 
    help
fi

##  Call getopt to validate the provided input.
##+ This depends on the getopt version available
getopt -T > /dev/null

if test "$?" -eq 4
then ## GNU enhanced getopt is available
  ARGS=`getopt -o y:d:s:p:hv \
  -l year:,doy:,stations:,path:,help,version \
  -n 'crl2rnx' -- "$@"`
else ## Original getopt is available 
     ## (no long option names, no whitespace, no sorting)
  ARGS=`getopt y:d:s:p:hv "$@"`
fi

## Check for getopt error
if test "$?" -ne 0 
then 
    echo "getopt error code : $status ;Terminating..." >&2
    exit 1
fi

eval set -- $ARGS

## Extract options and their arguments into variables.
while true ; do
  case "$1" in
    -y|--year)
      YEAR="$2"
      shift;;
    -d|--doy)
      DOY=`echo "${2}" | sed 's|^0||g'`
      shift;;
    -s|--stations)
      STATIONS_STRING="$2"
      shift;;
    -p|--path)
      DIR="$2"
      shift;;
    -h|--help)
      help
      exit 0;;
    -v|--version)
      dversion
      exit 0;;
    --) ## end of options
      shift;
      break;;
     *) 
      echo "*** Invalid argument ${1}; skipped"
      ;;
  esac
  shift 
done

# ////////////////////////////////////////////////////////////////////////////
# CHECK COMMAND LINE ARGUMENTS
# ////////////////////////////////////////////////////////////////////////////

## If year is set, then doy must also be set
## If both are set, manipulate them
if [ ! -z ${YEAR+x} ]
then
    
    if [ -z ${DOY+x} ]
    then
        echo "ERROR. Year is set but doy is not! "
        exit 1
    else
        if test $DOY -lt 10
        then 
            DOY=00${DOY}
        elif test $DOY -lt 100
        then 
            DOY=0${DOY}
        else
            DOY=${DOY}
        fi
    fi

    if test "${#YEAR}" -eq 2
    then
        YR2=${YEAR}
        if test ${YR2} -lt 80
        then 
            YEAR=20${YR2};
        else
            YEAR=19${YR2};
        fi

    elif test "${#YEAR}" -eq 4
    then
        YR2=${YEAR:(-2)}

    else
        echo "ERROR. Invalid year : $YEAR"
        exit 1
    fi

    ## Compute month and day-of-month
    MONTH=`date -d "${YEAR}-01-01 +${DOY} days -1 day" "+%m" 2>/dev/null`
    DOM=`date -d "${YEAR}-01-01 +${DOY} days -1 day" "+%d" 2>/dev/null`
    if test $? -ne 0
    then
        echo "ERROR. Failed to compute month/day-of-month"
        exit 1
    fi

fi

## If doy is set, then year must also be set
if [ ! -z ${DOY+x} ] && [ -z ${YEAR+x} ]
then
    echo "ERROR. Doy is set but year is not! "
    exit 1
fi

## If input directory is set, check that it exists
if [ ! -z ${DIR+x} ] && [ ! -d $DIR ]
then
    echo "ERROR. Cannot find directory : $DIR"
    exit 1
fi
if [ ! -z ${DIR+x} ]
then
    ## add trailing '/' if it does not exist
    if test "${DIR:(-1)}" != "/"
    then
        DIR=${DIR}/
    fi
fi

# ////////////////////////////////////////////////////////////////////////////
# COMPILE A LIST OF ALL RAW DATA FILES WE WANT TO CONVERT
# ////////////////////////////////////////////////////////////////////////////

## If user already specified the stations, only use them
if [ ! -z ${STATIONS_STRING+x} ]
then
    STATIONS=()
    IFS=',' read -a STATIONS <<<"$STATIONS_STRING"

##  Else, search through the specified path, for files matching
##+ the pattern 'path/ssssmmdd?.tps', where 'ssss' must match one
##+ of the valid stations.
else
    for sta in "${VALID_STATIONS[@]}"
    do
        ## echo "searching for ${DIR}${sta}${MONTH}${DOM}?.tps"
        TMP_STA=()
        IFS=',' read -a TMP_STA <<< `ls ${DIR}${sta}${MONTH}${DOM}?.tps 2>/dev/null`
        if test "${#TMP_STA}" -gt 0
        then
            STATIONS+=("${sta}")
        fi
    done
fi

## If the station list is empty, nothing to do !
if test "${#STATIONS[@]}" -eq 0
then
    echo "No stations specified/found to convert!"
    exit 0
else
    echo "Number of raw data files: ${#STATIONS[@]}"
fi

# ////////////////////////////////////////////////////////////////////////////
# TRANSFORM EVERY RAW DATA FILE
# ////////////////////////////////////////////////////////////////////////////

## teqc translation options
# teqc_opt='-top tps -O.r CRLAB -O.obs l1+l2+ca+p1+p2 -O.ag CRL -O.o CRL -O.dec 30'
teqc_opt='-top tps -O.r DSO-HGL/NTUA -O.obs l1+l2+ca+p1+p2+s1+s2 -O.ag CRL -O.o CRL'

for i in "${STATIONS[@]}"
do
    ## raw data file is ( for session = 0 )
    raw=${DIR}${i}${MONTH}${DOM}0.tps

    ## get a list of raw data files, of the same date, depending on session
    session_files=(`ls ${DIR}${i}${MONTH}${DOM}?.tps`)

    ## get station information
    line=`station_sentence $i`
    if test "$?" -ne 0
    then
        echo "ERROR. Cannot find station information for $i"
        echo "instead got $line"
        exit 1
    fi

    ## split the station info, to get what we want
    name=`echo $line | awk -F',' '{print $2}'`
    antenna_nr=`echo $line | awk -F',' '{print $3}'`
    antenna=`echo $line | awk -F',' '{print $4}'`
    receiver_nr=`echo $line | awk -F',' '{print $5}'`
    receiver=`echo $line | awk -F',' '{print $6}'`
    xyz=`echo $line | awk -F',' '{print $7,$8,$9}'`

    ## loop through all data files for all sessions
    rinex_files=()
    for raw in "${session_files[@]}"
    do

        ## extract session identifier
        SESSION=${raw:(-5):1}

        ## how should the rinex be named ?
        rinex=${DIR}${i}${DOY}${SESSION}.${YR2}o

        ## run the command
        if ! teqc ${teqc_opt} -O.mo "${i^^}" -O.mn "${name}" -O.an "${antenna_nr}" \
            -O.at "${antenna}" -O.px ${xyz} ${raw} 1>${rinex} 2>/dev/null
        then
            echo "ERROR. Failed to translate raw data file : $raw (error code ${?})"
        else
            echo "Translated raw data file $raw to $rinex"
            rinex_files+=(${rinex})
        fi

    done

    ##  Handle 1sec rinex
    ##  In loop only if more than 5 sessions exist
    if test "${#rinex_files[@]}" -gt 5
    then
        echo "Merging rinex data (sampling rate = 30sec) for station ${i}"
        merge_w_teqc="teqc -O.dec 30 "
        for j in "${rinex_files[@]}"
        do
            merge_w_teqc="${merge_w_teqc} ${j}"
        done
        $merge_w_teqc > ${DIR}${i}.tmp
        mv ${DIR}${i}.tmp ${DIR}${i}${DOY}0.${YR2}o
    fi

done

# ALL DONE; EXIT
exit 0

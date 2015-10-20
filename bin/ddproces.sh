#! /bin/bash
CMD_THIS_HTML="$(basename $0) ${@}"

NAME=ddprocess
VERSION="0.90"
REVISION="-10"
LAST_UPDATE="Oct 2015"

# //////////////////////////////////////////////////////////////////////////////
# FUNCTIONS
# //////////////////////////////////////////////////////////////////////////////

##  echo to stderr
echoerr () { echo "$@" 1>&2; }

##  control perl script output
##  argv1 -> path to BPE
##  argv2 -> status filename (no path)
##  argv3 -> output filename (no path)
check_run () {

  bpe_path="$1"
  status_f="${bpe_path}/${2}"
  outout_f="${bpe_path}/${3}"

  if ! test -f ${status_f}; then
    echoerr "ERROR. Cannot find status file $status_f"
    return 1
  fi
  ## grep for error
  if grep "error" ${status_f} &>/dev/null ; then
    if ! test -d ${bpe_path}; then
      echoerr "ERROR. Invalid /BPE folder: $bpe_path"
      return 1
    fi
    for i in `ls ${bpe_path}/*.LOG`; do
      cat ${i} >&2
    done
    cat ${outout_f} >&2
    exit 1
  else ## no error hurray !!!!
    return 0
  fi
}

##  print help message
help ()
{
echo "
/******************************************************************************/
Program Name : $NAME
Version      : $VERSION
Last Update  : $LAST_UPDATE

Purpose : Process a network using DD approach via a given PCF file

Usage   :

Switches: -a --analysis-center= specify the analysis center; this can be e.g.
           * igs, or
           * cod (default)

          -b --bern-loadgps= specify the Bernese LOADGPS.setvar file; this
           is needed to resolve the Bernese-related path variables; it will be
           sourced.

          -c --campaign= specify the campaign name; the argument passed will be
           truncated to uppercase (thus passing 'greece' is the same as 'GREECE'
           --see Note 3

          -d --doy= specify doy

          -e --elevation-angle specify the elevation angle (degrees, integer)
           default value is 3 degrees

          -f --ion-products= specify (a-priori) ionospheric correction file identifier.
           If more than one, use a comma-seperated list (e.g. -f FFG,RFG) --see Note 5

          -g --tables-dir specify the TABLES directory

          -i --solution-id= specify solution id (e.g. FFG) --see Note 1

          -l --stations-per-cluster= specify the number of stations per cluster
           (default is 5)

          -m --calibration-model he extension (model) used for antenna calibration.
           This can be e.g. I01, I05 or I08. What you enter here, will be appended to
           the pcv filename (provided via the -f switch) and all calibration-dependent
           Bernese processing files (e.g. SATELLITE.XXX). --see Note 2

          -p --pcv-file= specify the .PCV file to be used --see Note 2

          -r --save-dir= specify directory where the solution will be saved; note that
           if the directory does not exist, it will be created

          -s --satellite-system specify the satellite system; this can be
           * gps, or
           * mixed (for gps + glonass)
           uppercase or lowercase. Default value is 'gps'

          -t --solution-type specify the dolution type; this can be:
           * final, or
           * urapid

          -u --update= specify which records/files should be updated; valid values are:
           * crd update the default network crd file
           * sta update station-specific files, i.e. time-series records for the stations
           * ntw update update network-specific records
           * all both the above
           More than one options can be provided, in a comma seperated string e.g. 
           --update=crd,sta
           See Note 6 for this option

          -y --year= specify year (4-digit)

          -x --xml-output produce an xml (actually docbook) output summary

          --force-remove-previous remove any files from the specified save directory (-r --save-dir=)
           prior to start of processing.

          --debug set debugging mode

          --add-suffix= add a suffix (e.g. _GPS) to saved products of the processing

          -h --help display (this) help message and exit

          -v --version display version and exit
/******************************************************************************/"
}

## validate entries in the TABLES_DIR directory
## argv1 -> TABLES_DIR
## argv2 -> CAMPAIGN NAME
check_tables () {
  for f in ${1}/pcv/${2} \
           ${1}/blq/${2}.BLQ \
           ${1}/atl/${2}.ATL \
           ${1}/crd/${2}.CRD \
           ${1}/atl/${2}52.STA; do
    if ! test -f $i ; then
      echoerr "Missing file: $i"
      return 1
    fi
  done

  return 0
}

##  year - doy to datetime in format '%Y-%m-%d %H-%M-%S'
##  argv1 -> year
##  argv2 -> (3-digit) doy
##  argv3 -> (optional) hours
##  argv4 -> (optional) minutes
##  argv5 -> (optional) seconds (integer)
ydoy2dt () {
  if [ "$#" -ne 2 ] && [ "$#" -ne 5 ] ; then
    echoerr "ERROR. Invalid argc in ydoy2dt(). Cannot parse date. ($#)"
    return 1
  fi

  local year="$1"
  local doy="$2"
  local hour="00"
  local min="00"
  local sec="00"

  if test "$#" -ne 2; then
    hour="$3"
    min="$4"
    sec="$5"
  fi

  python - <<END

import datetime
import sys

exit_status=0

try:
  # print "[python] trying to parse date [${year}-${doy} ${hour}:${min}:${sec}]"
  print datetime.datetime.strptime('${year}-${doy} ${hour}:${min}:${sec}', \
    '%Y-%j %H:%M:%S').strftime("%Y-%m-%d %H:%M:%S")
except:
  exit_status=1

sys.exit(exit_status)
END

  if test "$?" -ne 0 ; then
    date_str=
    for i in "${*}"; do date_str="${date_str} ${i}"; done
    echoerr "ERROR. Cannot resolve date: [${date_str}]"
    return 1
  else
    return 0
  fi
}

##
##  argv1 -> file extension (e.g. 'SNX')
##  argv2 -> campaign dir (e.g. 'SOL')
##  argv3 -> product type (e.g. 'SINEX')
##  argv4 -> (optional) sol type, i.e 'F' for final, 'R' for size-reduced and
##+          'P' for preliminery.
save_n_update () {

  local solution_id=

  if test "$#" -eq 4 ; then
    case "${4}" in
      F|f)
        solution_id=${FINAL_SOLUTION_ID}
        ;;
      R|r)
        solution_id=${REDUCED_SOLUTION_ID}
        ;;
      P|p)
        solution_id=${PRELIM_SOLUTION_ID}
        ;;
      *)
        echoerr "Invalid one-char solution id!"
        return 1
        ;;
    esac
  else
    if test "$#" -ne 3 ; then
      echoerr "Invalid call to save_n_update()."
      return 1
    else
      solution_id=${FINAL_SOLUTION_ID}
    fi
  fi
 
  local src_f=${solution_id}${YEAR:2:2}${DOY_3C}0.${1} ## source file
  local trg_f=${solution_id}${YEAR:2:2}${DOY_3C}0${APND_SUFFIX}.${1} ## target

  if cp ${P}/${CAMPAIGN}/${2}/${src_f} ${SAVE_DIR}/${YEAR}/${DOY_3C}/${trg_f} \
     && compress -f ${SAVE_DIR}/${YEAR}/${DOY_3C}/${trg_f} \
     && add_products_2db.py \
          --campaign-name=${CAMPAIGN} \
          --satellite-system=${DB_SAT_SYS} \
          --solution-type=DDFINAL \
          --product-type="${3}" \
          --start-epoch="${START_OF_DAY_STR/ /_}" \
          --end-epoch="${END_OF_DAY_STR/ /_}" \
          --host-ip="147.102.110.69" \
          --host-dir="${SOL_DIR}/${YEAR}/${DOY_3C}/" \
          --product-filename="${trg_f}.Z" ; then
#  printf "[SAVED::%s] File %s saved as %s.Z; " \
#          "$1" "$src_f" "$trg_f"
#  printf "Database entry inserted at 147.102.110.69%s\n" \
#          "${SOL_DIR}/${YEAR}/${DOY_3C}/"
#  printf "<tr><td>%s</td><td><code>%s</code></td><td><code>%s</code></td><td><code>%s</code></td><td>%s</td><td>%s</td></tr>\n" \
#          "${3}" "${src_f}" "${trg_f}.Z" "${SOL_DIR}/${YEAR}/${DOY_3C}/" \
#          "${START_OF_DAY_STR/ /_}" "${END_OF_DAY_STR/ /_}"
    printf "{\"prod_type\":\"%s\",\"extension\":\"%s\",\"local_dir\":\"%s\",\"sol_type\":\"%s\",\"filename\":\"%s\",\"savedas\":\"%s\",\"host\":\"%s\",\"host_dir\":\"%s\"}" \
      "${3}" "${1}" "${2}" "${solution_id}" "${src_f}" "${trg_f}.Z" "147.102.110.69" "${SOL_DIR}/${YEAR}/${DOY_3C}/"
  return 0
else
  echoerr "ERROR. Failed to save/record ${1} sinex : ${trg_f}"
  return 1
fi
}

# //////////////////////////////////////////////////////////////////////////////
# GLOBAL VARIABLES
# //////////////////////////////////////////////////////////////////////////////
DEBUG_MODE=NO

##  following variables should be set via cmd arguments (else error!)
# YEAR=
# DOY=
# B_LOADGPS=
# CAMPAIGN=
# LOGFILE=
# SOLUTION_ID=
# SAVE_DIR=
# APND_SUFFIX=

##  optional parameters; may be changes via cmd arguments
SAT_SYS=GPS
TABLES_DIR=${HOME}/tables
AC=COD
STATIONS_PER_CLUSTER=3
FILES_PER_CLUSTER=7
ELEVATION_ANGLE=3
PCF_FILE=NTUA_DDP.PCF

##  Ntua's product area
MY_PRODUCT_AREA=/media/Seagate/solutions52 ## add yyyy/ddd later on
# MY_PRODUCT_ID optionaly set via cmd, if we are going to search our products

##  database for local/user products
DB_HOST="147.102.110.73"
DB_USER="bpe2"
DB_PASSWORD="webadmin"
DB_DBNAME="procsta"

PATH=${PATH}:/home/bpe2/src/autobpe/bin

## ////////////////////////////////////////////////////////////////////////////
##  CREATE STAMP FILE
## ////////////////////////////////////////////////////////////////////////////

##  create/touch a file that won't do anything! It will just act as a time
##+ stamp; i.e. all files in the campaign-specific folders created/modified
##+ after this (the stamp file) are created/modified by the ddprocess script.
TIME_STAMP_FILE=".ddprocess-ts-${BASHPID}"
touch ${TIME_STAMP_FILE}
date > ${TIME_STAMP_FILE}

## ////////////////////////////////////////////////////////////////////////////
## GET/EXPAND COMMAND LINE ARGUMENTS
## ////////////////////////////////////////////////////////////////////////////

##  we nee to have at least some cmd arguments
if test $# -eq "0"; then help; fi

##  Call getopt to validate the provided input. This depends on the
##+ getopt version available.
getopt -T > /dev/null ## check getopt version

if test $? -eq 4; then
  ##  GNU enhanced getopt is available
  ARGS=`getopt -o hvy:d:b:c:s:g:r:i:e:a: \
-l  help,version,year:,doy:,bern-loadgps:,campaign:,satellite-system:,tables-dir:,debug,logfile:,stations-per-cluster:,save-dir:,solution-id:,files-per-cluster:,elevation-angle:,analysis-center:,use-ntua-products:,append-suffix: \
-n 'ddprocess' -- "$@"`
else
  ##  Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvy:d:b:c:s: "$@"`
fi

##  check for getopt error
if test $? -ne 0; then
  echoerr "getopt error code : $status ;Terminating..." >&2
  exit 1
fi

eval set -- $ARGS

##  extract options and their arguments into variables.
printf "{command:["
while true
do
  case "$1" in

    --use-ntua-products)
      MY_PRODUCT_ID="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -r|--save-dir)
      SAVE_DIR="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -i|--solution-id)
      SOLUTION_ID="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -a|--analysis-center)
      AC="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -b|--bern-loadgps)
      B_LOADGPS="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -c|--campaign)
      CAMPAIGN="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --debug)
      DEBUG_MODE=YES
      printf "{\"switch\":\"%s\"}" "${1}"
      ;;
    --logfile)
      LOGFILE="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -d|--doy) ## remove any leading zeros
      DOY=`echo "${2}" | sed 's|^0*||g'`
      DOY_3C=$( printf "%03i\n" $DOY )
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -g|--tables-dir)
      TABLES_DIR="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -h|--help)
      printf "{\"switch\":\"%s\"}" "${1}"
      help
      exit 0
      ;;
    -s|--satellite-system)
      SAT_SYS="${2^^}"
      if test ${SAT_SYS} != "GPS" && test ${SAT_SYS} != "MIXED" ; then
        echoerr "ERROR. Invalid satellite system : ${SAT_SYS}"
        exit 1
      fi
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --stations-per-cluster)
      STATIONS_PER_CLUSTER="${2}"
      if ! [[ $STATIONS_PER_CLUSTER =~ ^[0-9]+$ ]] ; then
        echoerr "ERROR. stations-per-cluster must be a positive integer!"
        exit 1
      fi
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --files-per-cluster)
      FILES_PER_CLUSTER="${2}"
      if ! [[ $FILES_PER_CLUSTER =~ ^[0-9]+$ ]]; then
        echoerr "ERROR. files-per-cluster must be a positive integer!"
        exit 1
      fi
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -e|--elevation-angle)
      ELEVATION_ANGLE="${2}"
      if ! [[ $ELEVATION_ANGLE =~ ^[0-9]+$ ]]; then
        echoerr "ERROR. Elevation angle must be a positive integer!"
        exit 1
      fi
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --append-suffix)
      APND_SUFFIX="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -v|--version)
      printf "{\"switch\":\"%s\"}" "${1}"
      dversion
      exit 0
      ;;
    -y|--year)
      YEAR="${2}"
      printf "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --) # end of options
      printf "]}\n"
      shift
      break
      ;;
     *)
      echoerr "*** Invalid argument $1 ; fatal" 
      exit 1
      ;;

  esac
  shift
done

## ////////////////////////////////////////////////////////////////////////////
##  LOGFILE, STDERR & STDOUT
##  ---------------------------------------------------------------------------
##  if a logfile is specified, redirect stderr to logfile
## ////////////////////////////////////////////////////////////////////////////
if test -z ${LOGFILE+x}; then
  :
else
  # Close STDERR fd
  exec 2<&-
  # Open STDERR as $LOGFILE file for read and write.
  exec 2>&1
fi

## ////////////////////////////////////////////////////////////////////////////
##  VALIDATE COMMAND LINE ARGUMENTS
##  ---------------------------------------------------------------------------
##  Note that we set the following variables:
##
##  1. 'DOY_3C' this is the 3-digit doy, whereas 'DOY' is not zero padded.
##  e.g. given day of year=3, the $DOY='3' and $DOY_3C='003'
##
##  2. All variable from the LOADGPS.setvar file are loaded (exported). This
##  file defines a lot of variables, which we should NOT override; some of
##  the most used ones are:
##    a. ${P} -> campaign directory,
##    b. ${D} -> datapool directory,
##    c. ${VERSION} -> the bernese version
##
##  3. The $CAMPAIGN variable is the one specified in the command line argument,
##  translated to UPPERCASE. Note that this is only the campaign name not 
##  including the path (see bullet 2.)
##
##  This section also call the check_tables() function, which validates that
##  all campaign-specific files are located in the $TABLES directory.
##
##  The directory specified for saving the results is checked for existance; if
##  it does not exist, it is created.
## ////////////////////////////////////////////////////////////////////////////

##  year must be set
if test -z ${YEAR+x}; then
  echoerr "ERROR. Year must be set!"
  exit 1
fi

##  doy must be set
if test -z ${DOY+x}; then
  echoerr "ERROR. Day of year must be set!"
  exit 1
fi
if test "${#DOY_3C}" -ne 3; then
  echoerr "ERROR. Something funny happened with doy ..."
  exit 1
fi

##  bernese-variable file must be set; if it is, check that it exists 
##+ and source it.
if test -z ${B_LOADGPS+x}; then
  echoerr "ERROR. LOADGPS.setvar must be set!"
  exit 1
else
  if test -f ${B_LOADGPS} && . ${B_LOADGPS} ; then
    if test "${VERSION}" != "52"; then
      echoerr "ERROR. Invalid Bernese version: ${VERSION}"
      exit 1
    fi
  else
    echoerr "ERROR. Failed to load variable file: ${B_LOADGPS}"
    exit 1
  fi
fi

##  campaign must exist in campaign directory
if test -z ${CAMPAIGN+x}; then
  echoerr "ERROR. Campaign must be set!"
  exit 1
else
  CAMPAIGN=${CAMPAIGN^^}
  if ! test -d "${P}/${CAMPAIGN}"; then
    echoerr "ERROR. Cannot find campaign directory: ${P}/${CAMPAIGN}"
    exit 1
  fi
fi

##  check the tables dir and its entries
if ! test -d "${TABLES_DIR}" ; then
  echoerr "ERROR. Cannot find tables directory: $TABLES_DIR"
  exit 1
else
  if ! check_tables ${TABLES_DIR} ${CAMPAIGN}; then
    exit 1
  fi
fi

##  solution id must be set
if test -z ${SOLUTION_ID+x}; then
  echoerr "ERROR. Solution identifier must be set!"
  exit 1
fi

##  save directoy must be set; if it doesn't exist, try to create it
if test -z ${SAVE_DIR+x}; then
  echoerr "ERROR. Save directory must be set!"
  exit 1
else
  SAVE_DIR="${SAVE_DIR%/}"
  if ! test -d ${SAVE_DIR}; then
    if ! mkdir -p ${SAVE_DIR}; then
      echoerr "ERROR. Failed to create directory ${SAVE_DIR}"
      exit 1
    fi
  fi
fi

## ////////////////////////////////////////////////////////////////////////////
##  DATETIME VARIABLES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
if ! START_OF_DAY_STR=$(ydoy2dt "${YEAR}" "${DOY_3C}") ; then
  echoerr "ERROR. Failed to parse date"
  exit 1
fi

if ! END_OF_DAY_STR=$(ydoy2dt "${YEAR}" "${DOY_3C}" "23" "59" "30") ; then
  echoerr "ERROR. Failed to parse date"
  exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  REPORT ..
## ////////////////////////////////////////////////////////////////////////////
printf "{general_info:"
printf "\"campaign\": \"%s\"," "${CAMPAIGN}"
printf "\"user\": \"%s\"," "${USER}"
printf "\"host\":\"%s\"," "${HOSTNAME}"
printf "{\"program\": {\"name\":\"%s\",\"version\":\"%s\",\"revision\":\"%s\",\"last_upd\":\"%s\"}," \
    "${NAME}" "${VERSION}" "${REVISION}" "${LAST_UPDATE}"
printf "\"day_processed\": \"%s-%s\"," "${YEAR}" "${DOY_3C}"
printf "{\"interval\": {\"from\":\"%s\", \"to\":\"%s\"}" "${START_OF_DAY_STR}" "${END_OF_DAY_STR}"
printf "}\n"

## ////////////////////////////////////////////////////////////////////////////
##  DOWNLOAD RINEX FILES
##  ---------------------------------------------------------------------------
##  Use the program rnxdwnl.py to download all available rinex files for
##+ the selected network. The downloaded files are going to be located at the
##+ DATAPOOL area. Note that some of them may already exist (in which case they
##+ are not going to be re-downloaded but they will be used).
##
##  The validate_ntwrnx.py script is then used to produce an informative table;
##+ this table is used to filter/crete arrays holding the available rinex files
##+ and the respective station names.
##
##  Lastly, copy and uncompress (.Z && crx2rnx) the files in the campaign
##+ directory /RAW.
## ////////////////////////////////////////////////////////////////////////////
if test 2 -eq 1 ; then

>.rnxsta.dat ## temporary file

##  download the rinex files for the input network; the database knows 
##+ the details .... Call rnxdwnl.py
if ! rnxdwnl.py \
              --networks=${CAMPAIGN} \
              --year=${YEAR} \
              --doy=${DOY} \
              --path=${D} \
              1>&2; then
  echoerr "ERROR. Failed to download RINEX files -> [rnxdwnl.py]"
  exit 1
fi

##  make a table with available rinex/station names, reference stations, etc ..
##  dump output to the .rnxsta.dat file (filter it later on)
if ! validate_ntwrnx.py \
            --year=${YEAR} \
            --doy=${DOY} \
            --fix-file=/home/bpe2/tables/fix/IGB08.FIX \
            --no-marker-numbers \
            --network=${CAMPAIGN} \
            --rinex-path=${D} \
            --no-marker-numbers \
            1> .rnxsta.dat; then
  echoerr "ERROR. Failed to compile rinex/station summary -> [validate_ntwrnx.py]"
  exit 1
fi

declare -a RNX_ARRAY     ##  array to hold available rinex files;
                         ##+ no path; compressed
declare -a STA_ARRAY     ##  array to hold available station names
declare -a REF_STA_ARRAY ##  array to hold available reference stations
MAX_NET_STA=             ##  nr of stations in the network

mapfile -t STA_ARRAY < <(filter_available_stations.awk .rnxsta.dat)
mapfile -t RNX_ARRAY < <(filter_available_rinex.awk .rnxsta.dat)
mapfile -t REF_STA_ARRAY < <(filter_available_reference.awk .rnxsta.dat)
MAX_NET_STA=$(cat .rnxsta.dat | tail -n+2 | wc -l)

## basic validation; make sure nothing went terribly wrong!
if [[ $MAX_NET_STA -lt 0 \
      || ${#STA_ARRAY[@]} -ne ${#RNX_ARRAY[@]} \
      || ! -f .rnxsta.dat ]]; then
  echoerr "ERROR! Error in handling rinex files/station names!"
  exit 1
fi

rm .rnxsta.dat ## remove temporary; no longer needed

## make sure number reference stations > 4
if test ${#REF_STA_ARRAY[@]} -lt 5; then
  echoerr "ERROR. Two few reference stations (${#REF_STA_ARRAY[@]}); \
    processing stoped."
  exit 1
fi

## transfer all available rinex to RAW/ and uncompress them
for i in "${RNX_ARRAY[@]}"; do
  if RNX=${i} \
        && cp ${D}/${RNX} ${P}/${CAMPAIGN}/RAW/ \
        && uncompress -f ${P}/${CAMPAIGN}/RAW/${RNX} \
        && crx2rnx -f ${P}/${CAMPAIGN}/RAW/${RNX%.Z} \
        && j=${RNX/%d.Z/o} \
        && j=${j^^} \
        && mv ${P}/${CAMPAIGN}/RAW/${RNX/%d.Z/o} ${P}/${CAMPAIGN}/RAW/${j}
  then
    :
  else
    echoerr "ERROR. Failed to manipulate rinex file ${RNX}"
    exit 1
  fi
done

##  dump all (available) station names to a file for later use; one station
##+ per line.
>.station-names.dat
for sta in "${STA_ARRAY[@]}"; do echo $sta >> .station-names.dat; done

## ////////////////////////////////////////////////////////////////////////////
##  REPORT ..
## ////////////////////////////////////////////////////////////////////////////
printf "<p>Number of stations available: %s/%s</p>\n" \
        "${#STA_ARRAY[@]}" "${MAX_NET_STA}"
printf "<p>Number of reference stations: %s</p>\n" \
        "${#REF_STA_ARRAY[@]}"
fi
## ////////////////////////////////////////////////////////////////////////////
##  DOWNLOAD IONOSPHERIC MODEL FILE
##  ---------------------------------------------------------------------------
##  If the user has specified a local solution id, then search through ntua's
##  TODO :: mysql ...
##  If such a file does not exist, download CODE's ionospheric file.
## ////////////////////////////////////////////////////////////////////////////
printf "{products:["

ION_DOWNLOADED=0

if mysql -h "${DB_HOST}" \
        --user="${DB_USER}" \
        --password="${DB_PASSWORD}" \
        --database="${DB_NAME}" \
        --execute="use procsta; \
         SELECT product.pth2dir, product.filename \
         FROM product \
         JOIN prodtype \
         ON product.prodtype_id=prodtype.prodtype_id \
         JOIN network \
         ON product.network_id=network.network_id \
         WHERE prodtype.prodtype_name=\"ION\" \
         AND network.network_name=\"${CAMPAIGN}\" \
         AND product.dateobs_start<=\"${START_OF_DAY_STR}\" \
         AND product.dateobs_stop>=\"${END_OF_DAY_STR}\";" \
      | grep -v "+----" \
      | tail -n +2 \
      | awk '{print $1$2}' > .procsta-answer.dat \
    && grep "[a-z,A-Z]*" .procsta-answer.dat &>/dev/null ; then
  my_ion_file=$(cat .procsta-answer.dat)
  echoerr "ERROR. NTUA's ION file found but ddprocess does not yet handle that!"
  echoerr "Write more code bitch!"
else
  echoerr "[WARNING]. No NTUA .ION file found."
fi

## ////////////////////////////////////////////////////////////////////////////
##  DOWNLOAD PRODUCTS
##  ---------------------------------------------------------------------------
##  Just call Python to do the job!
##
##  If any product fails, then trigger an error and exit (!=0).
##
##  Depending on the time-lag between today and the day we are processing,
##+ the following will download the best possible products; for more info, see
##+ the bernutils module documentation.
## ////////////////////////////////////////////////////////////////////////////
if test 1 -eq 1 ;  then
##  will we need an ion file ?
if test ${ION_DOWNLOADED} -eq 1; then
  if ! handle_dd_products.py \
          --year="${YEAR}" \
          --doy="${DOY}" \
          --analysis-center="${AC}" \
          --datapool="${D}" \
          --destination="${P}/${CAMPAIGN}/ORB" \
          --satellite-system="${SAT_SYS}" \
          --report=json; then
    echoerr "ERROR. Failed to download/copy/uncompress products."
    exit 1
  fi
else
  if ! handle_dd_products.py \
          --year="${YEAR}" \
          --doy="${DOY}" \
          --analysis-center="${AC}" \
          --datapool="${D}" \
          --destination="${P}/${CAMPAIGN}/ORB" \
          --satellite-system="${SAT_SYS}" \
          --download-ion \
          --report=json; then
    echoerr "ERROR. Failed to download/copy/uncompress products."
    exit 1
  fi
fi
fi
## ////////////////////////////////////////////////////////////////////////////
##  DOWNLOAD VMF1 GRID
##  ---------------------------------------------------------------------------
##  Just call Python to do the job (again)!
##
##  Download 5 grid files: 4 for the day we are processing and one for the
##+ first 6 hours of the next day (a bernese thing). We need to merge all
##+ files to a final one.
## ////////////////////////////////////////////////////////////////////////////
if test 1 -eq 1 ; then
## temporary file to hold getvmf1.py output
TMP_FL=.vmf1-${YEAR}${DOY}.dat

if ! getvmf1.py --year=${YEAR} --doy=${DOY} --outdir=${D} --json=".vmf1.json" 1> ${TMP_FL}; then
  echoerr "ERROR. Failed to get VMF1 grid file(s)"
  exit 1
fi

##  grid files are downloaded to ${D} as individual files; merge them and move
##+ to /GRID
if ! mapfile -t VMF_FL_ARRAY < <(filter_local_vmf1.awk ${TMP_FL}) ; then
  echoerr "ERROR. Failed to merge VMF1 grid file(s)"
  exit 1
else
  MERGED_VMF_FILE=${P}/${CAMPAIGN}/GRD/VMF${YEAR:2:2}${DOY_3C}0.GRD
  >${MERGED_VMF_FILE}
  for fl in ${VMF_FL_ARRAY[@]}; do
    cat ${fl} >> ${MERGED_VMF_FILE}
  done
fi

##  write a nice report like the one given by handle_products.
##if ! mapfile -t VMF_FL_ARRAY < <(cat ${TMP_FL} | awk '{print $2}') ; then
##  echoerr "ERROR. Failed to report VMF1 grid file(s). Strange !!"
##  exit 1
##fi
##let c=${#VMF_FL_ARRAY[@]}-1
##tmp_="<code>${VMF_FL_ARRAY[0]}"
##for i in `seq 1 $c`; do tmp_="${tmp_}, ${VMF_FL_ARRAY[${i}]}"; done
##tmp_="${tmp_}</code>"
##printf "<p>Product type: <strong>vmf1</strong> :\
##  downloaded file(s) %s ; moved to %s</p>\n" \
##      "$tmp_" "$MERGED_VMF_FILE"
cat .vmf1.json 2>/dev/null
rm ${TMP_FL} ## remove temporary file
fi

printf "]}" ## done with products
## ////////////////////////////////////////////////////////////////////////////
##  MAKE THE CLUSTER FILE
##  ---------------------------------------------------------------------------
##  Using the array holding the stations names of all available stations (i.e.
##+ STA_ARRAY), we will create the cluster file: NETWORK_NAME.CLU placed in
##+ the /STA folder.
##
##  Each cluster cannot have more than STATIONS_PER_CLUSTER stations.
##
##  Note that the .PCF file may hold a different variable called V_CLU which
##+ holds the *FILES* per cluster (i.e. baselines) and not the *STATIONS*
##+ per cluster
## ////////////////////////////////////////////////////////////////////////////

CLUSTER_FILE=${P}/${CAMPAIGN}/STA/${CAMPAIGN}.CLU

awk -v num_of_clu=${STATIONS_PER_CLUSTER} -f \
  make_cluster_file.awk .station-names.dat \
  1>${CLUSTER_FILE}

## ////////////////////////////////////////////////////////////////////////////
##  SET SOLUTION IDENTIFIERS
##  ---------------------------------------------------------------------------
##  The solution id provided by the user will be reserved for the final,
##+ ambiguity-fixed results; hence, we need to name two more kinds of results,
##+ 1. the preliminary (ambiguity-float) and
##+ 2. the size-reduced
##
##  Preliminary results are going to be named exactly as the final ones,
##+ except for the last character which will be changed to 'P'. If this is 
##+ already the last character of the final solution id, then append '1'.
##
##  Size-reduced results are going to be named exactly as the final ones,
##+ except for the last character which will be changed to 'R'. If this is 
##+ already the last character of the final solution id, then append '1'.
##
##  e.g. --solution-id=FFG will result to:
##+      FINAL_SOLUTION_ID   = 'FFG'
##+      PRELIM_SOLUTION_ID  = 'FFP'
##+      REDUCED_SOLUTION_ID = 'FFR'
##
##  e.g. --solution-id=FFR will result to:
##+      FINAL_SOLUTION_ID   = 'FFR'
##+      PRELIM_SOLUTION_ID  = 'FFP'
##+      REDUCED_SOLUTION_ID = 'FFR1'
## ////////////////////////////////////////////////////////////////////////////
printf "{solution_identifiers:["
##  Final (ambiguity-fixed) results
FINAL_SOLUTION_ID="${SOLUTION_ID}"

##  Preliminary (ambiguity-float) results
if test "${FINAL_SOLUTION_ID:(-1)}" == "P"; then
  echoerr -n "WARNING. Last char of final solution is 'P'."
  PRELIM_SOLUTION_ID="${SOLUTION_ID%?}P1"
  echoerr "Truncating Preliminary to $PRELIM_SOLUTION_ID"
else
  PRELIM_SOLUTION_ID="${SOLUTION_ID%?}P"
fi

##  Size-reduced NEQ information
if test "${FINAL_SOLUTION_ID:(-1)}" == "R"; then
  echoerr -n "WARNING. Last char of final solution is 'R'."
  REDUCED_SOLUTION_ID="${SOLUTION_ID%?}R1"
  echoerr "Truncating Size-reduced to $REDUCED_SOLUTION_ID"
else
  REDUCED_SOLUTION_ID="${SOLUTION_ID%?}R"
fi

##  report ..
printf "{\"description\":\"Final Solution\", \"id\":\"%s\"}" "$FINAL_SOLUTION_ID"
printf "{\"description\":\"Size-Reduced\", \"id\":\"%s\"}" "$REDUCED_SOLUTION_ID"
printf "{\"description\":\"Preliminary Solution\", \"id\":\"%s\"}" "$PRELIM_SOLUTION_ID"
printf "]}"

## ////////////////////////////////////////////////////////////////////////////
##  SET VARIABLES IN THE PCF FILE
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////

##  Bernese has no 'MIXED' satellite system; this defaults to 'GPS/GLO'.
if test "${SAT_SYS}" == "MIXED"; then
  BERN_SAT_SYS="GPS/GLO"
else 
  BERN_SAT_SYS="${SAT_SYS}"
fi

if ! test -f ${U}/PCF/${PCF_FILE}; then
  echoerr "ERROR. Invalid pcf file ${U}/PCF/${PCF_FILE}"
  exit 1
fi

if ! set_pcf_variables.py "${U}/PCF/${PCF_FILE}" \
        B="${AC^^}" \
        C="${PRELIM_SOLUTION_ID}" \
        E="${FINAL_SOLUTION_ID}" \
        F="${REDUCED_SOLUTION_ID}" \
        BLQINF="${CAMPAIGN}" \
        ATLINF="${CAMPAIGN}" \
        SATSYS="${BERN_SAT_SYS}" \
        PCV="I08" \
        PCVINF="PCV_${CAMPAIGN:0:3}" \
        ELANG="${ELEVATION_ANGLE}" \
        CLU="${FILES_PER_CLUSTER}"; then
  echoerr "ERROR. Failed to set variables in PCF file."
  exit 1
fi

##  TODO:    This needs to change... fix the program / make new
##  ---------------------------------------------------------------------------
##  Depending on the AC, set the INP file POLUPD.INP to fill in the right
##+ widget, using the script setpolupdh utility. But first, we have got to find
##+ out which directory in the ${U}/OPT area holds the INP file. Note that only
##+ one line containing the POLUPDH script is allowd in the PCF file.
LNS=`/bin/grep POLUPDH ${U}/PCF/${PCF_FILE} | /bin/grep -v "#" | wc -l`
if test "$LNS" -ne 1 ; then
  echoerr "Non-unique line for POLUPDH in the PCF file; Don't know what to do!"
  exit 1
fi
PAN=`/bin/grep POLUPDH ${U}/PCF/${PCF_FILE} | /bin/grep -v "#" | awk '{print $3}'`
if ! setpolupdh.sh --bernese-loadvar=${B_LOADGPS} \
        --analysis-center=${AC^^} \
        --pan=${PAN}
then
  echo "bernese-loadvar=${B_LOADGPS}"
  exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  A-PRIORI COORDINATES FOR REGIONAL SITES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
if ! awk -v FLAG=R -v REPLACE_ALL=NO -f \
        change_crd_flags.awk ${TABLES_DIR}/crd/${CAMPAIGN}.CRD \
        1>${P}/${CAMPAIGN}/STA/REG${YEAR:2:2}${DOY_3C}0.CRD; then
  echoerr "ERROR. Could not create a-priori coordinate file."
  exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  PROCESS THE DATA
##  ---------------------------------------------------------------------------
##  Call the perl script which ignites the BPE via the PCF :)
## ////////////////////////////////////////////////////////////////////////////
BERN_TASK_ID="${CAMPAIGN:0:1}DD"

if test 2 -eq 1; then
##  run the perl script to ignite the PCF
${U}/SCRIPT/ntua_pcs.pl ${YEAR} \
          ${DOY_3C}0 \
          NTUA_DDP USER \
          ${CAMPAIGN} \
          ${BERN_TASK_ID};
fi
##  check the status
if ! check_run \
      ${P}/${CAMPAIGN}/BPE \
      "${CAMPAIGN:0:3}_${BERN_TASK_ID}.RUN" \
      "${CAMPAIGN:0:3}_${BERN_TASK_ID}.OUT" ; then
  echoerr "ERROR. Fatal, processing stoped."
  exit 1
else
  :
fi

## ////////////////////////////////////////////////////////////////////////////
##  COPY PRODUCTS TO HOST; UPDATE DATABASE ENTRIES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
printf "{saved_products:["
if test 1 -eq 1 ; then
##  warning: in the db mixed := GPS+GLO
if test "${SAT_SYS^^}" = "MIXED"; then
  DB_SAT_SYS="GPS+GLO"
else
  DB_SAT_SYS=${SAT_SYS}
fi

##  create the directory ${SAVE_DIR}/YYYY/DDD (if it doesn't exist)
if ! test -d "${SAVE_DIR}/${YEAR}/${DOY_3C}"; then
  echo "Creating solution directory ${SAVE_DIR}/${YEAR}/${DOY_3C}/"
  if ! mkdir -p "${SAVE_DIR}/${YEAR}/${DOY_3C}"; then
    echoerr "ERROR. Failed to create directory ${SAVE_DIR}/${YEAR}/${DOY_3C}/"
    exit 1
  fi
fi

##  warning: dates have whitespace ('%Y-%m-%d %H:%M:%S'); replace whitespace
##+ with underscore, i.e. '%Y-%m-%d_%H:%M:%S'

##  argv1 -> file extension (e.g. 'SNX')
##  argv2 -> campaign dir (e.g. 'SOL')
##  argv3 -> product type (e.g. 'SINEX')

##  final tropospheric sinex
if ! save_n_update TRO ATM TRO_SNX ; then exit 1 ; else printf "," ; fi

## final SINEX
if ! save_n_update SNX SOL SINEX ; then exit 1 ; else printf "," ; fi

## final NQ0
if ! save_n_update NQ0 SOL NQ ; then exit 1 ; else printf "," ; fi

## reduced NQ0
if ! save_n_update NQ0 SOL NQ R ; then exit 1 ; else printf "," ; fi

## final coordinates
if ! save_n_update CRD STA CRD_FILE ; then exit 1 ; fi

fi
printf "]}"

## ////////////////////////////////////////////////////////////////////////////
##  COMPILE (NON-FATAL) ERROR/WARNINGS FILE
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
WRN_FILE=${P}/${CAMPAIGN}/LOG/wrn${YEAR}${DOY_3C}0.log

if ! >${WRN_FILE} ; then
  echoerr "ERROR. Failed to create warnings file ${WRN_FILE}"
fi

find ${P}/${CAMPAIGN}/OUT/WRN${DOY_3C}0*.SUM -not -empty -ls -exec \
      cat {} 1>>${WRN_FILE} 2>/dev/null \; ## match files e.g 'WRN0010003.SUM'

find ${P}/${CAMPAIGN}/OUT/*${YEAR}${DOY_3C}0.ERR -not -empty -ls -exec \
      cat {} 1>>${WRN_FILE} 2>/dev/null \; ## match files e.g 'RNX150010.ERR'

## echo "Warnings file created as ${WRN_FILE}"
##  warnings to json ..
if ! wrn2json.py ${WRN_FILE} 2>/dev/null ; then
  echoerr "ERROR. Failed to create json warning file!"
  exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  ADDNEQ SUMMARY TO HTML
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////

##  the ambiguity summary file
AMBSM=${P}/${CAMPAIGN}/OUT/AMB${YEAR:2:2}${DOY_3C}0.SUM
python - <<END
import sys, bernutils.bamb
try:
  ambf = bernutils.bamb.AmbFile( "${AMBSM}" )
  ambf.toJson()
except:
  print>>sys.stderr,'ERROR. Cannot translate amb file to json!'
  sys.exit(1)
sys.exit(0)
END
if test "$?" -ne 0 ; then exit 1 ; fi

printf "<h2>ADDNEQ Summary</h2>"
##  the final ADDNEQ summary file should be
ADNQ=${P}/${CAMPAIGN}/OUT/${FINAL_SOLUTION_ID}${YEAR:2:2}${DOY_3C}0.OUT
#adnq2html.py --addneq-file="${ADNQ}" \
#          --table-entries='latcor,loncor,hgtcor,dn,de,du,adj' \
#          --warnings-str='dn=.01,de=.01,du=.01'
python - <<END
import sys, bernutils.badnq
#try:
adnf = bernutils.badnq.AddneqFile( "${ADNQ}" )
adnf.toJson()
#except:
#  print>>sys.stderr,'ERROR. Cannot translate addneq file to json!'
sys.exit(1)
sys.exit(0)
END
if test "$?" -ne 0 ; then exit 1 ; fi

## ////////////////////////////////////////////////////////////////////////////
##  REMOVE CAMPAIGN FILES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
if test 1 -eq 2 ; then
##  we are going to remove any file in the campaign-specific folders, newer
##+ than .ddprocess-time-stamp (i.e. the stamp file), except from symlinks.
find -P ${P}/${CAMPAIGN}/ \
      -maxdepth 1 \
      -type f \
      -newer ${TIME_STAMP_FILE} \
      ! name ${WRN_FILE}
fi

exit 0

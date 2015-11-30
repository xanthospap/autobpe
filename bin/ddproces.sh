#! /bin/bash

NAME=ddprocess
VERSION="0.90"
REVISION="20"
LAST_UPDATE="Oct 2015"
START_DD=$(date +%s.%N)

# //////////////////////////////////////////////////////////////////////////////
# FUNCTIONS
# //////////////////////////////////////////////////////////////////////////////

##  echo to stderr
echoerr () { echo "$@" 1>&2; }

##  echo to stdout only if debuging flag is set, i.e. if the variable 
##+ "DEBUG_MODE" > 0.
echodbg() { 
  test "${DEBUG_MODE}" -gt 0 && echo "$@" 
}

##  control perl script output
##  argv1 -> path to BPE
##  argv2 -> status filename (no path)
##  argv3 -> output filename (no path)
check_bpe_run () {

  bpe_path="$1"
  status_f="${bpe_path}/${2}"
  outout_f="${bpe_path}/${3}"

  if ! test -f ${status_f}; then
    echoerr "[ERROR] Cannot find the bpe status file \"$status_f\""
    return 1
  fi

  ##  Grep the status file for /error/. If found, cat all log files
  ##+ to stderr.
  if grep "error" ${status_f} &>/dev/null ; then
    for i in `ls ${bpe_path}/${BERN_TASK_ID}${YEAR:2:2}${DOY_3C}*.LOG`; do
      cat ${i} >> ${PROC_LOG}
    done
    cat ${outout_f} >> ${PROC_LOG}
    return 1
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

          -p --pcv-file= specify the .PCV file to be used. The pcv file should
           exist in the \'\${TABLES_DIR}\'. The extension of this file, should
           match the \'\${PCV_EXT}\' variable, which is default set to \'I08\'.
           So, given e.g. the argument \'--pcv-file=FOO\', the script will
           search for the file \'\${TABLES_DIR}/pcv/FOO.\${PCV_EXT}\'

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

          --json-out= Output file in json format.

          --repro2-prods Use IGS repro2 campaign products.

          --cod-repro13 Use CODE's REPRO2013 results.

          --atl-file Specify the ATL correction file.

          --antex= Specify an antex file to transform to a PCV

          --stainf= Specify the station information file (no extension). This
           file should be placed either in the \'\${TABLES_DIR}/sta\' or the
           \'\${P}/\${CAMPAIGN}/STA\' directory.

          --fix-file= Specify the name of the .FIX file

          --blq-file= Specify the blq file

          --skip-remove Do not remove campaign-specifi files

          -h --help display (this) help message and exit

          -v --version display version and exit
/******************************************************************************/"
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
##  argv2 -> campaign dir   (e.g. 'SOL')
##  argv3 -> product type   (e.g. 'SINEX')
##  argv4 -> (optional) sol type
##+          'F' for final, 
##+          'R' for size-reduced and
##+          'P' for preliminery
##
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
        echoerr "[ERROR] Invalid one-char solution id!"
        return 1
        ;;
    esac
  else
    if test "$#" -ne 3 ; then
      echoerr "[ERROR] Invalid call to save_n_update()."
      return 1
    else
      solution_id=${FINAL_SOLUTION_ID}
    fi
  fi
 
  local src_f=${solution_id}${YEAR:2:2}${DOY_3C}0.${1} ## source file
  local trg_f=${solution_id}${YEAR:2:2}${DOY_3C}0${APND_SUFFIX}.${1} ## target
  local src_p=${P}/${CAMPAIGN}/${2}
  compress -f ${src_p}/${src_f} \
      && src_f="${src_f}.Z" \
      && trg_f="${trg_f}.Z"
  local status=0
  local host=

  if ! test -f ${src_p}/${src_f} ; then
    echoerr "[ERROR] File to save: \"${src_p}/${src_f}\" does not exist!"
    return 1
  fi

  ## try to save the product
  if ! test -z "${SAVE_DIR_HOST}" ; then
    host=${SAVE_DIR_HOST}
    rm .ftp.log 2>/dev/null
    ftp -inv $SAVE_DIR_HOST << EOF > .ftp.log
user $SAVE_DIR_URN $SAVE_DIR_PSS
cd ${SAVE_DIR_DIR}/${YEAR}/${DOY_3C}
put ${src_p}/${src_f} ${trg_f}
close
bye
EOF
    if grep -e "226 Transfer complete" \
            -e "226-File successfully transferred" \
            .ftp.log 1>/dev/null .ftp.log ; then
      status=0
    else
      status=1
    fi
  else
    host=${HOSTNAME}
    cp ${src_p}/${src_f} ${SAVE_DIR}/${YEAR}/${DOY_3C}/${trg_f}
    status="$?"
  fi

  if test "${status}" -ne 0 ; then
    echoerr "[ERROR] Failed to save file: \"${src_p}/${src_f}\"."
    if test -f .ftp.log ; then
      echoerr "        Check the log file \".ftp.log\"."
    fi
    return 1
  else
    echodbg "[DEBUG] File \"$src_f\" saved at \"${host}\" as"
    echodbg "        \"$trg_f\"."
  fi

  if add_products_2db.py \
          --campaign-name=${CAMPAIGN} \
          --satellite-system=${DB_SAT_SYS} \
          --solution-type=DDFINAL \
          --product-type="${3}" \
          --start-epoch="${START_OF_DAY_STR/ /_}" \
          --end-epoch="${END_OF_DAY_STR/ /_}" \
          --host-ip="${host}" \
          --host-dir="${SAVE_DIR_DIR}/${YEAR}/${DOY_3C}/" \
          --product-filename="${trg_f}.Z" ; then
    printf 1>>${JSON_OUT} "{\"prod_type\":\"%s\",\"extension\":\"%s\",\"local_dir\":\"%s\",\"sol_type\":\"%s\",\"filename\":\"%s\",\"savedas\":\"%s\",\"host\":\"%s\",\"host_dir\":\"%s\"}" \
      "${3}" "${1}" "${2}" "${solution_id}" "${src_f}" "${trg_f}" "${host}" "${SOL_DIR}/${YEAR}/${DOY_3C}/"
      echodbg "[DEBUG] DB updated to include file \"${src_f}\"."
    else
      echoerr "[ERROR] Failed to update DB."
      return 1
  fi
}

##  This function will remove all files within the
##+ tmp_file_array array ant ehn exit with the integer
##+ provided as the first command line argument.
clear_n_exit () {
  for f in "${tmp_file_array[@]}" ; do
    rm $f 2>/dev/null
  done
  exit $1
}

##
##  Search through a list of command line arguments (short and/or
##+ long options included), find the long option '--config=<ARG>'
##+ and return the <ARG>. If not found, return ''
##
find_config_file () {
  local cf=
  OLD_IFS=${IFS}
  IFS='='
  for i in "$@" ; do
    read -ra arr <<< "$i"
    if test "${arr[0]}" == "--config" ; then
      if test ${#arr[@]} -ne 2; then
        echoerr "ERROR. Invalid cmd: $i"
        exit 1
      fi
      cf="${arr[1]}"
      break
    fi
  done
  IFS=${OLD_IFS}
  echo $cf
}

set_json_out () {
  JSON_OUT=/dev/null
  OLD_IFS=${IFS}
  IFS='='
  for i in "$@" ; do
    read -ra arr <<< "$i"
    if test "${arr[0]}" == "--json-out" ; then
      if test ${#arr[@]} -ne 2; then
        echoerr "ERROR. Invalid cmd: $i"
        exit 1
      fi
      ##  echo "--Setting json-out to ${arr[1]}"
      JSON_OUT="${arr[1]}"
      break
    fi
  done
  IFS=${OLD_IFS}
}

# //////////////////////////////////////////////////////////////////////////////
# GLOBAL VARIABLES
# //////////////////////////////////////////////////////////////////////////////

##  set debug mode:
##+ 0 : no debug
##+ 1 : print debuging messages
##+ 2 : extended debuging mode (sets '-v')
DEBUG_MODE=0

##  following variables should be set via cmd arguments (else error!)
# YEAR=
# DOY=
# B_LOADGPS=
# CAMPAIGN=
# LOGFILE=
# SOLUTION_ID=
# SAVE_DIR=
# APND_SUFFIX=
# JSON_OUT

##  optional parameters; may be changes via cmd arguments
SAT_SYS=GPS
TABLES_DIR=${HOME}/tables
AC=COD
STATIONS_PER_CLUSTER=3
FILES_PER_CLUSTER=7
ELEVATION_ANGLE=3
PCF_FILE=NTUA_DDP.PCF
USE_REPRO2=NO
COD_REPRO13=NO

## pcv and antex related variables ##
PCV_EXT=I08
# PCVINF=
# ATXINF=

## station information file ##
## STAINF=                  ##  the filename (no path, no extension); unset
## STAINF_FILE=             ##  the file; unset
STAINF_EXT="STA"            ##  the extension

## fix file
FIXINF=IGB08

## blq file
# BLQINF=

## atl file
# ATLINF=

##  exclude file/stations
# STA_EXCLUDE_FILE=
USE_EUREF_EXCLUDE_LIST=NO

##  will we delete campaign files ?
# SKIP_REMOVE=

##  Ntua's product area
MY_PRODUCT_AREA=/media/Seagate/solutions52 ## add yyyy/ddd later on
# MY_PRODUCT_ID optionaly set via cmd, if we are going to search our products

##  database for local/user products and RINEX info
DB_HOST=
DB_USER=
DB_PASS=
DB_NAME=
UPD_DB_PROD=

##  FIXME: This needs to be the path to the autobpe/bin directory
PATH=${PATH}:${HOME}/autobpe/bin
PATH=${PATH}:${HOME}/autobpe/bin/etc
P2ETC=${HOME}/autobpe/bin/etc

##  The config file (if any)
# CONFIG=

##  an array to hold the filenames of all temporary files created
##+ by this script
tmp_file_array=()

## ////////////////////////////////////////////////////////////////////////////
##  CREATE STAMP FILE & SET JSON OUTPUT (IF ANY)
## ////////////////////////////////////////////////////////////////////////////

##  create/touch a file that won't do anything! It will just act as a time
##+ stamp; i.e. all files in the campaign-specific folders created/modified
##+ after this (the stamp file) are created/modified by the ddprocess script.
TIME_STAMP_FILE=".ddprocess-ts-${BASHPID}"
touch ${TIME_STAMP_FILE}
date > ${TIME_STAMP_FILE}
tmp_file_array+=("${TIME_STAMP_FILE}")

##  search through the cmd's to find the JSON_OUT (if any)
set_json_out $@

##  load the configuration file (if any). This has to be done before
##+ storing the command line args.
CONFIG_FILE=$(find_config_file "$@")
if [ ! -z "${CONFIG_FILE+x}" ] && [ "${CONFIG_FILE}" != "" ] ; then
  eval $(etc/source_dd_config.sh $CONFIG_FILE)
  echo "[DEBUG] Found and loaded configuration file: \"${CONFIG_FILE}\"."
fi
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
  ARGS=`getopt -o hvy:d:b:c:s:g:r:i:e:a:p: \
-l  help,version,year:,doy:,bern-loadgps:,campaign:,satellite-system:,tables-dir:,debug,logfile:,stations-per-cluster:,save-dir:,solution-id:,files-per-cluster:,elevation-angle:,analysis-center:,use-ntua-products:,append-suffix:,json-out:,repro2-prods,cod-repro13,atl-file:,antex:,pcv-file:,stainf:,use-epn-exclude,exclude-list:,skip-remove,fix-file:,blq-file:,config: \
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
printf 1>${JSON_OUT} "{\"command\":[\n"
while true
do
  case "$1" in

    --use-ntua-products)
      MY_PRODUCT_ID="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -r|--save-dir)
      SAVE_DIR_DIR="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -i|--solution-id)
      SOLUTION_ID="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -a|--analysis-center)
      AC="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -b|--bern-loadgps)
      B_LOADGPS="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -c|--campaign)
      CAMPAIGN="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --debug)
      DEBUG_MODE=1
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      ;;
    --logfile)
      LOGFILE="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -d|--doy) ## remove any leading zeros
      DOY=`echo "${2}" | sed 's|^0*||g'`
      DOY_3C=$( printf "%03i\n" $DOY )
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -g|--tables-dir)
      TABLES_DIR="${2%/}" ## trim last '/' if any
      printf 1>>${JSON_OUT} "{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -h|--help)
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      help
      exit 0
      ;;
    -s|--satellite-system)
      SAT_SYS="${2^^}"
      if test ${SAT_SYS} != "GPS" && test ${SAT_SYS} != "MIXED" ; then
        echoerr "ERROR. Invalid satellite system : ${SAT_SYS}"
        exit 1
      fi
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --stations-per-cluster)
      STATIONS_PER_CLUSTER="${2}"
      if ! [[ $STATIONS_PER_CLUSTER =~ ^[0-9]+$ ]] ; then
        echoerr "ERROR. stations-per-cluster must be a positive integer!"
        exit 1
      fi
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --files-per-cluster)
      FILES_PER_CLUSTER="${2}"
      if ! [[ $FILES_PER_CLUSTER =~ ^[0-9]+$ ]]; then
        echoerr "ERROR. files-per-cluster must be a positive integer!"
        exit 1
      fi
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -e|--elevation-angle)
      ELEVATION_ANGLE="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --append-suffix)
      APND_SUFFIX="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -v|--version)
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      dversion
      exit 0
      ;;
    --repro2-prods)
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      USE_REPRO2=YES
      ;;
    --cod-repro13)
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      COD_REPRO13=YES
      ;;
    --atl-file)
      ATLINF="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -y|--year)
      YEAR="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --antex)
      ATXINF="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --stainf)
      STAINF="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    -p|--pcv-file)
      PCVINF="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --fix-file)
      FIXINF="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --blq-file)
      BLQINF="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --json-out)
      ## This should have already been set !
      if [ "$JSON_OUT" != "$2" ]; then
        echoerr "ERROR. json-out not parsed correctly! ($JSON_OUT \!= $2)"
        exit 1
      fi
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --use-epn-exclude)
      USE_EUREF_EXCLUDE_LIST=YES
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      ;;
    --skip-remove)
      SKIP_REMOVE=YES
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\"}" "${1}"
      ;;
    --exclude-list)
      STA_EXCLUDE_FILE="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --config)
      CONFIG_FILE="${2}"
      printf 1>>${JSON_OUT} "\n{\"switch\":\"%s\", \"arg\": \"%s\"}" "${1}" "${2}"
      shift
      ;;
    --) # end of options
      printf 1>>${JSON_OUT} "\n],\n"
      shift
      break
      ;;
     *)
      echoerr "*** Invalid argument $1 ; fatal" 
      exit 1
      ;;

  esac
  shift
  if test "${#}" -gt 1 ; then printf 1>>${JSON_OUT} "," ; fi
done

##  Source the config file if any
#if ! test -z "${CONFIG_FILE+x}" ; then
#  eval $(etc/source_dd_config.sh $CONFIG_FILE)
#  echodbg "[DEBUG] Read config file \"${CONFIG_FILE}\"."
#fi

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
  echoerr "[ERROR] Year must be set!"
  exit 1
fi

##  doy must be set
if test -z ${DOY+x}; then
  echoerr "[ERROR] Day of year must be set!"
  exit 1
else
  DOY=$(echo "${DOY}" | sed 's|^0*||g')
   DOY_3C=$( printf "%03i\n" $DOY )
fi
if test "${#DOY_3C}" -ne 3; then
  echoerr "[ERROR] Something funny happened with doy ..."
  exit 1
fi

if test -z ${ELEVATION_ANGLE+x}; then ELEVATION_ANGLE=3 ; fi
if ! [[ $ELEVATION_ANGLE =~ ^[0-9]+$ ]]; then
  echoerr "[ERROR] Elevation angle must be a positive integer!"
  exit 1
fi

SAT_SYS="${SAT_SYS^^}"
if test ${SAT_SYS} != "GPS" && test ${SAT_SYS} != "MIXED" ; then
  echoerr "[ERROR] Invalid satellite system : ${SAT_SYS}"
  exit 1
fi

##  bernese-variable file must be set; if it is, check that it exists 
##+ and source it.
if test -z ${B_LOADGPS+x}; then
  echoerr "[ERROR] LOADGPS.setvar must be set!"
  exit 1
else
  if test -f ${B_LOADGPS} && . ${B_LOADGPS} ; then
    if test "${VERSION}" != "52"; then
      echoerr "[ERROR] Invalid Bernese version: ${VERSION}"
      exit 1
    fi
  else
    echoerr "[ERROR] Failed to load variable file: ${B_LOADGPS}"
    exit 1
  fi
fi

##  campaign must exist in campaign directory
if test -z ${CAMPAIGN+x}; then
  echoerr "[ERROR] Campaign must be set!"
  exit 1
else
  CAMPAIGN=${CAMPAIGN^^}
  if ! test -d "${P}/${CAMPAIGN}"; then
    echoerr "[ERROR] Cannot find campaign directory: ${P}/${CAMPAIGN}"
    exit 1
  fi
fi

##  check the tables dir and its entries
if ! test -d "${TABLES_DIR}" ; then
  echoerr "[ERROR] Cannot find tables directory: $TABLES_DIR"
  exit 1
fi

##  solution id must be set
if test -z ${SOLUTION_ID+x}; then
  echoerr "[ERROR] Solution identifier must be set!"
  exit 1
fi

##  save directoy must be set; if it doesn't exist, try to create it
if test -z "${SAVE_DIR_HOST}" ; then ##  using this host for saving
  if test -z ${SAVE_DIR+x}; then
    echoerr "[ERROR] Save directory must be set!"
    exit 1
  else
    SAVE_DIR="${SAVE_DIR%/}"
    if ! test -d ${SAVE_DIR}; then
      if ! mkdir -p ${SAVE_DIR}; then
        echoerr "[ERROR] Failed to create directory ${SAVE_DIR}"
        exit 1
      fi
    fi
  fi
else ##  need to see if we have access to host
  ftp -inv $SAVE_DIR_HOST <<EOF > .ftp.log
user $SAVE_DIR_URN $SAVE_DIR_PSS
cd ${SAVE_DIR_DIR}
mkdir ${YEAR}
cd ${YEAR}
mkdir ${DOY_3C}
cd ${DOY_3C}
close
bye
EOF
  if grep 1>/dev/null \
          -e "Name or service not known" \
          -e "Login failed" \
          -e "No such file or directory" \
          -e "Not connected" \
          .ftp.log ; then
    echoerr "[ERROR] Cannot connect to host \"${SAVE_DIR_HOST}\"."
    echoerr "        Check the username and password or see the log file: \".ftp.log\"."
    exit 1
  fi
fi

##  check validity of products/ac
##  cannot have both repro2 and repro13
if test "${COD_REPRO13}" == "YES" ; then
  if test "${USE_REPRO2}" == "YES" ; then
    echoerr "[ERROR] CAnnot have both repro2 and code's repro13."
    exit 1
  fi
  if test "${AC^^}" != "COD"; then
    echoerr "[ERROR] repro13 products only available from CODE"
    exit 1
  fi
fi

## ------------------------------------------------------------------------- ##
##                                                                           ##
##  Validate the station information file: see that it exists, and link it   ##
##+ from tables directory the the campaign's sta dir.                        ##
##                                                                           ##
## ------------------------------------------------------------------------- ##
if [ -z ${STAINF+x} ]; then
  echodbg "[DEBUG] Station information file not specified"
  echodbg "        seting it to \"${CAMPAIGN}\"."
  STAINF="${CAMPAIGN}"
fi

if ! test -f ${TABLES_DIR}/sta/${STAINF}.${STAINF_EXT} ; then
  if ! test -f ${P}/${CAMPAIGN}/STA/${STAINF}.${STAINF_EXT}; then
    echoerr "[ERROR] Cannot find the station information file \'${STAINF}.${STAINF_EXT}\'."
    echoerr "        It is neither locate in \'${TABLES}/sta\' nor in \'${P}/${CAMPAIGN}/STA\'."
    clear_n_exit 1
  else
    STAINF_FILE=${P}/${CAMPAIGN}/STA/${STAINF}.${STAINF_EXT}
  fi
else
  STAINF_FILE=${TABLES_DIR}/sta/${STAINF}.${STAINF_EXT}
  if ! ln -sf ${STAINF_FILE} ${P}/${CAMPAIGN}/STA/${STAINF}.${STAINF_EXT} ; then
    echoerr "[ERROR] Failed to link the station information file \'${STAINF_FILE}\'."
    clear_n_exit 1
  fi
fi

echodbg "[DEBUG] Using the the station information file \"${P}/STA/${STAINF}.${STAINF_EXT}\""

## ------------------------------------------------------------------------- ##
##                                                                           ##
##  Validate the blq file                                                    ##
##                                                                           ##
## ------------------------------------------------------------------------- ##
if [ -z "${BLQINF+x}" ] || [ "${BLQINF}" == "" ]; then
  echodbg "[DEBUG] Not using a BLQ file."
  BLQINF=
else
  if test -f ${P}/${CAMPAIGN}/STA/${BLQINF}.BLQ ; then
    echodbg "[DEBUG] Using BLQ file: \"${P}/${CAMPAIGN}/STA/${BLQINF}.BLQ\"."
  else
    if test -f ${TABLES_DIR}/blq/${BLQINF}.BLQ ; then
      blq_src=${TABLES_DIR}/blq/${BLQINF}.BLQ
      blq_trg=${P}/${CAMPAIGN}/STA/${BLQINF}.BLQ
      if ! ln -sf ${blq_src} ${blq_trg} ; then
        echoerr "[ERROR] Failed to link the BLQ file."
        echoerr "        Link failed \"${blq_src}\" -> \"${blq_trg}\"."
        echoerr "        Processing stoped."
        clear_n_exit 1
      else
        echodbg "[DEBUG] Using BLQ file: \"${blq_src}\"."
      fi
    else
      echoerr "[ERROR] Cannot find the specified BLQ file: \"${BLQINF}\"."
      echoerr "        Processing stoped."
      clear_n_exit 1
    fi
  fi
fi

## ------------------------------------------------------------------------- ##
##                                                                           ##
##  Validate the atl file                                                    ##
##                                                                           ##
## ------------------------------------------------------------------------- ##
if [ -z "${ATLINF+x}" ] || [ "${ATLINF}" == "" ] ; then
  echodbg "[DEBUG] Not using an ATL file."
  ATLINF=
else
  if test -f ${TABLES_DIR}/atl/${ATLINF}.ATL ; then
    src_atl=${TABLES_DIR}/atl/${ATLINF}.ATL
    trg_atl=${P}/${CAMPAIGN}/STA/${ATLINF}.ATL
    if ! ln -sf ${src_atl} ${trg_atl} ; then
      echoerr "[ERROR] Failed to link the ATL file ."
      echoerr "        Link failed \"${src_atl}\" -> \"${trg_atl}\" ."
      echoerr "        Processing stoped."
      clear_n_exit 1
    else
      echodbg "[DEBUG] Using ATL file: \"${src_atl}\" ."
    fi
  else
    if test -f ${P}/${CAMPAIGN}/STA/${ATLINF}.ATL ; then
      echodbg "[DEBUG] Using ATL file: \"${P}/${CAMPAIGN}/STA/${ATLINF}.ATL\"."
    else
      echoerr "[ERROR] Cannot find the specified ATL file: \"${ATLINF}\" ."
      echoerr "        Processing stoped."
      clear_n_exit 1
    fi
  fi
fi

## ------------------------------------------------------------------------- ##
##                                                                           ##
##  Validate the fix file.                                                   ##
##  Note that we need the actaul fix file to be later used by validate_ntw   ##
##+ Let's name that FIX_FILE                                                 ##
##                                                                           ##
## ------------------------------------------------------------------------- ##
if ! test -f ${TABLES_DIR}/fix/${FIXINF}.FIX ; then
  if ! test -f ${P}/${CAMPAIGN}/STA/${FIXINF}.FIX ; then
    echoerr "[ERROR] Cannot find the fix file \'${FIXINF}.FIX\'"
    echoerr "        It is neither in \'${TABLES_DIR}/fix\' nor in \'${P}/${CAMPAIGN}/STA\'."
    clear_n_exit 1
  else
    FIX_FILE=${P}/${CAMPAIGN}/STA/${FIXINF}.FIX
  fi
else
  FIX_FILE=${TABLES_DIR}/fix/${FIXINF}.FIX
  if ! ln -sf ${FIX_FILE} ${P}/${CAMPAIGN}/STA/${FIXINF}.FIX ; then
    echoerr "[ERROR] Could not link the fix file \'${FIX_FILE}\'"
    clear_n_exit 1
  fi
fi
echodbg "[DEBUG] Using .FIX file \"${FIX_FILE}\""

## ------------------------------------------------------------------------- ##
##                                                                           ##
##  Make the pcv file if neccessary and/or link, so that after this block,   ##
##+ we have a valid PCVINF file at ${X}/GEN, i.e. there should be a file     ##
##+ (or link) at ${X}/GEN/${PCVINF}.${PCV_EXT} holding pcv info for all      ##
##+ antennas. The variable PCVINF and PCV_EXT are later to be fed to the     ##
##+ PCF file as variables.                                                   ##
##                                                                           ##
##  At this point, all variables in the LOADGPS.setvar file should           ##
##+ have been exported.                                                      ##
##                                                                           ##
##  Also, we need the .STA file to be properly placed at the                 ##
##+ campaign-specific STA/ folder.                                           ##
##                                                                           ##
## ------------------------------------------------------------------------- ##

##  Set the verbocity level for the atx2pcv.sh script
A2P_VRB=0
if test "$DEBUG_MODE" -ne 0 ; then A2P_VRB=1 ; fi

##  Case a: We have both a PCV file and an antex file specified
if [ ! -z "${PCVINF+x}" ] && [ ! -z "${ATXINF+x}" ] ; then
  echodbg "[DEBUG] Both an antex file (\"$ATXINF\") and"
  echodbg "        a pcv file (\"$PCV_FILE\") given"
  echodbg "        Updating pcv file using the atx2pcv.sh program"
  if ! test -f ${TABLES_DIR}/atx/${ATXINF} ; then
    echoerr "[ERROR] Cannot find the atnex file: \"${TABLES_DIR}/atx/${ATXINF}\"."
    clear_n_exit 1
  fi
  if ! test -f ${TABLES_DIR}/pcv/${PCVINF}.${PCV_EXT} ; then
    if ! test -f ${P}/${CAMPAIGN}/OUT/${PCVINF}.${PCV_EXT} ; then
      echoerr "[ERROR] Cannot find the PCV file: \"${PCVINF}.${PCV_EXT}\" in neither"
      echoerr "        the \"${TABLES_DIR}/pcv/\" directory, nor in "
      echoerr "        \"${P}/${CAMPAIGN}/OUT/\"."
      echoerr "        Processing stoped."
      clear_n_exit 1
    else
      PCV_FILE=${P}/${CAMPAIGN}/OUT/${PCVINF}.${PCV_EXT}
    fi
  else
    PCV_FILE=${TABLES_DIR}/pcv/${PCVINF}.${PCV_EXT}
  fi
  if ! atx2pcv.sh --antex="${TABLES_DIR}/atx/${ATXINF}" \
                  --verbose="${A2P_VRB}" \
                  --sta="${P}/${CAMPAIGN}/STA/${STAINF}.STA" \
                  --campaign="${CAMPAIGN}" \
                  --pcv="${PCV_FILE}"
                  --phg-out="PCV_${CAMPAIGN:0:3}" \
                  --loadgps="${B_LOADGPS}" ; then
    echoerr "[ERROR] Failed to make the PCV file!"
    clear_n_exit 1
  else
    PCVINF=PCV_${CAMPAIGN:0:3}
  fi
else
##
##  Case b: We have a PCV file and no antex file
  if [ ! -z "${PCVINF+x}" ] && [ -z "${ATXINF+x}" ] ; then
    ## if not in ${X}/GEN dir, link it there
    pcv_trg=${X}/GEN/${PCVINF}.${PCV_EXT}
    if ! test -f ${pcv_trg} ; then
      if test -f ${TABLES_DIR}/pcv/${PCVINF}.${PCV_EXT} ; then
        pcv_src=${TABLES_DIR}/pcv/${PCVINF}.${PCV_EXT}
        if ! ln -sf ${pcv_src} ${pcv_trg} ; then
          echoerr "[ERROR] Failed to link PCV file \"$pcv_src\" to"
          echoerr "        \"${pcv_trg}\". Processing stoped."
          clear_n_exit 1
        fi
      else
        echoerr "[ERROR] Failed to find the PCV file \"${PCVINF}.${PCV_EXT}\" "
        echoerr "        in neither \"${X}/GEN/\" directory or in the"
        echoerr "        \"${TABLES_DIR}/pcv/\" directory."
        echoerr "        Processing stoped."
        clear_n_exit 1
      fi
    else
      pcv_src=${pcv_trg}
    fi
    echodbg "[DEBUG] Only specified a PCV file: \"$PCVINF\";"
    echodbg "        using this for processing. The actual file is"
    echodbg "        \"${pcv_src}\"."
##
##  Case c We have an antex file but no pcv file
  elif [ -z "${PCVINF}" ] && [ ! -z "${ATXINF+x}" ] ; then
    echodbg "[DEBUG] Only specified an antex file: \"${ATXINF}\"."
    echodbg "        Using this to create a pcv file."
    if ! test -f ${TABLES_DIR}/atx/${ATXINF} ; then
      echoerr "[ERROR] Cannot find file: \"${TABLES_DIR}/atx/${ATXINF}\"."
      echoerr "        Processing stoped."
      clear_n_exit 1
    fi
    if ! atx2pcv.sh --antex="${TABLES_DIR}/atx/${ATXINF}" \
                    --verbose="${A2P_VRB}" \
                    --sta="${P}/${CAMPAIGN}/STA/${STAINF}.STA" \
                    --campaign="${CAMPAIGN}" \
                    --phg-out="PCV_${CAMPAIGN:0:3}" \
                    --loadgps="${B_LOADGPS}" ; then
      echoerr "[ERROR] Failed to make the PCV file!"
      echoerr "        Processing stoped."
      clear_n_exit 1
    else
      PCVINF=PCV_${CAMPAIGN:0:3}
    fi
  else
    echoerr "[ERROR] Eisai malakas?  What PCV file do you want?"
    clear_n_exit 1
  fi
fi
##
##  final check
if ! test -f "${X}/GEN/${PCVINF}.${PCV_EXT}" ; then
  echoerr "[ERROR] Failed to make the PCV file (F)! 
                   Cannot find \"${X}/GEN/${PCVINF}.${PCV_EXT}\"."
  clear_n_exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  DATETIME VARIABLES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
if ! START_OF_DAY_STR=$(ydoy2dt "${YEAR}" "${DOY_3C}") ; then
  echoerr "[ERROR] Failed to parse date."
  clear_n_exit 1
fi

if ! END_OF_DAY_STR=$(ydoy2dt "${YEAR}" "${DOY_3C}" "23" "59" "30") ; then
  echoerr "[ERROR] Failed to parse date."
  clear_n_exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  REPORT ..
## ////////////////////////////////////////////////////////////////////////////
{
printf "\n\"general_info\":{"
printf "\n\"campaign\": \"%s\"," "${CAMPAIGN}"
printf "\n\"user\": \"%s\"," "${USER}"
printf "\n\"host\":\"%s\"," "${HOSTNAME}"
printf "\n\"program\": {\"name\":\"%s\",\"version\":\"%s\",\"revision\":\"%s\",\"last_upd\":\"%s\"}," \
    "${NAME}" "${VERSION}" "${REVISION}" "${LAST_UPDATE}"
printf "\n\"day_processed\": \"%s-%s\"," "${YEAR}" "${DOY_3C}"
printf "\n\"interval\": {\"from\":\"%s\", \"to\":\"%s\"}" "${START_OF_DAY_STR}" "${END_OF_DAY_STR}"
printf "\n},\n"
} 1>>${JSON_OUT}

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
START_RD=$(date +%s.%N)

>.rnxsta.dat ## temporary file
tmp_file_array+=('.rnxsta.dat')

##  download the rinex files for the input network; the database knows 
##+ the details .... Call rnxdwnl.py
if ! rnxdwnl.py \
              --networks=${CAMPAIGN} \
              --year=${YEAR} \
              --doy=${DOY} \
              --path=${D} \
              --marker-rename \
              --db-host="${DB_HOST}" \
              --db-user="${DB_USER}" \
              --db-pass="${DB_PASS}" \
              --db-name="${DB_NAME}" \
              -v "${DEBUG_MODE}" \
              1>&2; then
  echoerr "[ERROR] Failed to download RINEX files."
  clear_n_exit 1
fi

##  make a file with all excluded stations (if any)
X_STA_FL=.sta2exclude
>${X_STA_FL}
tmp_file_array+=("${X_STA_FL}")

if test "${USE_EUREF_EXCLUDE_LIST}" = "YES" ; then
  if ! ${P2ETC}/get_euref_excl_list.sh ${YEAR} ${DOY} 1>${X_STA_FL} ; then
    echoerr "[WARNING] Failed to download Euref exclusion list!"
  fi
fi
if ! test -z ${STA_EXCLUDE_FILE+x} ; then
  if ! test -f ${STA_EXCLUDE_FILE} ; then
    echoerr "[WARNING] Station exclusion file \"${STA_EXCLUDE_FILE}\" does not exist."
  else
    echodb "[DEBUG] Using ${STA_EXCLUDE_FILE} exclusion file."
    cat ${STA_EXCLUDE_FILE} >> ${X_STA_FL}
  fi
fi

##  make a table with available rinex/station names, reference stations, etc ..
##  dump output to the .rnxsta.dat file (filter it later on)

##  do not include --no-marker-numbers
if ! validate_ntwrnx.py \
            --db-host="${DB_HOST}" \
            --db-user="${DB_USER}" \
            --db-pass="${DB_PASS}" \
            --db-name="${DB_NAME}" \
            --year="${YEAR}" \
            --doy="${DOY}" \
            --fix-file="${FIX_FILE}" \
            --network="${CAMPAIGN}" \
            --rinex-path="${D}" \
            --exclude-file="${X_STA_FL}" \
            1> .rnxsta.dat; then
  echoerr "[ERROR] Failed to compile rinex/station summary."
  clear_n_exit 1
fi

declare -a RNX_ARRAY     ##  array to hold available rinex files;
                         ##+ no path; compressed
declare -a STA_ARRAY     ##  array to hold available station names
declare -a REF_STA_ARRAY ##  array to hold available reference stations
MAX_NET_STA=             ##  nr of stations in the network

mapfile -t STA_ARRAY < <(${P2ETC}/filter_available_stations.awk .rnxsta.dat)
mapfile -t RNX_ARRAY < <(${P2ETC}/filter_available_rinex.awk .rnxsta.dat)
mapfile -t REF_STA_ARRAY < <(${P2ETC}/filter_available_reference.awk .rnxsta.dat)
MAX_NET_STA=$(cat .rnxsta.dat | tail -n+2 | wc -l)

## basic validation; make sure nothing went terribly wrong!
if [[ $MAX_NET_STA -lt 0 \
      || ${#STA_ARRAY[@]} -ne ${#RNX_ARRAY[@]} \
      || ! -f .rnxsta.dat ]]; then
  echoerr "[ERROR] Error in handling rinex files/station names."
  clear_n_exit 1
fi

## make sure number reference stations > 4
if test ${#REF_STA_ARRAY[@]} -lt 5; then
  echoerr "[WARNING] Two few reference stations (${#REF_STA_ARRAY[@]})"
fi

## transfer all available rinex to RAW/ and uncompress them
unix_ucmpr() { ##  run uncompress if file ends with '.Z'
  if test "${1:(-2)}" == ".Z" ; then
    uncompress -f $1
    return $?
  else
    return 0
  fi
}
crx2rnx_if() { ##  run CRX2RNX if file ends with 'd' or 'D'
  if [[ "${1:(-1)}" =~ [dD] ]] ; then
    CRX2RNX -f ${1}
    return $?
  else
    return 0
  fi
}
for i in "${RNX_ARRAY[@]}"; do
  if RNX=${i} \
        && cp ${D}/${RNX} ${P}/${CAMPAIGN}/RAW/${RNX^^} \
        && RNX=${RNX^^} \
        && unix_ucmpr ${P}/${CAMPAIGN}/RAW/${RNX} \
        && RNX=${RNX%.Z} \
        && crx2rnx_if ${P}/${CAMPAIGN}/RAW/${RNX}
  then
    :
  else
    echoerr "[ERROR] Failed to manipulate rinex file \"${RNX}\"."
    clear_n_exit 1
  fi
done

##  dump all (available) station names to a file for later use; one station
##+ per line.
>.station-names.dat
for sta in "${STA_ARRAY[@]}"; do echo $sta >> .station-names.dat; done
tmp_file_array+=('.station-names.dat')

STOP_RD=$(date +%s.%N)

## ////////////////////////////////////////////////////////////////////////////
##  DOWNLOAD IONOSPHERIC MODEL FILE
##  ---------------------------------------------------------------------------
##  If the user has specified a local solution id, then search through ntua's
##  TODO :: mysql ...
##  If such a file does not exist, download CODE's ionospheric file.
## ////////////////////////////////////////////////////////////////////////////
START_PD=$(date +%s.%N)
printf 1>>${JSON_OUT} "\n\"products\":{"

ION_DOWNLOADED=0

# if mysql -h "${DB_HOST}" \
#         --user="${DB_USER}" \
#         --password="${DB_PASSWORD}" \
#         --database="${DB_NAME}" \
#         --execute="use procsta; \
#          SELECT product.pth2dir, product.filename \
#          FROM product \
#          JOIN prodtype \
#          ON product.prodtype_id=prodtype.prodtype_id \
#          JOIN network \
#          ON product.network_id=network.network_id \
#          WHERE prodtype.prodtype_name=\"ION\" \
#          AND network.network_name=\"${CAMPAIGN}\" \
#          AND product.dateobs_start<=\"${START_OF_DAY_STR}\" \
#          AND product.dateobs_stop>=\"${END_OF_DAY_STR}\";" \
#       | grep -v "+----" \
#       | tail -n +2 \
#       | awk '{print $1$2}' > .procsta-answer.dat \
#     && grep "[a-z,A-Z]*" .procsta-answer.dat &>/dev/null ; then
#   my_ion_file=$(cat .procsta-answer.dat)
#   echoerr "ERROR. NTUA's ION file found but ddprocess does not yet handle that!"
#   echoerr "Write more code bitch!"
# else
#   echoerr "[WARNING]. No NTUA .ION file found."
# fi
tmp_file_array+=('.procsta-answer.dat')

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
if test "$USE_REPRO2" == "YES" ; then
  add_option="--use-repro2"
fi
if test "$COD_REPRO13" == "YES" ; then
  add_option="--use-repro13"
fi

##  will we need an ion file ?
if test ${ION_DOWNLOADED} -eq 1; then
  if ! handle_dd_products.py 1>>${JSON_OUT} ${add_option}\
          --year="${YEAR}" \
          --doy="${DOY}" \
          --analysis-center="${AC}" \
          --datapool="${D}" \
          --destination="${P}/${CAMPAIGN}/ORB" \
          --satellite-system="${SAT_SYS}" \
          --report=json; then
    echoerr "[ERROR] Failed to download/copy/uncompress products."
    clear_n_exit 1
  fi
else
  if ! handle_dd_products.py 1>>${JSON_OUT} ${add_option} \
          --year="${YEAR}" \
          --doy="${DOY}" \
          --analysis-center="${AC}" \
          --datapool="${D}" \
          --destination="${P}/${CAMPAIGN}/ORB" \
          --satellite-system="${SAT_SYS}" \
          --download-ion \
          --report=json; then
    echoerr "[ERROR] Failed to download/copy/uncompress products."
    clear_n_exit 1
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

## temporary file to hold getvmf1.py output
TMP_FL=.vmf1-${YEAR}${DOY}.dat
tmp_file_array+=("${TMP_FL}")

if ! getvmf1.py \
            --year=${YEAR} \
            --doy=${DOY} \
            --outdir=${D} \
            --json=".vmf1.json" \
            1>${TMP_FL}; then
  echoerr "[ERROR] Failed to get VMF1 grid file(s)."
  clear_n_exit 1
fi

##  grid files are downloaded to ${D} as individual files; merge them and move
##+ to /GRID
if ! mapfile -t VMF_FL_ARRAY < <(filter_local_vmf1.awk ${TMP_FL}) ; then
  echoerr "[ERROR] Failed to merge VMF1 grid file(s)."
  clear_n_exit 1
else
  MERGED_VMF_FILE=${P}/${CAMPAIGN}/GRD/VMF${YEAR:2:2}${DOY_3C}0.GRD
  >${MERGED_VMF_FILE}
  for fl in ${VMF_FL_ARRAY[@]}; do
    cat ${fl} >> ${MERGED_VMF_FILE}
  done
fi

cat .vmf1.json 1>>${JSON_OUT} 2>/dev/null
tmp_file_array+=(".vmf1.json")

printf 1>>${JSON_OUT} "\n}," ## done with products

STOP_PD=$(date +%s.%N)

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
  ${P2ETC}/make_cluster_file.awk .station-names.dat \
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
##       FREENET_SOLUTION_ID = 'FFN'
##
##  e.g. --solution-id=FFR will result to:
##+      FINAL_SOLUTION_ID   = 'FFR'
##+      PRELIM_SOLUTION_ID  = 'FFP'
##+      REDUCED_SOLUTION_ID = 'FFR1'
## ////////////////////////////////////////////////////////////////////////////
printf 1>>${JSON_OUT} "\n\"solution_identifiers\":["

##  Final (ambiguity-fixed) results
FINAL_SOLUTION_ID="${SOLUTION_ID}"

##  Preliminary (ambiguity-float) results
if test "${FINAL_SOLUTION_ID:(-1)}" == "P"; then
  echoerr "[WARNING] Last char of final solution is 'P'."
  PRELIM_SOLUTION_ID="${SOLUTION_ID%?}P1"
  echoerr "          Truncating Preliminary to \"$PRELIM_SOLUTION_ID\"."
else
  PRELIM_SOLUTION_ID="${SOLUTION_ID%?}P"
fi

##  Size-reduced NEQ information
if test "${FINAL_SOLUTION_ID:(-1)}" == "R"; then
  echoerr "[WARNING] Last char of final solution is 'R'."
  REDUCED_SOLUTION_ID="${SOLUTION_ID%?}R1"
  echoerr "          Truncating Size-reduced to \"$REDUCED_SOLUTION_ID\"."
else
  REDUCED_SOLUTION_ID="${SOLUTION_ID%?}R"
fi

##  Free network NEQ information
if test "${FINAL_SOLUTION_ID:(-1)}" == "N"; then
  echoerr "[WARNING] Last char of final solution is 'N'."
  FREENET_SOLUTION_ID="${SOLUTION_ID%?}N1"
  echoerr "          Truncating Free-Network to \"$FREENET_SOLUTION_ID\"."
else
  FREENET_SOLUTION_ID="${SOLUTION_ID%?}N"
fi
##  report ..
{
printf "\n{\"description\":\"Final Solution\", \"id\":\"%s\"}," "$FINAL_SOLUTION_ID"
printf "\n{\"description\":\"Free Network Solution\", \"id\":\"%s\"}," "$FREENET_SOLUTION_ID"
printf "\n{\"description\":\"Size-Reduced\", \"id\":\"%s\"}," "$REDUCED_SOLUTION_ID"
printf "\n{\"description\":\"Preliminary Solution\", \"id\":\"%s\"}" "$PRELIM_SOLUTION_ID"
printf "\n],\n"
} 1>>${JSON_OUT}

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
  echoerr "[ERROR] Invalid pcf file \"${U}/PCF/${PCF_FILE}\"."
  clear_n_exit 1
fi

if ! set_pcf_variables.py "${U}/PCF/${PCF_FILE}" 1>>${JSON_OUT} \
        B="${AC^^}" \
        C="${PRELIM_SOLUTION_ID}" \
        E="${FINAL_SOLUTION_ID}" \
        F="${REDUCED_SOLUTION_ID}" \
        N="${FREENET_SOLUTION_ID}" \
        BLQINF="${BLQINF}" \
        ATLINF="${ATLINF}" \
        STAINF="${STAINF}" \
        CRDINF="${CAMPAIGN}" \
        SATSYS="${BERN_SAT_SYS}" \
        PCV="${PCV_EXT}" \
        PCVINF="${PCVINF}" \
        ELANG="${ELEVATION_ANGLE}" \
        FIXINF="${FIXINF}"\
        CLU="${FILES_PER_CLUSTER}"; then
  echoerr "[ERROR] Failed to set variables in PCF file."
  clear_n_exit 1
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
  clear_n_exit 1
fi
PAN=`/bin/grep POLUPDH ${U}/PCF/${PCF_FILE} | /bin/grep -v "#" | awk '{print $3}'`
if ! setpolupdh.sh --bernese-loadvar=${B_LOADGPS} \
        --analysis-center=${AC^^} \
        --pan=${PAN}
then
  echo "bernese-loadvar=${B_LOADGPS}"
  clear_n_exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  A-PRIORI COORDINATES FOR REGIONAL SITES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
if test -z "${APRINF+x}" ; then
  echoerr "[ERROR] You need to specify a valid a-priori coordinate file."
  clear_n_exit 1
fi

##  Find the a-priori coordinate file
if ! test -f ${TABLES_DIR}/crd/${APRINF}.CRD ; then
  if ! test -f ${P}/${CAMPAIGN}/STA/${APRINF}.CRD ; then
    echoerr "[ERROR] Failed to find a-priori coordinate file: \"${APRINF}.CRD\""
    echoerr "        either in \"${TABLES_DIR}/crd\" or in"
    echoerr "        \"${P}/${CAMPAIGN}/STA\"".
    clear_n_exit 1
  else
    APRCRD_FILE=${P}/${CAMPAIGN}/STA/${APRINF}.CRD
  fi
else
  APRCRD_FILE=${TABLES_DIR}/crd/${APRINF}.CRD
  echodbg "[DEBUG] Using a-priori coordinate file: \"${APRCRD_FILE}\"."
fi

##  Should we compile a .CRD file for EPN CLASS A stations ?
if [ ! -z "${USE_EPN_A_SSC}" ] && [ "${USE_EPN_A_SSC}" = "YES" ] ; then
  echodbg "[DEBUG] Compiling a-priori coordinate file for EPN class A sites."
  cat $APRCRD_FILE > TEMP.CRD ##  create a temp so that we don't mess it up
  APRCRD_FILE=TEMP.CRD
  tmp_file_array+=('TEMP.CRD')
  if ! make_euref_apr_crd.py --year="${YEAR}" \
                          --doy="${DOY}" \
                          --append-to-crd="${APRCRD_FILE}" ; then
    echoerr "[ERROR] Failed to make a-priori coordinates for EPN class A sites."
    clear_n_exit 1
  fi
  echodbg "[DEBUG] EPN class A site coordinates appended to file \"${APRCRD_FILE}\"."
fi

if ! awk -v FLAG=R -v REPLACE_ALL=NO -f \
        ${P2ETC}/change_crd_flags.awk ${APRCRD_FILE} \
        1>${P}/${CAMPAIGN}/STA/REG${YEAR:2:2}${DOY_3C}0.CRD; then
  echoerr "[ERROR] Could not create a-priori coordinate file."
  clear_n_exit 1
fi

## ////////////////////////////////////////////////////////////////////////////
##  PROCESS THE DATA
##  ---------------------------------------------------------------------------
##  Call the perl script which ignites the BPE via the PCF :)
## ////////////////////////////////////////////////////////////////////////////
START_BP=$(date +%s.%N)
BERN_TASK_ID="${CAMPAIGN:0:1}DD"
PROC_LOG=.proc${BERN_TASK_ID}${DOY_3C}.log

##  run the perl script to ignite the PCF
echodbg "[DEBUG] Fired up the processing engine."
${U}/SCRIPT/ntua_pcs.pl ${YEAR} \
          ${DOY_3C}0 \
          NTUA_DDP USER \
          ${CAMPAIGN} \
          ${BERN_TASK_ID} \
          1>${PROC_LOG} \
          2>${PROC_LOG}

##  check the status
if ! check_bpe_run \
      ${P}/${CAMPAIGN}/BPE \
      "${CAMPAIGN:0:3}_${BERN_TASK_ID}.RUN" \
      "${CAMPAIGN:0:3}_${BERN_TASK_ID}.OUT" ; then
  echoerr "[ERROR]. Fatal, processing stoped."
  echoerr "         Check the log file \"${PROC_LOG}\" for details."
  clear_n_exit 1
else
  tmp_file_array+=("${PROC_LOG}")
  echodbg "[DEBUG] Processing done. No errors detected."
fi
STOP_BP=$(date +%s.%N)

## ////////////////////////////////////////////////////////////////////////////
##  COPY PRODUCTS TO HOST; UPDATE DATABASE ENTRIES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
printf 1>>${JSON_OUT} "\n\"saved_products\":["

##  warning: in the db mixed := GPS+GLO
if test "${SAT_SYS^^}" = "MIXED"; then
  DB_SAT_SYS="GPS+GLO"
else
  DB_SAT_SYS=${SAT_SYS}
fi

##  create the directory ${SAVE_DIR}/YYYY/DDD (if it doesn't exist)
if ! test -d "${SAVE_DIR}/${YEAR}/${DOY_3C}"; then
  echodbg "[DEBUG] Creating solution directory \"${SAVE_DIR}/${YEAR}/${DOY_3C}/\"."
  if ! mkdir -p "${SAVE_DIR}/${YEAR}/${DOY_3C}"; then
    echoerr "[ERROR] Failed to create directory \"${SAVE_DIR}/${YEAR}/${DOY_3C}/\"."
    clear_n_exit 1
  fi
fi

##  warning: dates have whitespace ('%Y-%m-%d %H:%M:%S'); replace whitespace
##+ with underscore, i.e. '%Y-%m-%d_%H:%M:%S'

##  argv1 -> file extension (e.g. 'SNX')
##  argv2 -> campaign dir (e.g. 'SOL')
##  argv3 -> product type (e.g. 'SINEX')

{
##  final tropospheric sinex
if ! save_n_update TRO ATM TRO_SNX ; then exit 1 ; else printf "," ; fi

## final SINEX
if ! save_n_update SNX SOL SINEX ; then exit 1 ; else printf "," ; fi

## Free network SINEX
## FIXME add free network solution sinex
## if ! save_n_update SNX SOL SINEX ; then exit 1 ; else printf "," ; fi

## final NQ0
if ! save_n_update NQ0 SOL NQ ; then exit 1 ; else printf "," ; fi

## reduced NQ0
if ! save_n_update NQ0 SOL NQ R ; then exit 1 ; else printf "," ; fi

## final coordinates
if ! save_n_update CRD STA CRD_FILE ; then exit 1 ; fi
} 1>>${JSON_OUT}

printf 1>>${JSON_OUT} "],\n"
## ////////////////////////////////////////////////////////////////////////////
##  COMPILE (NON-FATAL) ERROR/WARNINGS FILE
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
##  check that the campaign has a /LOG directory
if test -d ${P}/${CAMPAIGN}/LOG ; then
  LOG_DIR=LOG
else
  LOG_DIR=BPE
fi

WRN_FILE=${P}/${CAMPAIGN}/${LOG_DIR}/wrn${YEAR}${DOY_3C}0.log
>${WRN_FILE}

find ${P}/${CAMPAIGN}/OUT/WRN${DOY_3C}0*.SUM -not -empty -ls -exec \
      cat {} 1>>${WRN_FILE} 2>/dev/null \; ## match files e.g 'WRN0010003.SUM'

find ${P}/${CAMPAIGN}/OUT/*${YEAR}${DOY_3C}0.ERR -not -empty -ls -exec \
      cat {} 1>>${WRN_FILE} 2>/dev/null \; ## match files e.g 'RNX150010.ERR'

## echo "Warnings file created as ${WRN_FILE}"
##  warnings to json ..
if test -s ${WRN_FILE} ; then
  if ! wrn2json.py ${WRN_FILE} 1>>${JSON_OUT} 2>/dev/null ; then
    echoerr "[ERROR] Failed to create json warning file!"
    clear_n_exit 1
  fi
else
  echodbg "[DEBUG] Warnings file is empty."
fi
## ////////////////////////////////////////////////////////////////////////////
##  ADDNEQ SUMMARY TO HTML
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
##  the ambiguity summary file
AMBSM=${P}/${CAMPAIGN}/OUT/AMB${YEAR:2:2}${DOY_3C}0.SUM
python - <<END 1>>${JSON_OUT}
import sys, bernutils.bamb
try:
  ambf = bernutils.bamb.AmbFile( "${AMBSM}" )
  ambf.toJson()
except:
  print>>sys.stderr,'[ERROR] Cannot translate amb file to json!'
  sys.exit(1)
sys.exit(0)
END
if test "$?" -ne 0 ; then
  echoerr "[ERROR] Failed to translate ambiguity summary file \"$AMBSM\""
  echoerr "        to json format."
  clear_n_exit 1
fi

##  the final ADDNEQ summary file should be
ADNQ=${P}/${CAMPAIGN}/OUT/${FINAL_SOLUTION_ID}${YEAR:2:2}${DOY_3C}0.OUT
python - <<END 1>>${JSON_OUT}
import sys, bernutils.badnq
try:
  adnf = bernutils.badnq.AddneqFile( "${ADNQ}" )
  adnf.toJson()
except:
  print>>sys.stderr,'[ERROR] Cannot translate addneq file to json!'
  sys.exit(1)
sys.exit(0)
END
if test "$?" -ne 0 ; then
  echoerr "[ERROR] Cannot translate ADDNEQ2 output file \"${ADNQ}\""
  echoerr "        to json format!"
  clear_n_exit 1
fi
## ////////////////////////////////////////////////////////////////////////////
##  REMOVE CAMPAIGN FILES
##  ---------------------------------------------------------------------------
## ////////////////////////////////////////////////////////////////////////////
if test "${SKIP_REMOVE}" != "YES" ; then

##  we are going to remove any file in the campaign-specific folders, newer
##+ than .ddprocess-time-stamp (i.e. the stamp file), except from symlinks.
  if ! test -f ${TIME_STAMP_FILE} ; then
    echoerr "[WARNING] Removing nothing cause file \"${TIME_STAMP_FILE}\" is missing."
  else
    b_wrnfile=$(basename ${WRN_FILE})
    find -P ${P}/${CAMPAIGN}/* \
          -maxdepth 1 \
          -type f \
          -newer ${TIME_STAMP_FILE} \
          -not -name ${b_wrnfile} \
          -not -name "*.STA" \
          -not -name "*.ABB" \
          -exec rm -rf {} \;
  fi
else
  echodbg "[DEBUG] Removing of campaign files skiped!"
fi

printf 1>>${JSON_OUT} "\n}"

STOP_DD=$(date +%s.%N)
echo "8"
##  PRINT TIME INFO
DD_RT=$(echo "scale=2; ($STOP_DD - $START_DD)/1" | bc)
RD_RT=$(echo "scale=2; ($STOP_RD - $START_RD)/1" | bc)
RD_PC=$(echo "scale=2; ($RD_RT / $DD_RT) * 100" | bc)
PD_RT=$(echo "scale=2; ($STOP_PD - $START_PD)/1" | bc)
PD_PC=$(echo "scale=2; ($PD_RT / $DD_RT) * 100" | bc)
BP_RT=$(echo "scale=2; ($STOP_BP - $START_BP)/1" | bc)
BP_PC=$(echo "scale=2; ($BP_RT / $DD_RT) * 100" | bc)
#echodbg "[DEBUG] Total running time                : $DD_RT ~ 100%"
#echodbg "[DEBUG] Rinex download and manipulation   : $RD_RT ~ $RD_PC %"
#echodbg "[DEBUG] Products download and manipulation: $PD_RT ~ $PD_PC %"
#echodbg "[DEBUG] Bernese processing                : $BP_RT ~ $BP_PC %"
printf "[DEBUG] Total running time                : %6.2f ~ 100.0%%\n" "$DD_RT"
printf "[DEBUG] Rinex download and manipulation   : %6.2f ~ %3.1f%%\n" "$RD_RT" "$RD_PC"
printf "[DEBUG] Products download and manipulation: %6.2f ~ %3.1f%%\n" "$PD_RT" "$PD_PC"
printf "[DEBUG] Bernese processing                : %6.2f ~ %3.1f%%\n" "$BP_RT" "$BP_PC"
echo "9"
clear_n_exit 0

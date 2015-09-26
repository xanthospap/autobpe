#! /bin/bash

# //////////////////////////////////////////////////////////////////////////////
# FUNCTIONS
# //////////////////////////////////////////////////////////////////////////////

##  echo to stderr
echoerr () { echo "$@" 1>&2; }

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
           ${1}/atl/${2}52.STA; do
    if ! test -f $i ; then
      echoerr "Missing file: $i"
      return 1
    fi
  done

  return 0
}

# //////////////////////////////////////////////////////////////////////////////
# GLOBAL VARIABLES
# //////////////////////////////////////////////////////////////////////////////
DEBUG_MODE=NO

## following variables should be set via cmd arguments (else error!)
# YEAR=
# DOY=
# B_LOADGPS=
# CAMPAIGN=
# LOGFILE=

## optional parameters; may be changes via cmd arguments
SAT_SYS=GPS
TABLES_DIR=${HOME}/tables
AC=COD
STATIONS_PER_CLUSTER=3

export PATH=${PATH}:/home/bpe2/src/autobpe/bin

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
  ARGS=`getopt -o hvy:d:b:c:s:g: \
-l  help,version,year:,doy:,bern-loadgps:,campaign:,satellite-system:,tables-dir:,debug,logfile:,stations-per-cluster \
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
while true
do
  case "$1" in

    -a|--analysis-center)
      AC="${2}"
      shift
      ;;
    -b|--bern-loadgps)
      B_LOADGPS="${2}"
      shift
      ;;
    -c|--campaign)
      CAMPAIGN="${2}"
      shift
      ;;
    --debug)
      DEBUG_MODE=YES
      ;;
    --logfile)
      LOGFILE="${2}"
      shift
      ;;
    -d|--doy) ## remove any leading zeros
      DOY=`echo "${2}" | sed 's|^0||g'`
      shift
      ;;
    -g|--tables-dir)
      TABLES_DIR="${2}"
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -s|--satellite-system)
      SAT_SYS="${2^^}"
      if test ${SAT_SYS} != "GPS" && test ${SAT_SYS} != "MIXED" ; then
        echoerr "ERROR. Invalid satellite system : ${SAT_SYS}"
        exit 1
      fi
      shift
      ;;
    --stations-per-cluster)
      STATIONS_PER_CLUSTER="${2}"
      if ! [[ $STATIONS_PER_CLUSTER =~ ^[0-9]+$ ]] ; then
        echoerr "ERROR. stations-per-cluster must be a positive integer!"
        exit 1
      fi
      shift
      ;;
    -v|--version)
      dversion
      exit 0
      ;;
    -y|--year)
      YEAR="${2}"
      shift
      ;;
    --) # end of options
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
## VALIDATE COMMAND LINE ARGUMENTS
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

echo "Number of stations available: ${#STA_ARRAY[@]}/${MAX_NET_STA}"
echo "Number of reference stations: ${#REF_STA_ARRAY[@]}"

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
if test 1 -eq 2; then
## download the sp3, erp, dcb file
python - <<END
import sys, datetime, traceback
import bernutils.products.pysp3
import bernutils.products.pyerp
import bernutils.products.pydcb

try:
  py_date = datetime.datetime.strptime('%s-%s'%('${YEAR}', '${DOY}'), \
    '%Y-%j').date()
except:
  print >>sys.stderr, 'ERROR. Failed to parse date!.'
  sys.exit(1)

ussr = True
if '$SAT_SYS' == 'gps' or '$SAT_SYS' == 'GPS':
  ussr = False

error_at = 0
try:
  info_list_sp3 = bernutils.products.pysp3.getOrb(date=py_date, \
    ac='${AC}', \
    out_dir='${D}', \
    use_glonass=ussr)
  error_at += 1

  info_list_erp = bernutils.products.pyerp.getErp(date=py_date, \
    ac='${AC}', \
    out_dir='${D}')
  error_at += 1

  info_list_dcb = bernutils.products.pydcb.getCodDcb(stype='c1_rnx', \
    datetm=py_date, \
    out_dir='${D}')
  error_at += 1

except Exception, e:
  ## where was the exception thrown ?
  if error_at == 0:
    print >>sys.stderr, 'ERROR. Failed to download orbit information.'
  elif error_at == 1:
    print >>sys.stderr, 'ERROR. Failed to download erp information.'
  elif error_at == 2:
    print >>sys.stderr, 'ERROR. Failed to download dcb information.'
  else:
    print >>sys.stderr, 'WTF! Should have come been here!'
  ## log exception/stack call
  print >>sys.stderr,'*** Stack Rewind:'
  exc_type, exc_value, exc_traceback = sys.exc_info()
  traceback.print_exception(exc_type, exc_value, exc_traceback, \
    limit=10, file=sys.stderr)
  print >>sys.stderr,'*** End'
  ## exit with error
  sys.exit(1)

sys.exit(0)
END
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
if test 1 -eq 2; then
## temporary file to hold getvmf1.py output
TMP_FL=.vmf1-${YEAR}${DOY}.dat

if ! getvmf1.py --year=${YEAR} --doy=${DOY} --outdir=${D} 1> ${TMP_FL}; then
  echoerr "ERROR. Failed to get VMF1 grid file(s)"
  exit 1
fi

##  grid files are downloaded to ${D} as individual files; merge them and move
##+ to /GRID
if ! mapfile -t VMF_FL_ARRAY < <(filter_local_vmf1.awk ${TMP_FL}) ; then
  echoerr "ERROR. Failed to merge VMF1 grid file(s)"
  exit 1
else
  MERGED_VMF_FILE=${P}/${CAMPAIGN}/GRD/VMF1_${YEAR}${DOY}.
  >${MERGED_VMF_FILE}
  for fl in ${VMF_FL_ARRAY[@]}; do
    cat ${fl} >> ${MERGED_VMF_FILE}
  done
fi
fi
rm ${TMP_FL} ## remove temporary file

## ////////////////////////////////////////////////////////////////////////////
##  MAKE THE CLUSTER FILE
##  ---------------------------------------------------------------------------
##  Using the array holding the stations names of all available stations (i.e.
##+ STA_ARRAY), we will create the cluster file: NETWORK_NAME.CLU placed in
##+ the /STA folder.
##
##  Each cluster cannot have more than STATIONS_PER_CLUSTER stations.
## ////////////////////////////////////////////////////////////////////////////

CLUSTER_FILE=${P}/${CAMPAIGN}/STA/${CAMPAIGN}.CLU

awk -v num_of_clu=${STATIONS_PER_CLUSTER} -f \
  make_cluster_file.awk .station-names.dat \
  1>${CLUSTER_FILE}

exit 0

#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : ddprocess.sh
                           NAME=ddprocess
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : DEC-2014
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : 
## uses                  : 
## notes                 :
## TODO                  : PCV files should be linked to GEN
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
  echo "/******************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Process a network using DD approach via a given PCF file"
  echo ""
  echo " Usage   : "
  echo ""
  echo " Switches: -a --analysis-center= specify the analysis center; this can be e.g."
  echo "              * igs, or"
  echo "              * cod (default)"
  echo "           -b --bernese-loadvar= specify the Bernese LOADGPS.setvar file; this"
  echo "            is needed to resolve the Bernese-related path variables"
  echo "           -c --campaign= specify the campaign --see Note 3"
  echo "           -d --doy= specify doy"
  echo "           -e --elevation-angle specify the elevation angle (degrees, integer)"
  echo "            default value is 3 degrees"
  echo "           -f --ion-products= specify (a-priori) ionospheric correction file identifier."
  echo "            If more than one, use a comma-seperated list (e.g. -f FFG,RFG) --see Note 5"
  echo "           -i --solution-id= specify solution id (e.g. FFG) --see Note 1"
  echo "           -l --stations-per-cluster= specify the number of stations per cluster"
  echo "            (default is 5)"
  echo "           -m --calibration-model he extension (model) used for antenna calibration."
  echo "            This can be e.g. I01, I05 or I08. What you enter here, will be appended to"
  echo "            the pcv filename (provided via the -f switch) and all calibration-dependent"
  echo "            Bernese processing files (e.g. SATELLITE.XXX). --see Note 2"
  echo "           -p --pcv-file= specify the .PCV file to be used --see Note 2"
  echo "           -r --save-dir= specify directory where the solution will be saved; note that"
  echo "            if the directory does not exist, it will be created"
  echo "           -s --satellite-system specify the satellite system; this can be"
  echo "              * gps, or"
  echo "              * mixed (for gps + glonass)"
  echo "            default is gps"
  echo "           -t --solution-type specify the dolution type; this can be:"
  echo "              * final, or"
  echo "              * urapid"
  echo "           -u --update= specify which records/files should be updated; valid values are:"
  echo "              * crd update the default network crd file"
  echo "              * sta update station-specific files, i.e. time-series records for the stations"
  echo "              * ntw update update network-specific records"
  echo "              * all both the above"
  echo "            More than one options can be provided, in a comma seperated string e.g. "
  echo "            --update=crd,sta"
  echo "            See Note 6 for this option"
  echo "           -y --year= specify year (4-digit)"
  echo "           -x --xml-output produce an xml (actually docbook) output summary"
  echo "           --force-remove-previous remove any files from the specified save directory (-r --save-dir=)"
  echo "            prior to start of processing."
  echo "           --debug set debugging mode"
  echo "           --add-suffix= add a suffix (e.g. _GPS) to saved products of the processing"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Expected Files :"
  echo ""
  echo "    ** Rinex files are expected to be in the DATAPOOL area, uncompresses and converted to"
  echo "       observation files (not Hatanaka). For station e.g. dyng, the script will try to"
  echo "       find the file \${DATAPOOL}/dyngDDD0.YYo"
  echo ""
  echo "    ** When using the Vienna Mapping Function (VMF1), the grid file must be present in the"
  echo "       \${DATAPOOL} area. This file must include all grid files for this day and the first"
  echo "       grid of the next day, and should be named as VMFG_YYYYDDD"
  echo ""
  echo " Exit Status: >0 -> error"
  echo " Exit Status:  0  -> sucesseful exit"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo " Note 1"
  echo "       The solution id will have an effect on the naming of the Final, Preliminary"
  echo "       and Size-Reduced solutionfiles. If e.g. the solution-id is set to NTA, then"
  echo "       the Final solution files will be named NTA, the preliminery NTP and the size-"
  echo "       reduced NTR."
  echo " Note 2"
  echo "       The pcv file must reside in the tables/pcv folder, and will be linked by the"
  echo "       script to the %GEN directory. Do not provide the extension; it will be automatically"
  echo "       generated using the pcv file and the extension given via the calibration model (-m)."
  echo "       E.g. using -p GRE_PCV and -m I08, then the script will search for the pcv file"
  echo "       \${TABLES}/pcv/GRE_PCV.I08"
  echo " Note 3"
  echo "       A list of files is expected to be present in the tables directory, specified by"
  echo "       the campaign name. I.e:"
  echo "       Expected File                      | Linked to"
  echo "       -----------------------------------|--------------------------------------"
  echo "       \${TABLES}/pcv/\${PCV_FILE}        | \${X}/GEN/\${PCV_FILE}"
  echo "       \${TABLES}/sta/\${CAMPAIGN}52.STA  | \${P}/STA/\${CAMPAIGN}.STA"
  echo "       \${TABLES}/blq/\${CAMPAIGN}.BLQ    | \${P}/STA/\${CAMPAIGN}.BLQ"
  echo "       \${TABLES}/atl/\${CAMPAIGN}.ATL    | \${P}/STA/\${CAMPAIGN}.ATL"
  echo "       \${TABLES}/crd/\${CAMPAIGN}.igs    | -"
  echo "       \${TABLES}/crd/\${CAMPAIGN}.epn    | -"
  echo "       \${TABLES}/crd/\${CAMPAIGN}.reg    | -"
  echo " Note 5"
  echo "       The ionospheric correction file, must be in the Bernese-specific ION format."
  echo "       These files should reside in the product area, specified by the variable \${PRODUCT_AREA}"
  echo "       stored as \${PRODUCT_AREA}/YYYY/DDD/XXXYYDDD0.ION.Z, where XXX is the solution identifier"
  echo "       specified by the -f option."
  echo "       If none of these files are found (or if the -f switch is not used), then the script"
  echo "       will try to download a Bernese-specific ION file from CODE's ftp, using the program"
  echo "       wgetion. This downloaded files can be final, rapid or ultra-rapid."
  echo " Note 6"
  echo "      The update options, need the following:"
  echo "       UPDATE STA : This will update the station-specific time-series files. These files"
  echo "                    should be preswent in the \$STA_TS_DIR variable (hardcoded); seperate"
  echo "                    files for final/rapid solutions are assumed. The list of stations to"
  echo "                    be updated, are given by the file \${TABLES}/crd/\${network}.update. Both"
  echo "                    cartesian and geodetic coordinate files are updated."
  echo "       UPDATE CRD : This option will forec the network's default coordinate file to be updated."
  echo "                    This (default) file is \${TABLES}/crd/\${network}.CRD. All stations"
  echo "                    processed will have their coordinates updated in the default file (obviously"
  echo "                    using the newly estimated values)".
  echo ""
  echo "/******************************************************************************/"
  exit 0
}

## ------------------------------------------------------------------------- ##
##                                                                           ##
##                               NOTICE :                                    ##
##                                                                           ##
## All variables should be stripped-off paths, e.g. do not use               ##
##     CAMPAIGN=${P}/CAMPAIGN/GREECE                                         ##
##     but                                                                   ##
##     CAMPAIGN=GREECE                                                       ##
##                                                                           ##
## The analysis center can have whatever value. In Bernese though (when set  ##
##     via the $B variable) it should be capitalized.                        ##
##                                                                           ##
## When linking products and other files in campaign folders, truncate the   ##
##     filenames to capital letters. For sp3, use the '.PRE' extension. For  ##
##     erp use '.ERP' only if analysis center is CODE. Else use '.IEP'. Do   ##
##     NOT rename the original files. Only rename the links or copies.       ##
##                                                                           ##
## ------------------------------------------------------------------------- ##

# //////////////////////////////////////////////////////////////////////////////
# HARDCODED VARIABLES
# //////////////////////////////////////////////////////////////////////////////
TABLES=/home/bpe2/tables                 ## table area
PRODUCT_AREA=/media/Seagate/solutions52  ## product area
PCF_FILE=NTUA_DDP                        ## the pcf file; no path, no extension
PL_FILE=ntua_pcs.pl                      ## the perl script to ignite the processing
LOG_DIR=/home/bpe2/log                   ## directory holding the log files
TMP=/home/bpe2/tmp                       ## a temp folder with r+w premissions
XML_TEMPLATES=/home/bpe2/src/autobpe/xml/templates ## xml templates for summary
STA_TS_DIR=/media/Seagate/solutions52/stations     ## path to station ts files

# //////////////////////////////////////////////////////////////////////////////
# VARIABLES
# //////////////////////////////////////////////////////////////////////////////
YEAR=                    ## the year
DOY=                     ## the day of year
LOADVAR=                 ## bernese52 loadvar file
CAMPAIGN=                ## campaign name 
AC=                      ## analysis center
SOL_ID=                  ## (final) solution id
PCV=                     ## pcv file to be used
SAT_SYS=                 ## satellite system
ELEV=                    ## elevation angle
STA_PER_CLU=             ## stations per cluster
SOL_TYPE=                ## solution type (f, or u)
ION_PRODS_ID=()          ## search for these ion products (as a-priori)
CLBR=                    ## calibration model (e.g. I08)
DEBUG=NO                 ## debugging mode
UPD_STA=NO               ## update station time-series
UPD_NTW=NO               ## update netowrk file/records
UPD_CRD=NO               ## update network's default crd file
SAVE_DIR=                ## where to save this solution
FORCE_REMOVE_PREV=NO     ## Remove previous solution files from save directory
XML_OUT=NO               ## xml output
XML_SENTENCE="<command>$NAME" ## the command issued as xml
SUFFIX=                  ## suffix for saved products

## Variables that are set during the script ##
GPSW=
DOW=
MONTH=
DOM=
DATAPOOL=
SP3=
ERP=
DCB=
ION=
RINEX_AV=()
RINEX_MS=()
STATIONS=()
AVIGS=()
AVEPN=()
AVREG=()

# //////////////////////////////////////////////////////////////////////////////
# START TIMING
# //////////////////////////////////////////////////////////////////////////////
START_PROCESS_SECONDS=$(date +"%s")
DTM_HHMMSS=`date +"%H:%M:%S"` ## this will change later on

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then
    help
fi

## Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]
then
  ## GNU enhanced getopt is available
  ARGS=`getopt -o hvc:b:a:i:p:s:e:y:d:l:t:f:m:u:r:x \
  -l  help,version,campaign:,bernese-loadvar:,analysis-center:,solution-id:,pcv-file:,satellite-system:,elevation-angle:,year:,doy:,stations-per-cluster:,solution-type:,ion-products:,debug,calibration-model:,update:,save-dir:,xml-output,force-remove-previous,add-suffix: \
  -n 'ddprocess' -- "$@"`
else
  ## Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvc:b:a:i:p:s:e:y:d:l:t:f:m:u:r:x "$@"`
fi

## check for getopt error
if [ $? -ne 0 ]
then 
    echo "getopt error code : $status ;Terminating..." >&2 
    exit 254 
fi

eval set -- $ARGS

## extract options and their arguments into variables.
while true ; do
  case "$1" in
    --debug)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      DEBUG=YES;;
    --add-suffix)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      SUFFIX="$2"
      shift ;;
    -f|--ion-products)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      ION_STRING="$2"; shift;;
    -t|--solution-type)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      SOL_TYPE=`echo ${2:0:1} | tr 'A-Z' 'a-z'`; shift;;
    -l|--stations-per-cluster)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      STA_PER_CLU="${2}"; shift;;
    -y|--year)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      YEAR="${2}"; shift;;
    -d|--doy)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      DOY=`echo "${2}" | sed 's|^0||g'`; shift;;
    -e|--elevation-angle)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      ELEV="${2}"; shift;;
    -s|--satellite-system)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      SAT_SYS="${2}"; shift;;
    -m|--calibration-model)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      CLBR="${2}"; shift;;
    -p|--pcv-file)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      PCV="${2}"; shift;;
    -i|--solution-id)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      SOL_ID="${2}"; shift;;
    -a|--analysis-center)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      AC="${2}"; shift;;
    -b|--bernese-loadvar)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      LOADVAR="${2}"; shift;;
    -c|--campaign)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      CAMPAIGN="${2}"; shift;;
    -u|--update)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      UPD_OPTION="${2}"; shift;;
    -r|--save-dir)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      SAVE_DIR="${2}"; shift;;
    -x|--xml-output)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      XML_OUT=YES;;
    --force-remove-previous)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      FORCE_REMOVE_PREV=YES;;
    -h|--help)
      help; exit 0;;
    -v|--version)
      dversion; exit 0;;
    --) # end of options
      shift; break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 254 ;;
  esac
  shift 
done
XML_SENTENCE="${XML_SENTENCE}</command>"

# //////////////////////////////////////////////////////////////////////////////
# CHECK VITAL : YEAR AND DOY
# //////////////////////////////////////////////////////////////////////////////

# 
# CHECK THAT YEAR AND DOY IS SET AND VALID
# 
if [ $YEAR -lt 1950 ]; then
  echo "*** Need to provide a valid year [>1950]"
  exit 1
fi
YR2=${YEAR:2:2}
if [ $DOY -lt 1 ] ||  [ $DOY -gt 366 ]; then
  echo "*** Need to provide a valid doy [1-366]"
  exit 1
fi
if [ $DOY -lt 10 ]; then DOY=00${DOY}
elif [ $DOY -lt 100 ]; then DOY=0${DOY}
else DOY=${DOY}
fi

# //////////////////////////////////////////////////////////////////////////////
# CREATE / SET LOG FILE, WARNINGS FILE, TMP DIRECTORY
# //////////////////////////////////////////////////////////////////////////////
LOGFILE=${LOG_DIR}/ddproc-${YEAR:2:2}${DOY}.log
WARFILE=${LOG_DIR}/ddproc-${YEAR:2:2}${DOY}.wrn
SOLSUMASC=${LOG_DIR}/ddproc-${YEAR:2:2}${DOY}.ssa
>$LOGFILE
>$WARFILE
>$SOLSUMASC

{
echo "#############################################################"
echo "#                                          Routine Processing"
echo "# date     : ${YEAR} ${DOY}"
echo "# logfile  : ${LOGFILE}"
echo "# warnings : ${WARFILE}"
echo "# solution : ${SOLSUMASC}"
echo "# started  : ${DTM_HHMMSS}"
echo "#############################################################"
echo "$*"
} | tee -a $LOGFILE $SOLSUMASC

START_T_STAMP=`/bin/date`
tmpd=${TMP}/${YEAR}${DOY}-ddprocess-${CAMPAIGN,,}-${SOL_TYPE}${SAT_SYS}
if test -d $tmpd
then
  rm -rf $tmpd/*
else
  mkdir ${tmpd}
fi

{
echo "Temporary directory : ${tmpd}"
echo "Log File            : ${LOGFILE}"
echo "Warnings            : ${WARFILE}"
echo "Process started at  : $START_T_STAMP"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

# //////////////////////////////////////////////////////////////////////////////
# CHECK REMAINING CMD; SOURCE LOADVAR
# //////////////////////////////////////////////////////////////////////////////

#
# CHECK THAT LOADVAR FILE EXISTS AND SOURCE IT
#
if ! test -f $LOADVAR ; then
  echo "*** Variable file $LOADVAR does not exist" >> $LOGFILE
  exit 1
fi
. $LOADVAR
if [ "$VERSION" != "52" ] ; then
  echo "***ERROR! Cannot load the source file: $LOADVAR" >> $SOLSUMASC
  exit 1
fi

#
# CHECK THAT THE PCF FILE EXISTS
#
if ! test -f ${U}/PCF/${PCF_FILE}.PCF ; then
  echo "*** Cannot find pcf file: ${U}/PCF/${PCF_FILE}.PCF" >> $LOGFILE
  exit 1
fi

#
# CHECK THAT THE CAMPAIGN EXISTS
#
if test -z $CAMPAIGN ; then
  echo "***ERROR! Need to specify campaign name" >> $LOGFILE
  exit 1
fi
if ! test -d ${P}/${CAMPAIGN} ; then
  echo "***ERROR! Cannot locate campaign ${P}/${CAMPAIGN}" >> $LOGFILE
  exit 1
fi

# 
# CHECK THAT THE ANALYSIS CENTER IS VALID
#
if [ ${AC^^} != "IGS" -a ${AC^^} != "COD" ]; then
  echo "*** Need to provide a valid analysis center" >> $LOGFILE
  exit 1
fi

# 
# CHECK THE SATELLITE SYSTEM
#
if [ "${SAT_SYS^^}" != "GPS" -a "${SAT_SYS^^}" != "MIXED" ]; then
  echo "*** Invalid satellite system" >> $LOGFILE
  exit 1
fi

# 
# CHECK THE ELEVATION ANGLE
# 
if [[ $ELEV =~ ^[0-9]+$ ]]; then
  if [ $ELEV -lt 3 -o $ELEV -gt 15 ]
  then
    echo "*** Elevation angle must be in the range [3-15]" >> $LOGFILE
    exit 1
  fi
else
  echo "*** Invalid elevation angle" >> $LOGFILE
  exit 1
fi

# 
# CHECK THE STATIONS PER CLUSTER
# 
if [[ $STA_PER_CLU =~ ^[0-9]+$ ]]; then
    :
else
   echo "*** Invalid stations per cluster" >> $LOGFILE
   exit 1
fi

#
# RESOLVE IONOSPHERIC PRODUCT IDENTIFIER
#
if ! test -z $ION_STRING ; then
  ION_PRODS_ID=( $( echo ${ION_STRING//,/ }  ) )
fi

#
# CHECK THE SOLUTION TYPE IDENTIFIER
#
if [ "$SOL_TYPE" != "f" -a "$SOL_TYPE" != "u" ]; then
  echo "*** Invalid solution type" >> $LOGFILE
  exit 1
fi

#
# CHECK THE UPDATE OPTIONS
#
if ! test -z "$UPD_OPTION"
then
  UPDOPT=()
  IFS=',' read -a UPDOPT <<<"$UPD_OPTION"
  for o in "${UPDOPT[@]}"
  do
    case "${o}" in
    all)
      UPD_STA=YES
      UPD_NTW=YES
      UPD_CRD=YES
      ;;
    crd)
      UPD_CRD=YES
      ;;
    sta)
      UPD_STA=YES
      ;;
    ntw)
      UPD_NTW=YES
      ;;
    *)
      echo "Invalid option for update! See help" >> $LOGFILE
      exit 1
      ;;
    esac
  done
fi
#
# CHECK THAT THE SAVE DIRECTORY EXISTS OR CREATE IT
#
if test -z $SAVE_DIR ; then
  echo "***ERROR! Need to specify save directory name" >> $LOGFILE
  exit 1
fi

if ! test -d $SAVE_DIR
then
  if ! mkdir -p ${SAVE_DIR}
  then
    echo "Failed to create save directory: $SAVE_DIR" >> $LOGFILE
    exit 1
  fi
else
  if test "${FORCE_REMOVE_PREV}" == "YES"
  then
    rm -rf ${SAVE_DIR}/*
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK & LINK (IF NEEDED) THE TABLE FILES
# //////////////////////////////////////////////////////////////////////////////

{
echo ""
echo "Linking required tables from ${TABLES}"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

# 
# CHECK THAT THE PCV FILE EXISTS AND LINK IT
#
if $( test -f ${TABLES}/pcv/${PCV}.${CLBR} ) && 
  $( /bin/ln -sf ${TABLES}/pcv/${PCV}.${CLBR} ${X}/GEN/${PCV}.${CLBR} )
then 
  echo "Linked  ${TABLES}/pcv/${PCV}.${CLBR} to ${X}/GEN/${PCV}.${CLBR}" \
      | tee -a $LOGFILE $SOLSUMASC >/dev/null
else 
  echo "*** Failed to link pcv file ${TABLES}/pcv/${PCV}.${CLBR} " >>$LOGFILE
  exit 1
fi

# 
# LINK THE .STA FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/sta/${CAMPAIGN}52.STA ) && \
   $( /bin/ln -sf ${TABLES}/sta/${CAMPAIGN}52.STA ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.STA )
then 
    echo "Linked ${TABLES}/sta/${CAMPAIGN}52.STA to ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.STA" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
else 
    echo "*** Failed to link sta file ${TABLES}/sta/${CAMPAIGN}52.STA" >> $LOGFILE
    exit 1
fi

# 
# LINK THE .BLQ FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/blq/${CAMPAIGN}.BLQ ) && \
   $( /bin/ln -sf ${TABLES}/blq/${CAMPAIGN}.BLQ ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.BLQ )
then 
    echo "Linked ${TABLES}/blq/${CAMPAIGN}.BLQ to ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.BLQ" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
else 
    echo "*** Failed to link blq file ${TABLES}/blq/${CAMPAIGN}.BLQ" >> $LOGFILE
    exit 1
fi

# 
# LINK THE .ATL FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/atl/${CAMPAIGN}.ATL ) && \
   $( /bin/ln -sf ${TABLES}/atl/${CAMPAIGN}.ATL ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.ATL ); then 
  echo "Linked ${TABLES}/atl/${CAMPAIGN}.ATL to ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.ATL" \
      | tee -a $LOGFILE $SOLSUMASC >/dev/null
else 
  echo "*** Failed to link atl file ${TABLES}/atl/${CAMPAIGN}.ATL" >> $LOGFILE
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# TRANSFORM DATE IN VARIOUS FORMATS
# //////////////////////////////////////////////////////////////////////////////
DATES_STR=`python -c "import bpepy.gpstime, sys
gpsweek,dow = bpepy.gpstime.yd2gpsweek ($YEAR,'"$DOY"')
if gpsweek == -999 : sys.exit (1)
month,dom = bpepy.gpstime.yd2month ($YEAR,'"$DOY"')
if month == -999 : sys.exit (1)
print '%04i %1i %02i %02i' %(gpsweek,dow,month,dom)
sys.exit (0);" 2>${LOGFILE}`

## check for error
if test $? -ne 0 ; then
  echo "***ERROR! Failed to resolve the date (got $DATES_STR)" >> $LOGFILE
  exit 1
fi

GPSW=`echo $DATES_STR | awk '{print $1}'`;
DOW=`echo $DATES_STR | awk '{print $2}'`;
MONTH=`echo $DATES_STR | awk '{print $3}'`;
DOM=`echo $DATES_STR | awk '{print $4}'`;

# //////////////////////////////////////////////////////////////////////////////
# LINK REQUIRED PRODUCTS FROM DATAPOOL AREA
#
# NOTE: the names of the linked files should be capitalize for convinience
#       when this is possible
# NOTE: allong with the products themselves, specify the .meta files which
#       hold the product information
# NOTE: if we preocess the ultra-rapid solution, then first try for matching
#       rapid products; if no such exist, try for ultra-rapid
# //////////////////////////////////////////////////////////////////////////////
ORB_META=
ERP_META=
ION_META=
DCB_META=

# WHERE IS DATAPOOL
DATAPOOL=${D}

{
echo ""
echo "Linking required products from ${DATAPOOL} to campaign area"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

#
# ORBITS
# ------------------------------------------------------------------------------
sp3=`/bin/grep --ignore-case "| ${AC} | ${SOL_TYPE}    | ${SAT_SYS} " <<EOF | awk '{print $8}'
 +---- +------+-------+-----------------------+
 | AC  | TYPE | GNSS  | FILE (as in datapool) |
 +---- +------+-------+-----------------------+
 | igs | f    | gps   | igswwwwd.sp3          |
 | igs | r    | gps   | igrwwwwd.sp3          |
 | igs | u    | gps   | iguwwwwd.sp3          |
 | igs | f    | mixed | igswwwwd.sp3          |
 | igs | r    | mixed | -                     |
 | igs | u    | mixed | igvwwwwd.sp3          |
 +---- +------+-------+-----------------------|
 | cod | f    | mixed | codwwwwd.sp3          |
 | cod | r    | mixed | corwwwwd.sp3          |
 | cod | u    | mixed | couwwwwd.sp3          |
 | cod | f    | gps   | codwwwwd.sp3          |
 | cod | r    | gps   | corwwwwd.sp3          |
 | cod | u    | gps   | couwwwwd.sp3          |
 +---- +------+-------+-----------------------+
EOF`
if test ${#sp3} -ne 12  ; then
  echo "*** Failed to resolve sp3 file" >> $LOGFILE
  exit 1
fi

SP3=${sp3/wwwwd/${GPSW}${DOW}}
TRG_SP3=${SP3/.sp3/.PRE}
TRG_SP3=${TRG_SP3/${TRG_SP3:0:3}/${AC^^}}
if test "$SOL_TYPE" == "u"
then
  SP3=${SP3/U/R}
  SP3=${SP3/u/r}
fi

if $( test -f ${DATAPOOL}/${SP3} ) && \
   $( /bin/ln -sf ${DATAPOOL}/${SP3} ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^} )
then
  ORB_META=${DATAPOOL}/${SP3}.meta
  echo "Linked orbit file ${DATAPOOL}/${SP3} to ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^}" | tee -a $LOGFILE $SOLSUMASC >/dev/null
  echo "Meta-file : $ORB_META" >> $LOGFILE
else 
  # failed to find/link rapid sp3; try for ultra-rapid
  echo "Failed to find/link sp3 file ${DATAPOOL}/${SP3}" >> $LOGFILE
  if test "$SOL_TYPE" == "u"
  then
    SP3=${SP3/R/U}
    SP3=${SP3/r/u}
    if $( test -f ${DATAPOOL}/${SP3} ) && \
      $( /bin/ln -sf ${DATAPOOL}/${SP3} ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^} )
    then
      ORB_META=${DATAPOOL}/${SP3}.meta
      echo "Linked orbit file ${DATAPOOL}/${SP3} to ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^}" | tee -a $LOGFILE $SOLSUMASC >/dev/null
      echo "Meta-file : $ORB_META" >> $LOGFILE
    else
      echo "*** Failed to link sp3 file ${DATAPOOL}/${SP3}" >> $LOGFILE
      exit 1
    fi
  else
    exit 1
  fi
fi

#
# EARTH ROTATION PARAMETERS
#
# Note that if the AC is NOT cod, then the extension needs to be .IEP
# ------------------------------------------------------------------------------

erp=`/bin/grep --ignore-case "| ${AC} | ${SOL_TYPE}    |" <<EOF | awk '{print $7}'
 +---- +------+-------+-----------------------+
 | AC  | TYPE | GNSS  | FILE (as in datapool) |
 +---- +------+-------+-----------------------+
 | igs | f    |       | igswwwwd.erp          |
 | igs | r    |       | igrwwwwd.erp          |
 | igs | u    |       | iguwwwwd.erp          |
 +---- +------+-------+-----------------------|
 | cod | f    |       | CODwwwwd.ERP          |
 | cod | r    |       | CORwwwwd.ERP          |
 | cod | u    |       | COUwwwwd.ERP          |
 +---- +------+-------+-----------------------+
EOF`

if test ${#erp} -ne 12 ; then
  echo "*** Failed to resolve erp file" >> $LOGFILE
  exit 1
fi

ERP=${erp/wwwwd/${GPSW}${DOW}}
if test ${AC^^} != "COD" ; then
  TRG_ERP=${ERP/.erp/.IEP}
else
  TRG_ERP=${ERP}
fi
TRG_ERP=${TRG_ERP/${TRG_ERP:0:3}/${AC^^}}
if test "$SOL_TYPE" == "u"
then
  ERP=${ERP/U/R}
  ERP=${ERP/u/r}
fi

if $( test -f ${DATAPOOL}/${ERP} ) && \
   $( /bin/ln -sf ${DATAPOOL}/${ERP} ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^} ); then 
  ERP_META=${DATAPOOL}/${ERP}.meta
  echo "Linked erp file ${DATAPOOL}/${ERP} to ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^}" \
      | tee -a $LOGFILE $SOLSUMASC >/dev/null
  echo "Meta-File $ERP_META" >> $LOGFILE
else
  echo "Failed to link erp ${DATAPOOL}/${ERP}" >> $LOGFILE
  if test "$SOL_TYPE" == "u"
  then
    ERP=${ERP/R/U}
    ERP=${ERP/r/u}
    if $( test -f ${DATAPOOL}/${ERP} ) && \
      $( /bin/ln -sf ${DATAPOOL}/${ERP} ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^} ) 
    then
      ERP_META=${DATAPOOL}/${ERP}.meta
      echo "Linked erp file ${DATAPOOL}/${ERP} to ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^}" \
          | tee -a $LOGFILE $SOLSUMASC >/dev/null
      echo "Meta-File $ERP_META" >> $LOGFILE
    else
      echo "*** Failed to link erp file ${DATAPOOL}/${ERP}" >> $LOGFILE
      exit 1
    fi
  else
    exit 1
  fi
fi

##  Depending on the AC, set the INP file POLUPD.INP to fill in the right widget, using
##+ the script setpolupdh utility. But first, we have got to find out which directory
##+ in the ${U}/OPT area holds the INP file. Note that only one line containing the
##+ POLUPDH script is allowd in the PCF file.

LNS=`/bin/grep POLUPDH ${U}/PCF/${PCF_FILE}.PCF | /bin/grep -v "#" | wc -l`
if [ $LNS -ne 1 ]; then
  echo "Non-unique line for POLUPDH in the PCF file; Don't know what to do! " >> $LOGFILE
  exit 1
fi
PAN=`/bin/grep POLUPDH ${U}/PCF/${PCF_FILE}.PCF | /bin/grep -v "#" | awk '{print $3}'`
if ! /usr/local/bin/setpolupdh \
  --bernese-loadvar=${LOADVAR} \
  --analysis-center=${AC^^} \
  --pan=${PAN}
then
  exit 1
else
  echo "Setting right the POLUPD.INP for the AC." | tee -a $LOGFILE $SOLSUMASC >/dev/null
fi

#
# DIFFERENTIAL CODE BIAS
# ------------------------------------------------------------------------------
DCB=P1C1${YR2}${MONTH}.DCB
CUR_MONTH=`/bin/date '+%m'`
DCB_META=${DATAPOOL}/P1C1_RINEX.DCB.meta ## we'll see about that ...

if test "${MONTH}" == "${CUR_MONTH}"
then
    if ! /bin/ln -sf ${DATAPOOL}/P1C1_RINEX.DCB ${P}/${CAMPAIGN}/ORB/${DCB}
    then
        echo "*** Failed to transfer dcb file ${DATAPOOL}/P1C1_RINEX.DCB from datapool" \
            >> $LOGFILE
        exit 1
    else
        echo "Linked dcb file ${DATAPOOL}/P1C1_RINEX.DCB to ${P}/${CAMPAIGN}/ORB/${DCB}" \
            | tee -a $LOGFILE $SOLSUMASC >/dev/null
        echo "Meta-File $DCB_META" >> $LOGFILE
    fi
else
    if test -f ${DATAPOOL}/${DCB}
    then
        if ! /bin/ln -sf ${DATAPOOL}/${DCB} ${P}/${CAMPAIGN}/ORB/${DCB}
        then
            echo "*** Failed to transfer dcb file ${DATAPOOL}/${DCB}" >> $LOGFILE
            exit 1
        else
            DCB_META=${DATAPOOL}/${DCB}.meta
            echo "Linked dcb file ${DATAPOOL}/${DCB} to ${P}/${CAMPAIGN}/ORB/${DCB}" \
                | tee -a $LOGFILE $SOLSUMASC >/dev/null
            echo "Meta-File $DCB_META" >> $LOGFILE
        fi
    else
        if ! /bin/ln -sf ${DATAPOOL}/P1C1_RINEX.DCB ${P}/${CAMPAIGN}/ORB/${DCB}
        then
            echo "*** Failed to transfer dcb file ${DATAPOOL}/P1C1_RINEX.DCB from datapool" >> $LOGFILE
            exit 1
        else
            echo "Linked dcb file ${DATAPOOL}/P1C1_RINEX.DCB to ${P}/${CAMPAIGN}/ORB/${DCB}" \
                | tee -a $LOGFILE $SOLSUMASC >/dev/null
            echo "Meta-File $DCB_META" >> $LOGFILE
        fi
    fi
fi

#
# IONOSPHERIC CORRECTIONS
# ------------------------------------------------------------------------------

# TODO if the ionospheric file is copied from ntua's products, it doesn't have a meta file

##  Create a .meta file in the TMP directory. We will write info later on.
ION_META=${TMP}/ion.meta
>${ION_META}

## Ok. Let's search the product area for a suitable solution file
for i in $ION_PRODS_ID; do
  ion=${i}${YR2}${DOY}0.ION.Z

  if $( test -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${ion} ) && \
     $( cp -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${ion} ${P}/${CAMPAIGN}/ATM/ )
  then 
    /bin/uncompress -f ${P}/${CAMPAIGN}/ION/${ion}
    echo "(ddprocess) Ionospheric correction file (ion) : \
      ${PRODUCT_AREA}/${YEAR}/${DOY}/${ion} from AC: ntua" >> ${ION_META}
    break
    echo "Copying ion file ${PRODUCT_AREA}/${YEAR}/${DOY}/${ion} to ${P}/${CAMPAIGN}/ATM/" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
    echo "Meta-File ${ION_META}" >> $LOGFILE
  else 
    ion=
  fi
done

##  did we download it already ?
if test -z $ion ; then
  if /usr/local/bin/wgetion \
    --output-directory=${P}/${CAMPAIGN}/ATM \
    --force-remove \
    --standard-names \
    --decompress \
    --year=${YEAR} \
    --doy=${DOY} \
    --xml-output \
    &>> $LOGFILE
  then
    ##  if this in not a final solution, then the downloaded ion file will be
    ##+ named as e.g. COUWWWD.ION ; need to replace the right analysis center
    ##+ i.e. 'COD' instead of 'COU' or 'COR'
    for i in D R U
    do
      if test -f ${P}/${CAMPAIGN}/ATM/CO${i}${GPSW}${DOW}.ION
      then
        ion=${P}/${CAMPAIGN}/ATM/CO${i}${GPSW}${DOW}.ION
        break
      fi
    done
    # ion=${P}/${CAMPAIGN}/ATM/COD${GPSW}${DOW}.ION
    if ! test -f ${ion}
    then
      echo "Error! Failed to download ion file $ion" >> $LOGFILE
      exit 1
    else
      ION_META=${ion}.meta
    fi
    if [ "$SOL_TYPE" == "u" ]
    then
      mv $ion ${ion/COU/COD} 2>/dev/null
      mv $ion ${ion/COR/COD} 2>/dev/null
    fi
    echo "Downloaded CODE's ION file $ion" | tee -a $LOGFILE $SOLSUMASC >/dev/null
    echo "Meta-File ${ION_META}" >> $LOGFILE
  else
    echo "*** Failed to download / locate ion file" >> $LOGFILE
    exit 1
  fi
fi
rm ${tmpd}/.tmp 2>/dev/null

#
# TROPOSPHERIC CORRECTIONS
# ------------------------------------------------------------------------------

#
# LINK THE VIENNA GRID FILE WHICH SHOULD BE AT THE DATAPOOL AREA
if $( test -f ${D}/VMFG_${YEAR}${DOY} ) && \
   $( /bin/ln -sf ${D}/VMFG_${YEAR}${DOY} ${P}/${CAMPAIGN}/GRD/VMF${YR2}${DOY}0.GRD )
then 
  echo "Linked VMF grid file ${D}/VMFG_${YEAR}${DOY} ${P}/${CAMPAIGN}/GRD/VMF${YR2}${DOY}0.GRD" \
      | tee -a $LOGFILE $SOLSUMASC >/dev/null
  echo "Meta-File ??" >> $LOGFILE
  TRO_META=${D}/VMFG_${YEAR}${DOY}.meta
else 
  echo "*** Failed to link VMF1 grid file ${D}/VMFG_${YEAR}${DOY}" >> $LOGFILE
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# TRANSFER THE RINEX FILES FROM DATAPOOL
# //////////////////////////////////////////////////////////////////////////////
{
echo ""
echo "Checking / Transfering Rinex files"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

##  Three arrays will be created/filled: the RINEX_AV including all available rinex files
##+ found in the datapool area; RINEX_MS listing all missing rinex files and finaly
##+ STATIONS listing all stations that should exist for this network. In addition,
##+ three lists are created: AVIGS, AVEPN and AVREG containing all sites available (i.e
##+ belonging to the RINEX_AV list) per network.

for i in igs epn reg; do
  file=${TABLES}/crd/${CAMPAIGN,,}.${i}
  if ! test -f ${file}
  then
      echo "*** Missing file $file" >> $LOGFILE
      exit 1
  fi
  STATIONS+=( $( /bin/cat "$file" ) )
done

for i in ${STATIONS[@]}
do
  rinex_file=${i}${DOY}0.${YR2}o
  if test -f ${DATAPOOL}/${rinex_file}
  then
    cp -f ${DATAPOOL}/${rinex_file} ${P}/${CAMPAIGN}/RAW/${rinex_file^^}
    RINEX_AV+=(${rinex_file})
    if /bin/egrep -i "${i}" ${TABLES}/crd/${CAMPAIGN,,}.igs &>/dev/null; then AVIGS+=($i); fi
    if /bin/egrep -i "${i}" ${TABLES}/crd/${CAMPAIGN,,}.epn &>/dev/null; then AVEPN+=($i); fi
    if /bin/egrep -i "${i}" ${TABLES}/crd/${CAMPAIGN,,}.reg &>/dev/null; then AVREG+=($i); fi
  else
    if test -f ${DATAPOOL}/${rinex_file^^}
    then
        cp -f ${DATAPOOL}/${rinex_file^^} ${P}/${CAMPAIGN}/RAW/${rinex_file^^}
        RINEX_AV+=(${rinex_file^^})
        if /bin/egrep -i "${i}" ${TABLES}/crd/${CAMPAIGN,,}.igs &>/dev/null; then AVIGS+=($i); fi
        if /bin/egrep -i "${i}" ${TABLES}/crd/${CAMPAIGN,,}.epn &>/dev/null; then AVEPN+=($i); fi
        if /bin/egrep -i "${i}" ${TABLES}/crd/${CAMPAIGN,,}.reg &>/dev/null; then AVREG+=($i); fi
      else
        RINEX_MS+=(${rinex_file})
      fi
  fi
done

if test ${#AVIGS[@]} -lt 4; then
  echo "*** Too few igs stations to process! Only found ${#AVIGS[@]} rinex" >> $LOGFILE
  exit 1
fi

if test ${#AVREG[@]} -lt 1; then
  echo "*** Too few regional stations to process! Only found ${#AVREG[@]} rinex" \
      >> $LOGFILE
  exit 1
fi
{
echo "Transfered Rinex files: "
echo "igs -> ${#AVIGS[@]}"
echo "epn -> ${#AVEPN[@]}"
echo "reg -> ${#AVREG[@]}"
echo "missing : ${#RINEX_MS[@]}"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT ALL STATIONS (TO BE PROCESSED) ARE IN THE BLQ FILE
# //////////////////////////////////////////////////////////////////////////////
for i in ${RINEX_AV[@]}
do
  sta_name=`echo ${i:0:4} | tr 'a-z' 'A-Z'`
  if ! /bin/egrep "^  ${sta_name} *" ${TABLES}/blq/${CAMPAIGN}.BLQ &>/dev/null
  then
    echo "Warning -- station ${sta_name} missing ocean loading corrections; \
      file ${TABLES}/blq/${CAMPAIGN}.BLQ" >> $WARFILE
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT ALL STATIONS (TO BE PROCESSED) ARE IN THE ATL FILE
# //////////////////////////////////////////////////////////////////////////////
for i in ${RINEX_AV[@]}
do
  sta_name=`echo ${i:0:4} | tr 'a-z' 'A-Z'`
  if ! /bin/egrep "^  ${sta_name} *" ${TABLES}/atl/${CAMPAIGN}.ATL &>/dev/null
  then
    echo "Warning -- station ${sta_name} missing atmospheric loading corrections; \
      file ${TABLES}/atl/${CAMPAIGN}.ATL" >> $WARFILE
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# CREATE THE CLUSTER FILE
# //////////////////////////////////////////////////////////////////////////////

{
echo ""
echo "Creating a cluster file"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

##  dump all available rinex files (station names) on a temporary file;
##+ then use the makecluster program to create a cluster file
>${tmpd}/.tmp
for i in "${RINEX_AV[@]}"
do 
    echo ${i:0:4} >> ${tmpd}/.tmp
done

/usr/local/bin/makecluster \
  --abbreviation-file=${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.ABB \
  --stations-per-cluster=${STA_PER_CLU} \
  --station-file=${tmpd}/.tmp \
  1>${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.CLU \
  2>>$LOGFILE
if test $? -ne 0 ; then
  echo "Failed to create the cluster file" >> $LOGFILE
  exit 1
else
    {
    echo "Cluster file created as ${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.CLU"
    echo "Baselines per Cluster : ${STA_PER_CLU}"
    } | tee -a $LOGFILE $SOLSUMASC >/dev/null
fi
rm ${tmpd}/.tmp

# //////////////////////////////////////////////////////////////////////////////
# CHOOSE A-PRIORI COORDINATES FILE FOR REGIONAL AND EPN STATIONS
# //////////////////////////////////////////////////////////////////////////////

##  Try for an already processed coordinate file (of same date). Check to see
##+ if such a file exists in the product area, using the identifiers for the
##+ final, preliminary and reduced solution (i.e. search for the files
##+ [${SOL_ID}|${SOL_ID%?}P|${SOL_ID%?}R]YYDDD0.CRD.Z). If any of these files
##+ exist, copy it at the cmapaign directory and CHECK that all stations to
##+ be processed are listed.
##+ If an already-processed crd file could not be found, or the ones found are
##+ missing some stations (to be procesed), then copy the default file (i.e.
##+ ${TABLES}/crd/${CAMPAIGN}.CRD
##+ At the end, we should have a file named REGYYDDD0.CRD listing coordinates
##+ for all stations to be processed.

{
echo ""
echo "Choosing apropriate a-priori crd fle"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

>${tmpd}/crd.meta

for i in ${SOL_ID} ${SOL_ID%?}P ${SOL_ID%?}R; do
  TMP=${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z
  printf "\nChecking $TMP ..." >> $LOGFILE
  if test -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z
  then
    cp ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z ${P}/${CAMPAIGN}/STA/APRIORI.CRD.Z
    /bin/uncompress -f ${P}/${CAMPAIGN}/STA/APRIORI.CRD.Z
    for j in ${RINEX_AV[@]}; do
      j=${j:0:4}
      if ! /bin/egrep " ${j^^} " ${P}/${CAMPAIGN}/STA/APRIORI.CRD &>/dev/null
      then
        rm ${P}/${CAMPAIGN}/STA/APRIORI.CRD
        TMP=
        printf "station $j missing; file skipped" >> $LOGFILE
        break
      fi
    done
    if ! test -z "$TMP"
    then
        echo   "<para>Chose a-priori coordinate file <filename>${TMP}</filename>.</para>" >> ${tmpd}/crd.meta
        echo   "File ${TMP} seems to fit; chossing this as a-priori" >> $SOLSUMASC
        printf "ok! using as a-priori" >> $LOGFILE
        break
    fi
  else
    printf "not available !" >> $LOGFILE
  fi
done

if ! test -f ${P}/${CAMPAIGN}/STA/APRIORI.CRD
then
  TMP=${TABLES}/crd/${CAMPAIGN}.CRD
  if ! cp ${TABLES}/crd/${CAMPAIGN}.CRD ${P}/${CAMPAIGN}/STA/APRIORI.CRD
  then
    echo "*** Failed to copy a-priori coordinate file ${TABLES}/crd/${CAMPAIGN}.CRD" >> $LOGFILE
    TMP=
    exit 1
  else
    echo "Copying default crd file ${TABLES}/crd/${CAMPAIGN}.CRD to ${P}/${CAMPAIGN}/STA/APRIORI.CRD" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
    echo "<para>Chose default a-priori coordinate for the network, i.e. <filename>${TMP}</filename>.</para>" >> ${tmpd}/crd.meta
  fi
fi

mv ${P}/${CAMPAIGN}/STA/APRIORI.CRD ${P}/${CAMPAIGN}/STA/REG${YR2}${DOY}0.CRD
echo "<para>File renamed to <filename>${P}/${CAMPAIGN}/STA/REG${YR2}${DOY}0.CRD$</filename>.</para>" >> ${tmpd}/crd.meta

# //////////////////////////////////////////////////////////////////////////////
# SET OPTIONS IN THE PCF FILE
# //////////////////////////////////////////////////////////////////////////////

# Strip the pcf files from path and extension (no need)
# TMP_PCF=${PCF_FILE##*/}
# TMP_PCF=${TMP_PCF%%.*}

{
echo ""
echo "Setting Options in the PCF file"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

if ! /usr/local/bin/setpcf \
  --analysis-center=${AC^^} \
  --bernese-loadvar=${LOADVAR} \
  --campaign=${CAMPAIGN} \
  --solution-id=${SOL_ID} \
  --pcf-file=${PCF_FILE} \
  --pcv-file=${PCV} \
  --satellite-system=${SAT_SYS,,} \
  --elevation-angle=${ELEV} \
  --blq=${CAMPAIGN^^} \
  --atl=${CAMPAIGN^^} \
  --calibration-model=${CLBR}
then
  echo "*** Failed to set variables in the PCF file" >> $LOGFILE
  exit 1
else
    {
    echo "Options set a pcf file:"
    echo "Analysis Center   = ${AC^^} "
    echo "Bernese Loadvar   = ${LOADVAR}"
    echo "Campaign Name     = ${CAMPAIGN}"
    echo "Solution Id       = ${SOL_ID}"
    echo "PCF file          = ${PCF_FILE}"
    echo "PCV file          = ${PCV}"
    echo "Satellite System  = ${SAT_SYS,,}"
    echo "Elevation Angle   = ${ELEV} (degrees)"
    echo "BLQ file          = ${CAMPAIGN^^}"
    echo "ATL file          = ${CAMPAIGN^^}"
    echo "Calibration Model = ${CLBR}"
    } | tee -a $LOGFILE $SOLSUMASC >/dev/null
fi

# //////////////////////////////////////////////////////////////////////////////
# SET OPTIONS IN THE PL FILE
# //////////////////////////////////////////////////////////////////////////////

{
echo ""
echo "Setting Options in the Perl script"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

##  The identifiers for the process are taken from the campaign name (first three
##+ characters) and pcf filename (3 more characters. These files will be used later 
##+ on, to check for any possible error in the process run.
SYSOUT=${CAMPAIGN:0:3}_${PCF_FILE:0:3}
SYSRUN=${CAMPAIGN:0:3}_${PCF_FILE:0:3}
TASKID=${CAMPAIGN:0:1}${PCF_FILE:0:1}

if ! /usr/local/bin/setpcl \
  --pcf-file=${PCF_FILE} \
  --campaign=${CAMPAIGN} \
  --pl-file=${PL_FILE%%.*} \
  --campaign=${CAMPAIGN^^} \
  --sys-out=${SYSOUT} \
  --sys-run=${SYSRUN} \
  --task-id=${TASKID} \
  --bernese-loadvar=${LOADVAR}
then
  echo "*** Failed to set variables in the PL file" >> $LOGFILE
  exit 1
else
    {
    echo "Options set in the perl script:"
    echo "PCF file       = ${PCF_FILE}"
    echo "Campaign       = ${CAMPAIGN}"
    echo "pl-file        = ${PL_FILE%%.*}"
    echo "Campaign       = ${CAMPAIGN^^}"
    echo "SYSOUT         = ${SYSOUT}"
    echo "SYSRUN         = ${SYSRUN}"
    echo "TASKID         = ${TASKID}"
    echo "Bernese Loadvar= ${LOADVAR}"
    } | tee -a $LOGFILE $SOLSUMASC >/dev/null
fi

# //////////////////////////////////////////////////////////////////////////////
# PROCESS THE DATA (AT LAST!)
# //////////////////////////////////////////////////////////////////////////////

## (skip processing)
## KOKO=A
## if test "$KOKO" == "LALA"
## then

{
echo ""
echo "Processing Data"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

## empty the BPE directory
rm ${P}/${CAMPAIGN^^}/BPE/* 2>/dev/null

START_BPE_SECONDS=$(date +"%s")
DTM_HHMMSS=`date +"%H:%M:%S"`
echo "Start at : $DTM_HHMMSS ($START_BPE_SECONDS sec)" \
    | tee -a $LOGFILE $SOLSUMASC >/dev/null

${U}/SCRIPT/${PL_FILE} ${YEAR} ${DOY}0 &>>$LOGFILE

STOP_BPE_SECONDS=$(date +"%s")
DTM_HHMMSS=`date +"%H:%M:%S"`
echo "Finished at : $DTM_HHMMSS ($STOP_BPE_SECONDS sec)" \
    | tee -a $LOGFILE $SOLSUMASC >/dev/null

##  Check for errors in the SYSOUT file and set the status
if /bin/grep ERROR ${P}/${CAMPAIGN^^}/BPE/${SYSOUT}.OUT ##&>/dev/null
then
    STATUS=ERROR
else
    STATUS=SUCCESS
fi
echo "STATUS : $STATUS" | tee -a $LOGFILE $SOLSUMASC >/dev/null

# //////////////////////////////////////////////////////////////////////////////
# CREATE A LOG MESSAGE FOR PROCESS ERROR
# //////////////////////////////////////////////////////////////////////////////
if test "${STATUS}" == "ERROR"
then

  echo "***********************************************************************" >> $LOGFILE
  echo "-------------------- PROCESS ERROR ------------------------------------" >> $LOGFILE
  echo "***********************************************************************" >> $LOGFILE

  ##  get the Session and PID_SUB of last program written in the SYSOUT file
  ##+ this info is extracted from the line:
  ##+ CPU name  # of jobs    Total  Mean   Max   Min  Total   Max  Session  PID_SUB
  ##+ -----------------------------------------------------------------------------
  ##+ localhost          3       16     5    15     0      0     0   150010  201_000
  FL=`/bin/grep localhost ${P}/${CAMPAIGN^^}/BPE/${SYSOUT}.OUT | \
    /usr/bin/awk '{print $9"_"$10".LOG"}' 2>/dev/null`

  ## now right whatever message is in this file to the LOGFILE
  cat ${P}/${CAMPAIGN^^}/BPE/${TASKID}${FL} >> $LOGFILE
  echo "***********************************************************************" >> $LOGFILE

  for i in `ls ${P}/${CAMPAIGN^^}/BPE/${TASKID}${YR2}${DOY}0*.LOG`
  do
    cat $i >> $LOGFILE
    echo "PROCESS ERROR. SEE LOG FILE $LOGFILE" >> $SOLSUMASC
  done
  exit 1
fi
## (skip processing)
## fi
# //////////////////////////////////////////////////////////////////////////////
# SAVE THE FILES WE WANT
# //////////////////////////////////////////////////////////////////////////////

{
echo ""
echo "Saving Products/Results"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

>${tmpd}/saved.files
for i in ATM/${SOL_ID}${YR2}${DOY}0.TRO \
         ATM/${SOL_ID}${YR2}${DOY}0.TRP \
         OUT/AMB${YR2}${DOY}0.SUM \
         OUT/${SOL_ID}${YR2}${DOY}0.OUT \
         STA/${SOL_ID}${YR2}${DOY}0.CRD \
         SOL/${SOL_ID}${YR2}${DOY}0.NQ0 \
         SOL/${SOL_ID}${YR2}${DOY}0.SNX \
         SOL/${SOL_ID%?}P${YR2}${DOY}0.NQ0 \
         SOL/${SOL_ID%?}R${YR2}${DOY}0.NQ0 ; do
  if ! test -f ${P}/${CAMPAIGN}/${i}
  then
    echo "ERROR! Failed to locate file ${P}/${CAMPAIGN^^}/${i}" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
    exit 1
  else
    sfn=${i##*/}
    if test "${sfn}" == "AMB${YR2}${DOY}0.SUM"
    then
      sfn=${SOL_ID}${YR2}${DOY}0${SUFFIX}.SUM
    else
        EXTNS="${sfn##*.}"
        BSNM="${sfn%%.*}"
        sfn=${BSNM}${SUFFIX}.${EXTNS}
    fi
    cp ${P}/${CAMPAIGN}/${i} ${SAVE_DIR}/${sfn}
    echo "Copying ${P}/${CAMPAIGN}/${i} to ${SAVE_DIR}/${sfn}.Z" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
    compress -f ${SAVE_DIR}/${sfn}
  echo "<listitem><para>Saved file <filename>${i}</filename> to <filename>${SAVE_DIR}/${sfn}.Z</filename></para></listitem>" >> ${tmpd}/saved.files
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# UPDATE STATION TIME-SERIES
# //////////////////////////////////////////////////////////////////////////////
{
echo ""
echo "Updating Station Time-Series Files"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

>${tmpd}/ts.update
if test "${UPD_STA}" == "YES"
then
  if test "${SOL_TYPE}" == "u"
  then
    SET_U="--ultra-rapid"
    echo "Updating Ultra-Rapid time-series files" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
  else
    SET_U=
    echo "Updating Final time-series files" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
  fi
  /usr/local/bin/extractStations \
    --station-file ${TABLES}/crd/${CAMPAIGN,,}.update \
    --solution-summary ${P}/${CAMPAIGN^^}/OUT/${SOL_ID}${YR2}${DOY}0.OUT \
    --save-dir ${STA_TS_DIR} \
    --quiet \
    ${SET_U} 1>${tmpd}/xs.diffs 2>>${LOGFILE}
 TS_UPDATED=$?
 if test ${TS_UPDATED} -gt 250
 then
   echo "Script extractStations seems to have failed! Exit status: ${TS_UPDATED}" \
       | tee -a $LOGFILE $SOLSUMASC >/dev/null
   echo "Status = $TS_UPDATED" | tee -a $LOGFILE $SOLSUMASC >/dev/null
   exit 1
 fi
 echo "Updated ${TS_UPDATED} time-series files" | tee -a $LOGFILE $SOLSUMASC >/dev/null
 cat ${tmpd}/xs.diffs | sed '$ d' | sort -k1 | \
     awk '{printf "%03i %4s %10s %10s %10s %10s %10s %10s\n",a++,tolower($1),$2,$4,$5,$6,$7,$8}' \
     >> $SOLSUMASC
 echo "<program>extractStations</program> successefuly updated records for ${TS_UPDATED} time-series files" >> ${tmpd}/ts.update
 ## check to see if the updated stations match the sum of available reg + epn stations
 tmp_nreg=${#AVREG[@]}
 tmp_nepn=${#AVEPN[@]}
 let should=tmp_nreg+tmp_nepn
 if test ${should} != ${TS_UPDATED}
 then
   echo "<warning><para>Updated station time-series do not add up to the sum of available EPN and REGIONAL stations.</para></warning>" >> ${tmpd}/ts.update
   echo "WARNING !! Updated station time-series do not add up to the sum of available EPN and REGIONAL stations." \
       | tee -a $LOGFILE $SOLSUMASC >/dev/null
 fi
else ## User said no update !
  echo "<important><para>No time-series files were updated, no such command given! see <xref linkend='options' /></para></important>" >> ${tmpd}/ts.update
  echo "Nothing to do;" | tee -a $LOGFILE $SOLSUMASC >/dev/null
fi

# //////////////////////////////////////////////////////////////////////////////
# UPDATE DEFAULT CRD FILE
# //////////////////////////////////////////////////////////////////////////////$

{
echo ""
echo "Updating Default Coordinate File"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

>${tmpd}/crd.update
##
## TODO :: Should updatecrd use the '--limit' option ?
##
if test "${UPD_CRD}" == "YES"
then
    if test "${CAMPAIGN,,}" == "uranus"
    then
        CMDS="/usr/local/bin/updatecrd"
    else
    ##  CMDS="/usr/local/bin/updatecrd --limit"
        CMDS="/usr/local/bin/updatecrd"
    fi
##  /usr/local/bin/updatecrd \
    ${CMDS} \
    --update-file=${TABLES}/crd/${CAMPAIGN}.CRD \
    --reference-file=${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
    --station-file=${TABLES}/crd/${CAMPAIGN,,}.update \
    --flags=W,A,P,C \
    &>>$LOGFILE
  if test $? -gt 250
  then
    echo "Error updating default crd file; see log" \
        | tee -a $LOGFILE $SOLSUMASC >/dev/null
    exit 1
  else
    {
    echo "Default crd file :${TABLES}/crd/${CAMPAIGN}.CRD updated"
    echo "Reference crd file : ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD"
    } | tee -a $LOGFILE $SOLSUMASC >/dev/null
    echo "<program>updatecrd</program> successefuly updated coordinate records regional sites." >> ${tmpd}/crd.update
    echo "Default file updated : <filename>${TABLES}/crd/${CAMPAIGN}.CRD</filename> using the reference file <filename>${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD</filename>" >> ${tmpd}/crd.update
  fi
else ## User said NO !!
  echo "<important><para>No coordinate files were updated, no such command given! see <xref linkend='options' /></para></important>" >> ${tmpd}/crd.update
  echo "Nothing to do." | tee -a $LOGFILE $SOLSUMASC >/dev/null
fi

# //////////////////////////////////////////////////////////////////////////////
# STOP TIMER
# //////////////////////////////////////////////////////////////////////////////
STOP_PROCESS_SECONDS=$(date +"%s")

# //////////////////////////////////////////////////////////////////////////////
# MAKE XML SUMMARY (DOCBOOK)
# //////////////////////////////////////////////////////////////////////////////

{
echo ""
echo "Compiling DocBook report"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

if test "$XML_OUT" == "YES"
then
##  We need to write all related variables to a file, which can the be
##+ sourced by following scripts.
V_TODAY=`date`
V_DATE_PROCCESSED=`echo "${YEAR}-${MONTH}-${DOM} (DOY: ${DOY})"`
V_NETWORK=${CAMPAIGN}
V_USER_N=`echo $USER`
V_HOST_N=`echo $HOSTNAME`
V_SYSTEM_INFO=`uname -a`
V_SCRIPT="${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
V_COMMAND=${XML_SENTENCE}
V_BERN_INFO=`cat /home/bpe2/bern52/info/bern52_release. | tail -1`
V_GEN_UPD=`cat /home/bpe2/bern52/info/bern52_GEN_upd. | tail -1`
V_ID="${SOL_ID} (preliminery: ${SOL_ID%?}P, size-reduced: ${SOL_ID%?}R)"
PCF_FILE=${PCF_FILE}
V_ELEVATION=${ELEV}
V_TROPO=VMF1
if test "${SOL_TYPE}" == "f"
then
    V_SOL_TYPE=FINAL
else
    V_SOL_TYPE="RAPID/ULTRA_RAPID"
fi
V_AC_CENTER=${AC^^}
V_SAT_SYS=${SAT_SYS}
V_STA_PER_CLU=${STA_PER_CLU}
V_UPDATE_CRD=${UPD_CRD}
V_UPDATE_STA=${UPD_STA}
V_UPDATE_NET=${UPD_NTW}
V_MAKE_PLOTS=${MAKE_PLOTS}
V_SAVE_DIR=${SAVE_DIR}
V_ATX=${TABLES}/pcv/${PCV}.${CLBR}
V_LOG=${LOGFILE}
V_YEAR=${YEAR}
V_DOY=${DOY}
AVAIL_RNX="${#RINEX_AV[@]}"
V_IGS_RNX="${#AVIGS[@]}"
V_EPN_RNX="${#AVEPN[@]}"
V_REG_RNX="${#AVREG[@]}"
V_RNX_MIS="${#RINEX_MS[@]}"
V_RNX_TOT="${#STATIONS[@]}"
CRD_META=${tmpd}/crd.meta
SCRIPT_SECONDS=$(($STOP_PROCESS_SECONDS-$START_PROCESS_SECONDS))
SCRIPT_SECONDS=`echo $SCRIPT_SECONDS | \
    awk '{printf "%10i seconds (or %5i min and %2i sec)",$1,$1/60.0,$1%60}'`
# BPE_SECONDS=$(($STOP_BPE_SECONDS-$START_BPE_SECONDS))
BPE_SECONDS=500
BPE_SECONDS=`echo $BPE_SECONDS | \
    awk '{printf "%10i seconds (or %5i min and %2i sec)",$1,$1/60.0,$1%60}'`
{
echo "CRD_META=${CRD_META}"
echo "tmpd=${tmpd}"
echo "XML_TEMPLATES=${XML_TEMPLATES}"
echo "V_DOY=${V_DOY}"
echo "V_TROPO=${V_TROPO}"
echo "V_TODAY=${V_TODAY}"
echo "V_DATE_PROCCESSED=${V_DATE_PROCCESSED}"
echo "V_NETWORK=${V_NETWORK}"
echo "V_USER_N=${V_USER_N}"
echo "V_HOST_N=${V_HOST_N}"
echo "V_SYSTEM_INFO=${V_SYSTEM_INFO}"
echo "V_COMMAND=${V_COMMAND}"
echo "V_SCRIPT=${V_SCRIPT}"
echo "V_BERN_INFO=${V_BERN_INFO}"
echo "V_GEN_UPD=${V_GEN_UPD}"
echo "V_ID=${V_ID}"
echo "PCF_FILE=${PCF_FILE}"
echo "V_ELEVATION=${V_ELEVATION}"
echo "V_SOL_TYPE=${V_SOL_TYPE}"
echo "V_AC_CENTER=${V_AC_CENTER}"
echo "V_SAT_SYS=${V_SAT_SYS}"
echo "V_STA_PER_CLU=${V_STA_PER_CLU}"
echo "V_UPDATE_CRD=${V_UPDATE_CRD}"
echo "V_UPDATE_STA=${V_UPDATE_STA}"
echo "V_UPDATE_NET=${V_UPDATE_NET}"
echo "V_MAKE_PLOTS=${V_MAKE_PLOTS}"
echo "V_SAVE_DIR=${V_SAVE_DIR}"
echo "V_ATX=${V_ATX}"
echo "V_LOG=${V_LOG}"
echo "V_YEAR=${V_YEAR}"
echo "AVAIL_RNX=${AVAIL_RNX}"
echo "V_IGS_RNX=${V_IGS_RNX}"
echo "V_EPN_RNX=${V_EPN_RNX}"
echo "V_REG_RNX=${V_REG_RNX}"
echo "V_RNX_MIS=${V_RNX_MIS}"
echo "V_RNX_TOT=${V_RNX_TOT}"
echo "ORB_META=${ORB_META}"
echo "ERP_META=${ERP_META}"
echo "ION_META=${ION_META}"
echo "TRO_META=${TRO_META}"
echo "DCB_META=${DCB_META}"
echo "SCRIPT_SECONDS=${SCRIPT_SECONDS}"
echo "BPE_SECONDS=${BPE_SECONDS}"
echo "V_MONTH=${MONTH}"
echo "V_DAY_OF_MONTH=${DOM}"
echo "V_SOL_ID=${SOL_ID}"
} >> ${tmpd}/variables

    ## Also, we need a file recording all stations
    >${tmpd}/all.stations
    for i in ${STATIONS[@]}
    do
      echo -ne "$i " >> ${tmpd}/all.stations
    done

    ## We need a file with available rinex
    >${tmpd}/rnx.av
    for i in "${RINEX_AV[@]}"
    do
      echo -ne "${i} " >> ${tmpd}/rnx.av
    done
    if ! /usr/local/bin/makedocbook ${tmpd}/variables &>>${LOGFILE}
    then
        echo "Failed to make docbook report"
    else
        echo "XML output (docbook) created"
    fi

else
    echo "No XML output specified."
fi

# //////////////////////////////////////////////////////////////////////////////
# CLEAR CAMPAIGN DIRECTORIES
# //////////////////////////////////////////////////////////////////////////////

{
echo ""
echo "Clearing Campaign Directories"
echo "-------------------------------------------------------------------------"
} | tee -a $LOGFILE $SOLSUMASC >/dev/null

FORCE_CLEAN=YES
if test "${FORCE_CLEAN}" == "YES"
then
for i in ATM \
         BPE \
         GRD \
         LOG \
         OBS \
         ORB \
         ORX \
         OUT \
         RAW \
         SOL ; do
    rm -rf ${P}/${CAMPAIGN}/${i}/*${YR2}${DOY}* 2>/dev/null
done

## Remove everything from OBS, OUT, RAW, BPE directory
for i in OBS OUT RAW BPE
do
    rm ${P}/${CAMPAIGN}/${i}/* 2>/dev/null
done
fi

DTM_HHMMSS=`date +"%H:%M:%S"`
{
echo "All done!"
echo "Finished at : $DTM_HHMMSS"
} | tee -a $LOGFILE $SOLSUMASC ## >/dev/null

exit 0

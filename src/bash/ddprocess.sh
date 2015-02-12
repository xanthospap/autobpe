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
  echo "           --debug set debugging mode"
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
XML_OUT=NO               ## xml output
XML_SENTENCE="<command>$NAME" ## the command issued as xml

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
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi
## Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  ## GNU enhanced getopt is available
  ARGS=`getopt -o hvc:b:a:i:p:s:e:y:d:l:t:f:m:u:r:x \
  -l  help,version,campaign:,bernese-loadvar:,analysis-center:,solution-id:,pcv-file:,satellite-system:,elevation-angle:,year:,doy:,stations-per-cluster:,solution-type:,ion-products:,debug,calibration-model:,update:,save-dir:,xml-output \
  -n 'ddprocess' -- "$@"`
else
  ## Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvc:b:a:i:p:s:e:y:d:l:t:f:m:u:r:x "$@"`
fi
## check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

## extract options and their arguments into variables.
while true ; do
  case "$1" in
    --debug)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      DEBUG=YES;;
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
    -e|elevation-angle)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      ELEV="${2}"; shift;;
    -s|satellite-system)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      SAT_SYS="${2}"; shift;;
    -m|--calibration-model)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      CLBR="${2}"; shift;;
    -p|pcv-file)
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
>$LOGFILE
>$WARFILE
echo "$*" >> $LOGFILE
START_T_STAMP=`/bin/date`
tmpd=${TMP}/${YEAR}${DOY}-ddprocess-${CAMPAIGN,,}
if test -d $tmpd
then
  rm -rf $tmpd/*
else
  mkdir ${tmpd}
fi
echo "Temporary directory : ${tmpd}"        >> $LOGFILE
echo "Log File            : ${LOGFILE}"     >> $LOGFILE
echo "Warnings            : ${WARFILE}"     >> $LOGFILE
echo "Process started at  : $START_T_STAMP" >> $LOGFILE

# //////////////////////////////////////////////////////////////////////////////
# CHECK REMAINING CMD; SOURCE LOADVAR
# //////////////////////////////////////////////////////////////////////////////

# 
# CHECK THAT LOADVAR FILE EXISTS AND SOURCE IT
#
if ! test -f $LOADVAR ; then
  echo "*** Variable file $LOADVAR does not exist"
  exit 1
fi
. $LOADVAR
if [ "$VERSION" != "52" ] ; then
  echo "***ERROR! Cannot load the source file: $LOADVAR"
  exit 1
fi

#
# CHECK THAT THE PCF FILE EXISTS
#
if ! test -f ${U}/PCF/${PCF_FILE}.PCF ; then
  echo "*** Cannot find pcf file: ${U}/PCF/${PCF_FILE}.PCF"
  exit 1
fi

#
# CHECK THAT THE CAMPAIGN EXISTS
#
if test -z $CAMPAIGN ; then
  echo "***ERROR! Need to specify campaign name"
  exit 1
fi
if ! test -d ${P}/${CAMPAIGN} ; then
  echo "***ERROR! Cannot locate campaign ${P}/${CAMPAIGN}"
  exit 1
fi

# 
# CHECK THAT THE ANALYSIS CENTER IS VALID
#
if [ ${AC^^} != "IGS" -a ${AC^^} != "COD" ]; then
  echo "*** Need to provide a valid analysis center"
  exit 1
fi

# 
# CHECK THE SATELLITE SYSTEM
#
if [ "${SAT_SYS^^}" != "GPS" -a "${SAT_SYS^^}" != "MIXED" ]; then
  echo "*** Invalid satellite system"
  exit 1
fi

# 
# CHECK THE ELEVATION ANGLE
# 
if [[ $ELEV =~ ^[0-9]+$ ]]; then
  if [ $ELEV -lt 3 -o $ELEV -gt 15 ]
  then
    echo "*** Elevation angle must be in the range [3-15]"
    exit 1
  fi
else
  echo "*** Invalid elevation angle"
  exit 1
fi

# 
# CHECK THE STATIONS PER CLUSTER
# 
if [[ $STA_PER_CLU =~ ^[0-9]+$ ]]; then
    :
else
   echo "*** Invalid stations per cluster"
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
  echo "*** Invalid solution type"
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
      echo "Invalid option for update! See help"
      exit 1
      ;;
    esac
  done
fi
#
# CHECK THAT THE SAVE DIRECTORY EXISTS OR CREATE IT
#
if test -z $SAVE_DIR ; then
  echo "***ERROR! Need to specify save directory name"
  exit 1
fi
if ! test -d $SAVE_DIR
then
  if ! mkdir -p ${SAVE_DIR}
  then
    echo "Failed to create save directory: $SAVE_DIR"
    exit 1
  fi
else
  :
  #rm -rf ${SAVE_DIR}/*
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK & LINK (IF NEEDED) THE TABLE FILES
# //////////////////////////////////////////////////////////////////////////////

echo "" >> $LOGFILE
echo "Linking required tables from ${TABLES}" >> $LOGFILE

# 
# CHECK THAT THE PCV FILE EXISTS AND LINK IT
#
if $( test -f ${TABLES}/pcv/${PCV}.${CLBR} ) && 
  $( /bin/ln -sf ${TABLES}/pcv/${PCV}.${CLBR} ${X}/GEN/${PCV}.${CLBR} ); then 
  echo "Linked  ${TABLES}/pcv/${PCV}.${CLBR} to ${X}/GEN/${PCV}.${CLBR}" >> $LOGFILE
else 
  echo "*** Failed to link pcv file ${TABLES}/pcv/${PCV}.${CLBR} "
  exit 1
fi

# 
# LINK THE .STA FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/sta/${CAMPAIGN}52.STA ) && \
   $( /bin/ln -sf ${TABLES}/sta/${CAMPAIGN}52.STA ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.STA ); then 
  echo "Linked ${TABLES}/sta/${CAMPAIGN}52.STA to \
    ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.STA" >> $LOGFILE
else 
  echo "*** Failed to link sta file ${TABLES}/sta/${CAMPAIGN}52.STA"
  exit 1
fi

# 
# LINK THE .BLQ FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/blq/${CAMPAIGN}.BLQ ) && \
   $( /bin/ln -sf ${TABLES}/blq/${CAMPAIGN}.BLQ ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.BLQ ); then 
  echo "Linked ${TABLES}/blq/${CAMPAIGN}.BLQ to \
    ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.BLQ" >> $LOGFILE
else 
  echo "*** Failed to link blq file ${TABLES}/blq/${CAMPAIGN}.BLQ"
  exit 1
fi

# 
# LINK THE .ATL FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/atl/${CAMPAIGN}.ATL ) && \
   $( /bin/ln -sf ${TABLES}/atl/${CAMPAIGN}.ATL ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.ATL ); then 
  echo "Linked ${TABLES}/atl/${CAMPAIGN}.ATL to \
    ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.ATL" >> $LOGFILE
else 
  echo "*** Failed to link atl file ${TABLES}/atl/${CAMPAIGN}.ATL"
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
  echo "***ERROR! Failed to resolve the date (got $DATES_STR)"
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

echo "" >> $LOGFILE
echo "Linking required products from ${DATAPOOL}" >> $LOGFILE

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
  echo "*** Failed to resolve sp3 file"
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
  echo "Linked orbit file ${DATAPOOL}/${SP3} to \
    ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^}" >> $LOGFILE
  echo "Meta-file : $ORB_META" >> $LOGFILE
else 
  # failed to find/link rapid sp3; try for ultra-rapid
  echo "Failed to find/link file ${DATAPOOL}/${SP3}"
  if test "$SOL_TYPE" == "u"
  then
    SP3=${SP3/R/U}
    SP3=${SP3/r/u}
    if $( test -f ${DATAPOOL}/${SP3} ) && \
      $( /bin/ln -sf ${DATAPOOL}/${SP3} ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^} )
    then
      ORB_META=${DATAPOOL}/${SP3}.meta
      echo "Linked orbit file ${DATAPOOL}/${SP3} to \
        ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^}" >> $LOGFILE$
      echo "Meta-file : $ORB_META" >> $LOGFILE
    else
      echo "*** Failed to link orbit file ${DATAPOOL}/${SP3}"
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
  echo "*** Failed to resolve erp file"
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
  echo "Linked erp file ${DATAPOOL}/${ERP} to \
    ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^}" >> $LOGFILE
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
      echo "Linked erp file ${DATAPOOL}/${ERP} to \
        ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^}" >> $LOGFILE
      echo "Meta-File $ERP_META" >> $LOGFILE
    else
      echo "*** Failed to link erp file ${DATAPOOL}/${ERP}"
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
  echo "Non-unique line for POLUPDH in the PCF file; Don't know what to do! "
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
  echo "Setting right the POLUPD.INP:" >> $LOGFILE
  echo "/usr/local/bin/setpolupdh \
    --bernese-loadvar=${LOADVAR} \
    --analysis-center=${AC^^} \
    --pan=${PAN}" >> $LOGFILE
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
		echo "*** Failed to transfer dcb file ${DATAPOOL}/P1C1_RINEX.DCB from datapool"
		exit 1
	else
        echo "Linked dcb file ${DATAPOOL}/P1C1_RINEX.DCB to ${P}/${CAMPAIGN}/ORB/${DCB}" >> $LOGFILE
        echo "Meta-File $DCB_META" >> $LOGFILE
	fi
else
	if test -f ${DATAPOOL}/${DCB}
	then
		if ! /bin/ln -sf ${DATAPOOL}/${DCB} ${P}/${CAMPAIGN}/ORB/${DCB}
		then
			echo "*** Failed to transfer dcb file ${DATAPOOL}/${DCB}"
			exit 1
		else
			DCB_META=${DATAPOOL}/${DCB}.meta
			echo "Linked dcb file ${DATAPOOL}/${DCB} to ${P}/${CAMPAIGN}/ORB/${DCB}" >> $LOGFILE
            echo "Meta-File $DCB_META" >> $LOGFILE
		fi
	else
		if ! /bin/ln -sf ${DATAPOOL}/P1C1_RINEX.DCB ${P}/${CAMPAIGN}/ORB/${DCB}
		then
			echo "*** Failed to transfer dcb file ${DATAPOOL}/P1C1_RINEX.DCB from datapool"
			exit 1
		else
            echo "Linked dcb file ${DATAPOOL}/P1C1_RINEX.DCB to ${P}/${CAMPAIGN}/ORB/${DCB}" >> $LOGFILE
            echo "Meta-File $DCB_META" >> $LOGFILE
		fi
	fi
fi

#
# IONOSPHERIC CORRECTIONS
# ------------------------------------------------------------------------------

# TODO if the ionospheric file is copied from ntua's products, it doesn't have a meta file
echo "" >> $LOGFILE
echo "Ionospheric Corrections" >> $LOGFILE

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
    echo "Copying ion file ${PRODUCT_AREA}/${YEAR}/${DOY}/${ion} \
      to ${P}/${CAMPAIGN}/ATM/" >> $LOGFILE
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
      echo "Error! Failed to download ion file $ion"
      exit 1
    else
      ION_META=${ion}.meta
    fi
    if [ "$SOL_TYPE" == "u" ]
    then
      mv $ion ${ion/COU/COD} 2>/dev/null
      mv $ion ${ion/COR/COD} 2>/dev/null
    fi
    echo "/usr/local/bin/wgetion \
      --output-directory=${P}/${CAMPAIGN}/ATM \
      --force-remove \
      --standard-names \
      --decompress \
      --year=${YEAR} \
      --doy=${DOY} \
      1>${tmpd}/.tmp 2>/dev/null" >> $LOGFILE
    echo "Downloaded CODE's ION file $ion" >> $LOGFILE
    echo "Meta-File ${ION_META}" >> $LOGFILE
  else
    echo "*** Failed to download / locate ion file"
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
  echo "Linked VMF grid file ${D}/VMFG_${YEAR}${DOY} \
    ${P}/${CAMPAIGN}/GRD/VMF${YR2}${DOY}0.GRD" >> $LOGFILE
  echo "Meta-File ??" >> $LOGFILE
  TRO_META=${D}/VMFG_${YEAR}${DOY}.meta
else 
  echo "*** Failed to link VMF1 grid file ${D}/VMFG_${YEAR}${DOY}"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# TRANSFER THE RINEX FILES FROM DATAPOOL
# //////////////////////////////////////////////////////////////////////////////

echo "" >> $LOGFILE
echo "Checking / transfering Rinex files" >> $LOGFILE

##  Three arrays will be created/filled: the RINEX_AV including all available rinex files
##+ found in the datapool area; RINEX_MS listing all missing rinex files and finaly
##+ STATIONS listing all stations that should exist for this network. In addition,
##+ three lists are created: AVIGS, AVEPN and AVREG containing all sites available (i.e
##+ belonging to the RINEX_AV list) per network.

for i in igs epn reg; do
  file=${TABLES}/crd/${CAMPAIGN,,}.${i}
  if ! test -f ${file}; then echo "*** Missing file $file"; exit 1; fi
  STATIONS+=( $( /bin/cat "$file" ) )
done

for i in ${STATIONS[@]}; do
  rinex_file=${i}${DOY}0.${YR2}o
  if test -f ${DATAPOOL}/${rinex_file}; then
    cp -f ${DATAPOOL}/${rinex_file} ${P}/${CAMPAIGN}/RAW/${rinex_file^^}
    RINEX_AV+=(${rinex_file})
    if /bin/egrep "${i}" ${TABLES}/crd/${CAMPAIGN,,}.igs &>/dev/null; then AVIGS+=($i); fi
    if /bin/egrep "${i}" ${TABLES}/crd/${CAMPAIGN,,}.epn &>/dev/null; then AVEPN+=($i); fi
    if /bin/egrep "${i}" ${TABLES}/crd/${CAMPAIGN,,}.reg &>/dev/null; then AVREG+=($i); fi
  else
    RINEX_MS+=(${rinex_file})
  fi
done

if test ${#AVIGS[@]} -lt 4; then
  echo "*** Too few igs stations to process! Only found ${#AVIGS[@]} rinex"
  exit 1
fi

if test ${#AVREG[@]} -lt 1; then
  echo "*** Too few regional stations to process! Only found ${#AVREG[@]} rinex"
  exit 1
fi

echo "Transfered Rinex files: "  >> $LOGFILE
echo "igs -> ${#AVIGS[@]}"       >> $LOGFILE
echo "epn -> ${#AVEPN[@]}"       >> $LOGFILE
echo "reg -> ${#AVREG[@]}"       >> $LOGFILE
echo "missing : ${#RINEX_MS[@]}" >> $LOGFILE

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT ALL STATIONS (TO BE PROCESSED) ARE IN THE BLQ FILE
# //////////////////////////////////////////////////////////////////////////////
for i in ${RINEX_AV[@]}; do
  sta_name=`echo ${i:0:4} | tr 'a-z' 'A-Z'`
  if ! /bin/egrep "^  ${sta_name} *" ${TABLES}/blq/${CAMPAIGN}.BLQ
  then
    echo "Warning -- station ${sta_name} missing ocean loading corrections; \
      file ${TABLES}/blq/${CAMPAIGN}.BLQ" >> $WARFILE
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT ALL STATIONS (TO BE PROCESSED) ARE IN THE ATL FILE
# //////////////////////////////////////////////////////////////////////////////
for i in ${RINEX_AV[@]}; do
  sta_name=`echo ${i:0:4} | tr 'a-z' 'A-Z'`
  if ! /bin/egrep "^  ${sta_name} *" ${TABLES}/atl/${CAMPAIGN}.ATL
  then
    echo "Warning -- station ${sta_name} missing atmospheric loading corrections; \
      file ${TABLES}/atl/${CAMPAIGN}.ATL" >> $WARFILE
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# CREATE THE CLUSTER FILE
# //////////////////////////////////////////////////////////////////////////////

##  dump all available rinex files (station names) on a temporary file;
##+ then use the makecluster program to create a cluster file
>${tmpd}/.tmp
for i in "${RINEX_AV[@]}"; do echo ${i:0:4} >> ${tmpd}/.tmp; done

/usr/local/bin/makecluster \
  --abbreviation-file=${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.ABB \
  --stations-per-cluster=${STA_PER_CLU} \
  --station-file=${tmpd}/.tmp \
  1>${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.CLU
if test $? -ne 0 ; then
  echo "Failed to create the cluster file"
  exit 1
else
  echo "" >> $LOGFILE
  echo "Cluster file created as ${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.CLU" >> $LOGFILE
  echo "/usr/local/bin/makecluster \
    --abbreviation-file=${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.ABB \
    --stations-per-cluster=${STA_PER_CLU} \
    --station-file=${tmpd}/.tmp \
    1>${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.CLU" >> $LOGFILE
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

echo "" >> $LOGFILE
echo "Choosing apropriate crd fle" >> $LOGFILE

for i in ${SOL_ID} ${SOL_ID%?}P ${SOL_ID%?}R; do
  TMP=${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z
  printf "\nChecking $TMP ..." >> $LOGFILE
  if test -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z ; then
    cp ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z ${P}/${CAMPAIGN}/STA/APRIORI.CRD.Z
    /bin/uncompress -f ${P}/${CAMPAIGN}/STA/APRIORI.CRD.Z
    for j in ${RINEX_AV[@]}; do
      j=${j:0:4}
      if ! /bin/egrep " ${j^^} " ${P}/${CAMPAIGN}/STA/APRIORI.CRD &>/dev/null; then
        rm ${P}/${CAMPAIGN}/STA/APRIORI.CRD
        TMP=
        printf "station $j missing; file skipped" >> $LOGFILE
        break
      fi
    done
    printf "ok! using a a-priori" >> $LOGFILE
  else
    printf "not available !" >> $LOGFILE
  fi
done

if ! test -f ${P}/${CAMPAIGN}/STA/APRIORI.CRD; then
  TMP=${TABLES}/crd/${CAMPAIGN}.CRD
  if ! cp ${TABLES}/crd/${CAMPAIGN}.CRD ${P}/${CAMPAIGN}/STA/APRIORI.CRD; then
    echo "*** Failed to copy a-priori coordinate file ${TABLES}/crd/${CAMPAIGN}.CRD"
    TMP=
    exit 1
  else
    echo "Copying default crd file ${TABLES}/crd/${CAMPAIGN}.CRD to \
      ${P}/${CAMPAIGN}/STA/APRIORI.CRD" >> $LOGFILE
  fi
fi

mv ${P}/${CAMPAIGN}/STA/APRIORI.CRD ${P}/${CAMPAIGN}/STA/REG${YR2}${DOY}0.CRD

# //////////////////////////////////////////////////////////////////////////////
# SET OPTIONS IN THE PCF FILE
# //////////////////////////////////////////////////////////////////////////////

# Strip the pcf files from path and extension (no need)
# TMP_PCF=${PCF_FILE##*/}
# TMP_PCF=${TMP_PCF%%.*}

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
  echo "*** Failed to set variables in the PCF file"
  exit 1
else
  echo "" >> $LOGFILE
  echo "Options set a pcf file:" >> $LOGFILE
  echo "/usr/local/bin/setpcf \
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
    --calibration-model=${CLBR}" >> $LOGFILE
fi

# //////////////////////////////////////////////////////////////////////////////
# SET OPTIONS IN THE PL FILE
# //////////////////////////////////////////////////////////////////////////////

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
  echo "*** Failed to set variables in the PL file"
  exit 1
else
  echo "" >> $LOGFILE
  echo "Options set in the perl script" >> $LOGFILE
  echo "/usr/local/bin/setpcl \
    --pcf-file=${PCF_FILE} \
    --campaign=${CAMPAIGN} \
    --pl-file=${PL_FILE%%.*} \
    --campaign=${CAMPAIGN^^} \
    --sys-out=${SYSOUT} \
    --sys-run=${SYSRUN} \
    --task-id=${TASKID} \
    --bernese-loadvar=${LOADVAR}" >> $LOGFILE
fi

# //////////////////////////////////////////////////////////////////////////////
# PROCESS THE DATA (AT LAST!)
# //////////////////////////////////////////////////////////////////////////////

## (skip processing)
KOKO=A
if test "$KOKO" == "LALA"
then

## empty the BPE directory
rm ${P}/${CAMPAIGN^^}/BPE/*

${U}/SCRIPT/${PL_FILE} ${YEAR} ${DOY}0 &>>$LOGFILE

##  Check for errors in the SYSOUT file and set the status
if /bin/grep ERROR ${P}/${CAMPAIGN^^}/BPE/${SYSOUT}.OUT ##&>/dev/null
then
	STATUS=ERROR
else
	STATUS=SUCCESS
fi

# //////////////////////////////////////////////////////////////////////////////
# CREATE A LOG MESSAGE FOR PROCESS ERROR
# //////////////////////////////////////////////////////////////////////////////
if test "${STATUS}" == "ERROR"; then

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
  done
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# SAVE THE FILES WE WANT
# //////////////////////////////////////////////////////////////////////////////
for i in ATM/${SOL_ID}${YR2}${DOY}0.TRO \
         ATM/${SOL_ID}${YR2}${DOY}0.TRP \
         OUT/AMB${YR2}${DOY}0.SUM \
         OUT/${SOL_ID}${YR2}${DOY}0.OUT \
         SOL/${SOL_ID}${YR2}${DOY}0.NQ0 \
         SOL/${SOL_ID}${YR2}${DOY}0.SNX \
         SOL/${SOL_ID%?}P${YR2}${DOY}0.NQ0 \
         SOL/${SOL_ID%?}R${YR2}${DOY}0.NQ0 ; do
  if ! test -f ${P}/${CAMPAIGN}/${i}
  then
    echo "ERROR! Failed to locate file ${P}/${CAMPAIGN^^}/${i}"
    exit 1
  else
    cp ${P}/${CAMPAIGN}/${i} ${SAVE_DIR}/${i#*/}
    compress -f ${SAVE_DIR}/${i#*/}
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# UPDATE STATION TIME-SERIES
# //////////////////////////////////////////////////////////////////////////////
if test "${UPD_STA}" == "YES"
then
  if test "${SOL_TYPE}" == "u"
  then
    SET_U="--ultra-rapid"
  else
    SET_U=
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
   echo "Script extractStations seems to have failed! Exit status: ${TS_UPDATED}"
   exit 1
 fi
 echo "(extractStations) Updated ${TS_UPDATED} time-series files" >> $LOGFILE
fi

# //////////////////////////////////////////////////////////////////////////////
# UPDATE DEFAULT CRD FILE
# //////////////////////////////////////////////////////////////////////////////$
if test "${UPD_CRD}" == "YES"
then
  /usr/local/bin/updatecrd \
    --update-file=${TABLES}/crd/${CAMPAIGN}.CRD \
    --reference-file=${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
    --station-file=${TABLES}/crd/${CAMPAIGN,,}.update \
    --flags=W,A,P,C \
    --limit \
    &>>$LOGFILE
  if test $? -gt 250
  then
    echo "Error updating default crd file; see log"
    exit 1
  else
    echo ""
    echo "Default crd file updated" >> $LOGFILE
    echo "  /usr/local/bin/updatecrd \
      --update-file=${TABLES}/crd/${CAMPAIGN}.CRD \
      --reference-file=${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
      --station-file=${TABLES}/crd/${CAMPAIGN,,}.update \
      --flags=W,A,P,C \
      --limit" >> $LOGFILE
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# CLEAR CAMPAIGN DIRECTORIES
# //////////////////////////////////////////////////////////////////////////////
#for i in ATM \
#         BPE \
#         GRD \
#         LOG \
#         OBS \
#         ORB \
#         ORX \
#         OUT \
#         RAW \
#         SOL ; do
#    rm -rf ${P}/${CAMPAIGN}/${i}/* 2>/dev/null
#done

# //////////////////////////////////////////////////////////////////////////////
#
# //////////////////////////////////////////////////////////////////////////////

# //////////////////////////////////////////////////////////////////////////////
# MAKE XML SUMMARY
# //////////////////////////////////////////////////////////////////////////////

## (skip processing)
fi
if test "${XML_OUT}" == "YES"
then
## TODO check that the script /usr/local/bin/plot-amb-sum is available
/usr/local/bin/plot-amb-sum ${P}/${CAMPAIGN^^}/OUT/AMB${YR2}${DOY}0.SUM ${tmpd}/${CAMPAIGN,,}${YEAR}${DOY}-amb.ps
echo "MAKING XML"
mkdir ${tmpd}/xml
#cp ${XML_TEMPLATES}/*.xml ${tmpd}/xml

V_TODAY=`date`
export V_TODAY
V_DATE_PROCCESSED=`echo "${YEAR}-${MONTH}-${DOM} (DOY: ${DOY})"`
export V_DATE_PROCCESSED
V_NETWORK=${CAMPAIGN}
export V_NETWORK
V_USER_N=`echo $USER`
export V_USER_N
V_HOST_N=`echo $HOSTNAME`
export V_HOST_N
V_SYSTEM_INFO=`uname -a`
export V_SYSTEM_INFO
V_SCRIPT="${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
export V_SCRIPT
V_COMMAND=${XML_SENTENCE}
export V_COMMAND
V_BERN_INFO=`cat /home/bpe2/bern52/info/bern52_release. | tail -1`
export V_BERN_INFO
V_GEN_UPD=`cat /home/bpe2/bern52/info/bern52_GEN_upd. | tail -1`
export V_GEN_UPD
V_ID="${SOL_ID} (preliminery: ${SOL_ID%?}P, size-reduced: ${SOL_ID%?}R)"
export V_ID
PCF_FILE=${PCF_FILE}
export PCF_FILE
V_ELEVATION=${ELEV}
export V_ELEVATION
V_TROPO=VMF1
export V_TROPO
if test "${SOL_TYPE}" == "f"
then
    V_SOL_TYPE=FINAL
else
    V_SOL_TYPE="RAPID/ULTRA_RAPID"
fi
export V_SOL_TYPE
V_AC_CENTER=${AC^^}
export V_AC_CENTER
V_SAT_SYS=${SAT_SYS}
export V_SAT_SYS
V_STA_PER_CLU=${STA_PER_CLU}
export V_STA_PER_CLU
V_UPDATE_CRD=${UPD_CRD}
export V_UPDATE_CRD
V_UPDATE_STA=${UPD_STA}
export V_UPDATE_STA
V_UPDATE_NET=${UPD_NTW}
export V_UPDATE_NET
V_MAKE_PLOTS=${MAKE_PLOTS}
export V_MAKE_PLOTS
V_SAVE_DIR=${SAVE_DIR}
export V_SAVE_DIR
V_ATX=${TABLES}/pcv/${PCV}.${CLBR}
export V_ATX
V_LOG=${LOGFILE}
export V_LOG
V_YEAR=${YEAR}
export V_YEAR
V_DOY=${DOY}
export V_DOY

AVAIL_RNX="${#RINEX_AV[@]}"
V_IGS_RNX="${#AVIGS[@]}"
V_EPN_RNX="${#AVEPN[@]}"
V_REG_RNX="${#AVREG[@]}"
V_RNX_MIS="${#RINEX_MS[@]}"
V_RNX_TOT="${#STATIONS[@]}"
export AVAIL_RNX
export V_IGS_RNX
export V_EPN_RNX
export V_REG_RNX
export V_RNX_MIS
export V_RNX_TOT

export ORB_META
export ERP_META
export ION_META
export TRO_META
export DCB_META
export tmpd
export XML_TEMPLATES

##  note that here we are interested in all stations NOT just the ones
##+ to be updated
>${tmpd}/xml/all.stations
for i in ${STATIONS[@]}
do
  echo -ne "$i " >> ${tmpd}/xml/all.stations
done
/usr/local/bin/extractStations \
    --station-file ${tmpd}/xml/all.stations \
    --solution-summary ${P}/${CAMPAIGN^^}/OUT/${SOL_ID}${YR2}${DOY}0.OUT \
    --save-dir ${STA_TS_DIR} \
    --quiet \
    --only-report \
    1>${tmpd}/xs.diffs

/usr/local/bin/ambsum2xml \
  ${P}/${CAMPAIGN}/OUT/AMB${YR2}${DOY}0.SUM \
  1>${tmpd}/amb.xml

>${tmpd}/rnx.av
for i in "${RINEX_AV[@]}"
do
  echo -ne "${i} " >> ${tmpd}/rnx.av
done
/usr/local/bin/rnxsum2xml \
  ${CAMPAIGN} \
  ${tmpd}/rnx.av \
   ${tmpd}/xs.diffs \
  ${YEAR} \
  ${DOY} \
  ${MONTH} \
  ${DOM} \
  ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD \
  1>/${tmpd}/rnx.xml

eval "echo \"$(< ${XML_TEMPLATES}/procsum-main.xml)\"" > ${tmpd}/xml/main.xml
eval "echo \"$(< ${XML_TEMPLATES}/procsum-info.xml)\"" > ${tmpd}/xml/info.xml
eval "echo \"$(< ${XML_TEMPLATES}/procsum-options.xml)\"" > ${tmpd}/xml/options.xml
echo "Creating options.xml"
/home/bpe2/src/autobpe/xml/src/makeoptionsxml.sh
echo "Creating rinex.xml"
/home/bpe2/src/autobpe/xml/src/makerinexxml.sh
echo "Creating ambiguities.xml"
/home/bpe2/src/autobpe/xml/src/makeambxml.sh
echo "Creating mauprp.xml"
/home/bpe2/src/autobpe/xml/src/mauprpxml.sh ${P}/${CAMPAIGN^^}/OUT/MPR${YR2}${DOY}0.SUM
echo "Creating crddifs.xml"
/home/bpe2/src/autobpe/xml/src/crddifs.sh ${tmpd}/xs.diffs ${P}/${CAMPAIGN}/STA/${SOL_ID}${YR2}${DOY}0.CRD
echo "Creating chksum.xml"
/home/bpe2/src/autobpe/xml/src/chksumxml.sh ${P}/${CAMPAIGN^^}/OUT/CHK${YR2}${DOY}0.OUT
mkdir ${tmpd}/xml/html
cd ${tmpd}/xml/ && xmlto --skip-validation -o html html main.xml
fi

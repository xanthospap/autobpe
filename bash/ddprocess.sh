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
  echo "           -s --satellite-system specify the satellite system; this can be"
  echo "              * gps, or"
  echo "              * mixed (for gps + glonass)"
  echo "            default is gps"
  echo "           -t --solution-type specify the dolution type; this can be:"
  echo "              * final, or"
  echo "              * urapid"
  echo "           --debug set debugging mode"
  echo "           -y --year= specify year (4-digit)"
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
TABLES=/home/bpe2/tables                ## table area
PRODUCT_AREA=/media/Seagate/solutions52 ## product area
PCF_FILE=NTUA_DDP                       ## the pcf file; no path, no extension
PL_FILE=ntua_pcs.pl                     ## the perl script to ignite the processing
LOG_DIR=/home/bpe2/log                  ## directory holding the log files

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
  ARGS=`getopt -o hvc:b:a:i:p:s:e:y:d:l:t:f:m: \
  -l  help,version,campaign:,bernese-loadvar:,analysis-center:,solution-id:,pcv-file:,satellite-system:,elevation-angle:,year:,doy:,stations-per-cluster:,solution-type:,ion-products:,debug,calibration-model: \
  -n 'ddprocess' -- "$@"`
else
  ## Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt hvc:b:a:i:p:s:e:y:d:l:t:f:m: "$@"`
fi
## check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

## extract options and their arguments into variables.
while true ; do
  case "$1" in
    --debug)
      DEBUG=YES;;
    -f|--ion-products)
      ION_STRING="$2"; shift;;
    -t|--solution-type)
      SOL_TYPE=`echo ${2:0:1} | tr 'A-Z' 'a-z'`; shift;;
    -l|--stations-per-cluster)
      STA_PER_CLU="${2}"; shift;;
    -y|--year)
      YEAR="${2}"; shift;;
    -d|--doy)
      DOY=`echo "${2}" | sed 's|^0||g'`; shift;;
    -e|elevation-angle)
      ELEV="${2}"; shift;;
    -s|satellite-system)
      SAT_SYS="${2}"; shift;;
    -m|--calibration-model)
      CLBR="${2}"; shift;;
    -p|pcv-file)
      PCV="${2}"; shift;;
    -i|solution-id)
      SOL_ID="${2}"; shift;;
    -a|analysis-center)
      AC="${2}"; shift;;
    -b|bernese-loadvar)
      LOADVAR="${2}"; shift;;
    -c|--campaign)
      CAMPAIGN="${2}"; shift;;
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
# CREATE / SET LOG FILE, WARNINGS FILE
# //////////////////////////////////////////////////////////////////////////////
LOGFILE=${LOG_DIR}/ddproc-${YEAR:2:2}${DOY}.log
WARFILE=${LOG_DIR}/ddproc-${YEAR:2:2}${DOY}.wrn
>$LOGFILE
>$WARFILE
echo "$*" >> $LOGFILE
START_T_STAMP=`/bin/date`
echo "Process started at: $START_T_STAMP" >> $LOGFILE

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
# TODO
# if ! `echo $ELEV | /bin/egrep [0-9]` ; then
#   echo "*** Invalid elevation angle"
#   exit 1
# else
#   if [ $ELEV -lt 3 -o $ELEV -gt 15 ]; then
#     echo "*** Invalid elevation angle [3-15]"
#     exit 1
#   fi
# fi

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

# //////////////////////////////////////////////////////////////////////////////
# CHECK & LINK (IF NEEDED) THE TABLE FILES
# //////////////////////////////////////////////////////////////////////////////

# 
# CHECK THAT THE PCV FILE EXISTS AND LINK IT
#
if $( test -f ${TABLES}/pcv/${PCV}.${CLBR} ) && $( /bin/ln -sf ${TABLES}/pcv/${PCV}.${CLBR} ${X}/GEN/${PCV}.${CLBR} ); then 
  :
else 
  echo "*** Failed to link pcv file ${TABLES}/pcv/${PCV}.${CLBR} "
  exit 1
fi

# 
# LINK THE .STA FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/sta/${CAMPAIGN}52.STA ) && \
   $( /bin/ln -sf ${TABLES}/sta/${CAMPAIGN}52.STA ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.STA ); then 
  :
else 
  echo "*** Failed to link sta file ${TABLES}/sta/${CAMPAIGN}52.STA"
  exit 1
fi

# 
# LINK THE .BLQ FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/blq/${CAMPAIGN}.BLQ ) && \
   $( /bin/ln -sf ${TABLES}/blq/${CAMPAIGN}.BLQ ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.BLQ ); then 
  :
else 
  echo "*** Failed to link blq file ${TABLES}/blq/${CAMPAIGN}.BLQ"
  exit 1
fi

# 
# LINK THE .ATL FILE (MUST BE NAMED AS THE CAMPAIGN)
#
if $( test -f ${TABLES}/atl/${CAMPAIGN}.ATL ) && \
   $( /bin/ln -sf ${TABLES}/atl/${CAMPAIGN}.ATL ${P}/${CAMPAIGN}/STA/${CAMPAIGN}.ATL ); then 
  :
else 
  echo "*** Failed to link atl file ${TABLES}/atl/${CAMPAIGN}.ATL"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# TRANSFORM DATE IN VARIOUS FORMATS
# //////////////////////////////////////////////////////////////////////////////
DATES_STR=`python -c "import bpepy.gpstime, sys
gpsweek,dow = bpepy.gpstime.yd2gpsweek ($YEAR,$DOY)
if gpsweek == -999 : sys.exit (1)
month,dom = bpepy.gpstime.yd2month ($YEAR,$DOY)
if month == -999 : sys.exit (1)
print '%04i %1i %02i %02i' %(gpsweek,dow,month,dom)
sys.exit (0);" 2>/dev/null`
    
## check for error
if test $? -ne 0 ; then
  echo "***ERROR! Failed to resolve the date"
  exit 1
fi

GPSW=`echo $DATES_STR | awk '{print $1}'`;
DOW=`echo $DATES_STR | awk '{print $2}'`;
MONTH=`echo $DATES_STR | awk '{print $3}'`;
DOM=`echo $DATES_STR | awk '{print $4}'`;

# //////////////////////////////////////////////////////////////////////////////
# LINK REQUIRED PRODUCTS FROM DATAPOOL AREA
#
# Note that the names of the linked files should be capitalize for convinience
# when this is possible
# //////////////////////////////////////////////////////////////////////////////

# WHERE IS DATAPOOL
DATAPOOL=${D}

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

if $( test -f ${DATAPOOL}/${SP3} ) && \
   $( /bin/ln -sf ${DATAPOOL}/${SP3} ${P}/${CAMPAIGN}/ORB/${TRG_SP3^^} ); then 
  :
else 
  echo "*** Failed to link orbit file ${DATAPOOL}/${SP3}"
  exit 1
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
 | cod | f    |       | codwwwwd.erp          |
 | cod | r    |       | corwwwwd.erp          |
 | cod | u    |       | couwwwwd.erp          |
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

if $( test -f ${DATAPOOL}/${ERP} ) && \
   $( /bin/ln -sf ${DATAPOOL}/${ERP} ${P}/${CAMPAIGN}/ORB/${TRG_ERP^^} ); then 
  :
else 
  echo "*** Failed to link orbit file ${DATAPOOL}/${SP3}"
  exit 1
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
if ! /usr/local/bin/setpolupdh --bernese-loadvar=${LOADVAR} --analysis-center=${AC^^} --pan=${PAN} ; then
  exit 1
fi

#
# DIFFERENTIAL CODE BIAS
# ------------------------------------------------------------------------------

## TODO

DCB=DCB${MONTH}${YR2}.DCB

if ! /bin/ln -sf ${DATAPOOL}/${DCB} ${P}/${CAMPAIGN}/ORB/${DCB} ; then
  echo "*** Failed to transfer dcb file $DCB from datapool"
  exit 1
fi


#
# IONOSPHERIC CORRECTIONS
# ------------------------------------------------------------------------------
for i in $ION_PRODS_ID; do
  ion=${i}${YR2}${DOY}0.ION.Z
  if [ "$DEBUG" == "YES" ];then echo -ne "(debug) checking ion file ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.ION.Z";fi
  if $( test -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.ION.Z ) && \
     $( cp -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.ION.Z ${P}/${CAMPAIGN}/ATM/ ); then 
    /bin/uncompress -f ${P}/${CAMPAIGN}/ION/${i}${YR2}${DOY}0.ION.Z
    if [ "$DEBUG" == "YES" ];then echo -ne "... file found!\n";fi
    break
  else 
    ion=
    if [ "$DEBUG" == "YES" ];then echo -ne "... file does not exist\n";fi
  fi
done

if test -z $ion ; then
  if [ "$DEBUG" == "YES" ];then echo -ne "(debug) downloading CODE's ion file";fi
  if /usr/local/bin/wgetion --output-directory=${P}/${CAMPAIGN}/ATM --force-remove --standard-names \
	      --decompress --year=${YEAR} --doy=${DOY} 1>.tmp 2>/dev/null; then
    ion=`cat .tmp | awk '{print $5}'`
    if [ "$DEBUG" == "YES" ];then echo -ne "... ok, downloaded $ion\n";fi
  else
    echo "*** Failed to download / locate ion file"
    exit 1
  fi
fi
rm .tmp 2>/dev/null

#
# TROPOSPHERIC CORRECTIONS
# ------------------------------------------------------------------------------

#
# LINK THE VIENNA GRID FILE WHICH SHOULD BE AT THE DATAPOOL AREA
if $( test -f ${D}/VMFG_${YEAR}${DOY} ) && \
   $( /bin/ln -sf ${D}/VMFG_${YEAR}${DOY} ${P}/${CAMPAIGN}/GRD/VMF${YR2}${DOY}0.GRD ); then 
  :
else 
  echo "*** Failed to link VMF1 grid file ${D}/VMFG_${YEAR}${DOY}"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# TRANSFER THE RINEX FILES FROM DATAPOOL
# //////////////////////////////////////////////////////////////////////////////

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

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT ALL STATIONS (TO BE PROCESSED) ARE IN THE BLQ FILE
# //////////////////////////////////////////////////////////////////////////////
for i in ${RINEX_AV[@]}; do
  sta_name=`echo ${i:0:4} | tr 'a-z' 'A-Z'`
  if ! /bin/egrep "^  ${sta_name} *" ${TABLES}/blq/${CAMPAIGN}.BLQ; then
    echo "Warning -- station ${sta_name} missing ocean loading corrections; file ${TABLES}/blq/${CAMPAIGN}.BLQ"
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT ALL STATIONS (TO BE PROCESSED) ARE IN THE ATL FILE
# //////////////////////////////////////////////////////////////////////////////
for i in ${RINEX_AV[@]}; do
  sta_name=`echo ${i:0:4} | tr 'a-z' 'A-Z'`
  if ! /bin/egrep "^  ${sta_name} *" ${TABLES}/atl/${CAMPAIGN}.ATL; then
    echo "Warning -- station ${sta_name} missing atmospheric loading corrections; file ${TABLES}/atl/${CAMPAIGN}.ATL"
  fi
done

# //////////////////////////////////////////////////////////////////////////////
# CREATE THE CLUSTER FILE
# //////////////////////////////////////////////////////////////////////////////

##  dump all available rinex files (station names) on a temporary file;
##+ then use the makecluster program to create a cluster file
>.tmp
for i in "${RINEX_AV[@]}"; do echo ${i:0:4} >> .tmp; done
/usr/local/bin/makecluster --abbreviation-file=${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.ABB \
                           --stations-per-cluster=${STA_PER_CLU} \
                           --station-file=.tmp \
                           1>${P}/${CAMPAIGN^^}/STA/${CAMPAIGN^^}.CLU
if test $? -ne 0 ; then
  echo "Failed to create the cluster file"
  exit 1
fi

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

for i in ${SOL_ID} ${SOL_ID%?}P ${SOL_ID%?}R; do
  TMP=${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z
  if [ "$DEBUG" == "YES" ];then echo -ne "(debug) checking crd file $TMP";fi
  if test -f ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z ; then
    if [ "$DEBUG" == "YES" ];then echo -ne " ... file exists";fi
    cp ${PRODUCT_AREA}/${YEAR}/${DOY}/${i}${YR2}${DOY}0.CRD.Z ${P}/${CAMPAIGN}/STA/APRIORI.CRD.Z
    /bin/uncompress -f ${P}/${CAMPAIGN}/STA/APRIORI.CRD.Z
    for j in ${RINEX_AV[@]}; do
      j=${j:0:4}
      if ! /bin/egrep " ${j^^} " ${P}/${CAMPAIGN}/STA/APRIORI.CRD &>/dev/null; then
        rm ${P}/${CAMPAIGN}/STA/APRIORI.CRD
        TMP=
        if [ "$DEBUG" == "YES" ];then echo -ne "... missing station $j \n";fi
        break
      fi
    done
    if [ "$DEBUG" == "YES" ];then echo -ne "... ok!\n";fi
  fi
done

if ! test -f ${P}/${CAMPAIGN}/STA/APRIORI.CRD; then
  TMP=${TABLES}/crd/${CAMPAIGN}.CRD
  if [ "$DEBUG" == "YES" ];then echo -ne "(debug) using default crd file $TMP";fi
  if ! cp ${TABLES}/crd/${CAMPAIGN}.CRD ${P}/${CAMPAIGN}/STA/APRIORI.CRD; then
    echo "*** Failed to copy a-priori coordinate file ${TABLES}/crd/${CAMPAIGN}.CRD"
    TMP=
    exit 1
  fi
fi

mv ${P}/${CAMPAIGN}/STA/APRIORI.CRD ${P}/${CAMPAIGN}/STA/REG${YR2}${DOY}0.CRD
echo "Using a-priori coordinate file: $TMP"

# //////////////////////////////////////////////////////////////////////////////
# SET OPTIONS IN THE PCF FILE
# //////////////////////////////////////////////////////////////////////////////

# Strip the pcf files from path and extension (no need)
# TMP_PCF=${PCF_FILE##*/}
# TMP_PCF=${TMP_PCF%%.*}

if ! /usr/local/bin/setpcf --analysis-center=${AC^^} --bernese-loadvar=${LOADVAR} --campaign=${CAMPAIGN} \
    --solution-id=${SOL_ID} --pcf-file=${PCF_FILE} --pcv-file=${PCV} --satellite-system=${SAT_SYS,,} \
    --elevation-angle=${ELEV} --blq=${CAMPAIGN^^} --atl=${CAMPAIGN^^} --calibration-model=${CLBR} ; then
  echo "*** Failed to set variables in the PCF file"
  exit 1
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

if ! /usr/local/bin/setpcl --pcf-file=${PCF_FILE} --campaign=${CAMPAIGN} --pl-file=${PL_FILE%%.*} \
    --campaign=${CAMPAIGN^^} --sys-out=${SYSOUT} --sys-run=${SYSRUN} --task-id=${TASKID} \
    --bernese-loadvar=${LOADVAR} ; then
  echo "*** Failed to set variables in the PL file"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# PROCESS THE DATA (AT LAST!)
# //////////////////////////////////////////////////////////////////////////////

## empty the BPE directory
rm ${P}/${CAMPAIGN^^}/BPE/*

${U}/SCRIPT/${PL_FILE} ${YEAR} ${DOY}0

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

  echo "***********************************************************************" ##>> $LOGFILE
  echo "-------------------- PROCESS ERROR ------------------------------------" ##>> $LOGFILE
  echo "***********************************************************************" ##>> $LOGFILE

  ##  get the Session and PID_SUB of last program written in the SYSOUT file
  ##+ this info is extracted from the line:
  ##+ CPU name  # of jobs    Total  Mean   Max   Min  Total   Max  Session  PID_SUB
  ##+ -----------------------------------------------------------------------------
  ##+ localhost          3       16     5    15     0      0     0   150010  201_000
  FL=`/bin/grep localhost ${P}/${CAMPAIGN^^}/BPE/${SYSOUT}.OUT | /usr/bin/awk '{print $9"_"$10".LOG"}' 2>/dev/null`

  ## now right whatever message is in this file to the LOGFILE
  cat ${P}/${CAMPAIGN^^}/BPE/${TASKID}${FL} >> $LOGFILE
  echo "***********************************************************************" ##>> $LOGFILE

  for i in `ls ${P}/${CAMPAIGN^^}/BPE/${TASKID}${YR2}${DOY}0*.LOG`; do cat $i >> $LOGFILE; done
fi

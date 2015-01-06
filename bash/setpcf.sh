#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : setpcf.sh
                           NAME=setpcf
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : DEC-2014
## usage                 : 
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : 
## uses                  : 
## dependancies          : 
## notes                 :
## TODO                  : maybe set the variable V_CRXINF
## detailed update list  :
                           LAST_UPDATE=DEC-2014
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
  echo " Purpose : Set variables in .PCF file"
  echo ""
  echo " Usage   :"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches: -a --analysis-center= specify the analysis center; this can be e.g."
  echo "              * igs, or"
  echo "              * cod (default)"
  echo "           -b --bernese-loadvar= specify the Bernese LOADGPS.setvar file; this"
  echo "            is needed to resolve the Bernese-related path variables"
  echo "           -c --campaign= specify campaign name"
  echo "           -i --solution-id= specify solution id (e.g. FFG) --see Note 1"
  echo "           -p --pcf-file= specify the .PCF file to be configured (no path)"
  echo "            Note that the extension of the file is supposed to be .PCF and it must"
  echo "            not be provided; e.g. if user wants to specify the file some/path/foo.PCF,"
  echo "            the switch should be used as --pcf-file=foo"
  echo "           -f --pcv-file= specify the .PCV file to be used (no path). Do not provide the"
  echo "            extension; it is supposed to be .I08"
  echo "           -s --satellite-system specify the satellite system; this can be"
  echo "              * gps, or"
  echo "              * mixed (for gps + glonass)"
  echo "            default is gps"
  echo "           -e --elevation-angle= specify the elevation angle (degrees, integer)"
  echo "            default value is 3 degrees"
  echo "           -l --blq= specify ocean tide loading correction file (format .blq). Do not"
  echo "            provide extension; it is supposed to be .BLQ"
  echo "           -t --atl= specify atmospheric loading correction file (format .atl)."
  echo "            Do not provide extension; it is supposed to be .ATL"
  echo " [OBSOLETE]-w --warnings if set, then the following are tested and the script"
  echo "            fails in case they are not true:"
  echo "              * the extension of the blq file, must be .BLQ,"
  echo "              * the extension of the atl file, must be .ATL,"
  echo "              * the extension of the pcv file, must be .I08"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-2 -> Failed to substitute variable in PCF file"
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
  echo ""
  echo " Example: $NAME -a emp -b LOADGPS.setvar -c CAMPGN -i NTA -p S_PCF -f S_PCV -s mixed\\"
  echo "          -e 7 -l S_BLQ -t S_ATL"
  echo " this command, will configure the following variables in the S_PCF.PCF file:"
  echo "VARIABLE DESCRIPTION                              DEFAULT"
  echo "8******* 40************************************** 30****************************"
  echo "V_B      Orbit/ERP, DCB, CLK information          EMP"
  echo "V_C      Preliminary (ambiguity-float) results    NTP"
  echo "V_E      Final (ambiguity-fixed) results          NTA"
  echo "V_F      Size-reduced NEQ information             NTR"
  echo "V_CRDINF Merged CRD/VEL filename                  CAMPGN"
  echo "V_BLQINF BLQ FILE NAME, CMC CORRECTIONS           S_BLQ"
  echo "V_ATLINF ATL FILE NAME, CMC CORRECTIONS           S_ATL"
  echo "V_SATSYS Select the GNSS (GPS, GPS/GLO)           GPS/GLO"
  echo "V_PCVINF PCV information file                     S_PCV"
  echo "V_ELANG  Elevation angle (mask) in degrees        7"
  echo ""
  echo " Note 1"
  echo "       The solution id will have an effect on the naming of the Final, Preliminary"
  echo "       and Size-Reduced solutionfiles. If e.g. the solution-id is set to NTA, then"
  echo "       the Final solution files will be named NTA, the preliminery NTP and the size-"
  echo "       reduced NTR."
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

########################## FILE EXTENSIONS #####################################
PCF_EXT=PCF
BLQ_EXT=BLQ
ATL_EXT=ATL
PCV_EXT=I08

# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
AC=COD           ## analysis center; upper case
SOLID=           ## solution id
PCF=             ## pcf file, including path
BPCF=            ## pcf file, no path
PCV=             ## pcv file, including path
BPCV=            ## pcv file, no path
SATSYS=GPS       ## satellite system
ELEV=3           ## elevation angle
LOADVAR=         ## bernese LOADGPS.setvar file
BCAMPAIGN=       ## campaign name, no path
CAMPAIGN=        ## campaign name, with path 
BBLQ=            ## blq file, no path
BLQ=             ## blq, with path 
BATL=            ## atl file, no path
ATL=             ## atl, with path 
CHECK=FALSE      ## check variables (file name extensions)

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o a:b:i:p:f:s:e:hvw:c:l:t: \
  -l analysis-center:,bernese-loadvar:,solution-id:,pcf-file:,pcv-file:,satellite-system:,elevation-angle:,help,version,warnings:,campaign:,blq:,atl: \
  -n 'setpcl' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt a:b:i:p:f:s:e:hvw:c:l:t: "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -a|--analysis-center)
      AC="${2}"; shift;;
    -b|--bernese-loadvar)
      LOADVAR="${2}"; shift;;
    -c|--campaign)
      BCAMPAIGN="${2^^}"; shift;;
    -i|--solution-id)
      SOLID="${2}"; shift;;
    -p|--pcf-file)
      BPCF="${2}.${PCF_EXT}"; shift;;
    -f|--pcv-file)
      BPCV="${2}.${PCV_EXT}"; shift;;
    -s|--satellite-system)
      SATSYS="${2^^}"; shift;;
    -l|--blq)
      BBLQ="${2}.${BLQ_EXT}"; shift;;
    -t|--atl)
      BATL="${2}.${ATL_EXT}"; shift;;
    -e|--elevation-angle)
      ELEV="${2}"; shift;;
    -w|--warnings)
      CHECK=TRUE;;
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
# CHECK & LOAD THE LOADVAR FILE
# //////////////////////////////////////////////////////////////////////////////
if test -z $LOADVAR ; then
  echo "***ERROR! Need to specify the Bernese LOADGPS.setvar file"
  exit 254
fi
if ! test -f $LOADVAR ; then
  echo "***ERROR! Cannot locate file $LOADVAR"
  exit 254
fi
. $LOADVAR
if test -z $VERSION ; then
  echo "***ERROR! Cannot load the source file: $LOADVAR"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT AT LEAST THE NEEDED PARAMETERS ARE SET & VALID
# //////////////////////////////////////////////////////////////////////////////
if test -z $SOLID ; then
  echo "***ERROR! Need to specify solution id"
  exit 254
fi

PCF=${U}/PCF/$BPCF
if test -z $BPCF ; then
  echo "***ERROR! Need to specify pcf file"
  exit 254
fi
if ! test -f $PCF ; then
  echo "***ERROR! Cannot locate file $PCF"
  exit 254
fi

PCV=${X}/GEN/$BPCV
if test -z $BPCV ; then
  echo "***ERROR! Need to specify pcv file"
  exit 254
fi
if ! test -f $PCV ; then
  echo "***ERROR! Cannot locate file $PCV"
  exit 254
fi

CAMPAIGN=${P}/${BCAMPAIGN}
if test -z $BCAMPAIGN ; then
  echo "***ERROR! Need to specify campaign name"
  exit 254
fi
if ! test -d $CAMPAIGN ; then
  echo "***ERROR! Cannot locate campaign $CAMPAIGN"
  exit 254
fi

BLQ=${CAMPAIGN}/STA/${BBLQ}
if test -z $BBLQ ; then
  echo "***ERROR! Need to specify blq file"
  exit 254
fi
if ! test -f $BLQ ; then
  echo "***ERROR! Cannot locate .blq file $BLQ"
  exit 254
fi

ATL=${CAMPAIGN}/STA/${BATL}
if test -z $BATL ; then
  echo "***ERROR! Need to specify atl file"
  exit 254
fi
if ! test -f $ATL ; then
  echo "***ERROR! Cannot locate .atl file $ATL"
  exit 254
fi

if [ "$SATSYS" != "GPS" -a "$SATSYS" != "MIXED" ]; then
  echo "***ERROR! Invalid satellite system identifier"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# SET THE SOLUTION IDs
# //////////////////////////////////////////////////////////////////////////////
## if given solution id is e.g. XXX, then the preliminary solution id will be
## XXP and the size-reduced results XXR. This means, that the last char of the
## solution id cannot be 'P' or 'R'.
if [ "${SOLID:${#SOLID}-1}" == "R" -o "${SOLID:${#SOLID}-1}" == "P" ]; then
  echo "ERROR! Ending character pf solution identifier cannot be 'P' or 'R'"
  exit 254
fi
FSI=$SOLID
PSI=${SOLID%?}P
RSI=${SOLID%?}R

# //////////////////////////////////////////////////////////////////////////////
# THIS IS THE SCRIPT TO SET
# //////////////////////////////////////////////////////////////////////////////
SCRIPT=${U}/SCRIPT/ntua_pcs.pl.bck
if ! test -f $SCRIPT ; then
  echo "***ERROR! Cannot locate script file $SCRIPT"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# SET VARIABLES IN THE .PCF FILE
# //////////////////////////////////////////////////////////////////////////////

## VARIABLE FOR AC, SET IN LINE
## V_B      Orbit/ERP, DCB, CLK information
## ---------------------------------------------------------------
if ! sed -i "s|^V_B      .*|V_B      Orbit/ERP, DCB, CLK information          ${AC}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set analysis center"; 
  exit 253; 
fi

## VARIABLE FOR PRELIMINARY SOLUTION ID, SET IN LINE
## V_C      Preliminary (ambiguity-float) results
## ---------------------------------------------------------------
if ! sed -i "s|^V_C      .*|V_C      Preliminary (ambiguity-float) results    ${PSI}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set preliminary results id"; 
  exit 253; 
fi

## VARIABLE FOR FINAL SOLUTION ID, SET IN LINE
## V_E      Final (ambiguity-fixed) results          
## ---------------------------------------------------------------
if ! sed -i "s|^V_E      .*|V_E      Final (ambiguity-fixed) results          ${FSI}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set final results id"; 
  exit 253; 
fi

## VARIABLE FOR SIZE_REDUCED SOLUTION ID, SET IN LINE
## V_F      Size-reduced NEQ information             
## ---------------------------------------------------------------
if ! sed -i "s|^V_F      .*|V_F      Size-reduced NEQ information             ${RSI}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set reduced results id"; 
  exit 253; 
fi

## VARIABLE FOR MERGED CRD/VEL, SET IN LINE
## V_CRDINF Merged CRD/VEL filename                  
## ---------------------------------------------------------------
if ! sed -i "s|^V_CRDINF .*|V_CRDINF Merged CRD/VEL filename                  ${BCAMPAIGN}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set Merged CRD/VEL"; 
  exit 253; 
fi

## VARIABLE FOR BLQ FILE, SET IN LINE
## V_BLQINF BLQ FILE NAME, CMC CORRECTIONS           
## ---------------------------------------------------------------
if ! sed -i "s|^V_BLQINF .*|V_BLQINF BLQ FILE NAME, CMC CORRECTIONS           ${BBLQ%${BLQ_EXT}}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set blq file"; 
  exit 253; 
fi

## VARIABLE FOR ATL FILE, SET IN LINE
## V_ATLINF ATL FILE NAME, CMC CORRECTIONS           
## ---------------------------------------------------------------
if ! sed -i "s|^V_ATLINF .*|V_ATLINF ATL FILE NAME, CMC CORRECTIONS           ${BATL%${ATL_EXT}}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set atl file"; 
  exit 253; 
fi

## VARIABLE FOR GNSS, SET IN LINE
## V_SATSYS Select the GNSS (GPS, GPS/GLO)           
## ---------------------------------------------------------------
if [ "$SATSYS" == "GPS" ]; then GSYS=GPS; else GSYS=GPS/GLO; fi
if ! sed -i "s|^V_SATSYS .*|V_SATSYS Select the GNSS (GPS, GPS/GLO)           ${GSYS}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set gnss"; 
  exit 253; 
fi

## VARIABLE FOR PCV, SET IN LINE
## V_PCVINF PCV information file                     
## ---------------------------------------------------------------
if ! sed -i "s|^V_PCVINF .*|V_PCVINF PCV information file                     ${BPCV%${PCV_EXT}}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set gnss"; 
  exit 253; 
fi

## VARIABLE FOR ELEVATION ANGLE, SET IN LINE
## V_ELANG  Elevation angle (mask) in degrees        
## ---------------------------------------------------------------
if ! sed -i "s|^V_ELANG  .*|V_ELANG  Elevation angle (mask) in degrees        ${ELEV}|g" \
$PCF 2>/dev/null; then 
  echo "***ERROR! Failed to set gnss"; 
  exit 253;
fi

# //////////////////////////////////////////////////////////////////////////////
# SHORT REPORT
# //////////////////////////////////////////////////////////////////////////////
echo "Configured Variables in ${PCF} as follows:"
echo "Analysis Center : ${AC}"
echo "Solution ID     : ${FSI} (Preliminary ${PSI}, Reduced ${RSI})"
echo "BLQ Corrections : ${BBLQ%%.*} (.${BLQ_EXT})"
echo "ATL Corrections : ${BATL%%.*} (.${ATL_EXT})"
echo "Satellite System: ${GSYS}"
echo "PCV Corrections : ${BPCV%%.*} (.${PCV_EXT})"
echo "Elevation Angle : ${ELEV} degrees"

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0

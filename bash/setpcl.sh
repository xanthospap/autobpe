#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : setpcl.sh
                           NAME=setpcl
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
## TODO                  : 
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
  echo " Purpose : Set variables in a .pl script file. These files reside in GPSUSER52/SCRIPT directory"
  echo "           and are used to ignite a protocol file (.PCF)"
  echo ""
  echo " Usage   :"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches: -p --pcf-file= specify the protocol (.pcf) file to be ignited. Do not use path, or"
  echo "            extension (e.g. for \${U}/PCF/RNX2SNX.PCF only specify RNX2SNX)"
  echo "           -l --pl-file= specify the .pl (perl script) file; this file must be present in"
  echo "            \${U}/SCRIPT/GIVEN_PL.pl; only the name must be provideed, no path, no extension"
  echo "           -b --bernese-loadvar= specify the Bernese LOADGPS.setvar file; this"
  echo "            is needed to resolve the Bernese-related path variables"
  echo "           -u --cpu-file= specify the CPU file to be used. Default value is 'USER'; do not"
  echo "            change this unless you know what you're doing"
  echo "           -c --campaign= specify the campaign name. The campaign should exist in the \${P}"
  echo "            directory (e.g. as \${P}/SOME_CAMPAIGN_NAME/)"
  echo "           -o --sys-out= specify the name of the process output file (i.e. output of PCF)"
  echo "           -r --sys-run= specify the name of the process run file (i.e. output of PCF)"
  echo "           -i --task-id= specify the task identifier (2 chars)"
  echo " [OBSOLETE]-w --warnings if this switch is set, then the script will try to check the validity"
  echo "            of the options givem. I.e."
  echo "                * \${U}/PCF/GIVEN_PCF.PCF, "
  echo "                * \${P}/GIVEN_CAMPAIGN/"
  echo "                * length of TASKID is 2"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
  echo ""
  echo " Example Usage"
  echo " The part of the .pl file to be edited, is given below, given the command:"
  echo " \$ $NAME -p NTUA_DDP -c GREECE -o G-NTUA_DDP -r G-NTUA_DDP -i GN"
  echo " # Redefine mandatory variables"
  echo " # ----------------------------"
  echo " \$\$bpe{PCF_FILE}     = \"NTUA_DDP\";"
  echo " \$\$bpe{CPU_FILE}     = \"USER\";"
  echo " \$\$bpe{BPE_CAMPAIGN} = \"GREECE\";"
  echo " \$\$bpe{YEAR}         = \$ARGV[0];"
  echo " \$\$bpe{SESSION}      = \$ARGV[1];"
  echo " \$\$bpe{SYSOUT}       = \"G-NTUA_DDP\";"
  echo " \$\$bpe{STATUS}       = \"G-NTUA_DDP.RUN\";"
  echo " \$\$bpe{TASKID}       = \"GN\""
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

# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
PCL=        ## The .pl file to edit
PCF=        ## The pcf file (no path, no extension)
LOADVAR=    ## The bernese .setvar file
CPU=USER    ## The CPU file
CAMPAIGN=   ## The name of the campaign
SOUT=       ## The sysout identifier
SRUN=       ## The sysrun identifier
TASK_ID=    ## The task id identifier
CHECK=YES   ## perform no checks

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o p:b:u:c:o:r:i:hvwl: \
  -l  pcf-file:,bernese-loadvar:,--cpu-file:,campaign:,sys-out:,sys-run:,task-id:,help,version,warnings,--pl-file: \
  -n 'setpcl' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt p:b:u:c:o:r:i:hvwl: "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -l|--pl-file)
      PCL="${2}"; shift;;
    -u|--cpu-file)
      CPU="${2}"; shift;;
    -b|--bernese-loadvar)
      LOADVAR="${2}"; shift;;
    -c|--campaign)
      CAMPAIGN="${2}"; shift;;
    -i|--task-id)
      TASK_ID="${2}"; shift;;
    -p|--pcf-file)
      PCF="${2}"; shift;;
    -o|--sys-out)
      SOUT="${2}"; shift;;
    -r|--sys-run)
      SRUN="${2}"; shift;;
    -w|--warnings)
      echo "## -w switch is obsolete; warnings are implemented by default"
      CHECK=YES;;
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
if ! test -f $LOADVAR ; then
  echo "*** Variable file $LOADVAR does not exist"
  exit 1
fi
. $LOADVAR
if [ "$VERSION" != "52" ] ; then
  echo "***ERROR! Cannot load the source file: $LOADVAR"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# IF NEEDED, CHECK THE OPTIONS
# //////////////////////////////////////////////////////////////////////////////
if [ "$CHECK" == "YES" ]; then

  if ! test -f ${U}/SCRIPT/${PCL}.pl ; then
    echo "*** Failed to locate file ${U}/SCRIPT/${PCL}.pl"
    exit 254
  fi

  if ! test -f ${U}/PCF/${PCF}.PCF ; then
    echo "*** Failed to locate file ${U}/PCF/${PCF}.PCF"
    exit 254
  fi
  
  if ! test -d ${P}/${CAMPAIGN} ; then
    echo "*** Failed to locate campaign ${P}/${CAMPAIGN}"
    exit 254
  fi
  
  if [ ${#TASK_ID} -ne 2 ]; then
    echo "*** Task Id must be a 2-char string"
    exit 254
  fi
  
  if test -z $SOUT ; then
    echo "*** SYS_OUT undefined"
    exit 254
  fi
  
  if test -z $SRUN ; then
    echo "*** SYS_RUN undefined"
    exit 254
  fi
  
fi

# //////////////////////////////////////////////////////////////////////////////
# EDIT THE VARIABLES
# //////////////////////////////////////////////////////////////////////////////
SCRIPT=${U}/SCRIPT/${PCL}.pl

if ! sed -i "s|^\$\$bpe{PCF_FILE}     =.*|\$\$bpe{PCF_FILE}     = \"${PCF}\";|g" $SCRIPT ;then
  echo "*** Failed to set PCF file variable"
  exit 254
fi

if ! sed -i "s|^\$\$bpe{CPU_FILE}     =.*|\$\$bpe{CPU_FILE}     = \"${CPU}\";|g" $SCRIPT ;then
  echo "*** Failed to set CPU variable"
  exit 254
fi

if ! sed -i "s|^\$\$bpe{BPE_CAMPAIGN} =.*|\$\$bpe{BPE_CAMPAIGN} = \"${CAMPAIGN}\";|g" $SCRIPT ;then
  echo "*** Failed to set CAMPAIGN variable"
  exit 254
fi

if ! sed -i "s|^\$\$bpe{SYSOUT}       =.*|\$\$bpe{SYSOUT}       = \"${SOUT}\";|g" $SCRIPT ;then
  echo "*** Failed to set SYSOUT variable"
  exit 254
fi

if ! sed -i "s|^\$\$bpe{STATUS}       =.*|\$\$bpe{STATUS}       = \"${SRUN}.RUN\";|g" $SCRIPT ;then
  echo "*** Failed to set SYSRUN variable"
  exit 254
fi

if ! sed -i "s|^\$\$bpe{TASKID}       =.*|\$\$bpe{TASKID}       = \"${TASK_ID}\";|g" $SCRIPT ;then
  echo "*** Failed to set TASKID variable"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0
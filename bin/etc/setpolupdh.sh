#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : setpolupdh.sh
                           NAME=setpolupdh
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : 
## exit code(s)          : 0 -> Success
##                       : 1 -> Error
## discription           : Edit a POLUPD.INP file to set the right input file.
## uses                  : 
## notes                 :
## TODO                  :
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
# HELPMESSAGE
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Edit an POLUPD.INP file to set the correct values for the input file. The Pole"
  echo "           Information update process (handled by POLUPD), can have different input values"
  echo "           (different widgets) depending on the analysis center providing the file. E.g.,"
  echo "           when using an erp file from CODE, then the widget 'Bernese formatted ERP files'"
  echo "           must be set; in a different case, the widget 'Foreign formatted ERP files' must"
  echo "           be filled."
  echo ""
  echo " Usage   : <comparesta.sh> "
  echo ""
  echo " Switches:"
  echo "           -a --analysis-center= specify the analysis center. The user can provide whatever"
  echo "            value possible; the script compares this value against 'cod', meaning the CODE"
  echo "            analysis center."
  echo "           -b --bernese-loadvar= specify the Bernese LOADGPS.setvar file; this"
  echo "            is needed to resolve the Bernese-related path variables"
  echo "           -p --pan= specify the folder in which the INP file is to be found. This is usually"
  echo "            something like '\${U}/OPT/R2S_GEN/'. The user must ONLY provide the folder, NOT"
  echo "            the path. I.e. to set the file POLUPD.INP in the folder \${U}/OPT/R2S_GEN/, use"
  echo "            --pan=R2S_GEN"
  echo "           -h --help print help message and exit"
  echo "           -v --version print version and exit"
  echo ""
  echo " Exit Status: 255-1 -> Error"
  echo " Exit Status:     0 -> Success"
  echo ""
  echo " IMPORTANT"
  echo " The actual value for the (erp) file to be used is: \$B\$WD+0"
  echo ""
  echo " Note"
  echo " This script will only edit two lines of the input POLUPD.INP file (marked below as 1 and 2)"
  echo ""
  echo "++++++++++++++++++++++++++++++++++++++++ PART OF POLUPD.INP +++++++++++++++++++++++++++++++"
  echo "! Input Pole Files Bernese Format"
  echo "! -------------------------------"
  echo "ERPFIL 0                                                           <---------------------[1]"
  echo "## widget = selwin; path = DIR_ERP; ext = EXT_ERP; maxfiles = 999"
  echo "## emptyallowed = true"
  echo "# "
  echo ""
  echo "MSG_ERPFIL 1  \"Bernese formatted ERP files\""
  echo ""
  echo "ERPFIL_TXT_COL_1 1  \"Input Bernese ERP files\""
  echo ""
  echo "! Input Pole Files Foreign Format"
  echo "! -------------------------------"
  echo "IEPFIL 1  \"\${P}/GREECE/ORB/\$B\$Y\$S+0\"                               <---------------------[2]"
  echo "## widget = selwin; path = DIR_IEP; ext = EXT_IEP; maxfiles = 999"
  echo "## emptyallowed = true"
  echo "# $B$W+-7"
  echo "MSG_IEPFIL 1  \"Foreign formatted ERP files\""
  echo "++++++++++++++++++++++++++++++++++++++++ PART OF POLUPD.INP +++++++++++++++++++++++++++++++"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo "/******************************************************************************************/"
}

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if test "$#" -eq "0" ; then 
  help
  exit 0
fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o a:b:p:hv \
  -l analysis-center:,bernese-loadvar:,pan:,help,version \
  -n 'setpolupdh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt a:b:p:hv "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -a|--analysis-center)
      AC="${2^^}"
      shift
      ;;
    -b|--bernese-loadvar)
      LOADVAR="${2}"
      shift
      ;;
    -p|--pan)
      PAN="${2}"
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -v|--version)
      dversion
      exit 0
      ;;
    --) # end of options
      shift
      break
      ;;
     *) 
      echo "*** Invalid argument $1 ; fatal"
      exit 1
      ;;
  esac
  shift 
done


# //////////////////////////////////////////////////////////////////////////////
# CHECK & LOAD THE LOADVAR FILE
# //////////////////////////////////////////////////////////////////////////////
if test -z $LOADVAR ; then
  echo "***ERROR! Need to specify the Bernese LOADGPS.setvar file"
  exit 1
fi
if ! test -f $LOADVAR ; then
  echo "***ERROR! Cannot locate file $LOADVAR"
  exit 1
fi
. $LOADVAR
if test -z $VERSION ; then
  echo "***ERROR! Cannot load the source file: $LOADVAR"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT THE INP FILE EXISTS
# //////////////////////////////////////////////////////////////////////////////
INP_FILE=${U}/OPT/${PAN}/POLUPD.INP
if ! test -f ${INP_FILE} ; then
  echo "***ERROR! Cannot file INP file : ${INP_FILE}"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# MAKE THE CHANGE
# //////////////////////////////////////////////////////////////////////////////
if test "${AC}" == "COD" ; then
  ## Here is how the edited portion of the file should look like :
  ##
  ## ! Input Pole Files Bernese Format
  ## ! -------------------------------
  ## ERPFIL 1  "$B$Y$S+0"
  ##   ## widget = selwin; path = DIR_ERP; ext = EXT_ERP; maxfiles = 999
  ##   ## emptyallowed = true
  ## 
  ## MSG_ERPFIL 1  "Bernese formatted ERP files"
  ## 
  ## ERPFIL_TXT_COL_1 1  "Input Bernese ERP files"
  ## 
  ## ! Input Pole Files Foreign Format
  ## ! -------------------------------
  ## IEPFIL 1  ""
  ##   ## widget = selwin; path = DIR_IEP; ext = EXT_IEP; maxfiles = 999
  ##   ## emptyallowed = true
  ## 
  ## MSG_IEPFIL 1  "Foreign formatted ERP files"
  if ! /bin/sed -i "s|^ERPFIL [0-1].*|ERPFIL 1  \"\$B\$WD+0\"|g" $INP_FILE 2>/dev/null; then
    echo "***ERROR! Failed to substitute 'ERPFIL' value"
    exit 254
  fi
  if ! /bin/sed -i "s|^IEPFIL [0-1].*|IEPFIL 0  \"\"|g" $INP_FILE 2>/dev/null; then
    echo "***ERROR! Failed to substitute 'IEPFIL' value"
    exit 254
  fi
else
  ## Here is how the edited portion of the file should look like :
  ##
  ## ! Input Pole Files Bernese Format
  ## ! -------------------------------
  ## ERPFIL 1  ""
  ## widget = selwin; path = DIR_ERP; ext = EXT_ERP; maxfiles = 999
  ## emptyallowed = true
  ## MSG_ERPFIL 1  "Bernese formatted ERP files"
  ## 
  ## ERPFIL_TXT_COL_1 1  "Input Bernese ERP files"
  ## 
  ## ! Input Pole Files Foreign Format
  ## ! -------------------------------
  ## IEPFIL 1  "$B$Y$S+0"
  ##   ## widget = selwin; path = DIR_IEP; ext = EXT_IEP; maxfiles = 999
  ##   ## emptyallowed = true
  ## 
  ## MSG_IEPFIL 1  "Foreign formatted ERP files"
  if ! /bin/sed -i "s|^IEPFIL [0-1].*|IEPFIL 1  \"\$B\$WD+0\"|g" $INP_FILE 2>/dev/null; then
    echo "***ERROR! Failed to substitute 'IEPFIL' value"
    exit 254
  fi
  if ! /bin/sed -i "s|^ERPFIL [0-1].*|ERPFIL 0  \"\"|g" $INP_FILE 2>/dev/null; then
    echo "***ERROR! Failed to substitute 'ERPFIL' value"
    exit 254
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT OK
# //////////////////////////////////////////////////////////////////////////////
exit 0

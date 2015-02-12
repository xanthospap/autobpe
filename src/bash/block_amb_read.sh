#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : block_amb_read.sh
                           NAME=block_amb_read
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : block_amb_read -f [AMBIGUITYFILE] -m []
## exit code(s)          : 0 -> sucess
##                         1 -> failure
## discription           : This file will read an ambiguity summary file and report
##                         a block of ambiguity information in (as many
##                         as the baselines) xml table format. I.e. it will create
##                         xml table rows, one for each baseline.
##                         The format of the summary file is very stringent and applies
##                         to output from Bernese v5.2 RNX2SNX output.
##                         The xml output is directed to stdout.
## uses                  : sed, head, read, awk
## needs                 : 
## notes                 : You can see an ambiguity summary file at :
##                         ftp://bpe2@147.102.110.69~/templates/dd/AMBYYDDD0.SUM
## TODO                  : 
## WARNING               : This script is meant to be used by the ambsum2xml program.
##                         Better to not use as standalone!
## detailed update list  : 
                           LAST_UPDATE=JAN-20145
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
  echo " Purpose : Read ambiguity resolution information of from an ambiguity summary file and"
  echo "           exctract information for a given method in xml (table) format. The info is"
  echo "           exctracted to stdout."
  echo ""
  echo " Usage   : "
  echo ""
  echo " Switches: -f --summary-file= specify the ambiguity resolution summary file (Note 1)"
  echo "           -m --method= specify the method to be considered. This can be: "
  echo "              * cbwl -> Code-Based WideLane,"
  echo "              * cbnl -> Code-Based NarrowLane,"
  echo "              * pbwl -> Phase-Based WideLane,"
  echo "              * pbnl -> Phase-Based NarrowLane,"
  echo "              * qif  -> QIF,"
  echo "              * dir  -> Direct L1/L2"
  echo "           -h --help print help message and exit"
  echo "           -v --version print version and exit"
  echo ""
  echo " Exit Status: Success 0"
  echo "            : Error   255-1"
  echo ""
  echo " WARNING !! The long options are only available if the GNU-enhanced version of getopt is"
  echo "            available; else, the user must only use short options"
  echo ""
  echo " Note 1"
  echo " The ambiguity summary file has a very stringent format and this script is hardcoded to"
  echo " work exactly with this. You can see an example of such a file here: "
  echo " bpe2@vincenty.ntua.gr~/templates/dd/AMBYYDDD0.SUM"
  echo ""
  echo " Note 2"
  echo " This script only produces rows for a table which is set elsewhere. The format of this"
  echo " table is vital and any change (there) may cast this script's output to gibberish."
  echo " See : ambsum2xml.sh"
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
# VARIABLES
# //////////////////////////////////////////////////////////////////////////////
AMBFILE=               ## input ambiguity file
METHOD=                ## method to be extracted
TOT_BSL=0              ## total number of baselines found

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o f:m:hv \
  -l summary-file:,method:,help,version \
  -n 'block_amb_read' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt f:m:hv "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -f|--summary-file)
      AMBFILE="${2}"; shift;;
    -m|--method)
      METHOD="${2}"; shift;;
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
# CHECK COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////

if ! test -f $AMBFILE ; then
  echo "***ERROR! Cannot find file $AMBFILE"
  exit 254
fi

if test $METHOD != "cbwl" ; then
  if test $METHOD != "cbnl" ; then
    if test $METHOD != "pbwl" ; then
      if test $METHOD != "pbnl" ; then
        if test $METHOD != "qif" ; then
          if test $METHOD != "dir" ; then
            echo "***ERROR! Not valid method $METHOD; see help file"
            exit 254
          else
            START="Direct L1\/L2 Ambiguity"; STOP=""; MTH="Direct L1 / L2";
          fi
        else
          START="Quasi-Ionosphere-Free (QIF)"; STOP="Direct L1\/L2 Ambiguity"; MTH="QIF";
        fi
      else
        START="Phase-Based Narrowlane (L3)"; STOP="Quasi-Ionosphere-Free (QIF)"; MTH="Phase-Based Narrowlane (L3)";
      fi
    else
      START="Phase-Based Widelane (L5)"; STOP="Phase-Based Narrowlane (L3)"; MTH="Phase-Based Widelane (L5)";
    fi
  else
    START="Code-Based Narrowlane (NL)"; STOP="Phase-Based Widelane (L5)"; MTH="Code-Based Narrowlane (NL)";
  fi
else
  START="Code-Based Widelane (WL)"; STOP="Code-Based Narrowlane (NL)"; MTH="Code-Based Widelane (WL)";
fi

# //////////////////////////////////////////////////////////////////////////////
# EXTRACT INFORMATION
# //////////////////////////////////////////////////////////////////////////////
##
## NOTE :
## The comments bellow are written for the method Code-Based WideLane method.
##
##  get the part of file inbetween (and including) the lines:
##+ Code-Based Widelane (WL) ...
##+ ...
##+ Code-Based Narrowlane (NL) ...
##+ $sed -n '/Code-Based Widelane (WL)/,/Code-Based Narrowlane (NL)/p'
##+ remove the first two and last two lines
##+ $sed -e '1,2d' and $head -n -2
##+ remove empty lines
##+ $sed '/^$/d'
##+ remove table header lines :
##+ File     Sta1 Sta2    Length     Before ...
##+                        (km)    #Amb (mm) ...
##+ $sed '/^File     Sta1 Sta2    Length     Before.*/d'
##+ $sed '/^                       (km)    #Amb (mm).*/d'
##+ remove the [-------------...] lines
##+ $sed '/^------------------.*/d'

sed -n "/${START}/,/${STOP}/p" $AMBFILE | \
      sed -e '1,2d' | head -n -2 | \
      sed '/^$/d' | \
      sed '/^ File     Sta1 Sta2    Length     Before.*/d' | \
      sed '/^                        (km)    #Amb (mm).*/d' | \
      sed '/^ ------------------.*/d' > .tmp

## Now we should be left with something like this:
## ----------------------------------------------------------------------------
#  AUDU0010 AUT1 DUTH    173.419    59  4.6    21  4.9  64.4 G    0.169  0.069  LEICA GRX1200PRO     LEICA GRX1200GGPRO    #AR_L5 
#  AULA0010 AUT1 LARM    118.104    61  4.8    22  5.1  63.9 G    0.154  0.073  LEICA GRX1200PRO     LEICA GRX1200+GNSS    #AR_L5 
#  DULE0010 DUTH LEMN    139.825    52  6.4    21  6.6  59.6 G    0.121  0.066  LEICA GRX1200GGPRO   LEICA GRX1200PRO      #AR_L5 
#  KAKL0010 KASI KLOK    179.539    76  5.7    34  6.0  55.3 G    0.165  0.064  LEICA GRX1200PRO     LEICA GRX1200PRO      #AR_L5 
#  KLLA0010 KLOK LARM     32.553    73  1.8    28  1.9  61.6 G    0.115  0.029  LEICA GRX1200PRO     LEICA GRX1200+GNSS    #AR_L5 
#  KLRL0010 KLOK RLSO    174.174    74  7.1    42  7.4  43.2 G    0.203  0.080  LEICA GRX1200PRO     LEICA GRX1200PRO      #AR_L5 
#  RLVL0010 RLSO VLSM     77.996    51  3.4    17  3.5  66.7 G    0.118  0.042  LEICA GRX1200PRO     LEICA GRX1200PRO      #AR_L5 
#  Tot:   7              127.944   446  5.1   185  5.3  58.5 G    0.203  0.062                                             #AR_L5 
## ----------------------------------------------------------------------------
## or an empty file!

## first the case where the file is empty :
TOT_BSL=0
if ! test -s .tmp ; then
  echo "<row>"
  echo "<entry>${MTH}</entry>"
  for i in `seq 1 13`; do
    echo "<entry></entry>"
  done
  echo "</row>"
  ## short summary
  echo "<!-- ## Number of baselines   : 0      ## -->"
  echo "<!-- ## Resolved baselines    : 0 %    ## -->"
  echo "<!-- ## Mean baseline length  : 0 (km) ## -->"
  exit 0
fi

## file is not empty :
TOT_BSL=`cat .tmp | wc -l` ## number of baselines for this method
let TOT_BSL=TOT_BSL-1
##  Now every line can be read using the command :
##+ IFS=' ' read -a array <<< `sed -n "${1}p" < .tmp`
##+ and its elements will be stored in array 'array'
for i in `seq 1 $TOT_BSL`; do
  array=()
  IFS=' ' read -a array <<< `sed -n "${i}p" < .tmp`
  if [ ${#array[@]} -lt 14 ]; then
    echo "***ERROR! Failed to read ambiguity info"
    rm .tmp 2>/dev/null
    exit 254
  fi
  echo "<row>"
  ## if this is the first row of the method, add a vertical spanning row
  if test ${i} -eq 1 ; then
    echo "<entry morerows=\"${TOT_BSL}\" valign=\"middle\"><para>${MTH}</para></entry>"
  fi
  # NOTE:    Receiver models can have whitespaces in theri names, so they could span
  #          more than one elements in the array 'array'. e.g. if receiver1='ASHTECH Z-XII3'
  #          this would span 2 elements in the array. For that reason they should be read 
  #          seperately.
  REC1=`sed -n "${i}p" < .tmp | awk '{print substr($0,79,20)}'`
  REC2=`sed -n "${i}p" < .tmp | awk '{print substr($0,100,20)}'`
  # WARNING: For the QIF method, there are an extra 2 columns <Max/RMS L3> just afterthe
  #          <Max/RMS L5> columns.
  if test "${METHOD}" == "qif" ; then
    REC1=`sed -n "${i}p" < .tmp | awk '{print substr($0,93,20)}'`
    REC2=`sed -n "${i}p" < .tmp | awk '{print substr($0,114,20)}'`
  fi
  # write down the info of this line in xml format
  for j in `seq 1 11`; do
    echo "<entry>${array[${j}]}</entry>" ##>> .tmp.wl
  done
  echo "<entry>${REC1}</entry>" ##>> .tmp.wl
  echo "<entry>${REC2}</entry>" ##>> .tmp.wl
  echo "</row>"
done

## Special care for the last line (the summary)
let j=TOT_BSL+1
array=()
IFS=' ' read -a array <<< `sed -n "${j}p" < .tmp`
echo "<row>"
echo "<?dbhtml bgcolor='#CCCCFF' ?><?dbfo bgcolor='#CCCCFF' ?>"
echo "<entry spanname=\"hspan12\"></entry>"
for k in `seq 2 10`; do
  echo "<entry>${array[${k}]}</entry>"
done
echo "<entry></entry>"
echo "<entry></entry>"
echo "</row>"

## short summary
echo "<!-- ## Number of baselines   : ${TOT_BSL}       ## -->"
echo "<!-- ## Resolved baselines    : ${array[7]} %    ## -->"
echo "<!-- ## Mean baseline length  : ${array[2]} (km) ## -->"

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
rm .tmp 2>/dev/null
exit 0

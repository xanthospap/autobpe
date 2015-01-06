#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : marksolsta.sh
                           NAME=marksolsta
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : DEC-2013
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : extract processed stations and baselines for each network from a
##                         solution summary file (e.g. FG[YEAR][DOY]0.SUM). Will need the
##                         following files:
##                         * FG[YEAR][DOY]0.SUM, placed in /media/Seagate/solutions52/[YEAR]/[DOY]
##                         * /home/bpe2/crd/[NETWORK].crd
##                         * /home/bpe2/data/GPSDATA/CAMPAIGN52/GREECE/STA/IGB08_R.CRD
##                         Networks available are:  greece, uranus, santorini, metrica
##                         Output is printed in stdout
## uses                  : * awk, grep, [/home/bpe2/unix-geo-tools/bin/x]yz2flh
## notes                 :
## TODO                  :
## detailed update list  : DEC-2013 added help function and header
##                         DEC-2014 major revision
                           LAST_UPDATE=DEC-2014
##
################################################################################

# //////////////////////////////////////////////////////////////////////////////
# HELP FUNCTION
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************/"
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Extract processed station for each network"
  echo ""
  echo " Usage   : marksolsta.sh -y [year] | -d [doy] | -n [network] | -t [TYPE] | "
  echo ""
  echo " Switches: "
  echo "           -y [:=year] year of processed day"
  echo "           -d [:=doy] day of year of processed day"
  echo "           -n [:= network] network to plot [ greece | uranus | santorini | metrica ]"
  echo "           -t [:=type]  type of solution (final,urapid; default final)"
  echo "           -h [:= help] help menu"
  echo "           -s [:save dir] save directory for solution file"
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
  echo "/******************************************************************************/"
  exit 0
}


# //////////////////////////////////////////////////////////////////////////////
# VARIABLES
# //////////////////////////////////////////////////////////////////////////////
SAV_DIR=/media/Seagate/solutions52
CRD_FILE=/home/bpe2/crd
YEAR=5000
DOY=500
TYPE=final
OUTDIR=`pwd`
NETWORK=
NETC=
TYPC=

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then
  help
fi

while [ $# -gt 0 ]
do
  case "$1" in
    -y)
      YEAR=${2}
      shift
      shift
      ;;
    -d)
      DOY=${2}
      shift
      shift
      ;;
    -o)     ############# OBSOLETE ##################            
      OUTDIR=${2}
      shift
      shift
      ;;
    -h)
      help
      exit 0
      ;;
    -t)
      TYPE=$2
      shift
      shift
      ;;
    -n)
      NETWORK=$2
      shift
      shift
      ;;
    -s)
      SAVE_DIR=$2
      shift
      shift
      ;;
  esac
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT YEAR IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $YEAR -lt 1950 ] || [ $YEAR -gt 2014 ]
then
  echo "*** Need to provide a valid year [1950-2014]"
  exit 1
fi
YR2=${YEAR:2:2}

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT DOY IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]
then
  echo "*** Need to provide a valid doy [1-366]"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# MAKE DOY A 3-DIGIT NUMBER
# //////////////////////////////////////////////////////////////////////////////
DOY=`truncate $DOY`

# //////////////////////////////////////////////////////////////////////////////
# IF OUTPUT DIR GIVEN, SEE THAT IT EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $OUTDIR ]
then
  echo "*** Directory $OUTDIR does not exist!"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT TYPE IS VALID
# //////////////////////////////////////////////////////////////////////////////
if [ "$TYPE" != "final" ]; then
  if [ "$TYPE" != "urapid" ]; then
    echo "*** Error! Invalid solution type: ${TYPE}; Type can be <final> <urapid>"
    exit 1
  else
    TYPC=U
  fi
else
  TYPC=F
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT NETWORK IS VALID
# //////////////////////////////////////////////////////////////////////////////
if [ "$NETWORK" != "greece" ]; then
  if [ "$NETWORK" != "uranus" ]; then
    if [ "$NETWORK" != "santorini" ]; then
      if [ "$NETWORK" != "metrica" ]; then
        echo "*** Error! Network can be: <greece> <santorini> <uranus> <metrica>"
        exit 1;
      else
        NETC=L
        CRD_FILE=${CRD_FILE}/LEICA.CRD       # METRICA.CRD
      fi
    else
      NETC=S
      CRD_FILE=${CRD_FILE}/SANTORINI.CRD
    fi
  else
    NETC=U
    CRD_FILE=${CRD_FILE}/URANUS.CRD
  fi
else
  NETC=G
  CRD_FILE=${CRD_FILE}/GREECE.CRD
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT WE HAVE THE IGS COORDINATE FILE
# //////////////////////////////////////////////////////////////////////////////
IGS_FILE=/home/bpe2/data/GPSDATA/CAMPAIGN52/GREECE/STA/IGB08_R.CRD
if [ ! -f $IGS_FILE ]; then
  echo "*** Error! Igs coordinates not found: $IGS_FILE"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# CRD FILE MUST EXIST
# //////////////////////////////////////////////////////////////////////////////
if [ ! -f $CRD_FILE ]; then
  echo "***ERROR! Cannot find network's crd file: $CRD_FILE"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# SET THE NAME OF THE FILE TO CHECK
# //////////////////////////////////////////////////////////////////////////////
# in bern50 folders URANUS and GREECE had different identifiers (GF opposed to FU)
# no need for this in bern52
#if [ "$NETC" == "U" ]; then
# OUTFILE=${SAV_DIR}/${YEAR}/${DOY}/${TYPC}${NETC}_${YR2}${DOY}0.
#else
# OUTFILE=${SAV_DIR}/${YEAR}/${DOY}/${NETC}${TYPC}_${YR2}${DOY}0.
#fi

OUTFILE=${SAV_DIR}/${YEAR}/${DOY}/${TYPC}${NETC}${YR2}${DOY}0.SUM

if [ ! -f ${OUTFILE} ]; then
  echo "*** Output file: $OUTFILE does not exist!"
  exit 1
fi

LOGFILE=${OUTDIR}/${NETWORK}-${YR2}-${DOY}-${TYPC}.dat
## If logfile already exists, remove it
rm $LOGFILE 2>/dev/null

# //////////////////////////////////////////////////////////////////////////////
# WRITE TO OUTPUT THE PROCESSED STATIONS CRDs
# //////////////////////////////////////////////////////////////////////////////
echo "## Station Coordinates for network: $NETWORK"
echo "## File with network's crds: $CRD_FILE"
echo "## Type of solution: $TYPE"
echo "## Input Solution File: $OUTFILE"
echo -ne "## Date compiled:  "; date;
echo "## Automaticaly created by routine: marksolsta.sh"
echo "##  name dx      dy      dz      rms_x  rms_y  rms_z  typ  Longtitude Latitude   Height"
echo "##* **** ******* ******* ******* ****** ****** ****** ***  ********** ********** ******"

## First find where line starting with 'stat. ' is in the file
## Loop for 150 iterations or stop when an empty line is encountered
## Fir every non-empty line, print line to LOGFILE
awk '/stat. / {for (i=1;i<150;i++) {getline; if (NF>0) print; else break;}}' $OUTFILE >> $LOGFILE

ITERATOR=1
ARRAY=$(awk '{ printf "%4s ",$1 }' $LOGFILE)
for i in ${ARRAY[*]}; do
  grep -i $i $CRD_FILE &>/dev/null
  if [ "$?" -eq 0 ]; then
    iter=$ITERATOR
    if [ $ITERATOR -lt 100 ]; then iter=0$iter; fi
    if [ $ITERATOR -lt 10 ]; then iter=0$iter; fi
    xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
    ## flh=`/home/bpe/car2ell.py $xyz`
    flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud`
    line1=`grep $i $LOGFILE`
    echo "$iter $line1 EST $flh"
    let ITERATOR=ITERATOR+1
# else
#   echo "## WARNING : Station $i not found in crd file!"
  fi
done

## REMOVE LOGFILE
rm $LOGFILE

# //////////////////////////////////////////////////////////////////////////////
# WRITE TO OUTPUT THE PROCESSED BASELINES
# //////////////////////////////////////////////////////////////////////////////
NR_OF_BASELINES=`grep "NUMBER OF BASELINES :" $OUTFILE | awk '{print $5}'`
MEAN_BSL_LENGTH=`grep "MEAN BASELINE LENGTH:" $OUTFILE | awk '{print $4}'`
MEAN_AMB_RESOLVED=`grep "MEAN AMB. RESOLVED" $OUTFILE | awk '{print $5}'`
echo "## NUMBER OF BASELINES : $NR_OF_BASELINES"
echo "## MEAN BASELINE LENGTH: $MEAN_BSL_LENGTH"
echo "## MEAN AMB. RESOLVED  : $MEAN_AMB_RESOLVED"

ITERATOR=0
## WE ARE GOING TO NEED 3 TEMP FILES
>.tmp1
>.tmp2
>.tcrd
## WE ALSO NEED A NEW CRD FILE CONTAINING ALL REGIONAL AND ISG COORDINATES
cat $CRD_FILE > .tcrd
cat $IGS_FILE >>.tcrd
CRD_FILE=.tcrd

## First Code-Based Narrowlane

## Phase-Based Narrowlane L3
grep "#AR_L3" $OUTFILE | head -n -1 | awk '{print $2,$3,$9}' > $LOGFILE
ARRAY1=$(awk '{ printf "%4s ", $1 }' $LOGFILE)
ARRAY2=$(awk '{ printf "%4s ", $2 }' $LOGFILE)
for i in ${ARRAY1[*]}; do
  grep -i $i $CRD_FILE &>/dev/null
  if [ "$?" -eq 0 ]; then
    xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
    flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud | awk '{print $1,$2}'`
    line1=`grep $i $LOGFILE`
    echo "$i -> $flh" >> .tmp1
  else
    echo "## WARNING(1) : Station $i not found in crd file!"
  fi
  let ITERATOR=ITERATOR+1
done
for i in ${ARRAY2[*]}; do
        grep -i $i $CRD_FILE &>/dev/null
        if [ "$?" -eq 0 ]; then
                xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
                flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud | awk '{print $1,$2}'`
                line1=`grep $i $LOGFILE`
                echo "$i -> $flh" >> .tmp2
        else
                echo "## WARNING(2) : Station $i not found in crd file!"
        fi
done
paste .tmp1 .tmp2 $LOGFILE | awk '{print "BL",$3,$4,$7,$8,$11,"W/N"}'

>.tmp1
>.tmp2
## Quasi-Ionosphere-Fre (QIF)
grep "#AR_QIF" $OUTFILE | head -n -1 | awk '{print $2,$3,$9}' > $LOGFILE
ARRAY1=$(awk '{ printf "%4s ", $1 }' $LOGFILE)
ARRAY2=$(awk '{ printf "%4s ", $2 }' $LOGFILE)
for i in ${ARRAY1[*]}; do
        grep -i $i $CRD_FILE &>/dev/null
        if [ "$?" -eq 0 ]; then
                xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
                flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud | awk '{print $1,$2}'`
                line1=`grep $i $LOGFILE`
                echo "$i -> $flh" >> .tmp1
        else
                echo "## WARNING(1) : Station $i not found in crd file!"
        fi
  let ITERATOR=ITERATOR+1
done
for i in ${ARRAY2[*]}; do
        grep -i $i $CRD_FILE &>/dev/null
        if [ "$?" -eq 0 ]; then
                xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
                flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud | awk '{print $1,$2}'`
                line1=`grep $i $LOGFILE`
                echo "$i -> $flh" >> .tmp2
        else
                echo "## WARNING(2) : Station $i not found in crd file!"
        fi
done
paste .tmp1 .tmp2 $LOGFILE | awk '{print "BL",$3,$4,$7,$8,$11,"QIF"}'

>.tmp1
>.tmp2
## Direct L1/L2 Ambiguity Resolution
grep "#AR_L12" $OUTFILE | head -n -1 | awk '{print $2,$3,$9}' > $LOGFILE
ARRAY1=$(awk '{ printf "%4s ", $1 }' $LOGFILE)
ARRAY2=$(awk '{ printf "%4s ", $2 }' $LOGFILE)
for i in ${ARRAY1[*]}; do
        grep -i $i $CRD_FILE &>/dev/null
        if [ "$?" -eq 0 ]; then
                xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
                flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud | awk '{print $1,$2}'`
                line1=`grep $i $LOGFILE`
                echo "$i -> $flh" >> .tmp1
        else
                echo "## WARNING(1) : Station $i not found in crd file!"
        fi
  let ITERATOR=ITERATOR+1
done
for i in ${ARRAY2[*]}; do
        grep -i $i $CRD_FILE &>/dev/null
        if [ "$?" -eq 0 ]; then
                xyz=`grep -i $i $CRD_FILE | awk '{ print $3,$4,$5}'`
                flh=`echo $xyz | /home/bpe2/unix-geo-tools/bin/xyz2flh -ud | awk '{print $1,$2}'`
                line1=`grep $i $LOGFILE`
                echo "$i -> $flh" >> .tmp2
        else
                echo "## WARNING(2) : Station $i not found in crd file!"
        fi
done
paste .tmp1 .tmp2 $LOGFILE | awk '{print "BL",$3,$4,$7,$8,$11,"L12"}'

## Check the iterator to see how many baselines we translated
if [ $ITERATOR -ne $NR_OF_BASELINES ]; then
  echo "## !! WARNING: $ITERATOR out of $NR_OF_BASELINES baselines translated!" 
fi

# //////////////////////////////////////////////////////////////////////////////
## REMOVE LOGFILE AND TEMPORARIES
# //////////////////////////////////////////////////////////////////////////////
rm $LOGFILE
rm .tmp1 .tmp2 .tcrd

## SECESSEFUL EXIT
exit 0

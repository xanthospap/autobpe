#! /bin/bash

##############################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : plot-amb-sum.sh
                           NAME=plot-amb-sum
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAY-2013
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : Plots ambiguity results given an ambiguity summary 
##                         file
## uses                  :
## notes                 :
## TODO                  :
## detailed update list  : DEC-2013 added header
##                         JAN-2015 added option for output file
##                         MAR-2015 added more options
                           LAST_UPDATE=MAR-2015
##
##############################################################################

## Load the gmt /bin folder (helpfull if called by crontab)
export PATH=${PATH}:/usr/lib/gmt/bin

function help ()
{
    echo "Usage : plot-amb-sum.sh <AMByyddd0.SUM> [<OUTPUT_FILE>]"
}
function dversion ()
{
    echo "${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
}

echoerr () 
{
    echo "$@" 1>&2
}

# ////////////////////////////////////////////////////////////////////////////
# VARIABLES
# ////////////////////////////////////////////////////////////////////////////
YEAR=
YR2=
DOY=
AMB_SUM=
PSFILE=
SATELLITE_SYSTEM_STR=
USE_GPS=NO
USE_GLO=NO
USE_MXD=NO

if [ "$#" == "0" ]
then 
  help
  exit 0
fi

##  Call getopt to validate the provided input. This depends on the getopt 
##+ version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  ## GNU enhanced getopt is available
  ARGS=`getopt -o hvy:d:a:o:s: \
    -l  help,version,year:,doy:,ambiguity-file:,output-file:,satellite-system: \
    -n 'plot-amb-sum' -- "$@"`
else
  ##  Original getopt is available (no long option names, no whitespace, 
  ##+ no sorting)
  ARGS=`getopt hvy:d:a:o:s: "$@"`
fi

if test $? -ne 0
then 
  echoerr "getopt error code : $status ;Terminating..." >&2 
  exit 1 
fi

eval set -- $ARGS

## extract options and their arguments into variables.
while true ; do
  case "$1" in
    -y--year)
      YEAR="$2"
      shift
      ;;
    -d|--doy)
      DOY="$2"
      shift
      ;;
    -a|--ambiguity-file)
      AMB_SUM="$2"
      shift
      ;;
    -o|--output-file)
      PSFILE="$2"
      shift
      ;;
    -s|--satellite-system)
      SATELLITE_SYSTEM_STR="$2"
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
      break;;
    *)
      echoerr "*** Invalid argument $1 ; fatal"
      exit 1
      ;;
  esac
  shift
done

# ////////////////////////////////////////////////////////////////////////////
# CHECK COMMAND LINE ARGUMENTS
# ////////////////////////////////////////////////////////////////////////////
if ! test -s $AMB_SUM
then
  echoerr "ERROR! Cannot find input file: $AMB_SUM"
  exit 1
fi

if test -z $PSFILE
then
  CAMB_FILE=${AMB_SUM^^}
  PSFILE=${CAMB_FILE/.SUM/.ps}
  echoerr "## No output file given; set from input file as: $PSFILE"
fi

if test -z $YEAR
then
  CAMB_FILE=`basename $AMB_SUM`
  YR2=${CAMB_FILE:3:2}
  if test $YR2 -gt 50
  then
    YEAR=19${YR2}
  else
    YEAR=20${YR2}
  fi
  echoerr "## Year not provided; set from input file as: $YEAR"
fi

if test -z $DOY
then
  CAMB_FILE=`basename $AMB_SUM`
  DOY=${CAMB_FILE:5:3}
  echoerr "## Doy not provided; set from input file as: $DOY"
fi

if test -z $SATELLITE_SYSTEM_STR
then
    echoerr "## No satellite systems to plot provided. Using default=gps"
    USE_GPS=YES
else
    IFS=',' read -a ARRAY <<< "$SATELLITE_SYSTEM_STR"
    for s in "${ARRAY[@]}"
    do
        case "$s" in
            gps|GPS)
                USE_GPS=YES
                ;;
            glo|GLO)
                USE_GLO=YES
                ;;
            mixed|MIXED)
                USE_MXD=YES
                ;;
            *)
                echoerr "## Invalid satellite system: $s; skipping"
                ;;
        esac
    done
fi

# ////////////////////////////////////////////////////////////////////////////
# EXPORT DATA TO PLOT
# ////////////////////////////////////////////////////////////////////////////

## GPS
## ////////////////////////////////////////////////////////////////////////////
## Get number of unique baselines for GPS
NUM_OF_GPS_BSL=`cat $AMB_SUM | awk 'BEGIN {sum=0} \
  /#AR_((NL)|(L3)|(QIF)|(L12))/ { if ( $9=="G" && $1=="Tot:" ) {sum+=$2} } \
  END {print sum}'`
## Eport data for GPS; only unique baselines
## Station1 Station2 Length Resolution(%)
cat $AMB_SUM | awk '/#AR_((NL)|(L3)|(QIF)|(L12))/ {if( $10=="G" && $1!="Tot:")\
  {print $2,$3,$4,$9} }' | sort -nk3 > .input.g.dat
## Se that the data are extracted correctly
if [ "$?" -ne 0 ] || [ ! -s .input.g.dat ]
then
  echoerr "*** ERROR! Unable to extract data from file $AMB_SUM (GPS)"
  PLOT_GPS=NO
  GPS_NR=0
else
  PLOT_GPS=YES
fi
## Final check; collected records lines must match number of baselines
if test "$PLOT_GPS" == "YES"
then
    RECORDS=`cat .input.g.dat | wc -l`
    if test $RECORDS -ne $NUM_OF_GPS_BSL
    then
      echoerr "## Failed to collect correct number of baselines records\
        from file $AMB_SUM (GPS)"
      echoerr "## GPS baselines will not be plotted"
      PLOT_GPS=NO
      GPS_NR=0
    else
      GPS_NR=$RECORDS
      echo "## Number of GPS baselines: $GPS_NR"
    fi
fi

## GLONASS
## //////////////////////////////////////////////////////////////////////////////
## Get number of unique baselines for GLONASS
NUM_OF_GLO_BSL=`cat $AMB_SUM | awk 'BEGIN {sum=0} \
  /#AR_((NL)|(L3)|(QIF)|(L12))/ { if ( $9=="R" && $1=="Tot:" ) {sum+=$2} } \
  END {print sum}'`
## Eport data for GLO; only unique baselines
## Station1 Station2 Length Resolution(%)
cat $AMB_SUM | awk '/#AR_((NL)|(L3)|(QIF)|(L12))/ {if($10=="R" && $1!="Tot:")\
  {print $2,$3,$4,$9} }' | sort -nk3 > .input.r.dat
## Se that the data are extracted correctly
if [ "$?" -ne 0 ] || [ ! -s .input.r.dat ]
then
  echoerr "*** ERROR! Unable to extract data from file $AMB_SUM (GLONASS)"
  PLOT_GLO=NO
  GLO_NR=0
else
  PLOT_GLO=YES
fi
## Final check; collected records lines must match number of baselines
if test "$PLOT_GLO" == "YES"
then
    RECORDS=`cat .input.r.dat | wc -l`
    if test $RECORDS -ne $NUM_OF_GLO_BSL
    then
      echoerr "## Failed to collect correct number of baselines records\
        from file $AMB_SUM (GLO)"
      echoerr "## GLONASS baselines will not be plotted"
      PLOT_GLO=NO
      GLO_NR=0
    else
      GLO_NR=$RECORDS
      echo "## Number of GLONASS baselines: $GLO_NR"
    fi
fi

## MIXED (GPS + GLONASS)
## //////////////////////////////////////////////////////////////////////////////
## Get number of unique baselines for MIXED
if test "$GPS_NR" -ge "$GLO_NR"
then
    NUM_OF_MXD_BSL=$GLO_NR
else
    NUM_OF_MXD_BSL=$GPS_NR
fi
## Eport data for MIXED; only unique baselines
## Station1 Station2 Length Resolution(%)
cat $AMB_SUM | awk '/#AR_((NL)|(L3)|(QIF)|(L12))/ { if($10=="GR" && $1!="Tot:")\
  {print $2,$3,$4,$9} }' | sort -nk3 > .input.gr.dat
## See that the data are extracted correctly
if [ "$?" -ne 0 ] || [ ! -s .input.gr.dat ]
then
  echoerr "*** ERROR! Unable to extract data from file $AMB_SUM (MIXED)"
  PLOT_MXD=NO
  MXD_NR=0
else
  PLOT_MXD=YES
fi
## Final check; collected records lines must match number of baselines
if test "$PLOT_MXD" == "YES"
then
    RECORDS=`cat .input.gr.dat | wc -l`
    if test $RECORDS -ne $NUM_OF_MXD_BSL
    then
      echoerr "## Failed to collect correct number of baselines records\
        from file $AMB_SUM (MIXED)"
      echoerr "## Number of records in file: $RECORDS, number of baselines counted: \
          $NUM_OF_MXD_BSL"
      echoerr "## MIXED baselines will not be plotted"
      PLOT_MXD=NO
      MXD_NR=0
    else
      MXD_NR=$RECORDS
      echo "## Number of MIXED baselines: $MXD_NR"
    fi
fi

##  Hold on! Now we have 3 files, 
##  input.g.dat  for GPS,
##  input.g.dat  for GLONASS,
##  input.gr.dat for GPS+GLONASS,
##  If the corresponding variable (PLOT_[GPS,GLO,MXD]) is set to 'YES',
##+ then these files contain records to be ploted. The format is:
##  Station1 Station2 Length(km) Resolution(%)
##  Note however, that the number of lines in each file may differ, i.e
##+ not all stations observe GLONASS.
##
##  What do we need now? We ned a file, translating every possible
##+ (unique) baseline to an int. Let's make this
awk 'NF>0 { print $1":"$2,$3 }' .input.g.dat .input.gr.dat .input.r.dat\
    | sort -nk2 | uniq | \
    awk 'BEGIN{ FS=":" } { print NR,$1,$2 }' > .unq_bsl
UNQ_BSL=`cat .unq_bsl | wc -l`
echo "## Number of baselines to be ploted: $UNQ_BSL"

# ////////////////////////////////////////////////////////////////////////////
# MIN AND MAX VALUES
# ////////////////////////////////////////////////////////////////////////////

## Find min-max values (global)
awk 'BEGIN { max_length=0; min_length=50000; min_resolved=100; max_resolved=0;} \
    NF > 0 { \
        if ($3>max_length) {max_length=$3} \
        if ($3<min_length) {min_length=$3} \
        if ($4>max_resolved) {max_resolved=$4} \
        if ($4<min_resolved) {min_resolved=$4}\
    } \
    END {print max_length,min_length,max_resolved,min_resolved}' \
    .input.g.dat .input.r.dat .input.gr.dat > .limits

##  Ok. Now in every file .input[gr].dat, match the baseline with the
##+ corresponding int value from the .nq_bsl file
for i in .input.g.dat .input.r.dat .input.gr.dat
do
    awk 'NR==FNR {c[$2$3]=$1;next} \
        c[$1$2] > 0 {print c[$1$2],$1,$2,$3,$4}' \
        .unq_bsl $i > .tmp
    NEW_LINES=`cat .tmp | wc -l`
    OLD_LINES=`cat $i | wc -l`
    if test $NEW_LINES -ne $OLD_LINES
    then
        echoerr "Failed to resolve unique baselines for file $i"
        exit 1
    fi
    mv .tmp $i
done

minx=0
UNQ_BSL=`cat .unq_bsl | wc -l`
let maxx=${UNQ_BSL}+1
maxy=`awk '{ printf ("%5i",$1) }' .limits`
miny=`awk '{ printf ("%5i",$2) }' .limits`
yinc=$(echo "($maxy - $miny) / 10" | bc)
miny=$(echo "scale=0; $miny - $yinc / 2" | bc)
maxy=$(echo "scale=0; $maxy + $yinc / 2" | bc)

# ////////////////////////////////////////////////////////////////////////////
# RESET GMT DEFAULTS
# ////////////////////////////////////////////////////////////////////////////
# gmtdefaults -D > ~/.gmtdefaults4
# PLOT_GLO=NO

# ////////////////////////////////////////////////////////////////////////////
# MAKE TWO BASEMAPS, ONE FOR EACH KIND OF DATA (AMB, LENGTH)
# ////////////////////////////////////////////////////////////////////////////
gmtset BASEMAP_AXES=Sn \
    BASEMAP_FRAME_RGB=0/0/0 \
    TICK_PEN=1,black \
    LABEL_FONT_SIZE=14p

## Basemap for resolution
OUTPUT_FILE=$PSFILE
psbasemap -R$minx/$maxx/$miny/$maxy -JX25c/15c \
  -Bpf1:"Baseline"::."Ambiguity Resolution for day ${DOY} of year ${YEAR}":Sn \
  -K > $OUTPUT_FILE

## Print baseline names
## Use the file with all records for this
#cat .unq_bsl | awk '{ 
#if ( NR % 2 )
#    print $1,"'$miny'",7,45,10,"BL",$2"-"$3
#else 
#    print $1,"'$miny'",7,45,10,"TR",$2"-"$3
#}' \
#    | pstext -R -J -O -K -Gblack -N >> $OUTPUT_FILE
cat .unq_bsl | awk '{ print $1,"'$miny'",7,45,10,"BL",$2"-"$3 }'\
    | pstext -R -J -O -K -Gblack -N >> $OUTPUT_FILE

## Basemap for length
gmtset BASEMAP_AXES=W \
    BASEMAP_FRAME_RGB=255/0/0 \
    ANNOT_FONT_SIZE_PRIMARY=14p
psbasemap -R -J -Bp/a${yinc}:"Length (m)":W -O -K >> $OUTPUT_FILE

## Plot baseline lengths
cat .unq_bsl | awk '{print $1,$4}' \
    | psxy -R -J -O -K -W0.5p,red,- >> $OUTPUT_FILE
cat .unq_bsl | awk '{print $1,$4}' \
        | psxy -R -J -O -K -Gred -Sc0.1 >> $OUTPUT_FILE

## Put horizontal lines for each resolution technique
NUM_OF_BSL=$UNQ_BSL
echo "$minx 20" > .horizontal.dat
echo "$maxx 20" >> .horizontal.dat
cat .horizontal.dat | psxy -R -J -O -K -W0.2p,gray >> $OUTPUT_FILE
echo "$NUM_OF_BSL 20 13 0 9 BR < 20 km" \
    | pstext -R -J -O -K -Gblack -N >> $OUTPUT_FILE

if test "$maxy" -gt 200
then
    echo "$minx 200" > .horizontal.dat
    echo "$maxx 200" >> .horizontal.dat
    cat .horizontal.dat | psxy -R -J -O -K -W0.2p,gray >> $OUTPUT_FILE
    echo "$NUM_OF_BSL 200 13 0 9 BR < 200 km" \
        | pstext -R -J -O -K -Gblack -N >> $OUTPUT_FILE
fi

if test "$maxy" -gt 2000
then
    echo "$minx 2000" > .horizontal.dat
    echo "$maxx 2000" >> .horizontal.dat
    cat .horizontal.dat | psxy -R -J -O -K -W0.2p,gray >> $OUTPUT_FILE
    echo "$NUM_OF_BSL 2000 13 0 9 BR < 2000 km" \
        | pstext -R -J -O -K -Gblack -N >> $OUTPUT_FILE
fi

if test "$maxy" -gt 6000
then
    echo "$minx 6000" > .horizontal.dat
    echo "$maxx 6000" >> .horizontal.dat
    cat .horizontal.dat | psxy -R -J -O -K -W0.2p,gray >> $OUTPUT_FILE
    echo "$NUM_OF_BSL 6000 13 0 9 BR < 6000 km" \
        | pstext -R -J -O -K -Gblack -N >> $OUTPUT_FILE
fi

maxy=`awk '{print $3}' .limits`
miny=`awk '{print $4}' .limits`
yinc=$(echo "($maxy - $miny) / 10.0" | bc)
miny=$(echo "scale=4; $miny - $yinc / 2" | bc)
maxy=$(echo "scale=4; $maxy + $yinc / 2" | bc)

gmtset BASEMAP_AXES=E \
    BASEMAP_FRAME_RGB=0/0/255 \
    TICK_PEN=1,blue \
    ANNOT_FONT_SIZE_PRIMARY=14p
R=-R$minx/$maxx/$miny/$maxy
psbasemap $R -J -Bp/a${yinc}:"Percent (%)":E -O -K >> $OUTPUT_FILE

## Plot each satellite system
if [ "$PLOT_GPS" == "YES" ] && [ "$USE_GPS" == "YES" ]
then
    if [ "$PLOT_GLO" == "YES" ] && [ "$USE_GLO" == "YES" ]
    then
        PSTEXT=K
    else
        if [ "$PLOT_MXD" == "YES" ] && [ "$USE_MXD" == "YES" ]
        then
            PSTEXT=K
        else
            PSTEXT=
        fi
    fi
    echo "## Ploting GPS data points"
    cat .input.g.dat | awk '{print $1,$5}' | \
        psxy -R -J -O  -K -W0.5p,blue,- >> $OUTPUT_FILE
    cat .input.g.dat | awk '{print $1,$5}' | \
        psxy -R -J -O -K -Gblue -Sc0.1 >> $OUTPUT_FILE
    XCRD=`echo - | awk -v tot=${NUM_OF_BSL} '{print tot/5.0}'`
    AVG_GPS=`awk 'BEGIN{avg=0} {avg+=$5} END{printf ("%5.1f",avg/NR)}' .input.g.dat`

    ## use continuation (-K) or not ?
    if test "${PSTEXT}" == "K"
    then
        echo "$XCRD $AVG_GPS 15 0 9 BL SatelliteSystem=GPS mean=$AVG_GPS" \
            | pstext -K -R -J -O -Gblue -N -Sthin,black >> $OUTPUT_FILE
    else
        echo "$XCRD $AVG_GPS 15 0 9 BL SatelliteSystem=GPS mean=$AVG_GPS" \
            | pstext -R -J -O -Gblue -N -Sthin,black >> $OUTPUT_FILE
    fi

fi

if [ "$PLOT_GLO" == "YES" ] && [ "$USE_GLO" == "YES" ]
then
    if [ "$PLOT_MXD" == "YES" ] && [ "$USE_MXD" == "YES" ]
    then
        PSTEXT=K
    else
        PSTEXT=
    fi
    echo "## Ploting GLONASS data points"
    cat .input.r.dat | awk '{print $1,$5}' | \
        psxy -R -J -O -K -W0.5p,green,- >> $OUTPUT_FILE
    cat .input.r.dat | awk '{print $1,$5}' | \
        psxy -R -J -O -K -Ggreen -Sc0.1 >> $OUTPUT_FILE
    XCRD=`echo - | awk -v tot=${NUM_OF_BSL} '{print tot/5.0}'`
    AVG_GLO=`awk 'BEGIN{avg=0} {avg+=$5} END{printf ("%5.1f",avg/NR)}' .input.r.dat`

    ## use continuation (-K) or not ?
    if test "${PSTEXT}" == "K"
    then
        echo "$XCRD $AVG_GLO 15 0 9 BL SatelliteSystem=GLONASS mean=$AVG_GLO" \
            | pstext -K -R -J -O -Ggreen -N -Sthin,black >> $OUTPUT_FILE
    else
        echo "$XCRD $AVG_GLO 15 0 9 BL SatelliteSystem=GLONASS mean=$AVG_GLO" \
            | pstext -R -J -O -Ggreen -N -Sthin,black >> $OUTPUT_FILE
    fi
fi

if [ "$PLOT_MXD" == "YES" ] && [ "$USE_MXD" == "YES" ]
then
    echo "## Ploting MIXED data points"
    cat .input.gr.dat | awk '{print $1,$5}' | \
        psxy -R -J -O -K -W0.5p,brown,- >> $OUTPUT_FILE
    cat .input.gr.dat | awk '{print $1,$5}' | \
        psxy -R -J -O -K -Gbrown -Sc0.1 >> $OUTPUT_FILE
    XCRD=`echo - | awk -v tot=${NUM_OF_BSL} '{print tot/5.0}'`
    AVG_MXD=`awk 'BEGIN{avg=0} {avg+=$5} END{printf ("%5.1f",avg/NR)}' .input.gr.dat`
    echo "$XCRD $AVG_MXD 15 0 9 BL SatelliteSystem=MIXED mean=$AVG_MXD" \
        | pstext -R -J -O -Gbrown -N -Sthin,black >> $OUTPUT_FILE
fi

## Just close the file
## psxy -J -R -T -O >> $OUTPUT_FILE

# //////////////////////////////////////////////////////////////////////////////
# DELETE TEMPORARY FILES
# //////////////////////////////////////////////////////////////////////////////
rm -f .minmax .input.g.dat .input.r.dat .input.gr.dat .horizontal.dat \
    .limits .unq_bsl 2>/dev/null

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0

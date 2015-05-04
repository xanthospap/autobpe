#! /bin/bash

##############################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : amb_unique_bsl.sh
                           NAME=amb_unique_bsl
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : APR-2015
## usage                 :
## exit code(s)          : 0 -> success
##                       : 1 -> error
## discription           : Given a ambyyddd0.sum files, exports number of
##                         unique baselines per satellite system. If a BERNESE
##                         type CRS file is provided (as 2nd command line
##                         argument), the coordinates of the stations of each
##                         baseline are also reported.
## uses                  :
## notes                 :
## TODO                  :
## detailed update list  : APR-2015
                           LAST_UPDATE=APR-2015
##
##############################################################################

## ---------------------------------------------------------------------------
## TYPICAL OUTPUT (no coordinates):
## ---------------------------------------------------------------------------
## ## Number of GPS baselines: 91 average length 208.3 average amb. resolved 79.6
## ## Number of GLO baselines: 76 average length 120.9 average amb. resolved 46.8
## ## Number of MXD baselines: 76 average length 120.9 average amb. resolved 64.5
## AGNI OROP 21.017 41.3 R
## AGNI OROP 21.017 64.9 M
## AGNI OROP 21.017 87.5 G
## AGNI SHTE 35.384 36.4 R
## AGNI SHTE 35.384 64.1 M
## AGNI SHTE 35.384 89.6 G
## AGPA LESV 28.580 75.0 R
## ---------------------------------------------------------------------------
##
## ---------------------------------------------------------------------------
## TYPICAL OUTPUT (with coordinates):
## ---------------------------------------------------------------------------
## ## Number of GPS baselines: 91 average length 208.3 average amb. resolved 79.6
## ## Number of GLO baselines: 76 average length 120.9 average amb. resolved 46.8
## ## Number of MXD baselines: 76 average length 120.9 average amb. resolved 64.5
## AGNI OROP 21.017 41.3 R +35.1915037002 +25.7179940311 +35.1975870234 +25.4875228750
## AGNI OROP 21.017 64.9 M +35.1915037002 +25.7179940311 +35.1975870234 +25.4875228750
## AGNI OROP 21.017 87.5 G +35.1915037002 +25.7179940311 +35.1975870234 +25.4875228750
## AGNI SHTE 35.384 36.4 R +35.1915037002 +25.7179940311 +35.2111659442 +26.1058146386
## AGNI SHTE 35.384 64.1 M +35.1915037002 +25.7179940311 +35.2111659442 +26.1058146386
## AGNI SHTE 35.384 89.6 G +35.1915037002 +25.7179940311 +35.2111659442 +26.1058146386
## AGPA LESV 28.580 75.0 R +39.2464539684 +26.2690813400 +39.0305543524 +26.4491188428
## ---------------------------------------------------------------------------
##

function help
{
    echo "Usage : amb_unique_bsl <AMByyddd0.SUM> [<>]"
}
function dversion
{
    echo "${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
}

function echoerr
{
    echo "$@" 1>&2
}

function clear_temp
{
    rm .bsl.g.dat .bsl.r.dat .bsl.m.dat .bsl.grm.dat 2>/dev/null
}

## Check that the ambiguity summary files exists.
if test -z $1
then
    echoerr "ERROR. Need to provide ambiguity summary file name"
    exit 1
else
    if ! test -f $1
    then
        echoerr "ERROR. Unable to find (input) file $1"
        exit 1
    fi
fi
AMBSUM=$1

##  If the ambiguity summary file is compressed, copy it and
##+ decompress it
REMOVE_LOCAL_COPY=NO
if test "${AMBSUM##*.}" == "Z"
then
    cp $AMBSUM .
    uncompress $AMBSUM
    ## AMBSUM is now the local, uncompressed copy
    AMBSUM=${AMBSUM/.Z/}
    AMBSUM=${AMBSUM##*/}
    REMOVE_LOCAL_COPY=YES
    if ! test -f $AMBSUM
    then
        echoerr "ERROR. Could not make local copy of $1"
        exit 1
    fi
fi

## GPS
## ////////////////////////////////////////////////////////////////////////////
## Get number of unique baselines for GPS
NUM_OF_GPS_BSL=`cat $AMBSUM | awk 'BEGIN {sum=0} \
  /#AR_((NL)|(L3)|(QIF)|(L12))/ { if ( $9=="G" && $1=="Tot:" ) {sum+=$2} } \
  END {print sum}'`

## Eport data for GPS; only unique baselines
## Station1 Station2 Length Resolution(%)
cat $AMBSUM | awk '/#AR_((NL)|(L3)|(QIF)|(L12))/ {if( $10=="G" && $1!="Tot:")\
  {print $2,$3,$4,$9,"G"} }' | sort -nk3 > .bsl.g.dat

## See that the data are extracted correctly
if [ "$?" -ne 0 ]
then
    echoerr "*** ERROR! Unable to extract data from file $1 (GPS)"
    clear_temp
    exit 1
fi

## Final check; collected record lines must match number of baselines
RECORDS=`cat .bsl.g.dat | wc -l`
if test $RECORDS -ne $NUM_OF_GPS_BSL
then
    echoerr "## Failed to collect correct number of baselines records\
        from file $1 (GPS)"
    clear_temp
    exit 1
#else
#    echo "## Number of GPS baselines: $RECORDS"
fi
GPS_NR=$RECORDS

## compute averages
if test "$GPS_NR" -gt 0
then
    AVG_GPS=`awk 'BEGIN{avg_l=0; avg_r=0} \
        {avg_l+=$3; avg_r+=$4} \
        END{printf ("%5.1f %5.1f",avg_l/NR,avg_r/NR)}' \
        .bsl.g.dat `
    AVG_G_LENGTH=`echo $AVG_GPS | awk '{print $1}'`
    AVG_G_RESOLVED=`echo $AVG_GPS | awk '{print $2}'`
else
    AVG_G_LENGTH=0
    AVG_G_RESOLVED=0
fi

## GLONASS
## ////////////////////////////////////////////////////////////////////////////
## Get number of unique baselines for GLONASS
NUM_OF_GLO_BSL=`cat $AMBSUM | awk 'BEGIN {sum=0} \
  /#AR_((NL)|(L3)|(QIF)|(L12))/ { if ( $9=="R" && $1=="Tot:" ) {sum+=$2} } \
  END {print sum}'`

## Eport data for GLO; only unique baselines
## Station1 Station2 Length Resolution(%)
cat $AMBSUM | awk '/#AR_((NL)|(L3)|(QIF)|(L12))/ {if( $10=="R" && $1!="Tot:")\
  {print $2,$3,$4,$9,"R"} }' | sort -nk3 > .bsl.r.dat

## See that the data are extracted correctly
if [ "$?" -ne 0 ]
then
    echoerr "*** ERROR! Unable to extract data from file $1 (GLO)"
    clear_temp
    exit 1
fi

## Final check; collected record lines must match number of baselines
RECORDS=`cat .bsl.r.dat | wc -l`
if test $RECORDS -ne $NUM_OF_GLO_BSL
then
    echoerr "## Failed to collect correct number of baselines records\
        from file $1 (GLO)"
    clear_temp
    exit 1
#else
#    echo "## Number of GLO baselines: $RECORDS"
fi
GLO_NR=$RECORDS

## compute averages
if test "$GLO_NR" -gt 0
then
    AVG_GLO=`awk 'BEGIN{avg_l=0; avg_r=0} \
        {avg_l+=$3; avg_r+=$4} \
        END{printf ("%5.1f %5.1f",avg_l/NR,avg_r/NR)}' \
        .bsl.r.dat `
    AVG_R_LENGTH=`echo $AVG_GLO | awk '{print $1}'`
    AVG_R_RESOLVED=`echo $AVG_GLO | awk '{print $2}'`
else
    AVG_R_LENGTH=0
    AVG_R_RESOLVED=0
fi

## MIXED
## ////////////////////////////////////////////////////////////////////////////
## Get number of unique baselines for MIXED (GPS+GLONASS)
if test "$GPS_NR" -ge "$GLO_NR"
then
    NUM_OF_MXD_BSL=$GLO_NR
else
    NUM_OF_MXD_BSL=$GPS_NR
fi

## Eport data for MIXED; only unique baselines
## Station1 Station2 Length Resolution(%)
cat $AMBSUM | awk '/#AR_((NL)|(L3)|(QIF)|(L12))/ { if($10=="GR" && $1!="Tot:")\
  {print $2,$3,$4,$9,"M"} }' | sort -nk3 > .bsl.m.dat

## See that the data are extracted correctly
if [ "$?" -ne 0 ]
then
    echoerr "*** ERROR! Unable to extract data from file $1 (MIXED)"
    clear_temp
    exit 1
fi

## Final check; collected record lines must match number of baselines
RECORDS=`cat .bsl.m.dat | wc -l`
if test $RECORDS -ne $NUM_OF_MXD_BSL
then
    echoerr "## Failed to collect correct number of baselines records\
        from file $1 (MIXED)"
    clear_temp
    exit 1
#else
#    echo "## Number of MIXED baselines: $RECORDS"
fi
MXD_NR=$RECORDS

## compute averages
if test "$MXD_NR" -gt 0
then
    AVG_MXD=`awk 'BEGIN{avg_l=0; avg_r=0} \
        {avg_l+=$3; avg_r+=$4} \
        END{printf ("%5.1f %5.1f",avg_l/NR,avg_r/NR)}' \
        .bsl.m.dat `
    AVG_M_LENGTH=`echo $AVG_MXD | awk '{print $1}'`
    AVG_M_RESOLVED=`echo $AVG_MXD | awk '{print $2}'`
else
    AVG_M_LENGTH=0
    AVG_M_RESOLVED=0
fi

## We are ready to print the results; one more thing to do:
## Should we also report the stations coordinates?
REPORT_CRD=NO
if test "$#" -ge 2
then
    if test -f $2
    then
        CRDFILE=$2
        REPORT_CRD=YES
    else
        echoerr "ERROR. Cannot locate coordinate file $2"
        clear_temp
        exit 1
    fi
fi

##  If we want to report coordinates, then read each line from the
##+ temp files (.bsl.[rgm].dat) and populate the files with the
##+ coordinates
if test "$REPORT_CRD" == "YES"
then
    > .bsl.grm.dat
    for file in .bsl.g.dat .bsl.r.dat .bsl.m.dat
    do
        while read line; do
            sta1=`echo $line | awk '{print $1}'`
            sta2=`echo $line | awk '{print $2}'`
            xyz1=`grep $sta1 $CRDFILE | awk '{print $3,$4,$5}' 2>/dev/null`
            wil=`echo "$xyz1" | wc -w`
            if test "$wil" -ne 3; then
                echoerr "ERROR. Unable to find coordinates for station $sta1"
                clear_temp
                exit 1
            fi
            flh1=`echo $xyz1 | xyz2flh -ud | awk '{ print $6,$7 }'` 2>/dev/null
            wil=`echo "$flh1" | wc -w`
            if test "$wil" -ne 2; then
                echoerr "ERROR. Unable to transform coordinates for station $sta1"
                clear_temp
                exit 1
            fi
            xyz2=`grep $sta2 $CRDFILE | awk '{print $3,$4,$5}' 2>/dev/null`
            wil=`echo "$xyz1" | wc -w`
            if test "$wil" -ne 3; then
                echoerr "ERROR. Unable to find coordinates for station $sta2"
                clear_temp
                exit 1
            fi
            flh2=`echo $xyz2 | xyz2flh -ud | awk '{ print $6,$7 }'` 2>/dev/null
            wil=`echo "$flh2" | wc -w`
            if test "$wil" -ne 2; then
                echoerr "ERROR. Unable to transform coordinates for station $sta2"
                clear_temp
                exit 1
            fi
            echo $line $flh1 $flh2 >> .bsl.grm.dat
        done <$file
    done
fi

## Write to stdout all collected baselines
echo "## Number of GPS baselines: $GPS_NR average length $AVG_G_LENGTH average amb. resolved $AVG_G_RESOLVED"
echo "## Number of GLO baselines: $GLO_NR average length $AVG_R_LENGTH average amb. resolved $AVG_R_RESOLVED"
echo "## Number of MXD baselines: $MXD_NR average length $AVG_M_LENGTH average amb. resolved $AVG_M_RESOLVED"

## Write (to stdout) either with coordinates or not
if test "$REPORT_CRD" == "YES"
then
    cat .bsl.grm.dat | sort
else
    cat .bsl.g.dat .bsl.r.dat .bsl.m.dat | sort
fi

## clear temporary files
clear_temp

## if needed, remove the mbiguity file
if test "${REMOVE_LOCAL_COPY}" == "YES"
then
    rm $AMBSUM
fi

## exit with sucess
exit 0;

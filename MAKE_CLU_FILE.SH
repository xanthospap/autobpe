#! /bin/bash

#
# CREATE A .CLU FILE FOR A GIVEN DATE (YEAR DOY) AND CAMPAIGN
#

# //////////////////////////////////////////////////////////////////////////////
# HELP FUNCTION
# //////////////////////////////////////////////////////////////////////////////
function help {

	echo "/******************************************************************************************/"
	echo " Program Name : MAKE_CLU_FILE.SH"
	echo " Version : v-1.0"
	echo " Purpose : Make a cluster file for Bern52 double-difference processing"
	echo " Usage   : MAKE_CLU_FILE.SH -y YEAR -d DOY -c CAMPAIGN [-s STATIONS_PER_CLUSTER]"
	echo " Switches:"
	echo "           -y [:=year] specify year"
	echo "           -d [:=doy] specify doy"
	echo "           -c [:=campaign] specify campaign"
	echo "           -s [:=stations] set the number of stations per cluster"
	echo "           -i [:igs domes] augment the name of station using the domes nr"
	echo ""
	echo " Notes   : The script will automatically load the file /home/bpe2/bern52/BERN52/GPS/EXE/LOADGPS.setvar"
	echo "           where all the Bernese-depedent variables are supposed to be. Therefore,"
	echo "           the directory ${P}/${GIVEN_CAMPAIGN_NAME} must exist. Also, the script will create"
	echo "           the clusters using all stations found in ${P}/${GIVEN_CAMPAIGN_NAME}/RAW directory"
	echo " Exit Status: > 0 -> OK (number of clusters)"
	echo " Exit Status: < 0 -> Error"
	echo "/******************************************************************************************/"

exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# TRUNCATE A NUMBER BETWEEN 0-999 TO 3 DIGITS (e.g. 95 to 095)
# //////////////////////////////////////////////////////////////////////////////
function truncate {

if [ $# -ne 1 ]
then
        echo "*** Error; no number given to translate! fun->truncate()"
        exit -2
fi

num=$1

if [ $num -lt 100 ]; then
        if [ $num -lt 10 ]; then
                echo "00$num"
        else
                echo "0$num"
        fi
else
        echo "$num"
fi

exit 0;
}

# //////////////////////////////////////////////////////////////////////////////
# PRE_DEFINE COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
STA_PER_CLU=5
USE_DOMES=NO

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then
	help
	exit -1
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
                        DOY=`echo $2 | sed 's/^0*//'`
                        shift
                        shift
                        ;;
                -c)
                        CAMPAIGN=`echo ${2} | tr 'a-z' 'A-Z'`
                        shift
                        shift
                        ;;
		-s)
			STA_PER_CLU=${2}
			shift
			shift
			;;
		-h)
			help
			exit 0
			;;
		-i)     USE_DOMES=YES
			shift
			;;
		*)
			echo "## Ignoring cmd argument $1"
			shift
			;;
	esac
done

# //////////////////////////////////////////////////////////////////////////////
# SET PATH !!
# //////////////////////////////////////////////////////////////////////////////
export PATH=${PATH}:/home/bpe2/src52

# //////////////////////////////////////////////////////////////////////////////
# BERNESE-52 VARIABLES
# //////////////////////////////////////////////////////////////////////////////
source /home/bpe2/bern52/BERN52/GPS/EXE/LOADGPS.setvar

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT YEAR IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $YEAR -lt 1950 ] || [ $YEAR -gt 2014 ]
then
        echo "*** Need to provide a valid year [1950-2014]"
        exit -1
fi
YR2=${YEAR:(-2)}

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT DOY IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]
then
        echo "*** Need to provide a valid doy [1-366]"
        exit -1
fi
DOY=`truncate $DOY`

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT CAMPAIGN EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d "${P}/${CAMPAIGN}/STA" ]; then
	echo "*** ERROR! Campaign directory: ${P}/${CAMPAIGN}/STA does not exist!"
	exit -1
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT THE STA_PER_CLU IS NUMERIC
# //////////////////////////////////////////////////////////////////////////////
if [ "$STA_PER_CLU" -ne "$STA_PER_CLU" ] 2>/dev/null; then
	echo "*** ERROR! Stations per cluster bad value!"
	exit -1
fi

if [ $USE_DOMES = "NO" ]; then
# //////////////////////////////////////////////////////////////////////////////
# GET LIST OF RINEX FILES (NO DOMES)
# //////////////////////////////////////////////////////////////////////////////
NPWD=`pwd`
cd ${P}/${CAMPAIGN}/RAW
rnx_list=`ls ????${DOY}0.${YR2}O`
if [ "${#rnx_list[@]}" -eq 0 ]; then
	echo "*** ERROR! Zero rinex found! Cannot make rinex cluster"
	cd $NPWD
	exit -1
fi
echo "Example for a station cluster file                               18-OCT-03 15:14"
echo "--------------------------------------------------------------------------------"
echo
echo "STATION NAME      CLU"
echo "****************  ***"
ALL_RINEX=`ls ????${DOY}0.${YR2}O | wc -l`
if [ "$ALL_RINEX" -eq 0 ]; then
	echo "*** ERROR! No rinex files found to create .CLU file!";
	exit -1
fi
RNX_COUNTER=1
CLUSTER=1
for j in ${rnx_list[*]}; do
	echo "${j:0:4}                ${CLUSTER}"
	let RNX_COUNTER=RNX_COUNTER+1
	if [ "$RNX_COUNTER" -gt "$STA_PER_CLU" ]; then
		RNX_COUNTER=0
		let CLUSTER=CLUSTER+1
	fi
done
cd $NPWD

else

# //////////////////////////////////////////////////////////////////////////////
# GET LIST OF RINEX FILES (USE DOMES)
# //////////////////////////////////////////////////////////////////////////////
NPWD=`pwd`
cd ${P}/${CAMPAIGN}/RAW
rnx_list=`ls ????${DOY}0.${YR2}O`
if [ "${#rnx_list[@]}" -eq 0 ]; then
        echo "*** ERROR! Zero rinex found! Cannot make rinex cluster"
        cd $NPWD
        exit -1
fi
echo "Example for a station cluster file                               18-OCT-03 15:14"
echo "--------------------------------------------------------------------------------"
echo
echo "STATION NAME      CLU"
echo "****************  ***"
ALL_RINEX=`ls ????${DOY}0.${YR2}O | wc -l`
if [ "$ALL_RINEX" -eq 0 ]; then
        echo "*** ERROR! No rinex files found to create .CLU file!";
        exit -1
fi
RNX_COUNTER=1
CLUSTER=1
for j in ${rnx_list[*]}; do
	domes=$(grep -i ${j:0:4} /home/bpe2/crd/ALL.CRD | head -1 | awk '{print $2}')
        echo "${j:0:4} $domes    ${CLUSTER}"
        let RNX_COUNTER=RNX_COUNTER+1
        if [ "$RNX_COUNTER" -gt "$STA_PER_CLU" ]; then
                RNX_COUNTER=0
                let CLUSTER=CLUSTER+1
        fi
done
cd $NPWD

fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
EXIT_STATUS=$CLUSTER
exit $EXIT_STATUS

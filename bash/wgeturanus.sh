#! /bin/bash


################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgeturanus.sh
                           NAME=wgeturanus
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : APR-2013
## usage                 : wgeturanus.sh
## exit code(s)          : >=0 -> success (actual number of stations downloaded)
##                       :  -1 -> error
##                       :  -2 -> error (no stations to download)
## discription           : downloads URANUS rinex files.
## dependancies          : the python library bpepy.gpstime must be installed and
##                         set in the python path variable.
## uses                  : wget, cat, hash, awk, sed
## notes                 : this is a newer version of the script downloadigs.sh
## TODO                  : -u switch does not work
##                         If a rinex is already here (and -r is not turned on) then
##                         this file will not be downloaded but the station counter
##                         will be augmented. So far all good. HOWEVER, if -x
##                         is set the (already present) file will not have its header
##                         fixed! This needs to be corrected.
## detailed update list  : DEC-2013 corrected exit codes
##                       : OCT-2014
##                       : NOV-2014 major revision
                           LAST_UPDATE=NOV-2014
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
function help {
  echo "/******************************************************************************************/"
  echo " Program Name : wgeturanus.sh"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Download URANUS stations rinex files for a specific date."
  echo ""
  echo " Usage   : wgeturanus.sh [-s [station1] [station2] [...] | -f [station file]] -y [year] -d [doy] {-o [output directory] | -m [max stations] | -r}"
  echo ""
  echo " Switches: "
  echo "           -p --print-stations print stations and exit"
  echo "           -l --table-file specify the station information table; default uranus.tbl"
  echo "           -u --uranus-id by default the script will recognize stations by their"
  echo "            4-char id given by ntua. If the stations are to be specified by their"
  echo "            uranus id (column 3 of the uranus table file) then this switch should be used"
  echo "           -s --stations specify stations to download seperated by "
  echo "            whitespace (e.g -s penc pdel ...) (*)"
  echo "           -f --station-file give a file specifying stations to be downloaded"
  echo "            File must have one line, where each station is seperated"
  echo "            by a whitespace character.(*)"
  echo "           -y --year 4-digit year of date to download (e.g. -y 2010)"
  echo "           -d --doy day of year [1-366] to download (e.g. -d 35)"
  echo "           -o --output-directory directory to save rinex files. Can be"
  echo "            either relative or absolute path not followed by / (e.g. /home/bpe/data)"
  echo "           -m --max-stations total number of allowed stations. Only a total"
  echo "            of max_stations will be downloaded. If more stations are specified"
  echo "            they will be skipped if max_stations is reached (e.g. -m 15)"
  echo "           -r --force-remove if a file is found with the same name as the one"
  echo "            to be downloaded, it will be deleted before downloading (e.g. -d)"
  echo "           -h --help display (this) help message and exit"
  echo "           -z --decompress decompress the downloaded rinex files"
  echo "           -x --fix-header fix header (MARKER NAME) to match the stations"
  echo "            4-char id"
  echo "           -n --upper-case rename (truncate) all downloaded files to capital letters"
  echo "           -q --quiet supress all mesagges"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-2 -> no stations to download provided"
  echo " Exit Status:255-1 -> error"
  echo " Exit Status: >= 0 -> sucesseful exit (actual number of stations downloaded if # stations < 255)"
  echo ""
  echo "(*) In case both -s and -f switches are used, the order of the stations is first"
  echo "the -s stations and then the -f ones (e.g > wgetigsrnx -s sta1 sta2 -f filename ..."
  echo "and filename has stations sta3 sta4, then the list of stations to download will be:"
  echo "sta1 sta2 sta3 sta4). The order of stations is crucial when the -m switch is specified."
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
# GLOBAL VARIABLES
# //////////////////////////////////////////////////////////////////////////////
MAX_URANUS_STA=  ## maximum number of Uranus stations in server
MAX_2_DWNL=      ## maximum number of uranus stations to download
URANUS_TBL=uranus.tbl  ## the Uranus table file
URAURL=ftp://79.129.26.12/Rinex_URANUS
usern=ntua
passw=satm
FIX_RNX_NAME=0   ## fix the marker name (in header) to match the one in the tbl file
YEAR=-1900       ## year
YR2=00           ## last two digits of year
DOY=0            ## day of year
STARRAY=()       ## array of igs stations
OUTDIR=$(pwd)    ## directory to save rinex files
NUMOFTRIES=3     ## number of tries for wget
STACOUNTER=0     ## number of stations actualy downloaded
DOWNLOADED=0     ## flag to mark if a specific rinex has been downloaded
NUMOFST=0        ## total number of stations to download
MAXST=0          ## max number of stations to download (all stations after this 
                 ## number is reached will not be downloaded)
FORCE=0          ## delete any other rinex file with the same name already in the dir
STFILE=0         ## filename of the station file
DECOMP=0         ## decompress the rinex files
PRINT_STATIONS=0 ## print stations and exit
USE_URA_NAME=0   ## use uranus 4-char id
TRUNCATE=NO      ## truncate to upper case
QUIET=NO         ## supress messages

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then
  help
  exit 254
fi

while [ $# -gt 0 ]
do
  case "$1" in
    -s|--stations)
      shift
      while [ $# -gt 0 ]
      do
        j=$1
        if [ ${j:0:1} == "-" ]
        then
          break
        else
          STARRAY+=($j)
          shift
        fi
      done
      ;;
    -y|--year)
      YEAR=${2}
      shift
      shift
      ;;
    -d|--doy)
      DOY=`echo $2 | sed 's/^0*//'`
      shift
      shift
      ;;
    -o|--output-directory)
      OUTDIR=${2}
      shift
      shift
      ;;
    -m|--max-stations)
      MAXST=${2}
      shift
      shift
      ;;
    -r|--force-remove)
      FORCE=1
      shift
      ;;
    -h|--help)
      help
      ;;
    -f|--station-file)
      STFILE=${2}
      shift
      shift
      ;;
    -u|--uranus-id)
      USE_URA_NAME=1
      shift
      ;;
    -z|--decompress)
      DECOMP=1
      shift
      ;;
    -p|--print-stations)
      PRINT_STATIONS=1
      shift
      ;;
    -l|--table-file)
      URANUS_TBL=$2
      shift
      shift
      ;;
    -x|--fix-header)
      FIX_RNX_NAME=1
      shift
      ;;
    -n|--upper-case)
      TRUNCATE=YES
      shift
      ;;
    -v|--version)
      dversion
      ;;
  esac
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT TBL FILE EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -f $URANUS_TBL ]; then
  echo "Table file: $URANUS_TBL does not exist"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# PRINT STATIONS AND EXIT
# //////////////////////////////////////////////////////////////////////////////
if [ "$PRINT_STATIONS" -eq 1 ]; then
  cat $URANUS_TBL
  exit 0
fi

# //////////////////////////////////////////////////////////////////////////////
# IF FILE IS GIVEN, ADD ITS ENTRIES TO THE STATION LIST
# //////////////////////////////////////////////////////////////////////////////
if [ "$STFILE" != "0" ]; then
  if [ -f "$STFILE" ];   then
    TEMPARRAY=( $( cat "$STFILE" ) )
    for j in ${TEMPARRAY[*]}; do
      STARRAY+=($j)
    done
  else
    if [ $QUIET == "NO" ]; then echo "*** File ${STFILE} does not exist!"; fi
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT STATION LIST IS NOT EMPTY
# //////////////////////////////////////////////////////////////////////////////
if [ ${#STARRAY[*]} -eq 0 ]; then
  echo "*** Need to provide at least one URANUS station"
  exit 254
fi
NUMOFST=${#STARRAY[*]}

# //////////////////////////////////////////////////////////////////////////////
# CHECK IF MAX STATIONS IS SET, ELSE SET IT TO NUMBER OF STATIONS IN LIST
# //////////////////////////////////////////////////////////////////////////////
if [ "$MAXST" -eq 0 ]
then
  MAXST=$NUMOFST
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT YEAR AND IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $YEAR -lt 1950 ]; then
  echo "*** Need to provide a valid year [>1950]"
  exit 254
fi
YR2=${YEAR:2:2}
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]; then
  echo "*** Need to provide a valid doy [1-366]"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# MAKE DOY A 3-DIGIT NUMBER
# //////////////////////////////////////////////////////////////////////////////
if [ $DOY -lt 10 ]; then DOY=00${DOY}
elif [ $DOY -lt 100 ]; then DOY=0${DOY}
else DOY=${DOY}
fi

# //////////////////////////////////////////////////////////////////////////////
# IF OUTPUT DIR GIVEN, SEE THAT IT EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $OUTDIR ]; then
  echo "*** Directory $OUTDIR does not exist!"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# IF DECOMPRESS IS CALLED, CHECK THAT uncompress EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$DECOMP" -eq 1 ]; then
  hash uncompress 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    if [ $QUIET == "NO" ]; then echo "*** Asked for decompress but programm <uncompress> is not available"; fi
    if [ $QUIET == "NO" ]; then echo "*** Rinex files will not be decompressed"; fi
    DECOMP=0
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# IF WE ARE GOING TO FIX THE MARKER NAME, DECOMPRESS MUST BE CALLED
# //////////////////////////////////////////////////////////////////////////////
if [ "$FIX_RNX_NAME" -eq 1 -a "$DECOMP" -eq 0 ]; then
  if [ $QUIET == "NO" ]; then echo "Rinex files are going to be decompressed in order to fix marker name!"; fi
  DECOMP=1
fi

# //////////////////////////////////////////////////////////////////////////////
# STORE TODAY AND GIVEN DATE IN SHELL VARIABLES AND FIND DIFFERENCE IN DAYS
# //////////////////////////////////////////////////////////////////////////////
_DOY_=`echo $DOY | sed 's/^0*//'`
MD=`python -c "import bpepy.gpstime; m,d = bpepy.gpstime.yd2month($YEAR,$_DOY_); print '%02i %02i' %(m,d)"`
MONTH=`echo $MD | awk '{print $1}'`
ODM=`echo $MONTH | sed 's/^0*//'`
DOM=`echo $MD | awk '{print $2}'`
MONTHS=(Nan Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
SMONTH=${MONTHS[$ODM]}

# //////////////////////////////////////////////////////////////////////////////
# FOR EVERY STATION IN DOWNLOAD LIST
# //////////////////////////////////////////////////////////////////////////////
for station in ${STARRAY[*]}; do

  STATION=`echo $station | tr 'a-z' 'A-Z'`
  STA_FOUND_IN_TBL=NO

  LC=`grep "$station *$" $URANUS_TBL | wc -l`
  if [ $LC -gt 1 ]; then
    echo "*** Multiple lines found to match station $station; fatal!"
    exit 254
  elif [ $LC -eq 0 ]; then
    if [ $QUIET == "NO" ]; then echo "--- Station $station not found in $URANUS_TBL file; skiped"; fi
  else
    STA_FOUND_IN_TBL=YES
    LINE=`grep "$station *$" $URANUS_TBL 2>/dev/null`
    FULL_STA_NAME=`echo "$LINE" | awk '{print substr($0,5,15)}' | sed 's|^ *||g'`
    URA_ID=`echo "$LINE" | awk '{print substr($0,21,4)}'`
    DSO_ID=$station;
    # file to save with no ending char(s)
    f2s=${OUTDIR}/${URA_ID}${DOY}0.${YR2}
    F2S=${OUTDIR}/`echo ${URA_ID} | tr 'a-z' 'A-Z'`${DOY}0.${YR2}
  fi

  # only try to download if station is found in the table file
  if [ "$STA_FOUND_IN_TBL" == "YES" ]; then

    # only try to download if max number of stations not reached
    if [ "$STACOUNTER" -lt "$MAXST" ]; then

      # if flag is set, force delete any previous rinex with same name
      if [ "$FORCE" -eq 1 ]; then
        if [ -f ${f2s}o ]; then #check and remove rinex if it exists
          rm -f ${f2s}o
        fi
        if [ -f ${f2s}d ]; then #check and remove Hatanaka if it exists
          rm -f ${f2s}d
        fi
        if [ "$DECOMP" -eq 1 ]; then #check and remove Hatanaka compressed if it exists
          if [ -f ${f2s}d.Z ]; then
            rm -f ${f}
          fi
        fi
      fi ##if [ "$FORCE" -eq 1 ]

      PROCED_TO_DOWNLOAD=YES ## if the file already exists, this will be set to "NO"
      # check to see if the file already exists, either as Hatanaka (compressed or not) or as rinex
      if [ -f ${f2s}d.Z ]; then # the compressed Hatanaka version exists
        if [ $QUIET == "NO" ]; then echo "File ${f2s}d.Z exists as Hatanaka compressed"; fi
        if [ "$DECOMP" -eq 1 ]; then
          uncompress ${f2s}d.Z
        fi
        PROCED_TO_DOWNLOAD=NO
      fi
      if [ -f ${f2s}d ]; then # the uncompressed Hatanaka version exists
        if [ $QUIET == "NO" ]; then echo "File ${f2s}d exists as Hatanaka uncompressed"; fi
        if [ "$DECOMP" -ne 1 ]; then
          compress ${f2s}d
        fi
        PROCED_TO_DOWNLOAD=NO
      fi
      if [ -f ${f2s}o ]; then # the rinex version exists
        if [ $QUIET == "NO" ]; then echo "File ${f2s}o exists as rinex"; fi
        PROCED_TO_DOWNLOAD=NO
      fi

      # check to see if the file already exists, either as Hatanaka (compressed or not) or as rinex UPPER CASE
      if [[ $TRUNCATE == "YES" && $PROCED_TO_DOWNLOAD == "YES" ]]; then
        if [ -f ${F2S}D.Z ]; then # the compressed Hatanaka version exists
          if [ $QUIET == "NO" ]; then echo "File ${F2S}D.Z exists as Hatanaka compressed"; fi
          if [ "$DECOMP" -eq 1 ]; then
            uncompress ${F2S}D.Z
          fi
          PROCED_TO_DOWNLOAD=NO
        fi
        if [ -f ${F2S}D ]; then # the uncompressed Hatanaka version exists
          if [ $QUIET == "NO" ]; then echo "File ${F2S}D exists as Hatanaka uncompressed"; fi
          if [ "$DECOMP" -ne 1 ]; then
            compress ${F2S}D
          fi
          PROCED_TO_DOWNLOAD=NO
        fi
        if [ -f ${F2S}O ]; then # the rinex version exists
          if [ $QUIET == "NO" ]; then echo "File ${F2S}O exists as rinex"; fi
          PROCED_TO_DOWNLOAD=NO
        fi
      fi ##if [ $TRUNCATE == "YES" ]

      if [ ${PROCED_TO_DOWNLOAD} == "NO" ]; then ## do not proceed to download; file available
        let STACOUNTER=STACOUNTER+1

      else ## preceed to download
        # assume file is not downloaded
        DOWNLOADED=0
        # file to download
        f2d=${URAURL}/${FULL_STA_NAME}/${YEAR}/${SMONTH}/${DOM}/${URA_ID}${DOY}0.${YR2}d.Z
        # file to save
        f2s=${f2s}d.Z
        # try to download
        wget -nc --tries="$NUMOFTRIES" --ftp-user=ntua --ftp-password=satm -q -O \
              ${f2s} ${f2d}
        # check the exit status of wget
        if [ "$?" -ne 0 ]; then
          if [ $QUIET == "NO" ]; then echo "## Station $station could not be downloaded"; fi
          rm -f $f2s 2>/dev/null ## remove empty file if any
          DOWNLOADED=0
        else
          DOWNLOADED=1
        fi

        # if station downloaded, augment counter
        if [ "$DOWNLOADED" -eq 1 ]; then
          let STACOUNTER=STACOUNTER+1
          if [ $QUIET == "NO" ]; then echo "Station $station downloaded"; fi    

          # if decompressed called and file is compressed, uncompress the file
          if [ "$DECOMP" -eq 1 ]; then
            uncompress $f2s 2>/dev/null
          fi

          # if station name is different in rinex header change rinex header
          if [ "$FIX_RNX_NAME" -eq 1 ]; then
            HEADER_NAME=$(grep "MARKER NAME" ${OUTDIR}/${DSO_ID}${DOY}0.${YR2}d | awk '{print $1}')
            if [ "$HEADER_NAME" != "$STATION" ]; then
              if [ $QUIET == "NO" ]; then echo "Changing marker name from $HEADER_NAME to $STATION"; fi
              L2C=$(grep "MARKER NAME" ${OUTDIR}/${DSO_ID}${DOY}0.${YR2}d)
              L2P="$STATION                                                        MARKER NAME"
              sed -i "s|${L2C}|${L2P}|g" ${OUTDIR}/${DSO_ID}${DOY}0.${YR2}d
            fi
          fi

          # truncate name if needed
          if [ $TRUNCATE == "YES" ]; then
            CAPITAL_ID=`echo $DSO_ID | tr 'a-z' 'A-Z'`
            mv ${OUTDIR}/${DSO_ID}${DOY}0.${YR2}d ${OUTDIR}/${CAPITAL_ID}${DOY}0.${YR2}D 2>/dev/null
            mv ${OUTDIR}/${DSO_ID}${DOY}0.${YR2}d.Z ${OUTDIR}/${CAPITAL_ID}${DOY}0.${YR2}D.Z 2>/dev/null
          fi

        fi ## if [ "$DOWNLOADED" -eq 1 ]

      fi ##if [ ${PROCED_TO_DOWNLOAD} == "NO" ]

    else ##if [ "$STACOUNTER" -lt "$MAXST" ]
      if [ $QUIET == "NO" ]; then echo "Max number of stations reached! Skipping station $station"; fi

    fi ##if [ "$STACOUNTER" -lt "$MAXST" ]

  fi ##if [ "$STA_FOUND_IN_TBL" == "YES" ]

done ##for station in ${STARRAY[*]}

# //////////////////////////////////////////////////////////////////////////////
# PRINT NUMBER OF STATIONS DOWNLOADED
# //////////////////////////////////////////////////////////////////////////////
if [ $QUIET == "NO" ]; then echo "Downloaded $STACOUNTER / $NUMOFST stations"; fi

# //////////////////////////////////////////////////////////////////////////////
# SUCESEFUL EXIT
# //////////////////////////////////////////////////////////////////////////////
exit $STACOUNTER;

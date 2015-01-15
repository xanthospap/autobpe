 #! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgetepnrnx.sh
                           NAME=wgetepnrnx
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAY-2013
## usage                 : wgetepnrnx.sh
## exit code(s)          : >=0 -> success
##                       :  254 -> error
##                       :  253 -> error (no stations to download)
## discription           : downloads euref rinex files. All names 
##                         are truncated to capital letters.
## uses                  : wget, pwd, stat, hash
## notes                 : updating version of wgetigsrnx.sh for EPN stations
##                         Updated lists of EPN stations can be found at:
##                         ftp://igs.bkg.bund.de/EUREF/station/
## TODO                  :
## detailed update list  : DEC-2013 corrected exit codes
##                         NOV-2014 major revision
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
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************************/"
  echo " Program Name : wgetepnrnx.sh"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : Download EUREF(EPN) stations rinex files for a specific date."
  echo ""
  echo " Usage   : wgetepnrnx.sh [-s [station1] [station2] [...] | -f [station file]] -y [year] -d [doy] {-o [output directory] | -m [max stations] | -r}"
  echo ""
  echo " Switches: "
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
  echo "            to be downloaded, it will be deleted before downloading."
  echo "           -h --help display (this) help message and exit"
  echo "           -z --decompress decompress the downloaded rinex files"
  echo "           -n --upper-case rename (truncate) all downloaded files to capital letters"
  echo "           -q --quiet supress all mesagges"
  echo " [OBSOLETE]-t [:= file size] if -r switch is not given, then remove all files same as the"
  echo "            ones to be downloaded if their size is smaller than <file size> in bytes"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status: 255-2 -> no stations to download provided"
  echo " Exit Status: 255-1 -> error"
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
# CHECK IF A PROGRAM EXISTS; RETURNS 0 IN CASE THE PROGRAM EXISTS
# //////////////////////////////////////////////////////////////////////////////
function progexists {
  if [ $# -ne 1 ]
  then
    echo "*** Error; no program name given to test! fun->prgexists()"
    exit 254
  fi

  prog=$1

  hash "$prog" 2>/dev/null

  echo "$?"

  exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
YEAR=-1900    ## year
YR2=00        ## last two digits of year
DOY=0         ## day of year
STARRAY=()    ## array of igs stations
OUTDIR=$(pwd) ## directory to save rinex files
EPNURL1=ftp://igs.bkg.bund.de/EUREF/obs            ## url for euref rinex files
#EPNURL2=ftp://cddis.gsfc.nasa.gov/gps/data/daily/  ## url for euref rinex files
EPNURL2=ftp://olggps.oeaw.ac.at/pub                ## url for euref rinex files
NUMOFTRIES=3  ## number of tries for wget
STACOUNTER=0  ## number of stations actualy downloaded
DOWNLOADED=0  ## flag to mark if a specific rinex has been downloaded
NUMOFST=0     ## total number of stations to download
MAXST=0       ## max number of stations to download (all stations after this 
              ## number is reached will not be downloaded)
FORCE=0       ## delete any other rinex file with the same name already in the dir
STFILE=0      ## filename of the station file
DECOMP=0      ## decompress the rinex files
CSIZE=-1      ## size limit to delete already existing rinex files
TRUNCATE=NO   ## truncate to upper case
QUIET=NO      ## supress messages

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then
  help
  exit 0
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
    -z|--decompress)
      DECOMP=1
      shift
      ;;
    -t|--max-size)
      if [ $QUIET == "NO" ]; then echo "WARNING! -t switch is obsolete and will be ignored."; fi
      shift
      shift
      ;;
    -n|--upper-case)
      TRUNCATE=YES
      shift
      ;;
    -q|--quiet)
      QUIET=YES
      shift
      ;;
    -v|--version)
      dversion
      ;;
  esac
done

# //////////////////////////////////////////////////////////////////////////////
# IF FILE IS GIVEN, ADD ITS ENTRIES TO THE STATION LIST
# //////////////////////////////////////////////////////////////////////////////
if [ "$STFILE" != "0" ]
then
  if [ -f "$STFILE" ]
  then
    TEMPARRAY=( $( cat "$STFILE" ) )
    for j in ${TEMPARRAY[*]}
    do
      STARRAY+=($j)
    done
  else
    if [ $QUIET == "NO" ]; then echo "*** File ${STFILE} does not exist!"; fi
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT STATION LIST IS NOT EMPTY
# //////////////////////////////////////////////////////////////////////////////
if [ ${#STARRAY[*]} -eq 0 ]
then
  if [ $QUIET == "NO" ]; then echo "*** Need to provide at least one IGS station"; fi
  exit 253
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
# CHECK THAT YEAR AND DOY IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $YEAR -lt 1950 ]
then
  if [ $QUIET == "NO" ]; then echo "*** Need to provide a valid year [>1950]"; fi
  exit 254
fi
YR2=${YEAR:2:2}
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]
then
  if [ $QUIET == "NO" ]; then echo "*** Need to provide a valid doy [1-366]"; fi
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# IF OUTPUT DIR GIVEN, SEE THAT IT EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $OUTDIR ]
then
  if [ $QUIET == "NO" ]; then echo "*** Directory $OUTDIR does not exist!"; fi
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# MAKE DOY A 3-DIGIT NUMBER
# //////////////////////////////////////////////////////////////////////////////
if [ $DOY -lt 10 ]; 
  then DOY=00${DOY}
elif [ $DOY -lt 100 ]
  then DOY=0${DOY}
else
  DOY=${DOY}
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
# GET CURRENT YEAR
# //////////////////////////////////////////////////////////////////////////////
CYEAR=`date +%Y`

# //////////////////////////////////////////////////////////////////////////////
# DOWNLOAD EVERY IGS STATION IN LIST
# //////////////////////////////////////////////////////////////////////////////
for station in ${STARRAY[*]}; do

  # station in capital letters
  STATION=`echo $station | tr 'a-z' 'A-Z'`

  # file to save with no ending char(s)
  f2s=${OUTDIR}/${station}${DOY}0.${YR2}
  F2S=${OUTDIR}/${STATION}${DOY}0.${YR2}

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

    if [ ${PROCED_TO_DOWNLOAD} == "NO" ]; then ## do not preoceed to download; file available
      let STACOUNTER=STACOUNTER+1

    else ## preceed to download
      # assume file is not downloaded
      DOWNLOADED=0

      # try downloading from BKG
      wget -nc --tries="$NUMOFTRIES" -q -O ${OUTDIR}/${station}${DOY}0.${YR2}d.Z \
        ${EPNURL1}/${YEAR}/${DOY}/${station}${DOY}0.${YR2}d.Z
      # if station not downloaded, try OLG url
      if [ "$?" -ne 0 ]; then
        if [ $QUIET == "NO" ]; then echo "## Station $station not found in bkg; trying in olg ..."; fi
        rm -f ${OUTDIR}/${station}${DOY}0.${YR2}d.Z 2>/dev/null ## remove empty file if any
        # if requested year is the same as current, then the url for olg changes
        if [ $YEAR == $CYEAR ]; then
          EPNURL2_=${EPNURL2}/outdata/${station}
        else
          EPNURL2_=${EPNURL2}/${YEAR}/${DOY}
        fi
        wget -nc --tries="$NUMOFTRIES" -q -O ${OUTDIR}/${station}${DOY}0.${YR2}d.Z \
          ${EPNURL2_}/${station}${DOY}0.${YR2}d.Z
        # check if it is downloaded from olg
        if [ "$?" -ne 0 ]; then
          if [ $QUIET == "NO" ]; then echo "*** Station $station not found!"; fi
          rm -f ${OUTDIR}/${station}${DOY}0.${YR2}d.Z 2>/dev/null ## remove empty file if any
        else
          DOWNLOADED=1
        fi
      else
        DOWNLOADED=1
      fi ## if [ "$?" -ne 0 ]

      # if station downloaded, augment counter
      if [ "$DOWNLOADED" -eq 1 ]; then
        let STACOUNTER=STACOUNTER+1
        if [ $QUIET == "NO" ]; then echo "Station $station downloaded"; fi
          
        # if decompressed called, uncompress the file
        if [ "$DECOMP" -eq 1 ]; then
          uncompress ${OUTDIR}/${station}${DOY}0.${YR2}d.Z
        fi

        # truncate name if needed
        if [ $TRUNCATE == "YES" ]; then
          mv ${OUTDIR}/${station}${DOY}0.${YR2}d ${OUTDIR}/${STATION}${DOY}0.${YR2}D 2>/dev/null
          mv ${OUTDIR}/${station}${DOY}0.${YR2}d.Z ${OUTDIR}/${STATION}${DOY}0.${YR2}D.Z 2>/dev/null
        fi

      fi ## if [ "$DOWNLOADED" -eq 1 ]

    fi ##if [ ${PROCED_TO_DOWNLOAD} == "NO" ]

  else ##if [ "$STACOUNTER" -lt "$MAXST" ]
    if [ $QUIET == "NO" ]; then echo "Max number of stations reached! Skipping station $station"; fi

  fi ##if [ "$STACOUNTER" -lt "$MAXST" ]

done ##for station in ${STARRAY[*]}

# //////////////////////////////////////////////////////////////////////////////
# PRINT NUMBER OF STATIONS DOWNLOADED
# //////////////////////////////////////////////////////////////////////////////
if [ $QUIET == "NO" ]; then echo "Downloaded $STACOUNTER / $NUMOFST stations"; fi

# //////////////////////////////////////////////////////////////////////////////
# SUCESEFUL EXIT
# //////////////////////////////////////////////////////////////////////////////
exit $STACOUNTER;

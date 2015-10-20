#! /bin/bash

## 
##  Go and download the remote file: 
##+ ftp://epncb.oma.be/pub/station/general/excluded/exclude.${gps_week}
##+ Read it and return the (to be) excluded list of stations.
##  If one command line argument is provided, then it is assumed to be the
##+ gps week; else, if two command line arguments are provided, they are
##+ treated as year/doy. Anything else is an error.
##

usage () {
  echo "Usage: get_euref_excl_list [<gps_week> | <year> <doy>]"
}

gps_week=
year=
doy=

if test "$#" -eq 1 ; then
  if ! [[ "$1" =~ ^[0-9]+$ ]] ; then
    echo "Invalid gps week!" 1>&2
    exit 1
  else
    gps_week="${1}"
  fi
elif test "$#" -eq 2 ; then
  if ! [[ "$1" =~ ^[0-9]+$ ]] ; then
    echo "Invalid year !" 1>&2
    exit 1
  else
    year="${1}"
    echo "year set"
  fi
  if ! [[ "$2" =~ ^[0-9]+$ ]] ; then
    echo "Invalid day of year (doy) !" 1>&2
    exit 1
  else
    doy=$( echo ${2} | sed 's|^0*||g' )
    echo "doy set to $doy"
  fi
else
  echo "ERROR. Invalid Usage" 1>&2
  usage 1>&2
  exit 1
fi

if test -z "${gps_week}"; then
  gps_week="$( python - <<END
import bernutils.gpstime
import sys

exit_status=0

try:
  print bernutils.gpstime.ydoy2gps("${year}", "${doy}")[0]
except:
  print>>sys.stderr, "[Python] Error computing gpstime!"
  exit_status=1

sys.exit( exit_status )
END
)"
  if test $? -ne 0 ; then
    echo "ERROR. Failed to transform year/doy to gps week" 1>&2
    exit 1
  fi
fi

if ! wget -q -O .exclude.${gps_week} \
  ftp://epncb.oma.be/pub/station/general/excluded/excluded.${gps_week} ; then
  echo "ERROR. Failed to download file: ftp://epncb.oma.be/pub/station/general/excluded/excluded.${gps_week}" 1>&2
  rm .exclude.${gps_week} 2>/dev/null
  exit 1
else
  cat .exclude.${gps_week} | awk '{print $1,$2}'
  rm .exclude.${gps_week} 2>/dev/null
fi

exit 0

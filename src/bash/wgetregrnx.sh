#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgetregrnx.sh
                           NAME=wgetregrnx
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAY-2013
## usage                 : wgetregrnx.sh
## exit code(s)          : >=0 -> success (actual number of stations downloaded)
##                       :  -1 -> error
##                       :  -2 -> error (no stations to download)
## discription           : downloads regional rinex files.
## uses                  : wget, hash
## dependancies          : the python library bpepy.gpstime must be installed and
##                         set in the python path variable.
##                         In order to download data from the NOA2 server, the programs
##                         teqc, runpkr00 and rnx2crx must be installed and set in the
##                         PATH variable.
## notes                 : this is a newer version of the script downloadigs.sh
## TODO                  : If a rinex is already here (and -r is not turned on) then
##                         this file will not be downloaded but the station counter
##                         will be augmented. So far all good. HOWEVER, if -x
##                         is set the (already present) file will not have its header
##                         fixed! This needs to be corrected.
## detailed update list  :
##                        JUL-2013 : added stations idi1, nafp, siva, vam1, zkro
##                                   of NOA-GEIN network. These data are not placed
##                                   in the NOA server!
##                        JUL-2013 : station pylo of NOA-GEIN netowk is translated to
##                                   pyl2 to differ from IPGP pylo station
##                        DEC-2013 : corrected exit codes
##                        JUL-2014 : added station voli for NOA-GEIN
##                        NOV-2014 : major update
##                        DEC-2014 : added stations krin, psat, pat1, rod3, xili for ipgp
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
  echo " Dependancies : the python library bpepy.gpstime must be installed and"
  echo "                set in the python path variable."
  echo "                In order to download data from the NOA2 server, the programs"
  echo "                teqc, runpkr00 and rnx2crx must be installed and set in the"
  echo "                PATH variable."
  echo ""
  echo " Purpose : Download regional stations rinex files for a specific date."
  echo ""
  echo " Usage   : wgetigsrnx.sh [-s [station1] [station2] [...] | -f [station file]] -y [year] -d [doy] {-o [output directory] | -m [max stations] | -r}"
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
  echo "           -x --fix-header fix header (MARKER NAME) to match the station's name"
  echo "           -l --list-available list all regional gnss stations which can be downloaded via"
  echo "            this script; nothing else is done if this switch is given."
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
# RINEX LISTS
# //////////////////////////////////////////////////////////////////////////////

## RINEX FROM NTUA SERVER (1)
## ********************************
NTUA_RNX_LIST=(akyr anop ark2 arki atrs dion diop dsln gvds katc kery kith kryo mena meth mkmn mlos neap poly sntr sprt tilo vass wnry xrso)

## RINEX FROM NOA-GEIN SERVER (2)
## ********************************
##
## WARNING!!!!!!!!!!!!!!!!!!!!!!!!!
## STATION PYLO IS TRANSLATED TO PYL2 TO DIFFER FROM PYLO STATION OF
## IPGP NETWORK
##
NOA_RNX_LIST=(atal kasi katc kipo klok krps lemn neab nvrk pont prkv pyl2 rlso sant span stef thir vlsm voli)

## RINEX FROM IPGP SERVER (3)
## ********************************
IPGP_RNX_LIST=(eypa koun krin lamb lido pat1 psar psat pylo rod3 triz xili)

## RINEX FROM UNAVCO SERVER (4)
## ********************************
UNAVCO_RNX_LIST=(katc kera mozi nomi pkmn riba tilo)

## RINEX FROM NOA-2 SERVER (5)
## ********************************
## WARNING!!!!!!!!!!!!!!!!!!!!!!!!!
## THESE ARE RAW RECEIVER FILES NOT RINEX
##
NOA2_RNX_LIST=(idi1 nafp siva vam1 zkro)

# //////////////////////////////////////////////////////////////////////////////
# CHECK IF A FILE EXISTS IN A GIVEN LIST (0-sucesses)
# //////////////////////////////////////////////////////////////////////////////
function find_in_list {
  st=$1
  lt=$2
  STATUS=1

  case $lt in

    1)
      echo "${NTUA_RNX_LIST[@]}" | grep -w $st &>/dev/null
      STATUS=$?
      ;;

    2)
      echo "${NOA_RNX_LIST[@]}" | grep -w $st &>/dev/null
      STATUS=$?
      ;;

    3)
      echo "${IPGP_RNX_LIST[@]}" | grep -w $st &>/dev/null
      STATUS=$?
      ;;

    4)
      echo "${UNAVCO_RNX_LIST[@]}" | grep -w $st &>/dev/null
      STATUS=$?
      ;;
    5)
      echo "${NOA2_RNX_LIST[@]}" | grep -w $st &>/dev/null
      STATUS=$?
      ;;
    *)
      STATUS=$1
      ;;

  esac

  echo $STATUS
}

# //////////////////////////////////////////////////////////////////////////////
# GET A STATION OF A GIVEN LIST (0-sucesses)
# //////////////////////////////////////////////////////////////////////////////
function get_station {
  st=$1 # station name
  lt=$2 # network number
  yr=$3 # year
  y2=${yr:2:2} # two-digit year
  dy=$4 # doy
  od=$5 # output directory
  
  case $lt in

    1) # NTUA SERVER
      if [ -f "/media/WD/data/COMET/${yr}/${dy}/${st}${dy}0.${y2}d.Z" ]; then
        cp "/media/WD/data/COMET/${yr}/${dy}/${st}${dy}0.${y2}d.Z" ${od}/${st}${dy}0.${y2}d.Z
        echo $?
      else
        echo 1
      fi
      ;;

    2) # NOA SERVER
      ##
      ## SPECIAL CARE FOR PYLO
      ##
      if [ "$st" = "pyl2" ]; then
          wget -O ${od}/pyl2${dy}0.${y2}d.Z -q --tries=2 http://www.gein.noa.gr/services/GPSData/${yr}/${dy}/pylo${dy}0.${y2}d.Z
          if test -s ${od}/pyl2${dy}0.${y2}d.Z; then
            echo 0
          else
            rm ${od}/pyl2${dy}0.${y2}d.Z 2>/dev/null
            echo 1
          fi
      ##
      ## SPECIAL CARE FOR RLSO
      ##
      elif [[ "$st" = "rlso" && $yr -le 2008 ]]; then
          wget -O ${od}/${st}${dy}0.${y2}d.Z -q --tries=2 http://www.gein.noa.gr/services/GPSData/${yr}/${dy}/rls_${dy}0.${y2}d.Z
          if test -s ${od}/rlso${dy}0.${y2}d.Z; then
            echo 0
          else
            rm ${od}/rlso${dy}0.${y2}d.Z 2>/dev/null
            echo 1
          fi
      ##
      ## GENERAL FOR NOA
      ##
      else
        wget -O ${od}/${st}${dy}0.${y2}d.Z -q --tries=2 http://www.gein.noa.gr/services/GPSData/${yr}/${dy}/${st}${dy}0.${y2}d.Z
        if test -s ${od}/${st}${dy}0.${y2}d.Z; then
          echo 0
        else
          rm ${od}/${st}${dy}0.${y2}d.Z 2>/dev/null
          echo 1
        fi
      fi
      ;;

    3) # IPGP SERVER
      wget --no-check-certificate -q --timeout=90 --tries=2 -O ${od}/${st}${dy}0.${y2}d.Z https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/${yr}/${dy}/${st}${dy}0.${y2}d.Z
      if test -s ${od}/${st}${dy}0.${y2}d.Z; then
        echo 0
      else
        rm ${od}/${st}${dy}0.${y2}d.Z 2>/dev/null
        echo 1
      fi
      ;;

    4) # UNAVCO SERVER
      wget -q -O ${od}/${st}${dy}0.${y2}d.Z ftp://data-out.unavco.org/pub/rinex/obs/${yr}/${dy}/${st}${dy}0.${y2}d.Z
      if test -s ${od}/${st}${dy}0.${y2}d.Z; then
        echo 0
      else
        rm ${od}/${st}${dy}0.${y2}d.Z 2>/dev/null
        echo 1
      fi
      ;;

    5) # NOA2 SERVER
      ##
      ## NOTE THAT THESE ARE RAW RECEIVER FILES THAT NEED TO BE CONVERTED
      ##
      if ! test -f /home/bpe2/ntua.keys ; then
        echo "*** ERROR! Cannot find key file /home/bpe2/ntua.keys"
        exit 254
      fi
      NOA2URL=`egrep -w ^NOA2URL.* /home/bpe2/ntua.keys | awk '{print substr($0,20,31)}' | sed 's/[ \t]*$//'`
      NOA2USR=`egrep -w ^NOA2USR.* /home/bpe2/ntua.keys | awk '{print substr($0,20,31)}' | sed 's/[ \t]*$//'`
      NOA2PAS=`egrep -w ^NOA2PAS.* /home/bpe2/ntua.keys | awk '{print substr($0,20,31)}' | sed 's/[ \t]*$//'`

      #
      # GET MONTH AND DAY OF MONTH
      #
      _DOY_=`echo $DOY | sed 's/^0*//'`
      MD=`python -c "import bpepy.gpstime; m,d = bpepy.gpstime.yd2month($YEAR,$_DOY_); print '%02i %02i' %(m,d)"`
      #if [ -z "$MD" ]; then echo 1; exit; fi
      MONTH=`echo $MD | awk '{print $1}'`
      DAY_OF_MONTH=`echo $MD | awk '{print $2}'`

      ## STATION IDI1
      if [ "$st" = "idi1" ]; then
        filename=IDI0${MONTH}${DAY_OF_MONTH}a
        wget --user=${NOA2USR} --password='${NOA2PAS}' -O ${od}/${filename} -q --tries=2 ${NOA2URL}/IDI/${yr}/${dy}/${filename}
        if test -s ${od}/${filename}; then
          teqc -top tps -O.at "TPSCR.G5        TPSH" ${od}/${filename} > ${od}/idi1${dy}0.${y2}o 2>teqc_report
          rnx2crx ${od}/idi1${dy}0.${y2}o 2>>teqc_report
          #rm ${od}/${filename} 2>/dev/null
          echo 0
        else
          #rm ${od}/${filename} 2>/dev/null
          echo 1
        fi
      fi

      ## STATION SIVA
      if [ "$st" = "siva" ]; then
        filename=SIVA${yr}${MONTH}${DAY_OF_MONTH}0000a.T00
        wget --user=${NOA2USR} --password='${NOA2PAS}' -O ${od}/${filename} -q --tries=2 ${NOA2URL}/SIVA/${yr}/${dy}/${filename}
        if test -s ${od}/${filename}; then
          runpkr00 -d ${od}/${filename}
          fn=`echo $filename | sed 's|T00|dat|'`
          teqc -tr d -O.at "TRM41249.00     NONE" ${od}/${fn} > ${od}/siva${dy}0.${y2}o  2>>teqc_report
          rnx2crx ${od}/siva${dy}0.${y2}o 2>>teqc_report
          rm ${od}/${filename} ${od}/${fn} 2>/dev/null
          echo 0
        else
          rm ${od}/${filename} 2>/dev/null
          echo 1
        fi
      fi

      ## STATION VAM1
      if [ "$st" = "vam1" ]; then
        filename=VAM0${MONTH}${DAY_OF_MONTH}a
        wget --user=${NOA2USR} --password='${NOA2PAS}' -O ${od}/${filename} -q --tries=2 ${NOA2URL}/VAM/${yr}/${dy}/${filename}
        if test -s ${od}/${filename}; then
          teqc -top tps -O.at "TPSCR.G5        TPSH" ${od}/${filename} > ${od}/vam1${dy}0.${y2}o  2>>teqc_report
          rnx2crx ${od}/vam1${dy}0.${y2}o
          rm ${od}/${filename} 2>/dev/null
          echo 0
        else
          rm ${od}/${filename} 2>/dev/null
          echo 1
        fi
      fi

      ## STATION ZKRO
      if [ "$st" = "zkro" ]; then
        filename=ZKRO${yr}${MONTH}${DAY_OF_MONTH}0000a.T00
        wget --user=${NOA2USR} --password='${NOA2PAS}' -O ${od}/${filename} -q --tries=2 ${NOA2URL}/ZKR/${yr}/${dy}/${filename}
        if test -s ${od}/${filename}; then
          runpkr00 -d ${od}/${filename}
          fn=`echo $filename | sed 's|T00|dat|'`
          teqc -tr d -O.at "TRM41249.00     NONE" ${od}/${fn} > ${od}/zkro${dy}0.${y2}o  2>>teqc_report
          rnx2crx ${od}/zkro${dy}0.${y2}o
          rm ${od}/${filename} ${od}/${fn} 2>/dev/null
          echo 0
        else
          rm ${od}/${filename} 2>/dev/null
          echo 1
        fi
      fi

      ;;

    *) # INVALID !!
      echo 1
      ;;

  esac
}

# //////////////////////////////////////////////////////////////////////////////
# This function will show a list of all available gnss stations that can be 
# downloaded
# //////////////////////////////////////////////////////////////////////////////
function list_station {
  echo "+------+------+---------------------------------------------------------------------------+----------+"
  echo "| akyr | akyr | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| anop | anop | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| ark2 | ark2 | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| arki | arki | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| atal | atal | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| atrs | atrs | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| dion | dion | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| diop | diop | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| dsln | dsln | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| eypa | eypa | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| gvds | gvds | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| idi1 | idi1 | ftp://194.177.194.102/idi/YYYY/DDDD                                       | noa-2    |"
  echo "| kasi | kasi | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| katc | katc | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| katc | katc | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| katc | katc | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| kera | kera | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| kery | kery | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| kipo | kipo | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| kith | kith | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| klok | klok | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| koun | koun | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| krin | krin | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| krps | krps | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| kryo | kryo | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| lamb | lamb | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| lemn | lemn | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| lido | lido | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| mena | mena | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| meth | meth | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| mkmn | mkmn | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| mlos | mlos | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| mozi | mozi | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| neab | neab | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| neap | neap | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| nomi | nomi | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| nvrk | nvrk | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| pat1 | pat1 | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| pkmn | pkmn | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| poly | poly | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| pont | pont | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| prkv | prkv | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| psar | psar | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| psat | psat | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| pylo | pyl2 | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| pylo | pylo | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| riba | riba | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| rlso | rlso | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| rod3 | rod3 | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| sant | sant | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| siva | siva | ftp://194.177.194.102/siva/YYYY/DDDD                                      | noa-2    |"
  echo "| sntr | sntr | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| span | span | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| sprt | sprt | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| stef | stef | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| thir | thir | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| tilo | tilo | ftp://data-out.unavco.org/pub/rinex/obs/YYYY/DDDD                         | unavco   |"
  echo "| tilo | tilo | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| triz | triz | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| vam1 | vam1 | ftp://194.177.194.102/vam/YYYY/DDDD                                       | noa-2    |"
  echo "| vass | vass | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| vlsm | vlsm | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| voli | voli | http://www.gein.noa.gr/services/GPSData/YYYY/DDDD                         | noa-gein |"
  echo "| wnry | wnry | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| xili | xili | https://gpscope.dt.insu.cnrs.fr/chantiers/corinthe/data_by_date/YYYY/DDDD | crl      |"
  echo "| xrso | xrso | gpsdata@147.102.110.69:/media/WD/data/COMET/YYYY/DDD                      | ntua     |"
  echo "| zkro | zkro | ftp://194.177.194.102/zkr/YYYY/DDDD                                       | noa-2    |"
  echo "+------+------+---------------------------------------------------------------------------+----------+"
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
FIX_RNX_NAME=0  ## fix the marker name (in header) to match the one in the rnx file
TRUNCATE=NO   ## truncate to upper case
QUIET=NO      ## supress messages

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
    -z|--decompress)
      DECOMP=1
      shift
      ;;
    -x|--fix-header)
      FIX_RNX_NAME=1
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
    -l|--list-available)
      list_station
      exit 0
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
  echo "*** Need to provide a valid year [>1950]"
  exit 254
fi
YR2=${YEAR:2:2}
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]
then
  echo "*** Need to provide a valid doy [1-366]"
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
# IF OUTPUT DIR GIVEN, SEE THAT IT EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $OUTDIR ]
then
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
if [ "$FIX_RNX_NAME" -eq 1 -a "$DECOMP" -eq 0 ]
then
  if [ $QUIET == "NO" ]; then echo "Rinex files are going to be decompressed in order to fix marker name!"; fi
  DECOMP=1
fi

# //////////////////////////////////////////////////////////////////////////////
# FOR EVERY STATION IN DOWNLOAD LIST
# //////////////////////////////////////////////////////////////////////////////
for s in ${STARRAY[*]}; do
  
  STATION=`echo $s | tr 'a-z' 'A-Z'`
  station=`echo $s | tr 'A-Z' 'a-z'`
  Station=$s

  if [ "$Station" != "$station" ]; then
    echo "WARNING !! No match for names: $Station and $station"
  fi

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

    if [ ${PROCED_TO_DOWNLOAD} == "NO" ]; then ## do not proceed to download; file available
      let STACOUNTER=STACOUNTER+1

    else ## preceed to download
      # assume file is not downloaded
      DOWNLOADED=1
      # get the network the station belongs to, if any
      EXIST=0
      for ARRAY in `seq 1 5`; do
        FOUND=`find_in_list ${Station} ${ARRAY}`
        if [ "$FOUND" -eq 0 ]; then
          EXIST=1
          break;
        fi
      done

      # if the station belongs to the NOA2 server, then some utilities must be installed
      # to transform them to rinex
      if [[ "$EXIST" -eq 1 && $ARRAY -eq 5 ]]; then
        hash teqc 2>/dev/null || { echo >&2 "*** Routine teqc not available!"; EXIST=0; }
        hash rnx2crx 2>/dev/null || { echo >&2 "*** Routine rnx2crx not available!"; EXIST=0; }
        hash runpkr00 2>/dev/null || { echo >&2 "*** Routine runpkr00 not available!"; EXIST=0; }
      fi

      # if rinex belongs to one of the lists, try to download it
      if [ "$EXIST" -eq 1 ]; then
        DOWNLOADED=`get_station $Station $ARRAY $YEAR $DOY $OUTDIR`
      else
        if [[ $QUIET == "NO" && $ARRAY -ne 5 ]]; then echo "-- Station $Station not found in regional servers lists!"; fi
        if [[ $QUIET == "NO" && $ARRAY -eq 5 ]]; then echo "-- Station $Station cannot be downloaded (missing programs)!"; fi
        DOWNLOADED=1
      fi

      # if station downloaded, augment counter
      if [ "$DOWNLOADED" -eq 0 ]; then
        let STACOUNTER=STACOUNTER+1
        if [ $QUIET == "NO" ]; then echo "Station $Station downloaded"; fi    

        # if decompressed called and file is compressed, uncompress the file
        if [ "$DECOMP" -eq 1 ]; then
          uncompress ${OUTDIR}/${station}${DOY}0.${YR2}d.Z 2>/dev/null
        fi

        # if station name is different in rinex header change rinex header
        if [ "$FIX_RNX_NAME" -eq 1 ]; then
          HEADER_NAME=$(grep "MARKER NAME" ${OUTDIR}/${station}${DOY}0.${YR2}d | awk '{print $1}')
          if [ "$HEADER_NAME" != "$STATION" ]; then
            if [ $QUIET == "NO" ]; then echo "Changing marker name from $HEADER_NAME to $STATION"; fi
            L2C=$(grep "MARKER NAME" ${OUTDIR}/${station}${DOY}0.${YR2}d)
            L2P="$STATION                                                        MARKER NAME"
            sed -i "s|${L2C}|${L2P}|g" ${OUTDIR}/${station}${DOY}0.${YR2}d
          fi
        fi

        # truncate name if needed
        if [ $TRUNCATE == "YES" ]; then
          mv ${OUTDIR}/${station}${DOY}0.${YR2}d ${OUTDIR}/${STATION}${DOY}0.${YR2}D 2>/dev/null
          mv ${OUTDIR}/${station}${DOY}0.${YR2}d.Z ${OUTDIR}/${STATION}${DOY}0.${YR2}D.Z 2>/dev/null
        fi

      #else
      # no need for that; handled by function get_station
      #  an empty file will have propably been created; remove it
      #  rm -f ${OUTDIR}/${Station}${DOY}0.${YR2}d.Z 2>/dev/null

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

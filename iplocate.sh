#! /bin/bash

## CHECK THAT A VALID FILE IS GIVEN ##
if (( $# < 1 )); then
    echo "Please provide a valid file with a list of IP adresses"
    exit 1
fi

fin=$1

if [ ! -f $fin ]; then
    echo "File does not exist $fin"
    echo "Please provide a valid file with a list of IP adresses"
    exit 1
fi

## PARAMETERS ##
KEEP_GEO_FILES=NO
CREATE_MAP=NO
CREATE_KML=NO
FILTER_CRAWLS=NO

## COMMAND LINE OPTIONS ##
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
      -s|--keep-files)
        KEEP_GEO_FILES=YES
        ;;
      -m|--create-map)
        CREATE_MAP=YES
        ;;
      -k|--create-kml)
        CREATE_KML=YES
        ;;
      -f|--filter-crawls)
        FILTER_CRAWLS=YES
        ;;
      -h|--help)
        echo "Command line options:"
        echo "First argument must be the file containing IPs."
        echo "[-s or --keep-files]    : keep created files with information of IPs."
        echo "[-m or --create-map]    : create a map using gmt to depict the IPs."
        echo "[-k or --create-kml]    : create a kml file with the list of the IPs."
        echo "[-f or --filter-crawls] : filter out any bot IPs."
        echo "[-h or --help]          : display this help message and exit."
        ;;
      *)
        echo "Unknown command line argument: ${key}; ignored"
        ;;
  esac
  shift
done

echo "------------------------------------------------"
echo " IPLOCATE"
echo "------------------------------------------------"
echo " Resolving IPs from file: $fin"

> geolocations.dat
> cities.dat
> visitors.dat
crawls=( "msnbot" "googlebot" )

while read line
do
    > .ip.temp
    #curl ipinfo.io/${line}/geo > .ip.temp 2>/dev/null
    curl ipinfo.io/${line} > .ip.temp 2>/dev/null
    if [ -s .ip.temp ]; then
        crds=$(grep loc .ip.temp | sed 's|,| |g' | awk '{print $2,$3}' | sed 's|"||g')
        city=$(grep city .ip.temp | awk '{print $2}' | sed 's|"||g' | sed 's|,| |g')
        country=$(grep country .ip.temp | awk '{print $2}' | sed 's|"||g' | sed 's|,| |g')
        org=$(grep org .ip.temp | awk '{$1=""; print $0}' | sed 's|"||g' | sed 's|,| |g')
        host=$(grep hostnam .ip.temp | awk '{$1=""; print $0}' | sed 's|"||g' | sed 's|,| |g')
        if [ ${FILTER_CRAWLS} == "YES" ]; then
          ANSWER=0
          for bot in "${crawls[@]}"; do
            echo $host | grep $bot 1>/dev/null
            NANSWER=$?
            let ANSWER=ANSWER+NANSWER
          done
          if [ $ANSWER -eq ${#crawls[@]} ]; then
            grep loc .ip.temp | sed 's|,| |g' | awk '{print $2,$3}' | sed 's|"||g' >> geolocations.dat
            echo "${crds}:${city}:${country}" >> cities.dat
            echo "${crds}:${city}:${country}:${host}:${org}" >> visitors.dat
          else
            echo " ! filtered out bot: $host !"
          fi
        else
          grep loc .ip.temp | sed 's|,| |g' | awk '{print $2,$3}' | sed 's|"||g' >> geolocations.dat
          echo "${crds}:${city}:${country}" >> cities.dat
          echo "${crds}:${city}:${country}:${host}:${org}" >> visitors.dat
        fi
        rm .ip.temp 2>/dev/null
    else
        echo " !! Could not resolve ip: $line !!"
        rm .ip.temp
    fi
done < $fin

sed '/^$/d' geolocations.dat | uniq | awk '{print $2,$1}' > .ip.temp
mv .ip.temp geolocations.dat
sed '/^$/d' cities.dat | awk -F: '!_[$3]++' > .ip.temp
mv .ip.temp cities.dat
sed '/^$/d' visitors.dat | uniq > .ip.temp
mv .ip.temp visitors.dat

if [ ${CREATE_MAP} == "YES" ]; then
  echo " Creating visitors map : visitors.ps"
  #awk -F: '{print $2,$3}' cities.dat | sed 's|null||g' | tr "\\n" "," | fold -w 40 -s >> cities.txt
  cat cities.dat
  awk -F: '{print $2,$3}' cities.dat | sed 's|null||g' | tr "\\n" "," | fold -w 40 -s > cities.txt
  > cities.dat
  x_start=0
  y_start=4
  WC=$(cat cities.txt | wc -l)
  let WC=WC+1
  echo "number of lines $WC"
  for i in `seq 1 $WC`; do
    new_y=$(echo "$y_start-0.1" | bc)
    y_start=$new_y
    line=$(cat cities.txt | sed -n "${i}p")
    echo "$x_start $y_start $line" >> cities.dat
  done
  psbasemap -R-180/180/-85/85 -Jm0.020i -B30g30:.Mercator: -Lx1i/1i/0/5000 -K > visitors.ps
  pscoast -R -J -B30g30:."Who Visited dionysos.survey.ntua.gr": -Df -W0.5/0/0/0 -G195 -O -K >> visitors.ps
  psxy 
  psbasemap -JX8c/20c -R0/5/0/5 -B0g0 -X19c -Y-2c -O -K >> visitors.ps
  pstext cities.dat -J -R -F+f10p,Courier,black -N -O >> visitors.ps
fi

if [ ${CREATE_KML} == "YES" ]; then
  echo " Creating .kml file : visitors.kml"
  > visitors.kml
  echo '<?xml version="1.0" encoding="UTF-8"?>' > visitors.kml
  echo '<kml xmlns="http://www.opengis.net/kml/2.2">' >> visitors.kml
  echo '<Document>' >> visitors.kml
  ITERATOR=0
  while read line; do
    LINE=${line}
    CRD=$(echo $LINE | awk -F: '{print $1}')
    CRD=$(echo $CRD | awk '{print $2","$1}')
    CITY=$(echo $LINE | awk -F: '{print $2}')
    COUNTRY=$(echo $LINE | awk -F: '{print $3}')
    HOST=$(echo $LINE | awk -F: '{print $4}')
    ORG=$(echo $LINE | awk -F: '{print $5}')
    if [ $CRD != "," ]; then
      echo "  <Placemark>" >> visitors.kml
      echo "    <name>Visitor ${HOST}</name>" >> visitors.kml
      echo "    <description>Visitor from ${CITY}, ${COUNTRY}; Organization info ${ORG}, host is ${HOST}.</description>" >> visitors.kml
      echo "    <Point>" >> visitors.kml
      echo "      <coordinates>${CRD}</coordinates>" >> visitors.kml
      echo "    </Point>" >> visitors.kml
      echo "  </Placemark>" >> visitors.kml
      let ITERATOR=ITERATOR+1
    fi
  done < visitors.dat
  echo '</Document>' >> visitors.kml
  echo '</kml>' >> visitors.kml
  echo " Number of IPs written on kml file: $ITERATOR"
fi

if [ ${KEEP_GEO_FILES} == "NO" ]; then
  echo " Removing geo-dat files"
  rm geolocations.dat cities.dat cities.txt visitors.dat .ip.temp 2>/dev/null
fi

echo "------------------------------------------------"
exit 0

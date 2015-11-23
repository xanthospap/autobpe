#! /bin/bash

## argv[1] = year
## argv[2] = doy
year=${1}
doy=${2}

campaign=EPNDENS_BT
LOADGPS=/home/bpe/bern52/BERN52/GPS/EXE/LOADGPS.setvar
. ${LOADGPS}
P2C=${P}/${campaign}

##  First, let's make an up-to-date station information file.
##  Download the (historical) Sinex file from EUREF
rm EUREF.SNX 2>/dev/null
if ! wget -O EUREF.SNX -q \
          ftp://epncb.oma.be/epncb/station/general/euref.snx ; then
  echo 1>&2 "ERROR. Failed to download the sinex file."
fi

##  Extract the information from this sinex to a station information
##+ file, called 'EUREF.STA'
if ! /home/bpe/autobpe/bin/snx2sta.sh \
                      --year=${year} \
                      --doy=${doy} \
                      --sinex=EUREF.SNX \
                      --campaign=${campaign} \
                      --sta-out=EUREF \
                      --verbose=0 \
                      --loadgps=${LOADGPS} ; then
  echo 1>&2 "ERROR. Failed to create a .sta file from the sinex file."
  exit 1
fi

##  By now, we should have a .STA file in out campaign's STA/
##+ folder, named EUREF.STA. Let's merge that file with the
##+ the one NTUA keeps, i.e. NTUA52.STA to produce a 'super-sta'!
if ! /home/bpe/autobpe/bin/stamrg.sh \
                      --master-sta=${P2C}/STA/EUREF.STA \
                      --secondary-sta=/home/bpe/tables/sta/NTUA52.STA \
                      --campaign=${campaign} \
                      --sta-out=EPNDENS \
                      --verbose=0 \
                      --loadgps=${LOADGPS} ; then
  echo 1>&2 "ERROR. Failed to merge the .sta files."
  exit 1
fi

##  Nice! Now we have our `super-STA` in our campaign's STA/ dir, named as
##+ 'EPNDENS.STA'. Now we need a '.PCV' file ... 
##  To make the pcv file, we will download the latest atx from euref,
##+ and use the EPNDENS.STA to extract info for the antennas we want
if ! wget -O EUREF.ATX -q \
          ftp://epncb.oma.be/epncb/station/general/epn_08.atx ; then
  echo 1>&2 "ERROR. Failed to download the antex file."
fi

## Now transform it to PCV, named as 'PCV_EPN.I08'
if ! /home/bpe/autobpe/bin/atx2pcv.sh \
                      --antex=EUREF.ATX \
                      --sta=${P2C}/STA/EPNDENS \
                      --campaign=${campaign} \
                      --phg-out=PCV_EPN.I08 \
                      --verbose=2 \
                      --loadgps=${LOADGPS} ; then
  echo 1>&2 "ERROR. Failed to transform the atx to pcv."
  exit 1
fi


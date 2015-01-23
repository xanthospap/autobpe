
#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : cron_products.sh
                           NAME=cron_products
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : 
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           :
## uses                  :
## dependancies          :
## notes                 :
## TODO                  :
## detailed update list  :
                           LAST_UPDATE=JAN-2015
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
  echo " Purpose : Download GNSS products for automatic processing."
  echo ""
  echo " Usage   : cron_products"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches :"
  echo ""
  echo " WARNING !! The long options are only available if the GNU-enhanced version of getopt is"
  echo "            available; else, the user must only use short options"
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

##  Where is the DATAPOOL area?
POOL=/home/bpe2/data/GPSDATA/DATAPOOL

## Log file
LOGF=/home/bpe2/log/cron_prods$(/bin/date '+%Y-%m-%d')
>${LOGF}

##  We will download products for yesterday and -20 days before.
##  Products include:
##  *  GNSS (gps+glonass) orbit information from CODE (ultra-rapid and final)
##  *  Earth Rotation Parameters from CODE (ultra-rapid and final)
##  *  Vienna Mapping Function (VMF1) grid files (predicted and final)
##  *  Differential Code Bias (running and maybe for previous month)
##
##  All products will be placed at the DATAPOOL area and a meta file will be
##+ created for each reporting information.

##  First of all, we need to resolve the two dates, i.e. yesterday and -20 days.
##  Go ahead and do that.
YESTERDAY_STR=`/bin/date -d "1 day ago" '+%Y-%m-%d-%j-%w'`
YESTERDAY=()
IFS='-' read -a YESTERDAY <<< "${YESTERDAY_STR}"
if test ${#YESTERDAY[@]} -ne 5
then
  echo "ERROR. FAILED TO RESOLVE YESTERDAY'S DATE"
  exit 1
fi

M20DAYS_STR=`/bin/date -d "20 days ago" '+%Y-%m-%d-%j-%w'`
M20DAYS=()
IFS='-' read -a M20DAYS <<< "${M20DAYS_STR}"
if test ${#M20DAYS[@]} -ne 5
then
  echo "ERROR. FAILED TO RESOLVE -20 DAYS DATE"
  exit 1
fi

##  Now we have two arrays containing the dates we want as
##  [YEAR(0),MONTH(1),DOM(2),DOY(3),DOW(4)]

##  Download orbits. First the ultra-rapid one (or rapid if we can find it)
if ! /usr/local/bin/wgetorbit --analysis-center=cod \
                              --output-directory=${POOL} \
                              --standard-names \
                              --decompress \
                              --year=${YESTERDAY[0]} \
                              --doy=${YESTERDAY[3]} \
                              --force-remove \
                              2>>${LOGF} \
                              1>.tmp
then
  echo "ERROR. FAILED TO DOWNLOAD YESTERDAY'S ORBIT"
  exit 1
fi

##  Ok. Now we have a file named as '.tmp' wchich should contain one line, with
##+ something like:
##  '(wgetorbit) Downloaded Orbit File: COD18254.EPH.Z as 
##+ /home/bpe2/data/GPSDATA/DATAPOOL/COD18254.EPH of type: final from AC: cod'
##  Check that this is the case, and write the meta file.
cat .tmp >> $LOGF
LNS=`cat .tmp | wc -l`
if test $LNS -ne 1 ; then echo "ERROR. INVALID ORBIT REPORT"; exit 1; fi
FILE=`cat .tmp | awk '{print $7}'`
if ! test -f $FILE ; then echo "ERROR. INVALID ORBIT REPORT (2)"; exit 1; fi
mv .tmp ${FILE}.meta

##  Download orbits. Next the final one
if ! /usr/local/bin/wgetorbit --analysis-center=cod \
                              --output-directory=${POOL} \
                              --standard-names \
                              --decompress \
                              --year=${M20DAYS[0]} \
                              --doy=${M20DAYS[3]} \
                              --type=f \
                              --force-remove \
                              2>>${LOGF} \
                              1>.tmp
then
  echo "ERROR. FAILED TO DOWNLOAD FINAL ORBIT"
  exit 1
fi

##  Again, make the meta file
cat .tmp >> $LOGF
LNS=`cat .tmp | wc -l`
if test $LNS -ne 1 ; then echo "ERROR. INVALID ORBIT REPORT"; exit 1; fi
FILE=`cat .tmp | awk '{print $7}'`
if ! test -f $FILE ; then echo "ERROR. INVALID ORBIT REPORT (2)"; exit 1; fi
mv .tmp ${FILE}.meta

##  Hopefully all done with orbits; lets continue ...

##  Download erp files. First the (ultra) rapid one. Again, after a successful
##+ download, make the .meta file for each file.
if ! /usr/local/bin/wgeterp --analysis-center=cod \
                            --output-directory=${POOL} \
                            --standard-names \
                            --decompress \
                            --force-remove \
                            --year=${YESTERDAY[0]} \
                            --doy=${YESTERDAY[3]} \
                            2>>${LOGF} \
                            1>.tmp
then
  echo "ERROR. FAILED TO DOWNLOAD YESTERDAY'S ERP"
  exit 1
fi

##  Now the returned string (stored in .tmp) looks like:
##  '(wgeterp) Downloaded ERP File: COD18257.ERP.Z as \
##+ /home/bpe2/data/GPSDATA/DATAPOOL/COD18254.ERP  of type: final from AC: cod'
cat .tmp >> $LOGF
LNS=`cat .tmp | wc -l`
if test $LNS -ne 1 ; then echo "ERROR. INVALID ERP REPORT"; exit 1; fi
FILE=`cat .tmp | awk '{print $7}'`
if ! test -f $FILE ; then echo "ERROR. INVALID ERP REPORT (2)"; exit 1; fi
mv .tmp ${FILE}.meta

if ! /usr/local/bin/wgeterp --analysis-center=cod \
                            --output-directory=${POOL} \
                            --standard-names \
                            --decompress \
                            --force-remove \
                            --type=f \
                            --year=${M20DAYS[0]} \
                            --doy=${M20DAYS[3]} \
                            2>>${LOGF} \
                            1>.tmp
then
  echo "ERROR. FAILED TO DOWNLOAD FINAL ERP"
  exit 1
fi

cat .tmp >> $LOGF
LNS=`cat .tmp | wc -l`
if test $LNS -ne 1 ; then echo "ERROR. INVALID ERP REPORT"; exit 1; fi
FILE=`cat .tmp | awk '{print $7}'`
if ! test -f $FILE ; then echo "ERROR. INVALID ERP REPORT (2)"; exit 1; fi
mv .tmp ${FILE}.meta

## Download VMF1 grid files.
if ! /usr/local/bin/wgetvmf1 --output-directory=${POOL} \
                             --year=${YESTERDAY[0]} \
                             --doy=${YESTERDAY[3]} \
                             2>>${LOGF} \
                             1>.tmp
then
  echo "ERROR. FAILED TO DOWNLOAD VMF1 GRID FILE FOR YESTERDAY"
  exit 1
fi

##  Now we have to make the .meta file. The output (.tmp) looks like:
##  '(wgetvmf1) Downloaded VMF1 grid file \
##+ /home/bpe2/data/GPSDATA/DATAPOOLVMFG_20150120.H00 (final) ; merged to \
##+ /home/bpe2/data/GPSDATA/DATAPOOL/VMFG_2015020'
##  There should be 5 such lines.
cat .tmp >> $LOGF
LNS=`cat .tmp | wc -l`
if test $LNS -ne 5 ; then echo "ERROR. INVALID VMF1 REPORT"; exit 1; fi
FILE=`cat .tmp | head -n 1 | awk '{print $11}'`
if ! test -f $FILE ; then echo "ERROR. INVALID VMF1 REPORT (2)"; exit 1; fi
mv .tmp ${FILE}.meta

if ! /usr/local/bin/wgetvmf1 --output-directory=${POOL} \
                             --year=${M20DAYS[0]} \
                             --doy=${M20DAYS[3]} \
                             2>>${LOGF} \
                             1>.tmp
then
  echo "ERROR. FAILED TO DOWNLOAD VMF1 GRID FILE (FINAL)"
  exit 1
fi

cat .tmp >> $LOGF
LNS=`cat .tmp | wc -l`
if test $LNS -ne 5 ; then echo "ERROR. INVALID VMF1 REPORT"; exit 1; fi
FILE=`cat .tmp | head -n 1 | awk '{print $11}'`
if ! test -f $FILE ; then echo "ERROR. INVALID VMF1 REPORT (2)"; exit 1; fi
mv .tmp ${FILE}.meta

##  Download the DCB file(s)
##  First get the running
if ! wget --tries=50 --output-document=${POOL}/P1C1_RINEX.DCB \
          ftp://ftp.unibe.ch/aiub/CODE/P1C1_RINEX.DCB &>/dev/null
then
  echo "ERROR. FAILED TO DOWNLOAD RUNNING DCBs FROM CODE"
  exit 1
fi

DT=$(/bin/date '+%Y-%m-%d')
echo "(cron_products) CODE'S 30-DAY GNSS P1-C1 DCB (P1C1_RINEX.DCB) SOLUTION DOWNLOADED AT ${DT}" \
      > ${POOL}/P1C1_RINEX.DCB.meta

##  If today and -20 days belong to the same month, we need no other file; else
##+ first check if an appropriate file already exists. If not, try downloading
##+ it. If that fails, no problem !
if test "${YESTERDAY[1]}" != "${M20DAYS[1]}"
then
	YR2=${M20DAYS[0]}
	YR2=${YR2:2:2}
	if ! test -f ${POOL}/P1C1${YR2}${M20DAYS[1]}.DCB
	then
		wget -O ${POOL}/P1C1${YR2}${M20DAYS[1]}.DCB.Z \
			ftp://ftp.unibe.ch/aiub/CODE/${M20DAYS[0]}/P1C1${YR2}${M20DAYS[1]}_RINEX.DCB \
			2>/dev/null
		if test $? -ne 0
		then
			rm ${POOL}/P1C1${YR2}${M20DAYS[1]}.DCB.Z
		else
			uncompress -f ${POOL}/P1C1${YR2}${M20DAYS[1]}.DCB.Z
            echo "(cron_products) CODE'S FINAL GNSS P1-C1 DCB (P1C1${YR2}${M20DAYS[1]}_RINEX.DCB) SOLUTION" \
				> ${POOL}/P1C1${YR2}${M20DAYS[1]}.DCB.meta
		fi
	fi
fi

##  Finaly !! All done for today
exit 0

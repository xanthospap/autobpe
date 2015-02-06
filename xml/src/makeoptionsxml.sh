#! /bin/bash

##
##  this script is used to form the options.xml file after
##+ a successeful run of ddprocess. Do not try to use this
##+ script as standalone, as it will only produce garbage.
##+ It is designed to be called from (parent) ddprocess, after
##+ a number of variables and files are set.
##

## ORB META
###########################################################
##  Here is a sample line from an sp3 meta file:
##  (wgetorbit) Downloaded Orbit File: COD18272.EPH.Z \
##+ as /home/bpe2/data/GPSDATA/DATAPOOL/COD18272.EPH \
##+ of type: final from AC: cod
##  Make this in xml format

if test -z ${ORB_META}
then
  echo "ORB_META not set! Refusing to make options.xml"
  exit 1
else
  if ! test -f ${ORB_META}
  then
    echo "ORB_META ($ORB_META) not found! Refusing to make options.xml"
    exit 1
  fi
fi

#SC=`cat ${ORB_META} | awk '{print $1}' | sed 's/[)(]//g'`
#OR=`cat ${ORB_META} | awk '{print $5}'`
#DO=`cat ${ORB_META} | awk '{print $7}'`
#TY=`cat ${ORB_META} | awk '{print $10}'`
#AC=`cat ${ORB_META} | awk '{print $13}'`

#SENTENCE="Orbit Information (sp3) file: <filename>${SC}</filename> \
#(stored localy as <filename>${DO}</filename>). Type of information: \
#<emphasis>${TY}</emphasis>. Source of information (i.e. analysis center: \
#<emphasis>${AC}</emphasis>. Script used for \
#downloading was <application>${SC}</application>."
SENTENCE=`cat ${ORB_META}`

sed -i "s|V_ORBIT_META|${SENTENCE}|g" ${tmpd}/xml/options.xml

echo "Done orb meta"
## ERP META
###########################################################
##  Here is a sample line from an erp meta file:
##  (wgeterp) Downloaded ERP File: COD18277.ERP.Z as \
##+ /home/bpe2/data/GPSDATA/DATAPOOL/COD18272.ERP of type: \
##+ final from AC: cod
##  Make the xml!
if test -z ${ERP_META}
then
  echo "ERP_META not set! Refusing to make options.xml"
  exit 1
else
  if ! test -f ${ERP_META}
  then
    echo "ERP_META ($ERP_META) not found! Refusing to make options.xml"
    exit 1
  fi
fi

#SC=`cat ${ORB_META} | awk '{print $1}' | sed 's/[)(]//g'`
#OR=`cat ${ORB_META} | awk '{print $5}'`
#DO=`cat ${ORB_META} | awk '{print $7}'`
#TY=`cat ${ORB_META} | awk '{print $10}'`
#AC=`cat ${ORB_META} | awk '{print $13}'`

#SENTENCE="Earth Orientation Parameters (erp) Information file: <filename>${SC}</filename> \
#(stored localy as <filename>${DO}</filename>). Type of information: \
#<emphasis>${TY}</emphasis>. Source of information (i.e. analysis center: \
#<emphasis>${AC}</emphasis>. Script used for \
#downloading was <application>${SC}</application>."
SENTENCE=`cat ${ERP_META}`

sed -i "s|V_ERP_META|${SENTENCE}|g" ${tmpd}/xml/options.xml

echo "done erp meta"
## ION META
###########################################################
##  Sample of ion meta file (one line)
##  (wgetion) Downloaded ION File: \$OF as \$DF  of type: \$TF from AC: cod
##  Make the xml

if test -z ${ION_META}
then
  echo "ION_META not set! Refusing to make options.xml"
  exit 1
else 
  if ! test -f ${ION_META}
  then
    echo "ION_META file ($ION_META) not found! Refusing to make options.xml"
    exit 1
  fi
fi

#SC=`cat ${ION_META} | awk '{print $1}' | sed 's/[)(]//g'`
#OR=`cat ${ION_META} | awk '{print $5}'`
#DO=`cat ${ION_META} | awk '{print $7}'`
#TY=`cat ${ION_META} | awk '{print $10}'`
#AC=`cat ${ION_META} | awk '{print $13}'`

#SENTENCE="Ionospheric Corrections (ion) Information file: <filename>${SC}</filename> \
#(stored localy as <filename>${DO}</filename>). Type of information: \
#<emphasis>${TY}</emphasis>. Source of information (i.e. analysis center: \
#<emphasis>${AC}</emphasis>. Script used for \
#downloading was <application>${SC}</application>."

SENTENCE=`cat ${ION_META}`

sed -i "s|V_ION_META|${SENTENCE}|g" ${tmpd}/xml/options.xml

echo "done ion meta"
## DCB META
###########################################################
##  Sample of dcb meta file (one line)
if test -z ${DCB_META}
then
  echo "DCB_META not set! Refusing to make options.xml"
  exit 1
fi

SC=`cat ${DCB_META} | awk '{print $1}' | sed 's/[)(]//g'`
LN=`cat ${DCB_META} | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}'`

SENTENCE="Differential Code Bias file: ${LN}. Script used for \
downloading was <application>${SC}</application>."

sed -i "s|V_DCB_META|${SENTENCE}|g" ${tmpd}/xml/options.xml

echo "done dcb meta"
## ATX META
###########################################################

if test -z ${V_ATX}
then
  echo "V_ATX not set! Refusing to make options.xml"
  exit 1
else
  if ! test -f ${V_ATX}.info
  then
    echo "Failed to find atx information in file ${V_ATX}.info"
    echo "Refusing to make options.xml"
    exit 1
  fi
fi

ATX_REV=`cat ${V_ATX}.info`
sed -i "s|V_PCV_META|${ATX_REV}|g" ${tmpd}/xml/options.xml

echo "done pcv meta"

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

#SENTENCE=`cat ${ORB_META}`
sed -i "s|V_ORBIT_META|`cat ${ORB_META} | tr '\n' ' '`|g" ${tmpd}/xml/options.xml

## ERP META
###########################################################
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

#SENTENCE=`cat ${ERP_META}`
sed -i "s|V_ERP_META|`cat ${ERP_META} | tr '\n' ' '`|g" ${tmpd}/xml/options.xml

## ION META
###########################################################
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

#SENTENCE=`cat ${ION_META}`
sed -i "s|V_ION_META|`cat ${ION_META} | tr '\n' ' '`|g" ${tmpd}/xml/options.xml

## DCB META
###########################################################
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

#ATX_REV=`cat ${V_ATX}.info`
sed -i "s|V_PCV_META|`cat ${V_ATX}.info | tr '\n' ' '`|g" ${tmpd}/xml/options.xml

## TRO META
###########################################################

if test -z ${TRO_META}
then
  echo "TRO_META not set! Refusing to make options.xml"
  exit 1
else 
  if ! test -f ${TRO_META}
  then
    echo "TRO_META file ($TRO_META) not found! Refusing to make options.xml"
    exit 1
  fi
fi

sed -i "s|V_TRO_META|`cat ${TRO_META} | tr '\n' ' '`|g" ${tmpd}/xml/options.xml

## CRD META
###########################################################

if test -z ${CRD_META}
then
  echo "CRD_META not set! Refusing to make options.xml"
  exit 1
else 
  if ! test -f ${CRD_META}
  then
    echo "CRD_META file ($CRD_META) not found! Refusing to make options.xml"
    exit 1
  fi
fi

sed -i "s|V_CRD_META|`cat ${CRD_META} | tr '\n' ' '`|g" ${tmpd}/xml/options.xml

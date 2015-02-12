#! /bin/bash

##
##  This script will populate the template file 
##+ 'xml/procsum-rinex.xml'
##  The changes made to the template, are:
##  1. a table will be inserted, with rinex information
##
##  This script is not meant to be used in 'standalone' mode.
##+ It is ignited by 'ddprocess'
##
##  Expectations:
##  The following variables need to be set (i.e. exported by parent 
##+  process)
##   * tmpd
##   * XML_TEMPLATES
##  The (xml) template to be used:
##   * ${XML_TEMPLATES}/procsum-rinex.xml
##  The table to be paste in the xml:
##   * ${tmpd}/rnx.xml
##  Number of rinex, i.e.
##   * ${AVAIL_RNX}
##   * ${V_RNX_TOT}
##   * ${V_IGS_RNX}
##   * ${V_EPN_RNX}
##   * ${V_REG_RNX}
##  Network name
##   * ${V_NETWORK}
##
##  Note that 'rnx.xml', i.e. the table holding rinex
##+ information is NOT created by this script, but run independently.
##+ It should exist for this script to run succesefuly.
##
##  FEB-2015
##

if test -z ${tmpd}
then
  echo "Variable tmpd not set! Refusing to make rinex.xml"
  exit 1
fi

if test -z ${XML_TEMPLATES}
then
  echo "Variable XML_TEMPLATES not set! Refusing to make rinex.xml"
  exit 1
fi

if ! test -f ${XML_TEMPLATES}/procsum-rinex.xml
then
  echo "Failed to locate file ${XML_TEMPLATES}/procsum-rinex.xml"
  echo "Refusing to make rinex.xml"
  exit 1
fi

if ! test -f ${tmpd}/rnx.xml
then
  echo "Failed to locate file ${tmpd}/rnx.xml"
  echo "Refusing to make rinex.xml"
  exit 1
fi

## write the first part of the template
head -n 31 ${XML_TEMPLATES}/procsum-rinex.xml > ${tmpd}/xml/rinex.xml

## insert the rinex table
cat ${tmpd}/rnx.xml >> ${tmpd}/xml/rinex.xml

## write the last part of the template
tail -n 10 ${XML_TEMPLATES}/procsum-rinex.xml >> ${tmpd}/xml/rinex.xml

## replace variables
eval "echo \"$(< ${tmpd}/xml/rinex.xml)\"" > ${tmpd}/xml/.tmp
mv ${tmpd}/xml/.tmp ${tmpd}/xml/rinex.xml

## exit
exit 0

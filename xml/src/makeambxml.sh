#! /bin/bash

##
##  This script will populate the template file 
##+ 'xml/procsum-ambiguities.xml'
##  The changes made to the template, are:
##  1. a table will be inserted, with ambiguity resolution statistics
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
##   * ${XML_TEMPLATES}/procsum-ambiguities.xml
##  The teble to be paste in the xml:
##   * ${tmpd}/amb.xml
##
##  Note that 'amb.xml', i.e. the table holding ambiguity resolution
##+ information is NOT created by this script, but run independently.
##+ It should exist for this script to run succesefuly.
##
##  FEB-2015
##

## 'tmpd' must be set
if test -z ${tmpd}
then
  echo "Variable tmpd not set! Refusing to make ambiguities.xml"
  exit 1
fi

## 'XML_TEMPLATES' must be set
if test -z ${XML_TEMPLATES}
then
  echo "Variable XML_TEMPLATES not set! Refusing to make ambiguities.xml"
  exit 1
fi

## 'procsum-ambiguities.xml' must exist
if ! test -f ${XML_TEMPLATES}/procsum-ambiguities.xml
then
  echo "Failed to locate file ${XML_TEMPLATES}/procsum-ambiguities.xml"
  echo "Refusing to make ambiguities.xml"
  exit 1
fi

## 'amb.xml' must exist
if ! test -f ${tmpd}/amb.xml
then
  echo "Failed to locate file ${tmpd}/amb.xml"
  echo "Refusing to make ambiguities.xml"
  exit 1
fi

## paste top part of the template
head -n 30 ${XML_TEMPLATES}/procsum-ambiguities.xml > ${tmpd}/xml/ambiguities.xml

## paste the ambiguity table
cat ${tmpd}/amb.xml >> ${tmpd}/xml/ambiguities.xml

## paste the rest of the template
tail -n 10 ${XML_TEMPLATES}/procsum-ambiguities.xml >> ${tmpd}/xml/ambiguities.xml

##PICTURE=${V_NETWORK,,}${V_YEAR}${V_DOY}-amb.ps
##sed -i "s|V_AMB_PS|${PICTURE}|g" ${tmpd}/xml/ambiguities.xml

exit 0

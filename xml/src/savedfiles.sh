#! /bin/bash

##
##  This script will populate the template file 
##+ 'xml/procsum-savedfiles.xml'
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
##   * ${XML_TEMPLATES}/procsum-savedfiles.xml
##  Three files should be provided as command line arguments
##   1. saved.files (argv[1])
##   2. ts.update (argv[2])
##   3. crd.update (argv[2])
##
##  Note that these files should have been created by 'ddprocess'
##
##  FEB-2015
##

if test "$#" -ne 3
then
  echo "Failed to pass cmd files! Refusing to create savedfiles.xml"
  exit 1
else
  if ! test -f $1
  then
    echo "Failed to locate file ${1}. Refusing to create savedfiles.xml"
    exit 1
  fi
fi
if ! test -f $2
then
  echo "Failed to locate file ${2}. Refusing to create savedfiles.xml"
  exit 1
fi
if ! test -f $3
then
  echo "Failed to locate file ${3}. Refusing to create savedfiles.xml"
  exit 1
fi

## write the first part from the template
if [ -z ${XML_TEMPLATES} ] || [ -z ${tmpd} ]
then
  echo "Either XML_TEMPLATES or tmpd variables not defined"
  echo "Refusing to create savedfiles.xml"
  exit 1
fi
cat ${XML_TEMPLATES}/procsum-savedfiles.xml > ${tmpd}/xml/savedfiles.xml

sed -ie "s|<\!\-\- saved.files \-\->|`cat ${1} | tr '\n' ' '`|g" ${tmpd}/xml/savedfiles.xml

sed -ie "s|<\!\-\- ts.update \-\->|`cat ${2} | tr '\n' ' '`|g" ${tmpd}/xml/savedfiles.xml

sed -ie "s|<\!\-\- crd.update \-\->|`cat ${3} | tr '\n' ' '`|g" ${tmpd}/xml/savedfiles.xml

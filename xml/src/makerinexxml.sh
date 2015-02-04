#! /bin/bash

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

head -n 12 ${XML_TEMPLATES}/procsum-rinex.xml > ${tmpd}/xml/rinex.xml
cat ${tmpd}/rnx.xml >> ${tmpd}/xml/rinex.xml
tail -n+15 ${XML_TEMPLATES}/procsum-rinex.xml >> ${tmpd}/xml/rinex.xml

exit 0

#! /bin/bash

if test -z ${tmpd}
then
  echo "Variable tmpd not set! Refusing to make ambiguities.xml"
  exit 1
fi

if test -z ${XML_TEMPLATES}
then
  echo "Variable XML_TEMPLATES not set! Refusing to make ambiguities.xml"
  exit 1
fi

if ! test -f ${XML_TEMPLATES}/procsum-ambiguities.xml
then
  echo "Failed to locate file ${XML_TEMPLATES}/procsum-ambiguities.xml"
  echo "Refusing to make ambiguities.xml"
  exit 1
fi

if ! test -f ${tmpd}/amb.xml
then
  echo "Failed to locate file ${tmpd}/amb.xml"
  echo "Refusing to make ambiguities.xml"
  exit 1
fi

head -n 2 ${XML_TEMPLATES}/procsum-ambiguities.xml > ${tmpd}/xml/ambiguities.xml
cat ${tmpd}/amb.xml >> ${tmpd}/xml/ambiguities.xml
tail -n 8 ${XML_TEMPLATES}/procsum-ambiguities.xml >> ${tmpd}/xml/ambiguities.xml
PICTURE=${V_NETWORK,,}${V_YEAR}${V_DOY}-amb.ps
sed -i "s|V_AMB_PS|${PICTURE}|g" ${tmpd}/xml/ambiguities.xml

exit 0

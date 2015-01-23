#! /bin/bash

EXCLUDE=/KOKO1.CRD,LALA2.RPM,/BOB23423

if ! test -z $EXCLUDE ; then 
  IFS=',' read -a EXCLUDE_LIST <<< "$EXCLUDE"
fi
for i in "${!EXCLUDE_LIST[@]}"; do
  EXCLUDE_LIST[i]=${EXCLUDE_LIST[i]##/}
done
for i in "${EXCLUDE_LIST[@]}"; do echo $i; done
#! /bin/bash

##  
##  file: atx2pcv.sh
##  most of the work is done in the prepare_atx2pcv.py
##+ script; type atx2pcv.sh -h for help/usage
##  

rm run_atx2pcv.sh 2>/dev/null

##  call prepare_atx2pcv.py to create the script
##+ that call the perl module, plus makes all
##+ the required checks.
if ! prepare_atx2pcv.py "$@" --shell-script=run_atx2pcv.sh ; then
  exit 1
fi

##  if the user has specified '-h' nothing more to do ...
for i in "$@"; do 
  if test "$i" = "-h" ; then 
    exit 0
  fi
done

##  make it executable and run !
chmod +x run_atx2pcv.sh
./run_atx2pcv.sh
status=$?

rm run_atx2pcv.sh 2>/dev/null

##  return the status from run_atx2pcv.sh
exit $status

#! /bin/bash

##  
##  file: snx2sta.sh
##  most of the work is done in the prepare_snx2sta.py
##+ script; type snx2sta.sh -h for help/usage
##  

rm run_snx2sta.sh 2>/dev/null

##  call prepare_snx2sta.py to create the script
##+ that call the perl module, plus makes all
##+ the required checks.
if ! ./prepare_snx2sta.py "$@" --shell-script=run_snx2sta.sh ; then
  exit 1
fi

##  if the user has specified '-h' nothing more to do ...
for i in "$@"; do 
  if test "$i" = "-h" ; then 
    exit 0
  fi
done

##  make it executable and run !
chmod +x run_snx2sta.sh
./run_snx2sta.sh

exit $?

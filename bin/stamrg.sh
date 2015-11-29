#! /bin/bash

##  
##  file: stamrg.sh
##  most of the work is done in the prepare_stamrg.py
##+ script; type stamrg.sh -h for help/usage
##  

rm run_stamrg.sh 2>/dev/null

##  call prepare_stamrg.py to create the script
##+ that call the perl module, plus makes all
##+ the required checks.
if ! prepare_stamrg.py "$@" --shell-script=run_stamrg.sh ; then
  exit 1
fi

##  if the user has specified '-h' nothing more to do ...
for i in "$@"; do 
  if test "$i" = "-h" ; then 
    exit 0
  fi
done

##  make it executable and run !
chmod +x run_stamrg.sh
./run_stamrg.sh

rm run_stamrg.sh 2>/dev/null

exit $?

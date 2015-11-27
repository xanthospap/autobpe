#! /bin/bash

##
##  This script will read a ddprocess config file and source all
##+ variables listed therein.
##
##  Provide the file as command line argument
##  
##  The variables will be written to stdout, as e.g.
##+ 'export FOO=BAR'
##+ so in the parent script, you will need to:
##+ eval $(./source_dd_config.sh)
##

if test "${#}" -ne 1 ; then
  echo 1>&2 "[ERROR] You need to specify a config file."
  exit 1
fi

grep "^\s*[^#].*=.*$" config.template \
        | sed 's/ //g' \
        | awk -F"=" '/.*=.+/ {print "export",$0}'

exit 0

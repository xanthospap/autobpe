#! /usr/bin/awk -f

##
##  Given a result file from validate_ntwrnx.py, this script will
##+ filter the names of the rinex which are marked as 'AVAILABLE'
##+ and are not marked 'EXCLUDED'.
##
##  It will print the filtered rinex names to stdout.
##
##  Usage: filter_available_reference.awk <validate_ntwrnx.py output>
##

NR==1 {
  if ( $0 != ("RINEX           MARKER NAME      AVAILABLE REFERENCE EXCLUDED") ) 
  {
    print "ERROR. Invalid file !" > "/dev/stderr"
    exit 1
  }
}

{
  avail = substr($0, 34, 3)
  exclu = substr($0, 54, 2)
  if ( avail == "Yes" && exclu == "No" )
  {
    rinex = substr($0, 0, 16)
    gsub(/ *$/, "", rinex)
    print rinex
  }
}

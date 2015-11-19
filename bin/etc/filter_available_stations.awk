#! /usr/bin/awk -f

##
##  Given a result file from validate_ntwrnx.py, this script will
##+ filter the names of the all available stations which are not
##+ marked 'EXCLUDED'.
##
##  It will print the filtered names to stdout.
##
##  Usage: filter_available_reference.awk <validate_ntwrnx.py output>
##
##  The station names can be whatever the 'MARKER NAME' column holds,
##+ (either with marker number or not).
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
    name = substr($0, 17, 16)
    gsub(/ *$/, "", name)
    print name
  }
}

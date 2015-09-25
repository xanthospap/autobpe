#! /usr/bin/awk -f

NR==1 {
  if ( $0 != ("RINEX           MARKER NAME      AVAILABLE REFERENCE") ) {
    print "ERROR. Invalid file !" > "/dev/stderr"
    exit 1
  }
}

{
  answ = substr($0, 34, 3)
  if (answ == "Yes")
  {
    rinex = substr($0, 0, 16)
    gsub(/[[:blank:]]+$/, "", rinex)
    printf "%-15s\n", rinex
  }
}

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
    name = substr($0, 17, 16)
    gsub(/ *$/, "", name)
    print name
  }
}

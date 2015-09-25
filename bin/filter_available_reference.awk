#! /usr/bin/awk -f

NR==1 {
  if ( $0 != ("RINEX           MARKER NAME      AVAILABLE REFERENCE") ) {
    print "ERROR. Invalid file !" > "/dev/stderr"
    exit 1
  }
}

{
  answ1 = substr($0, 34, 3)
  answ2 = substr($0, 44, 3)
  if (answ1 == "Yes" && answ2 == "Yes")
  {
    name = substr($0, 17, 16)
    gsub(/[[:blank:]]+$/, "", name)
    printf "%-16s\n", name
  }
}

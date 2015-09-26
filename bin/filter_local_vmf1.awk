#! /usr/bin/gawk -f

NR==1 {
  if ( $1 != "Downloaded" &&  $3 != "to") {
    print "ERROR. Invalid file !" > "/dev/stderr"
    exit 1
  }
}

{
  print $4
}

END {
  if ( NR != 4 ) {
    print "ERROR. Invalid file !" > "/dev/stderr"
    exit 1
  }
}

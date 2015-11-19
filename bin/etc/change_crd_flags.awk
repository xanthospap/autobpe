#! /usr/bin/gawk -f

NR==5 {
  if ( $0 != "NUM  STATION NAME           X (M)          Y (M)          Z (M)     FLAG") {
    print "ERROR. Invalid CRD file !" > "/dev/stderr"
    exit 1
  }
}
NR < 7 {
  print $0
}

NR >=7 {
    if (REPLACE_ALL == "YES")
    {
      print substr($0, 0, 66),"   ",FLAG
    }
    else
    {
     if ( $(NF) ~ /[A-Z]+\s*$/) {
       print substr($0, 0, 66),"   ",FLAG
     } else {
      print $0
     }

    }
}

#! /usr/bin/gawk -f

function is_positive_int(x){
  return(x == x+0 && x > 0)
}

BEGIN {
  if ( !is_positive_int(num_of_clu) ) {
    printf "ERROR. Invalid argument to make_cluster.awk [%s]\n", num_of_clu
    exit 1
  }


  print "Cluster file automaticaly created by ddproces"
  print "\
--------------------------------------------------------------------------------\
"
  print ""
  print "STATION NAME      CLU"
  print "****************  ***"

  noc = num_of_clu
  ccl = 1
}

{
  printf "%-16s  %-3i\n", $0, ccl
  if (! (NR % noc) )
    ccl++
}

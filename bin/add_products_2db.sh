#! /bin/bash

##  argv1  -> campaign name
##  argv2  -> satsys
##  argv3  -> soltype
##  argv4  -> prodtype
##  argv5  -> time start
##  argv6  -> time stop
##  argv7  -> time processed
##  argv8  -> host ip
##  argv9  -> host dir
##  argv10 -> filename
##  argv11 -> comment

##  Database parameters
echo "DB HOSTNAME : ${DB_HOST}"
echo "DB USERAME  : ${DB_USER}"
echo "DB_PASSWORD : ${DB_PASSWORD}"
echo "DB_NAME     : ${DB_NAME}"
echo "YEAR        : ${YEAR}"
echo "DOY         : ${DOY_3C}"


mysql -h "${DB_HOST}" \
      --user="${DB_USER}" \
      --password="${DB_PASSWORD}" \
      --database="${DB_NAME}" \
      --execute="INSERT INTO product \ 
      (network_id, software_id, satsys_id, soltype_id, \
       prodtype_id, date_process, dateobs_start, dateobs_stop, \
       host_name,pth2dir,filename,prcomment) \
       VALUES ( \
        (SELECT network_id FROM network \
          WHERE network_name=\"GREECE\"), \
        (SELECT software_id FROM software \
          WHERE software_name=\"BERN52\"), \
        (SELECT satsys_id FROM satsys \
          WHERE satsys_name=\"GPS\"), \
        (SELECT soltype_id FROM soltype \
          WHERE soltype_name=\"DDFINAL\"), \
        (SELECT prodtype_id FROM prodtype \
          WHERE prodtype_name=\"SINEX\"), \
        \"2015-10-02 12:13:12\", \
        \"2015-10-02 00:13:12\", \
        \"2015-10-02 23:13:12\", \
        \"147.102.110.69\", \
        \"/test/\", \
        \"asdf.asdf\",\ 
        \"test mess\") ;"

exit 0

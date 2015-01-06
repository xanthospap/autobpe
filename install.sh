#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : install.sh
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : NOV-2014
## usage                 : 
## exit code(s)          :   0 -> success
##                       255-1 -> error
##                           1 -> warning
## discription           : 
## uses                  : 
## dependancies          : 
## notes                 :
## TODO                  :
## detailed update list  :
                           LAST_UPDATE=NOV-2014
##
################################################################################

STATUS=0  ## status
PWD=`pwd` ## where are we ?
FORCE=NO  ## force install if previous version found
FAIL_W=NO ## exit if warning
## list of bash shell scripts
BSS=(syncwbern_52.sh wgetepnrnx.sh wgetigsrnx.sh wgetregrnx.sh wgeturanus.sh \
  comparesta.sh extractStations.sh setpcl.sh\
  gutils/wgetorbit.sh gutils/wgeterp.sh gutils/wgetion.sh gutils/wgetvmf1.sh)
## list of prequisities
PRG=(crx2rnx rnx2crx runpkr00 uncompress getopt)
LINKP=/usr/local/bin ## default installation directory
PYFLIST=bpepy/.python.file.list ## file with list of installed python modules
UMANDIR=/usr/local/man/man1 ## default man directory
UNINSTALL=NO ## uninstall package
ADD_HTML=NO ## add html man pages

# uninstall scripts
function del_exe {
  for i in "${BSS[@]}"; do
    exe=`basename ${i} | sed 's|.sh||g'`
    if [ -f ${LINKP}/${exe} ]; then
      rm ${LINKP}/${exe}
    fi
  done
}
# uninstall man pages
function del_man {
  for i in "${BSS[@]}"; do
    manp=`basename ${i} | sed 's|.sh|.1|g'`
    if [ -f ${UMANDIR}/${manp}.gz ]; then
      rm ${UMANDIR}/${manp}.gz
    fi
  done
}
# uninstall py modules
function del_pym {
  if [ -f "$PYFLIST" ]; then
    cat $PYFLIST | xargs rm -rf 2>/dev/null
  else
    echo "No Python file list found in $PYFLIST"
  fi
}

function help {
  echo ""
  echo "Script : install.sh"
  echo "Purpose: install or uninstall AutoBpe Utils package"
  echo "Usage  : install.sh [-f -w -u -h]"
  echo "Arguments:"
  echo "  -f force remove any previous version"
  echo "  -w stop if warning occurs"
  echo "  -u uninstall package"
  echo "  -h display help massage"
  echo "  -i add html man pages; these will reside in man/html"
  echo "Script must be run with root priviladges"
  echo ""
  exit 0;
}

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o fwuhi -n 'install.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt fwuhi "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -f)
      FORCE=YES;;
    -w)
      FAIL_W=YES;;
    -u)
      UNINSTALL=YES;;
    -i)
      ADD_HTML=YES;;
    -h)
      help;;
    --) # end of options
      shift; break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 254 ;;
  esac
  shift 
done
# //////////////////////////////////////////////////////////////////////////////

#
# STEP -1 : UNINSTALL
#
if [ "$UNINSTALL" == "YES" ]; then
  echo "Uninstalling package AutoBpe Utils"
  if [ ! -d "${LINKP}" ]; then LINKP=/usr/bin; fi
  del_exe
  #for i in 8 7 6 5 4 3; do if [ -d /usr/local/man/man${i} ]; then UMANDIR=/usr/local/man/man${i}; break; fi; done
  del_man
  del_pym
  exit 0
fi

echo "Installing package AutoBpe Utils"

#
# STEP 0 : CHECK THAT THE USER IS ROOT
#
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] script must be run as root; installation terminated"
  exit 254
fi

#
# STEP 1 : INSTALL (i.e. link) THE SHELL SCRIPTS
#
echo "  * installing shell executables"
# decide the location to link the shell executables
if [ ! -d "${LINKP}" ]; then LINKP=/usr/bin; fi
if [ ! -d "${LINKP}" ]; then
  echo "[ERROR] Cannot detect bin directory for user. Missing /usr/local/bin" 
  echo "[ERROR] and /usr/bin; installation terminated"
  exit 254
fi
echo "    Installing shell scripts to ${LINKP}"
# check for previous versions
for i in "${BSS[@]}"; do
  exe=`basename ${i} | sed 's|.sh||g'`
  if [ -L ${LINKP}/${exe} ]; then
    if [ "${FORCE}" == "NO" ]; then
      echo "[ERROR] previous version detected; installation terminated"
      exit 254
    else
      rm ${LINKP}/${exe}
    fi
  fi
done
# link shell scripts to the bin path
for i in "${BSS[@]}"; do
  if [ ! -f bash/${i} ]; then
    echo "[ERROR] Missing bash script ${i}; installation terminated"
    exit 254
  else
    chmod +x bash/${i}
    bash/${i} -v
    exe=`basename ${i} | sed 's|.sh||g'`
    ln -s ${PWD}/bash/${i} ${LINKP}/${exe}
  fi
done

#
# STEP 2 : CHECK FOR THE PREQUISITIES
#
echo "  * checking for dependancies"
# check that all prequisities are available
for i in "${PRG[@]}"; do
  if ! type "$i" &>/dev/null; then
    echo "[WARNING] Program $i not installed or not set in PATH; some scripts may not work"
    STATUS=1
    if [ "$FAIL_W" == "YES" ]; then exit ${STATUS}; fi
  fi
done

#
# STEP 3 : CHECK getopt
#
echo "  * checking getopt version"
# check getopt version; warn for long options
getopt -T &>/dev/null
if [ $? -ne 4 ]; then
  # Original getopt is available (no long option names, no whitespace, no sorting)
  echo "[WARNING] GNU/getopt not detected; only use short options"
  STATUS=1
  if [ "$FAIL_W" == "YES" ]; then exit ${STATUS}; fi
fi

#
# STEP 4 : INSTALL PYTHON LIBRARIES
#
echo "  * installing python modules"
# install python libraries
cd bpepy/
python setup.py install --record .python.file.list &>/dev/null
if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to install python libraries; installation terminated"
  cd ../
  exit 254
fi
cd ../

#
# STEP 4.5 : INSTALL C++ LIBRARIES
#
echo "  * installing C++ modules"
cd C-dist/src
make
if test $? -ne 0 ; then
  echo "[ERROR] Failed to install C++ libraries; installation terminated"
  exit 254
fi
cd ../../

#
# STEP 5 : INSTALL MAN PAGES
#
echo "  * installing man pages"
# decide where to install man pages
#I=0
#for i in 8 7 6 5 4 3; do
#  if [ -d /usr/local/man/man${i} ]; then
#    I=${i}
#    break;
#  fi
#done
#if [ "${I}" == "0" ]; then
#  echo "[ERROR] Failed to detect man page location; installation terminated"
#  exit -1
#else
#  echo "    Installing man pages in /usr/local/man/man${I}"
#fi
UMANDIR=/usr/local/man/man1
# check for previous versions
for i in "${BSS[@]}"; do
  manp=`basename ${i} | sed 's|.sh|.1|g'`
  if [ -f ${UMANDIR}/${manp}.gz ]; then
    if [ "${FORCE}" == "NO" ]; then
      echo "[ERROR] previous version detected; installation terminated"
      exit 254
    else
      rm ${UMANDIR}/${manp}.gz
    fi
  fi
done
# install man pages
if [ "$ADD_HTML" == "YES" ]; then mkdir man/html 2>/dev/null; fi
for i in "${BSS[@]}"; do
  manp=`basename ${i} | sed 's|.sh|.1|g'`
  if [ ! -f man/${manp} ]; then
    echo "[WARNING] Missing man page for script ${i}; skipped"
    STATUS=1
  else
    install -g 0 -o 0 -m 0644 man/${manp} ${UMANDIR}
    gzip ${UMANDIR}/${manp}
    if [ "$ADD_HTML" == "YES" ]; then 
      cat man/${manp} | groff -mandoc -Thtml > man/html/`basename ${i} | sed 's|.sh|.htm|g'`
    fi
  fi
done

#
# STEP 6 : EXIT
#
exit $STATUS

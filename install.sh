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
##                           1 -> error
##                           2 -> warning
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
RPWD=`pwd` ## where are we ?
FORCE=NO  ## force install if previous version found
FAIL_W=NO ## exit if warning

## list of bash shell scripts
BSS=()

## list of prequisities
PRG=(crx2rnx rnx2crx runpkr00 uncompress getopt)

## default installation directory
INSTDIR=/usr/local/bin

## file with list of installed python modules
PYFLIST=bpepy/.python.file.list

## default man directory
MANDIR=/usr/local/man/man1

## uninstall package
UNINSTALL=NO

## add html man pages
ADD_HTML=NO

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
  echo "  -d installation directory (default is $INSTDIR)"
  echo "  -m man pages directory (default is $MANDIR)"
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
  ARGS=`getopt -o fwuhid:m: -n 'install.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt fwuhid:m: "$@"`
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
    -d)
      INSTDIR="${2}"; shift;;
    -m)
      MANDIR="${2}"; shift;;
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
# STEP 0.0 : CHECK THAT THE USER IS ROOT
#
#if [ "$EUID" -ne 0 ]; then
#  echo "[ERROR] script must be run as root; installation terminated"
#  exit 1
#fi

#
# STEP 0.0 : CHECK THAT INSTALL AND MAN PAGE DIRS EXIST
#
if ! test -d $INSTDIR
then
  printf "[ERROR] Could not find installation directory : $INSTDIR \n"
  printf "Installation terminated\n"
  exit 1
fi
if ! test -d $MANDIR
then
  printf "[ERROR] Could not find man-page directory : $MANDIR \n"
  printf "Installation terminated \n"
  exit 1
fi

printf "#########################################################################\n"
printf "                   Installing package AutoBpe Utils\n"
printf "#########################################################################\n"
printf " Installation Directory $INSTDIR\n"
printf " Man-Page Directory     $MANDIR\n"

#
# STEP 0.1 : CHECK FOR THE PREQUISITIES
#
printf " Checking for dependancies\n"
# check that all prequisities are available
for i in "${PRG[@]}"; do
  if ! type "$i" &>/dev/null; then
    printf "\t[WARNING] Program $i not installed or not set in PATH; some scripts may not work"
    STATUS=2
    if [ "$FAIL_W" == "YES" ]
    then 
      printf "[FATAL]\n"
      exit ${STATUS}
    else
      printf "[WARNINGS IGNORED]\n"
    fi
    else
      p=`which $i`
      printf "\tProgram $i found as $p \n"
  fi
done

#
# STEP 0.2 : CHECK getopt
#
printf " Checking getopt version ... "
# check getopt version; warn for long options
getopt -T &>/dev/null
if [ $? -ne 4 ]; then
  # Original getopt is available (no long option names, no whitespace, no sorting)
  printf "\n\t[WARNING] GNU/getopt not detected; only use short options\n"
  STATUS=2
  if [ "$FAIL_W" == "YES" ]; then exit ${STATUS}; fi
else
  printf "GNU enhanced version available [OK]\n"
fi

#
# STEP 0.3 : CHECK g++
#
printf " Checking GNU/gcc version ... "
GCCV=`g++ --version | head -n1 | awk '{print $4}' | sed 's|\.||g'`
if test $? -ne 0
then
  printf " \n[ERROR] Cannot locate GNU/g++\n"
  exit 1
fi
python -c "
import sys
vrs = '$GCCV'
if vrs < 450:
  sys.exit(1)
else:
  sys.exit(0)"
if test $? -ne 0
then
  printf "\n\t[WARNING] Found g++ version $GCCV ; You should change the\n"
  printf "\tmakefiles in src/cpp/* according to src/cpp/xyz2flh/readme\n"
else
  printf "found g++ version $GCCV [OK]\n"
fi

#
# STEP 0.5 : GET A LIST OF ALL BASH SHELL SCRIPTS TO INSTALL
#
BSS=( $(find src/ -type f -name "*.sh") )
printf " Getting list of (bash) shell scripts ... "
# for i in "${BSS[@]}"; do printf "\t$i\n"; done
printf " found ${#BSS[@]} programs\n"

#
# STEP 1.0 : INSTALL (i.e. link) THE SHELL SCRIPTS
#
printf " Installing shell executables\n"

# check for previous versions
for i in "${BSS[@]}"; do
  exe=`basename ${i} | sed 's|.sh||g'`
  if [ -L ${INSTDIR}/${exe} ]; then
    if [ "${FORCE}" == "NO" ]; then
      printf " [ERROR] previous version detected; installation terminated\n"
      printf " [HINT]  -- use the -f switch to overwrite\n"
      exit 1
    else
      rm ${INSTDIR}/${exe}
    fi
  fi
done

# link shell scripts to the bin path
for i in "${BSS[@]}"; do
  if [ ! -f ${RPWD}/${i} ]; then
    printf " [ERROR] Missing bash script ${i}; installation terminated\n"
    exit 1
  else
    chmod +x ${RPWD}/${i}
    ##${RPWD}/${i} -v
    exe=`basename ${i} | sed 's|.sh||g'`
    ln -sf ${RPWD}/${i} ${INSTDIR}/${exe}
  fi
done

printf " Done! shell executables installed successefuly\n"

#
# STEP 2.0 : INSTALL PYTHON LIBRARIES
#
printf " Installing python modules\n"
# install python libraries
cd src/python
python setup.py install --record ../../.python.file.list &>/dev/null
if [ $? -ne 0 ]; then
  printf " [ERROR] Failed to install python libraries; installation terminated\n"
  cd ${RPWD}
  exit 1
fi
cd ${RPWD}

#
# STEP 2.2 : CHECK INSTALLED PYTHON LIBRARIES
#
printf " Checking python modules ... "
python -c "
import bpepy.gpstime
import bpepy.products.orbits" 2>/dev/null
if [ $? -ne 0 ]; then
  printf " [ERROR] Failed to load installed python modules; installation failed!\n"
  exit 1
else
  printf " OK!\n Python modules installed successefuly (summary written in ../../.python.file.list)\n"
fi

#
# STEP 4.5 : INSTALL C++ LIBRARIES
#
printf " Installing C++ modules\n"
rm .stamp.file 2>/dev/null
touch .stamp.file
cd src/cpp
if test $? -ne 0
then
  printf "\n\t[ERROR] Failed to locate cpp directory!\n"
  cd $RPWD
  exit 1
fi
CSS=( $(find ./* -type d -not -name "*bin*") )
for i in "${CSS[@]}"
do
  cd $i && make &>/dev/null
  if test $? -ne 0
  then
    printf " [ERROR] Failed to compile dir : src/cpp/${i}\n"
    cd $RPWD
    exit 1
  else
    printf "\tCompiled module src/cpp/${i} [OK]\n"
    cd ../
  fi
done
printf "\tLinking programs ... "
#CSS=( $(find bin/ -type f -name "*.e" -cnewer ../../.stamp.file) )
CSS=( $(find bin/ -type f -name "*.e") )
# link programs to the bin path
COUNTER=0
for i in "${CSS[@]}"; do
  chmod +x ${i}
  exe=`basename ${i} | sed 's|.e||g'`
  ln -sf ${RPWD}/src/cpp/${i} ${INSTDIR}/${exe}
  let COUNTER=COUNTER+1
  printf "\n\t${i} -> ${INSTDIR}/${exe}"
done
printf "\n linked $COUNTER / ${#CSS[@]} [OK]\n"
rm ../../.stamp.file 2>/dev/null
cd $RPWD

exit 0
##################################################################################################
#

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

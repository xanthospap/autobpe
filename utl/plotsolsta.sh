#! /bin/bash

## argv1 -> Year (4-digit)
## argv2 -> Doy (3-digit)
## argv3 -> Solution summary file (e.g. FFGYYYYDDD0.SUM.Z)
## argv4 -> (Final) Coordinate estimates file (e.g. FFG${YR}${DOY}0.CRD.Z)
## argv5 -> Solution output file (e.g. FFGYYYYDDD0.OUT.Z)
## argv6 -> Network name
## argv7 -> Solution tye: 'f' for final, or 'u' for rapid/ultra-rapid
## argv8 -> temporary directory

#////////////////////////////////////////////////////////////
# Plot processed station maps for all networks
#////////////////////////////////////////////////////////////
export PATH="${PATH}:/usr/local/bin"
export PATH="$PATH:/usr/lib/gmt/bin"

echo "START plot MAPS"

# ///////////// READ ARGV ////////////////////////
YEAR=${1}
YR=${YEAR:(-2)}
DOY=${2}
SUM_FILE=${3}
CRD_FILE=${4}
OUT_FILE=${5}
NETN=${6^^}
netn=${6,,}
SOL_TYPE=${7}
TMP_DIR=${8}

if test "$SOL_TYPE" == "f"
then 
  solt=final
else
  solt=urapid
fi

if ! marksolsta2.sh \
  -y $YEAR \
  -d $DOY \
  -c /home/bpe2/tables/crd/GREECE.CRD \
  -s ${SUM_FILE}  \
  -f ${CRD_FILE} \
  -o ${OUT_FILE} \
  > ${TMP_DIR}/${netn}-${YR}${DOY}-${SOL_TYPE}.proc

/home/bpe2/maps/plot_proc.sh -y ${YEAR} \
  -d ${DOY} \
  -n ${netn} \
  -r europe \
  -t ${solt}  \
  -jpg \
  -bl \
  -hlmell \
  -i ${TMP_DIR}/${netn}-${YR}${DOY}-${SOL_TYPE}.proc \
  -o ${TMP_DIR}/${netn}-${YR}${DOY}-${SOL_TYPE}-europe.ps

/home/bpe2/maps/plot_proc.sh -y ${YEAR} \
  -d ${DOY} \
  -n ${netn} \
  -r greece \
  -t ${solt} \
  -jpg \
  -bl \
  -staall \
  -staproc \
  -l \
  -i ${TMP_DIR}/${netn}-${YR}${DOY}-${SOL_TYPE}.proc \
  -o ${TMP_DIR}/${netn}-${YR}${DOY}-${SOL_TYPE}-greece.ps

echo "Finished succesful"

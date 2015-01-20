#! /bin/bash

AMBFILE=AMB150010.SUM

## read and write the Code-Based WL
if ! ./block_amb_read.sh --summary-file=$AMBFILE --method=cbwl &>.tmp.cwl ; then
  echo "***ERROR! Failed to read Code-Based WL from file : $AMBFILE"
  exit 254
fi

## read and write the Code-Based NL
if ! ./block_amb_read.sh --summary-file=$AMBFILE --method=cbnl &>.tmp.cnl ; then
  echo "***ERROR! Failed to read Code-Based NL from file : $AMBFILE"
  exit 254
fi

## read and write the Phase-Based WL
if ! ./block_amb_read.sh --summary-file=$AMBFILE --method=pbwl &>.tmp.pwl ; then
  echo "***ERROR! Failed to read Phase-Based WL from file : $AMBFILE"
  exit 254
fi

## read and write the Phase-Based NL
if ! ./block_amb_read.sh --summary-file=$AMBFILE --method=pbnl &>.tmp.pnl ; then
  echo "***ERROR! Failed to read Phase-Based NL from file : $AMBFILE"
  exit 254
fi

## read and write the QIF
if ! ./block_amb_read.sh --summary-file=$AMBFILE --method=qif &>.tmp.qif ; then
  echo "***ERROR! Failed to read QIF from file : $AMBFILE"
  exit 254
fi

## read and write the DIRECT
if ! ./block_amb_read.sh --summary-file=$AMBFILE --method=dir &>.tmp.dir ; then
  echo "***ERROR! Failed to read DIRECT L1/L2 from file : $AMBFILE"
  exit 254
fi

echo "<table>"
echo "<title>Ambiguity Resolution Summary</title>"
echo "<tgroup cols=\"14\">"
for i in `seq 1 14`
do
  echo "<colspec colname=\"c${i}\" />"
done
echo "<spanspec spanname=\"hspan12\" namest=\"c1\" nameend=\"c2\" align=\"center\" />"
echo "<spanspec spanname=\"hspan45\" namest=\"c4\" nameend=\"c5\" align=\"center\" />"
echo "<spanspec spanname=\"hspan67\" namest=\"c6\" nameend=\"c7\" align=\"center\" />"
echo "<spanspec spanname=\"hspan01\" namest=\"c10\" nameend=\"c11\" align=\"center\" />"

echo "<thead>"
echo "<row>"
echo "<entry>Station 1</entry>"
echo "<entry>Station 2</entry>"
echo "<entry>Length</entry>"
echo "<entry spanname=\"hspan45\">Before</entry>"
echo "<entry spanname=\"hspan67\">After</entry>"
echo "<entry>Resolved</entry>"
echo "<entry>Sat. System</entry>"
echo "<entry spanname=\"hspan01\">Max/RMS L5</entry>"
echo "<entry>Receiver 1</entry>"
echo "<entry>Receiver 2</entry>"
echo "</row>"
echo "<row>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "<entry>(km)</entry>"
echo "<entry>#Amb</entry>"
echo "<entry>(mm)</entry>"
echo "<entry>#Amb</entry>"
echo "<entry>(mm)</entry>"
echo "<entry>(%)</entry>"
echo "<entry></entry>"
echo "<entry spanname="hspan01">(L5 Cycles)</entry>"
echo "<entry></entry>"
echo "<entry></entry>"
echo "</row>"
echo "</thead>"

echo "<tfoot>"
echo "<row>"
echo "<entry spanname=\"hspan12\">Total</entry>"
echo "<entry>TOT_LENGTH</entry>"
echo "<entry>TOT_BEF_AMB</entry>"
echo "<entry>TOT_BEF_MM</entry>"
echo "<entry>TOT_AFT_AMB</entry>"
echo "<entry>TOT_AFT_MM</entry>"
echo "<entry>TOT_RES</entry>"
echo "<entry>TOT_SYS</entry>"
echo "<entry>TOT_RMS_1</entry>"
echo "<entry>TOT_RMS_2</entry>"
echo "<entry> - </entry>"
echo "<entry> - </entry>"
echo "</row>"
echo "</tfoot>"

echo "<tbody>"

## AMBIGUITY INFO
echo "<!-- Code-Based Wide Lane -->"
cat .tmp.cwl
echo "<!-- Code-Based Narrow Lane -->"
cat .tmp.cnl
echo "<!-- Phase-Based Wide Lane -->"
cat .tmp.pwl
echo "<!-- Phase-Based Narrow lane -->"
cat .tmp.pnl
echo "<!-- Q I F -->"
cat .tmp.qif
echo "<!-- Direct L1 / L2 -->"
cat .tmp.dir


echo "</tbody>"

echo "</tgroup>"
echo "</table>"

# //////////////////////////////////////////////////////////////////////////////
# REMOVE TEMPORARY FILE
# //////////////////////////////////////////////////////////////////////////////
rm .tmp .tmp.??? 2>/dev/null
exit 0
echo off 
psxy elevRings.dat  -R-1.6/1.6/-1.6/1.6 -JX18.0  -W1.0p,black,solid -G230 -V -K -P -X1.5 -Y2.0 > skyplot.ps 
psxy cutoffRing.dat -R -JX -W.7p,black,-  -G255 -V  -O -K -P >> skyplot.ps 
psxy elevRings.dat  -R -JX -W1.0p,black,solid -V  -O -K -P >> skyplot.ps 
#psxy elevRings.dat  -R -JX -W0.5p,red,solid  -V  -O -K -P >> skyplot.ps 
pstext title.txt -R -JX -F+a0+jCM+f -N -V  -O -K -P >> skyplot.ps 
psvelo mp.xy  -R -JX  -L -Ggreen -W1.5p,green,solid -Se1.5/0.95/0 -A0.0 -N  -h0 -O -K -P -V >>  skyplot.ps 
psxy 1.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 2.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 4.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 5.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 6.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 7.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 8.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 9.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 10.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 11.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 12.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 13.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 14.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 15.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 16.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 17.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 18.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 19.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 20.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 21.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 22.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 23.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 24.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 25.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 26.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 27.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 28.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 29.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 30.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 31.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy 32.sat.xy -R -JX -W0.10p,black,solid -V -P -O -K >> skyplot.ps
psxy hr.xy  -R -JX -V  -Sc0.03 -G0/0/0  -O -K -P >> skyplot.ps 
pstext hr.txt -R -JX -V -F+a0+jML+f6p,Helvetica,blue -O -K -P >> skyplot.ps 
psxy cross.txt  -R -JX   -V -O -K -P >> skyplot.ps 
pstext nesw.txt  -R  -JX -F+a0+jCM+f10p,Helvetica,black -O -K  -N   >> skyplot.ps 
psvelo arrows.xy  -R -JX  -L  -W1.0p,red,solid -Se4/0.95/10 -A0.040/0.045/0.055  -Gred -N  -h0 -O -K -P -V >>  skyplot.ps 
pstext ring.txt -R -JX -F+a0+jCM+f8p,Helvetica,black -O -N -T -W0.5,black,solid -Gwhite  >> skyplot.ps 
echo ------------------------------ 
echo ------------------------------ 
echo View or print skyplot.ps 
echo on 
rm -f *.sat.xy arrows.xy cross.txt cutoffRing.dat elevRings.dat ring.txt hr.txt hr.xy mp.xy nesw.txt skyplot.AzEl title.txt

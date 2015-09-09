=============================
Moduleproducts
=============================

----------------------------------
DCB files (Differential Code Bias)
----------------------------------

DCB files are always downloaded from CODE's ftp archive. Depending on the latency
they can be placed in different directories: old DCB files are archived into
yearly directories, while the running average is placed at the root folder.

Available Code Differential Bias files from CODE are (see [aiub-ftp-readme]_):

* ftp://ftp.unibe.ch/aiub/CODE/

  * **P1C1.DCB**
    CODE sliding 30-day P1-C1 DCB solution, Bernese
    format, containing only the GPS satellites
  * **P1P2.DCB**
    CODE sliding 30-day P1-P2 DCB solution, Bernese
    format, containing all GPS and GLONASS satellites
  * **P1P2_ALL.DCB**
    CODE sliding 30-day P1-P2 DCB solution, Bernese
    format, containing all GPS and GLONASS satellites
    and all stations used
  * **P1P2_GPS.DCB**
    CODE sliding 30-day P1-P2 DCB solution, Bernese
    format, containing only the GPS satellites
  * **P1C1_RINEX.DCB**
    CODE sliding 30-day P1-C1 DCB values directly 
    extracted from RINEX observation files, Bernese 
    format, containing the GPS and GLONASS satellites
    and all stations used
  * **P2C2_RINEX.DCB**
    CODE sliding 30-day P2-C2 DCB values directly
    extracted from RINEX observation files, Bernese 
    format, containing the GPS and GLONASS satellites
    and all stations used
  * **CODE.DCB**
    Combination of P1P2.DCB and P1C1.DCB
  * **CODE_FULL.DCB**
    Combination of P1P2.DCB, P1C1.DCB (GPS satellites),
    P1C1_RINEX.DCB (GLONASS satellites), and P2C2_RINEX.DCB

  .. note::
    As soon as a final product is available the corresponding rapid,
    ultra-rapid, or predicted product is removed from the aftp server.

* ftp://ftp.unibe.ch/aiub/CODE/yyyy/

  * **P1C1yymm.DCB.Z**
    CODE monthly P1-C1 DCB solution, Bernese format,
    containing only the GPS satellites
  * **P1P2yymm.DCB.Z**
    CODE monthly P1-P2 DCB solution, Bernese format,
    containing all GPS and GLONASS satellites
  * **P1P2yymm_ALL.DCB.Z**
    CODE monthly P1-P2 DCB solution, Bernese format,
    containing all GPS and GLONASS satellites and all
    stations used
  * **P1C1yymm_RINEX.DCB**
    CODE monthly P1-C1 DCB values directly extracted
    from RINEX observation files, Bernese format, 
    containing the GPS and GLONASS satellites and all 
    stations used
  * **P2C2yymm_RINEX.DCB**
    CODE monthly P2-C2 DCB values directly extracted
    from RINEX observation files, Bernese format,
    containing the GPS and GLONASS satellites and all 
    stations used

.. note:: No DCBs are included in the ``REPRO_2013`` foolder.

The function :func:`bernutils.products.getCodDcb` uses the following translation table to
interpret the input parameter ``stype``.

+-----------------------------------+------------+---------------------------------+
| DCB file (remote)                 | string id  | Notes                           |
+===================================+============+=================================+
| P1C1.DCB                          |            | which of the two is selected,   |
+                                   +     ``c1`` + depends on the input date and   +
| P1C1yymm.DCB.Z                    |            | availability.                   |
+-----------------------------------+------------+---------------------------------+
| P1P2.DCB                          |            | which of the two is selected,   |
+                                   +     ``p2`` + depends on the input date and   +
| P1P2yymm.DCB.Z                    |            | availability.                   |
+-----------------------------------+------------+---------------------------------+
| P1P2_ALL.DCB                      |            |                                 |
+                                   +     -      + Not yet a valid choice          +
| P1P2yymm_ALL.DCB.Z                |            |                                 |
+-----------------------------------+------------+---------------------------------+
| P1P2_GPS.DCB                      |     -      | Not yet a valid choice          |
+-----------------------------------+------------+---------------------------------+
| P1C1_RINEX.DCB                    |            | which of the two is selected,   |
+                                   + ``c1_rnx`` + depends on the input date and   +
| P1C1yymm_RINEX.DCB                |            | availability.                   |
+-----------------------------------+------------+---------------------------------+
| P2C2_RINEX.DCB                    |            | which of the two is selected,   |
+                                   + ``c2_rnx`` + depends on the input date and   +
| P2C2yymm_RINEX.DCB                |            | availability.                   |
+-----------------------------------+------------+---------------------------------+
| CODE.DCB                          |     -      | Not yet a valid choice          |
+-----------------------------------+------------+---------------------------------+
| CODE_FULL.DCB                     |     -      | Not yet a valid choice          |
+-----------------------------------+------------+---------------------------------+

--------------------------------------
ERP (Earth Rotation Parameters) files
--------------------------------------

Earth Rotation Parameters files are produced by various Analysis Centers (AC) and
hence can be downloaded by various remote sources. In the ``bernutils`` library, two
ACs are available for downloading erp files, namely CODE and IGS.

CODE AC
^^^^^^^^

Available ERP files from CODE are (see [aiub-ftp-readme]_):

* ftp://ftp.unibe.ch/aiub/CODE/

  * **COD.ERP_U** 
    CODE ultra-rapid ERPs belonging to the ultra-rapid orbit product
  * **CODwwwwd.ERP_M** 
    CODE final rapid ERPs belonging to the final rapid orbits
  * **CODwwwwd.ERP_R** 
    CODE early rapid ERPs belonging to the early rapid orbits 
  * **CODwwwwd.ERP_P**
    CODE predicted ERPs belonging to the predicted 24-hour orbits
  * **CODwwwwd.ERP_P2**
    CODE predicted ERPs belonging to the predicted 48-hour orbits
  * **CODwwwwd.ERP_5D**
    CODE predicted ERPs belonging to the predicted 5-day orbits

  .. note::
    As soon as a final product is available the corresponding rapid,
    ultra-rapid, or predicted product is removed from the aftp server.

* ftp://ftp.unibe.ch/aiub/CODE/yyyy/

  * **CODwwwwd.ERP.Z**
    CODE final ERPs belonging to the final orbits
  * **CODwwww7.ERP.Z**
    collection of the 7 daily COD-ERP solutions of the week

* http://www.aiub.unibe.ch/download/REPRO_2013/BSWUSER52/yyyy/

  * **CODyyddd.ERP.Z**
    Daily final Earth rotation parameter files, Bernese format

* http://www.aiub.unibe.ch/download/REPRO_2013/CODE/yyyy/

  * **CODwwwwd.ERP.Z**
    Daily final Earth rotation parameter files, IERS format

The function used to download an erp file from CODE's remote server is 
:func:`bernutils.products.getCodErp`. 

+-------------------+-------------------+
| today - dt (days) | File to download  |
+===================+===================+
| > 5               |       -           |
+-------------------+-------------------+
| (3, 5]            | CODwwwwd.ERP_5D   |
+-------------------+-------------------+
| (1, 2]            | CODwwwwd.ERP_P2   |
+-------------------+-------------------+
| (0, 1]            | CODwwwwd.ERP_P    |
+-------------------+-------------------+
| (-1, 0]           | COD.ERP_U         |
+-------------------+-------------------+
| (                 |                   |
+-------------------+-------------------+

IGS AC
^^^^^^^^

todo!!

-----------------------------
Documentation
-----------------------------

.. automodule:: bernutils.products
   :members:
   :undoc-members:

-----------------------------
Examples
-----------------------------

If we want the dcb file containing the monthly P1-C1 DCB solution for GPS satellites, 
i.e. P1C1yymm.DCB for April 2014, saved in /home/foo/bar/ :

.. code-block:: python

  >>> import datetime
  >>> import bernutils.products

  >>> apr2014 = datetime.date(2014, 4, 1) # only need a date not datetime
  >>> result  = bernutils.products.getCodDcb('c1', apr2014, '/home/foo/bar/')
  >>> result
  >>> ('/home/foo/bar/P1C11404.DCB.Z', 'ftp.unibe.ch/aiub/CODE/2014/P1C11404.DCB.Z')

-----------------------------
References
-----------------------------

.. [aiub-ftp-readme] ftp://ftp.unibe.ch/aiub/AIUB_AFTP.TXT, last accessed Sep, 2015

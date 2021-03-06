***************
Module products
***************

DCB files (Differential Code Bias)
==================================

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

The function :func:`bernutils.products.pydcb.getCodDcb` uses the following translation table to
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

Documentation
-----------------------------

.. automodule:: bernutils.products.pydcb
   :members:
   :undoc-members:

Examples
-----------------------------

If we want the dcb file containing the monthly P1-C1 DCB solution for GPS satellites, 
i.e. P1C1yymm.DCB for April 2014, saved in /home/foo/bar/ :

.. code-block:: python

  >>> import datetime
  >>> import bernutils.products.pydcb

  >>> apr2014 = datetime.date(2014, 4, 1) # only need a date not datetime
  >>> result  = bernutils.products.pydcb.getCodDcb('c1', apr2014, '/home/foo/bar/')
  >>> result
  >>> ('/home/foo/bar/P1C11404.DCB.Z', 'ftp.unibe.ch/aiub/CODE/2014/P1C11404.DCB.Z')


ERP (Earth Rotation Parameters) files
======================================

Earth Rotation Parameters files are produced by various Analysis Centers (AC) and
hence can be downloaded by various remote sources. In the ``bernutils`` library, two
ACs are available for downloading erp files, namely CODE and IGS.

.. warning::

  In the following paragraphs, the AC-specific details for ERP files are summarized.
  However, it is recomended to use the AC-independent function :func:`bernutils.products.pyerp.getErp`
  to download any erp file (and **NOT** the versions per AC).

CODE AC
--------

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

* http://www.aiub.unibe.ch/download/REPRO_2013/CODE/yyyy/

  * **CODwwwwd.ERP.Z**
    Daily final Earth rotation parameter files, IERS format

* Also available !

  * **cofwwww7.erp.Z** One-day, final erp files from igs

  * ERPs generated for the igs REPRO2 campaign. These are available via the
    igs ftp server, in two versions:

    #. **cf2wwww7.erp.Z** from (CDDIS)/repro2/wwww/, and
    #. **co22wwww7.erp.Z** from (CDDIS)/repro2/wwww/

The function used to download a CODE-generated erp is 
:func:`bernutils.products.pyerp.getCodErp`.

+-------------------+--------------------+-------------------------------------+---------------------------------------------+
|                   |                    | FLAGS                               |                                             |
| today - dt (days) | File to download   +--------+-----------+----------------+  HOST + DIR                                 |
|                   |                    | REPRO2 | REPRO2013 | OneDaySolution |                                             |
+===================+====================+========+===========+================+=============================================+
| >= 15.0           | CODwwwwd.ERP.Z     | NO     | NO        | NO             | (CODE)/yyyy/                                |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | cf2wwww7.erp.Z     | YES    | NO        | YES            | (CDDIS)/repro2/wwww/                        |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | co22wwww7.erp.Z    | YES    | NO        | NO             | (CDDIS)/repro2/wwww/                        |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | cofwwww7.erp.Z     | NO     | NO        | YES            | (CDDIS)/wwww/                               |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | CODwwwwd.ERP.Z     | YES    | NO        | NO             | (CODE)/REPRO_2013/CODE/yyyy/                |
+-------------------+--------------------+--------+-----------+----------------+---------------------------------------------+
| [4, 15)           | First search for a valid final erp (as above)                                                          |
|                   +--------------------+-------------------------------------+---------------------------------------------+
|                   | CODwwwwd.ERP_M.Z   |                                     | (CODE)/yyyy_M/                              |
|                   +--------------------+          Ignored                    +---------------------------------------------+
|                   | CODwwwwd.ERP_M     |                                     | (CODE)/                                     |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+
| [0, 4)            | First search for a valid final rapid erp (as above)                                                    |
|                   +--------------------+-------------------------------------+---------------------------------------------+
|                   | CODwwwwd.ERP_R     |           Ignored                   | (CODE)/                                     |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+
| (0, -1]           | COD.ERP_U          |                                     |                                             |
|                   +--------------------+           Ignored                   | (CODE)                                      |
|                   | CODwwwwd.ERP_5D    |                                     |                                             |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+
| [-15, -1)         | CODwwwwd.ERP_5D    |           Ignored                   | (CODE)                                      |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+

IGS AC
-------

Available ERP files from IGS are (see [igs-products]_):

* **Ultra-Rapid** (predicted half) iguwwwwd_[00|06|12|18].erp.Z
* **Ultra-Rapid** (observed half) iguwwwwd_[00|06|12|18].erp.Z
* **Rapid** igrwwwwd.erp.Z
* **Final** igswwww7.erp.Z
* **igu00p01.erp.Z** Accumulated Ultra Rapid IGS erp files (in /products area 
  **NOT** archived by gps week)
* **ig2yyPwwww.erp.Z** igs repro2 erp files (in /products/repro2 area)

The function used to download an igs-generated erp file is 
:func:`bernutils.products.pyerp.getIGSErp`.

+-------------------+--------------------+--------+---------------------------------------------+
|                   |                    | FLAGS  |                                             |
| today - dt (days) | File to download   +--------+  HOST + DIR                                 |
|                   |                    | REPRO2 |                                             |
+===================+====================+========+=============================================+
| >= 17.0           | igswwww7.erp.Z     | NO     | (CDDIS)/wwww/                               |
|                   +--------------------+--------+---------------------------------------------+
|                   | ig2yyPwwww.erp.Z   | YES    | (CDDIS)/repro2/wwww/                        |
+-------------------+--------------------+--------+---------------------------------------------+
| [4, 17)           | First search for a valid final erp (as above)                             |
|                   +--------------------+--------+---------------------------------------------+
|                   | igrwwwwd.erp.Z     |   -    | (CDDIS)/wwww/                               |
+-------------------+--------------------+--------+---------------------------------------------+
| [0, 4)            | First search for a valid rapid erp (as above)                             |
|                   +--------------------+--------+---------------------------------------------+
|                   | iguwwwwd_HH.erp.Z  |   -    | (CDDIS)/wwww/                               |
+-------------------+--------------------+--------+---------------------------------------------+
| (0, -1]           | First search for a valid rapid erp (as above)                             |
|                   +--------------------+--------+---------------------------------------------+
|                   | igu00p01.erp.Z     |   -    | (CDDIS)                                     |
+-------------------+--------------------+--------+---------------------------------------------+
| [-15, -1)         | igu00p01.erp.Z     |   -    | (CDDIS)                                     |
+-------------------+--------------------+--------+---------------------------------------------+


Documentation
--------------

.. automodule:: bernutils.products.pyerp
   :members:
   :undoc-members:


Examples
---------


Satellite Orbit Information files (SP3)
========================================

.. warning::

  In the following paragraphs, the AC-specific details for SP3 files are summarized.
  However, it is recomended to use the AC-independent function :func:`bernutils.products.pysp3.getOrb`
  to download any sp3 file (and **NOT** the versions per AC).

CODE AC
--------

.. warning:: CODE does not use the default extension for sp3 files (i.e. .sp3).
  Instead, it uses the .EPH extension.

Available sp3-formated files from CODE are (see [aiub-ftp-readme]_):

* ftp://ftp.unibe.ch/aiub/CODE/

  * **COD.EPH_U** 
    CODE ultra-rapid GNSS orbits; GNSS ephemeris/broadcast clock data in at 15-min
    intervals in SP3 format, including accuracy codes computed from a long-arc
    analysis.
  * **COD.EPH_5D** Last update of CODE 5-day orbit predictions, from
    rapid analysis, including all active GLONASS satellites
  * **CODwwwwd.EPH_M** 
    CODE final rapid GNSS orbits (middle day of a long-arc solution where the rapid
    observations were completed by a subsequent ultra-rapid dataset)
  * **CODwwwwd.EPH_R** 
    CODE early rapid GNSS orbits (third day of a 72-hour solution)
  * **CODwwwwd.EPH_P**
    CODE 24-hour GNSS orbit predictions
  * **CODwwwwd.EPH_P2**
    CODE 48-hour GNSS orbit predictions
  * **CODwwwwd.ERP_5D**
    CODE 5-day GNSS orbit predictions

  .. note::
    As soon as a final product is available the corresponding rapid,
    ultra-rapid, or predicted product is removed from the aftp server.

* ftp://ftp.unibe.ch/aiub/CODE/yyyy/

  * **CODwwwwd.EPH.Z**
    GNSS ephemeris/clock data in 7 daily files at 15-min intervals in SP3 format, 
    including accuracy codes computed from a long-arc analysis.

* http://www.aiub.unibe.ch/download/REPRO_2013/CODE/yyyy/

  * **CODwwwwd.EPH.Z**
    Final GNSS orbits

* Also available !

  * **cofwwww7.eph.Z** One-day, final sp3 files from igs

  * SP3s generated for the igs REPRO2 campaign. These are available via the
    igs ftp server, in two versions:

    #. **cf2wwww7.eph.Z** from (CDDIS)/repro2/wwww/, and
    #. **co22wwww7.eph.Z** from (CDDIS)/repro2/wwww/

.. note:: CODE's sp3 orbit files include GLONASS information.

The function used to download a CODE-generated erp is 
:func:`bernutils.products.pysp3.getCodSp3`.

+-------------------+--------------------+-------------------------------------+---------------------------------------------+
|                   |                    | FLAGS                               |                                             |
| today - dt (days) | File to download   +--------+-----------+----------------+  HOST + DIR                                 |
|                   |                    | REPRO2 | REPRO2013 | OneDaySolution |                                             |
+===================+====================+========+===========+================+=============================================+
| >= 15.0           | CODwwwwd.EPH.Z     | NO     | NO        | NO             | (CODE)/yyyy/                                |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | cf2wwww7.sp3.Z     | YES    | NO        | YES            | (CDDIS)/repro2/wwww/                        |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | co22wwww7.sp3.Z    | YES    | NO        | NO             | (CDDIS)/repro2/wwww/                        |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | cofwwww7.sp3.Z     | NO     | NO        | YES            | (CDDIS)/wwww/                               |
|                   +--------------------+--------+-----------+----------------+---------------------------------------------+
|                   | CODwwwwd.EPH.Z     | YES    | NO        | NO             | (CODE)/REPRO_2013/CODE/yyyy/                |
+-------------------+--------------------+--------+-----------+----------------+---------------------------------------------+
| [4, 15)           | First search for a valid final sp3 (as above)                                                          |
|                   +--------------------+-------------------------------------+---------------------------------------------+
|                   | CODwwwwd.EPH_M.Z   |                                     | (CODE)/yyyy_M/                              |
|                   +--------------------+          Ignored                    +---------------------------------------------+
|                   | CODwwwwd.EPH_M     |                                     | (CODE)/                                     |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+
| [0, 4)            | First search for a valid final rapid sp3 (as above)                                                    |
|                   +--------------------+-------------------------------------+---------------------------------------------+
|                   | CODwwwwd.EPH_R     |           Ignored                   | (CODE)/                                     |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+
| (0, -1]           | COD.EPH_U          |                                     |                                             |
|                   +--------------------+           Ignored                   | (CODE)                                      |
|                   | CODwwwwd.EPH_5D    |                                     |                                             |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+
| [-15, -1)         | CODwwwwd.EPH_5D    |           Ignored                   | (CODE)                                      |
+-------------------+--------------------+-------------------------------------+---------------------------------------------+

IGS AC
-------

.. warning:: IGS sp3 products are not multi-gnss; that means that glonass and gps
  sp3 files are different (they have different names).

Gps - Sp3
________________________________________________________________________________

Available SP3 files from IGS are (see [igs-products]_):

* **Ultra-Rapid** (predicted half) iguwwwwd_[00|06|12|18].sp3.Z
* **Ultra-Rapid** (observed half) iguwwwwd_[00|06|12|18].sp3.Z
* **Rapid** igrwwwwd.sp3.Z
* **Final** igswwwwd.sp3.Z
* **ig2yyPwwwwd.sp3.Z** igs repro2 sp3 files (in /products/repro2 area)

  .. warning:: These files, i.e. ig2yyPwwwwd.sp3.Z are (at least for now) not
    available.

The function used to download an igs-generated gps-specific sp3 file is 
:func:`bernutils.products.pysp3.getIgsSp3Gps`.

+-------------------+--------------------+--------+---------------------------------------------+
|                   |                    | FLAGS  |                                             |
| today - dt (days) | File to download   +--------+  HOST + DIR                                 |
|                   |                    | REPRO2 |                                             |
+===================+====================+========+=============================================+
| >= 17.0           | igswwwwd.sp3.Z     | NO     | (CDDIS)/wwww/                               |
|                   +--------------------+--------+---------------------------------------------+
|                   | ig2yyPwwwwd.sp3.Z  | YES    | (CDDIS)/repro2/wwww/                        |
+-------------------+--------------------+--------+---------------------------------------------+
| [4, 17)           | First search for a valid final sp3 (as above)                             |
|                   +--------------------+--------+---------------------------------------------+
|                   | igrwwwwd.sp3.Z     |   -    | (CDDIS)/wwww/                               |
+-------------------+--------------------+--------+---------------------------------------------+
| [0, 4)            | First search for a valid rapid sp3 (as above)                             |
|                   +--------------------+--------+---------------------------------------------+
|                   | iguwwwwd_HH.sp3.Z  |   -    | (CDDIS)/wwww/                               |
+-------------------+--------------------+--------+---------------------------------------------+
| (0, -1]           | First search for a valid rapid sp3 (as above)                             |
|                   +--------------------+--------+---------------------------------------------+
|                   | iguwwwwd_HH.sp3.Z  |   -    | (CDDIS)                                     |
+-------------------+--------------------+--------+---------------------------------------------+
| [-15, -1)         |                        -                                                  |
+-------------------+--------------------+--------+---------------------------------------------+

Glonass - Sp3
________________________________________________________________________________

Available SP3 files from IGS are (see [igs-products]_):

* **Ultra-Rapid** igvwwwwd_[00|06|12|18].sp3.Z
* **Final** igvwwwwd.sp3.Z

The function used to download an igs-generated glonass-specific sp3 file is 
:func:`bernutils.products.pysp3.getIgsSp3Glo`.

+-------------------+--------------------+---------------------------------------------+
| today - dt (days) | File to download   |  HOST + DIR                                 |
+===================+====================+=============================================+
| >= 15.0           | iglwwwwd.sp3.Z     | (CDDIS)/wwww/                               |
+-------------------+--------------------+--------+------------------------------------+
| [-1, 15)          | First search for a valid final sp3 (as above)                    |
|                   +--------------------+---------------------------------------------+
|                   | igvwwwwd._HH.sp3.Z | (CDDIS)/wwww/                               |
+-------------------+--------------------+---------------------------------------------+

Mixed - Sp3
________________________________________________________________________________

To download mixed sp3 files (i.e. containing both GPS and GLONASS records), use the
funvtion :func:`bernutils.products.pysp3.getIgsSp3`. This function will use the
satellite-system-specific functions (:func:`bernutils.products.pysp3.getIgsSp3Gps`
and :func:`bernutils.products.pysp3.getIgsSp3Glo`) to download the two files (the 
gps-only and the glonass-only) and then will merge the two files in a new file
designated with the characters **'igc'**.


Broadcast Satellite Orbit files (NAV)
-------------------------------------

It is also possible to download navigation orbit files (in RINEX format), either
the accumulated daily one (where the station name is replaced by 'brdc'), or
for a given station.

For Station-specific navigation files it is also possible to download hourly files.

.. warning:: Station-specific navigation files are only available for igs staions,
  since the function uses the cddis archive.

For more information, see the function :func:`bernutils.products.pysp3.getNav`.


Documentation
--------------

.. automodule:: bernutils.products.pysp3
   :members:
   :undoc-members:


Examples
---------

Inospheric Information/Model Files
===================================

Ionospheric Correction/Model/Map files can be formated in various ways
and contain different kind of information. Within the Bernese software, users
usually make use of the .ION files. These files are Bernese-specific.

.ION files
--------------

ION files are distributed by CODE; the following options are available (see [aiub-ftp-readme]_):

* ftp://ftp.unibe.ch/aiub/CODE/

  * **COD.ION_U** Last update of CODE rapid ionosphere product (1 day) complemented
    with ionosphere predictions (2 days)
  * **CODwwwwd.ION_R** CODE rapid ionosphere product, Bernese format
  * **CODwwwwd.ION_P** CODE 1-day ionosphere predictions, Bernese format
  * **CODwwwwd.ION_P2** CODE 2-day ionosphere predictions, Bernese format
  * **CODwwwwd.ION_P5** CODE 5-day ionosphere predictions, Bernese format

* ftp://ftp.unibe.ch/aiub/CODE/yyyy

  * **CODwwwwd.ION.Z**  CODE final ionosphere product, Bernese format

+-------------------+--------------------+---------------------------------------------+
|                   |                    |                                             |
| today - dt (days) | File to download   +  HOST + DIR                                 |
|                   |                    |                                             |
+===================+====================+=============================================+
| >= 15.0           | CODwwwwd.ION.Z     | (CODE)/yyyy/                                |
+-------------------+--------------------+---------------------------------------------+
| [4, 15)           | First search for a valid final .ION (as above)                   |
|                   +--------------------+---------------------------------------------+
|                   | CODwwwwd.ION_R     | (CODE)                                      |
+-------------------+--------------------+---------------------------------------------+
| [4, 1)            | CODwwwwd.ION_R     | (CODE)                                      |
+-------------------+--------------------+---------------------------------------------+
| [1, -1)           | First search for a valid rapid ION file                          |
|                   +--------------------+---------------------------------------------+
|                   | COD.ION_U          | (CODE)                                      |
+-------------------+--------------------+---------------------------------------------+
| [-1, -3)          | COD.ION_U          | (CODE)                                      |
+-------------------+--------------------+---------------------------------------------+

References
===========

.. [aiub-ftp-readme] ftp://ftp.unibe.ch/aiub/AIUB_AFTP.TXT, last accessed Sep, 2015

.. [igs-products] https://igscb.jpl.nasa.gov/components/prods.html, last accessed Sep, 2015
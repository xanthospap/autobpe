=============================
Module : bamb
=============================

This module contains the classes:

* ambfile and
* ambline

**ambfile** represents a Bernese v5.2 ambiguity resolution summary file. This kind
of files, contain ambiguity resolution information for a list of baselines.
The default extension is .SUM (e.g. AMBYYDDDS.SUM). 

Ambiguity resolution summary file format format is very strict, and most of the 
functions/modules depend that this format is kept.

**ambline** is class holding ambiguity resolution record lines. Such instances are normally
used to accomodate the reading of **ambfile** objects; they are not used as standalone.

-----------------------------
Documentation
-----------------------------

.. currentmodule:: bernutils.bamb

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Class ambline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autoclass:: bernutils.bamb.AmbLine
   :members:
   :undoc-members:

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Class ambfile
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autoclass:: bernutils.bamb.AmbFile
   :members:

-----------------------------
Examples
-----------------------------

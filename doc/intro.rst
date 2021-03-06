bernutils Introduction
***********************

| Documentation for the bernutils Python package

The *bernutils* package is a collection of Python modules to
assist the automatic processing of GNSS data at the
National Technical University of Athens, carried out via the
Bernese v5.2 GNSS Software.


Installation
============

To install the package, clone the repository from github, https://github.com/xanthospap/autobpe
Go to the directory autobpe/src/python/new and install using Python, i.e.

.. code-block:: shell

  $> python setup.py install


To `compile` (this) document, go to autobpe/src/python/new/doc and type

.. code-block:: shell

  $> make html

.. warning:: To compile the documentation for the ``bernutils`` package you will
  need ``Sphinx``, see http://sphinx-doc.org/.


The ``/bin`` directory
=======================

The ``/bin`` directory includes a number of programs (scripts) used in the routine
processing. They are **NOT** documented via Sphinx/reStructuredText nor are they
described here. Look in the directory ``/doc/automati-doc``; there should be a file
``build.sh``; run it, it should generate a pdf output called ``automati.pdf``.

Bugs
====

Report any bugs to the dedicated Bugzilla tracker http://dionysos.survey.ntua.gr/bugzilla/

Contributing
============

Fork / clone / branch the repository.

Rules:

* Do **NOT** use tabs; only whitespaces,
* Whithin the project, tab = 2 whitespaces
* Comment your code (sphinx/rst)

Copyright
=========

.. image:: wtf.png
  :width: 100px
  :align: right
  :height: 100px
  :alt: alternate text

.. literalinclude:: copying

_______________________

| **National Technical University of Athens**
| *Dionysos Satellite Observatory*
| *Higher Geodesy Laboratory*

_______________________

.. image:: index.jpeg
  :width: 100px
  :align: right
  :height: 100px
  :alt: alternate text

| Authors:
| Xanthos Papanikolaou, xanthos@mail.ntua.gr
| Demitris Anastasiou,  danast@mail.ntua.gr
| Vangelis Zacharis,  vanzach@survey.ntua.gr


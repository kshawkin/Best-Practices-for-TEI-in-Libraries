# Best Practices for TEI in Libraries

This repository contains the [ODD](http://wiki.tei-c.org/index.php/ODD) source files for [Best Practices for TEI in Libraries: A guide for mass digitization, automated workflows, and promotion of interoperability with XML using the TEI](http://purl.oclc.org/NET/teiinlibraries).

To check out a copy of this repository to your local system use:
```
   git clone https://github.com/kshawkin/Best-Practices-for-TEI-in-Libraries.git
```

You can look at, play with, and even modify the files to your heart&#x2019;s content. If you like to submit your changes to the editors for inclusion, issue a pull request. (I.e., surf over to (https://github.com/kshawkin/Best-Practices-for-TEI-in-Libraries/pulls) and click on “New pull request”.)

There are a variety of ways to to generate schemas from the ODD.
(And remember to generate both ISO Schematron and RELAX NG; or, if for
some reason you can’t use RELAX NG you can
also generate DTDs or W3C XML Schema).

1. Submit the ODD files the TEI [Roma](http://www.tei-c.org/Roma/) website
1. Install `roma`[2] on your machine[3] issue something like `roma2 --patternprefix=lib3_ --noxsd --dochtml --nodtd --isoschematron lib3.odd .`
1. In oXygen, use the TEI ODD transformation scenarios.

To generate the main HTML documentation for the entire system, use something like
```
$ xmllint --xinclude main-driver.odd > /tmp/main-driver.odd
$ ~/Documents/Stylesheets/teitohtml /tmp/main-driver.odd
```
If `teitohtml` does not run on your system, you could submit the /tmp/main-driver.odd file to [OxGarage](http://www.tei-c.org/oxgarage/) instead.

Notes
-----
[2] See [page in the TEI wiki](https://wiki.tei-c.org/index.php/Roma); this is the program that combines customization ODDs with the TEI Guidelines and produces schemas and reference documentation.

[3] If you don’t already have `roma` on your Mac OS X system, you may find these [unofficial instructions](http://www.wwp.neu.edu/outreach/seminars/_current/handouts/roma_CLI_MacOS_X.html) useful. The likely work on a GNU/Linux system, too.

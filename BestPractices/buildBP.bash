#! /bin/bash

# buildBP.bash

# This is a script intended to build the TEI-in-Libraries
# _Best_Practices_for_TEI_in_Libraries_ from the source ODD files on
# Syd's machines. You will probably have to change some tests or paths
# to get it to work on your system. In addition, you would need to
# have the following things installed:
# * xmllint
# * xmlstarlet
# You need to either have the following installed, or provide
# pointers to web-accessible copies of them on the commandline:
# * TEI Stylesheets repo (modified -- see WARNING below)
# * TEI P5 source document
# And it is helpful to have a copy of the RELAX NG schema available or
# pointed to on the commandline.

# --------- WARNING ---------
# A single change is needed to one of the TEI stylesheets in order to
# generate the single large HTML document. See "IMPORTANT", below. If
# you don't make that tweak, the process will build all of the outputs
# for the individual levels, but not the main-driver.html, which will
# suffer a fatal error.
# --------- GNINRAW ---------

# watch what happens, as it happens
# set -o xtrace

PSC=${PSC:-_}                     # prefix separator string (typically '.' or '_')
TMPDIR=${TMPDIR:-/tmp}            # temporary directory
TMP=${TiLBPtemp}$$.xml            # temporary sibling file
TMPTMP=${TMPDIR}/{$TMP}           # temporary file in temp dir

# find xml starlet cmd
if which xml ; then
    STARLET=`which xml`
elif which xmlstarlet ; then
    STARLET=`which xmlstarlet`
fi

if [ -e /Applications/oxygen/ ] ; then
    # on a Mac OS X system. Hope it is Syd's, as these paths are where he stores stuff.
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-~/Documents/TEI-GitHub/P5/p5subset.xml}
    RELAX=${RELAX:--c /usr/local/share/emacs/23.2/etc/schema/relaxng.rnc}
elif [ ${HOSTNAME} = albus ] || [ ${HOSTNAME} = aberforth ]; then
    # Syd's desktop, use whatever his symlinks point to
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-/home/syd/Documents/TEI_dev/P5/p5subset.xml}
    RELAX=${RELAX:--c /usr/share/emacs/24.5/etc/schema/relaxng.rnc}    
elif egrep 'Ubuntu' /etc/issue || [ -e /etc/debian_veresion ]; then
    # on an Ubuntu or Debian system, use standard locations
    XSLDIR=${XSLDIR:-/usr/local/share/tei/Stylesheets}
    P5SRC=${P5SRC:-/usr/local/share/tei/P5/p5subset.xml}
else # dunno
    XSLDIR=${XSLDIR:-/usr/local/share/tei/Stylesheets}
    P5SRC=${P5SRC:-/usr/local/share/tei/P5/p5subset.xml}
fi

###TEMP### for BASE in lib1 lib2 lib3 lib4 ; do
###TEMP###     INNAME=${BASE}.odd                # input filename
###TEMP###     # find the prefix specified in the ODD file, if any
###TEMP###     # (the variable OSPFX is for Odd file Specified PreFiX)
###TEMP###     OSPFX=`${STARLET} sel -N t=http://www.tei-c.org/ns/1.0 -t -m "//t:schemaSpec[1]/@prefix" -v "." ${INNAME}`
###TEMP###     # if we found one, use it; otherwise append the separator string to the BASE filename
###TEMP###     PREFIX="${BASE}${PSC}"
###TEMP###     PREFIX="${OSPFX:-${PREFIX}}"
###TEMP### 
###TEMP###     if ${XSLDIR}/bin/teitorelaxng --odd --localsource=${P5SRC} $INNAME ; then
###TEMP### 	mv $INNAME.relaxng $BASE.rng
###TEMP### 	jing ${RELAX} ${BASE}.rng
###TEMP###     else
###TEMP### 	echo "Error generating RELAX NG (XML syntax) and Schematron from $INNAME"
###TEMP###     fi
###TEMP### 	 
###TEMP###     if ${XSLDIR}/bin/teitornc --odd --localsource=${P5SRC} $INNAME ; then
###TEMP### 	if ~/bin/fix_rnc_whitespace.perl --patternprefix=${PREFIX} < $INNAME.rnc > $BASE.rnc ; then
###TEMP### 	    rm $INNAME.rnc
###TEMP### 	else
###TEMP### 	    echo "Error fixing whitespace in $INNAME.rnc"
###TEMP### 	fi
###TEMP###     else
###TEMP### 	echo "Error generating RELAX NG (compact syntax) from $INNAME"
###TEMP###     fi
###TEMP### 
###TEMP###     if ${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} --summaryDoc $INNAME ; then
###TEMP### 	mv $INNAME.html $BASE.html
###TEMP###     else
###TEMP### 	echo "Error generating HTML from $INNAME"
###TEMP###     fi
###TEMP### 
###TEMP### done

# process  main-driver  here

#echo "13. generate XInclude processed version of main driver."


echo "generate HTML from main driver."
# need a way to set showTitleAuthor=true
# need a way to set suppressTEIexamples=true

# IMPORTANT -- As currently written, line 2392 of
# ${XSLDIR}/odds/teiodds.xsl tries to set the context node to
# that which was looked up by using
#   	  <xsl:for-each select="key('IDENTS',$lookup)">
# HOWEVER, because each of our 4 included ODD files (level1.odd,
# level2.odd, level3.odd, level4.odd) has a <specGrpRef> that points
# to a set of ODD elements in lib-header.odd, we end up with 4 copies
# of quite a few identifiable constructs in the IDENTS key. Thus when
# the author intended just to set the context node (I think), we now
# end up iterating over the same <elementSpec> (or whatever) 4 times.
# Thus the function being defined (tei:generateRefPrefix()) tries to
# return 4 things, when it is only allowed to return one, and we get a
# fatal error. To fix this, or at least to hack around it, change the
# line in question to read
#   	  <xsl:for-each select="key('IDENTS',$lookup)[1]">
# I am not checking that change into the TEI Stylesheets, because it
# is not at all clear to me that what we are doing here should be
# valid.

# Also HACK warning: in this first line we simply remove all of the
# <schemaSpec>s so as to avoid generating reference documentation from
# them.
${STARLET} ed -N t=http://www.tei-c.org/ns/1.0 --delete "//t:schemaSpec" main-driver.odd > ${TMP}
# now we have a version of 'main-driver.odd' in TMP that has XIncludes
# included, but has no <schemaSpec>s. Generate HTML from it:
${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} ${TMP}
# use correct name and nuke TMP file:
mv ${TMP}.html main-driver.html
rm ${TMP}

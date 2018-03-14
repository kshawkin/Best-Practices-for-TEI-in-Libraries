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
# This build process requires the change made to the Stylesheets at commit
# 0f7cdf348973d5eb80f6f28eb702d88548e086d8

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

if [ -e /Library/PreferencePanes/ ] ; then
    # on a Mac OS X system. Hope it is Syd's, as these paths are where he stores stuff.
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-~/Documents/TEI-GitHub/P5/p5subset.xml}
    RELAX=${RELAX:--c /usr/local/share/emacs/23.2/etc/schema/relaxng.rnc}
elif [ ${HOSTNAME} = albus ] || [ ${HOSTNAME} = aberforth ] || [ ${HOSTNAME} = paramedic ]; then
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

for BASE in lib1 lib2 lib3 lib4 ; do
    echo ""; echo "--------- begin processing ${BASE} ---------"
    INNAME=${BASE}.odd                # input filename
    # find the prefix specified in the ODD file, if any
    # (the variable OSPFX is for Odd file Specified PreFiX)
    OSPFX=`${STARLET} sel -N t=http://www.tei-c.org/ns/1.0 -t -m "//t:schemaSpec[1]/@prefix" -v "." ${INNAME}`
    # if we found one, use it; otherwise append the separator string to the BASE filename
    PREFIX="${BASE}${PSC}"
    PREFIX="${OSPFX:-${PREFIX}}"

    echo "------ teitorelaxng --odd $INNAME"
    if ${XSLDIR}/bin/teitorelaxng --odd --localsource=${P5SRC} $INNAME ; then
	mv $INNAME.relaxng $BASE.rng
	jing ${RELAX} ${BASE}.rng
    else
	echo "Error generating RELAX NG (XML syntax) and Schematron from $INNAME"
    fi
	 
    echo "------ teitornc --odd $INNAME"
    if ${XSLDIR}/bin/teitornc --odd --localsource=${P5SRC} $INNAME ; then
	if ~/bin/fix_rnc_whitespace.perl --patternprefix=${PREFIX} < $INNAME.rnc > $BASE.rnc ; then
	    rm $INNAME.rnc
	else
	    echo "Error fixing whitespace in $INNAME.rnc"
	fi
    else
	echo "Error generating RELAX NG (compact syntax) from $INNAME"
    fi

    echo "------ teitoschematron --odd $INNAME"
    if ${XSLDIR}/bin/teitoschematron --odd --localsource=${P5SRC} $INNAME ; then
	mv $INNAME.schematron $BASE.sch
    else
	echo "Error extracting Schematron from $INNAME"
    fi

    echo "------ teitohtml --odd --summaryDoc $INNAME"
    if ${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} --summaryDoc $INNAME ; then
	mv $INNAME.html $BASE.html
    else
	echo "Error generating HTML from $INNAME"
    fi

done

# process  main-driver  here

#echo "13. generate XInclude processed version of main driver."


echo ""; echo "--------- generate HTML from main driver ---------"
# need a way to set showTitleAuthor=true
# need a way to set suppressTEIexamples=true

# HACK warning 1: we simply remove all of the <schemaSpec>s so as
# to avoid generating reference documentation from them.
# HACK warning 2: it seems some versions of `xmlstartlet` do XInclude
# processing (using element() in @xpointer) and others do not; some
# versions of `xmllint` do XInclude processing (using element() in
# @xpointer) and some do not. So far, on all of my systems, one or the
# other (or both) will do it.
xmllint --xinclude main-driver.odd | ${STARLET} ed -N t=http://www.tei-c.org/ns/1.0 --delete "//t:schemaSpec" > ${TMP}
# now we have a version of 'main-driver.odd' in TMP that has XIncludes
# included, but has no <schemaSpec>s. Generate HTML from it:
${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} ${TMP}
# use correct name and nuke TMP file:
mv ${TMP}.html main-driver.html
rm ${TMP}

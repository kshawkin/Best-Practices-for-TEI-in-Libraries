#! /bin/bash

# buildBP.bash

# This is a script intended to build the TEI-in-Libraries
# _Best_Practices_for_TEI_in_Libraries_ from the source ODD files on
# Syd's machines. You will probably have to change some tests or paths
# to get it to work on your system.

# watch what happens, as it happens
# set -o xtrace

PSC=${PSC:-_}			  # prefix separator string (typically '.' or '_')
TMPDIR=${TMPDIR:-/tmp}		  # temporary directory
TMP=${TMPDIR}/TiLBPtemp.xml	  # temporary file

# find xml starlet cmd
if which xml ; then
    STARLET=`which xml`
elif which xmlstarlet ; then
    STARLET=`which xmlstarlet`
fi

if [ -e /Applications/oxygen/ ] ; then
    ROMACMD=${ROMACMD:-~/bin/roma2.sh}
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-~/Documents/TEI-GitHub/P5/Source/guidelines-en.xml}
    RELAX=${RELAX:--c /usr/local/share/emacs/23.2/etc/schema/relaxng.rnc}
elif [ ${HOSTNAME} = albus ] || [ ${HOSTNAME} = aberforth ]; then
    ROMACMD=${ROMACMD:-/usr/local/share/tei/Roma/roma2.sh}
    XSLDIR=${XSLDIR:-/usr/local/share/tei/Stylesheets}
    P5SRC=${P5SRC:-/usr/local/share/tei/P5/Source/guidelines-en.xml}
else
    ROMACMD=${ROMACMD:-/usr/bin/roma2}
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-/home/syd/Documents/TEI/P5/Source/guidelines-en.xml}
fi

# first, fix odds/odd2odd.xsl, common/header.xsl, and html/html_textstructure.xsl
# ###
# NO, take that back, skip the entire patch business for now
# ###
# sPWD=`pwd`
# LINE=`egrep '^\+' odds_odd2odd.xsl.patch | head -n 1 | perl -pe 's,^\+\s+,,;s,\s+$,,;s,<!--,.+,;s,-->,.+,;'`
# cd ${XSLDIR}
# if egrep -e "$LINE" odds/odd2odd.xsl ; then
#     echo "Found odds/odd2odd.xsl already patched, skipping patces to it, common/common_header.xsl, and html/html_textstructure.xsl"
# else
#     echo "Patching odds/odd2odd.xsl ..."
#     cd odds/
#     cp -p odd2odd.xsl odd2odd_hold.xsl
#     patch <${sPWD}/odds_odd2odd.xsl.patch
#     echo "Patching common/common_header.xsl ..."
#     cd ../common/
#     cp -p common_header.xsl common_header_hold.xsl
#     patch <${sPWD}/common_header.xsl.patch
#     echo "Patching html/html_textstructure.xsl ..."
#     cd ../html/
#     cp -p html_textstructure.xsl html_textstructure_hold.xsl
#     patch <${sPWD}/html_textstructure.xsl.patch
# fi
# cd $sPWD

# WARNING: we should use the same process to fix
# xhtml2/oddprocessing.xsl, but I can't get the patch file to work. So
# you'll have to do this one manually. The change just consists of
# moving the 4 lines that output element specifications to in front of
# those for model classes.



for BASE in lib1 lib2 lib3 lib4 ; do
    INNAME=${BASE}.odd                # input filename
    # find the prefix specified in the ODD file, if any
    # (the variable OSPFX is for Odd file Specified PreFiX)
    OSPFX=`${STARLET} sel -N t=http://www.tei-c.org/ns/1.0 -t -m "//t:schemaSpec[1]/@prefix" -v "." ${INNAME}`
    # if we found one, use it; otherwise append the separator string to the BASE filename
    PREFIX="${BASE}${PSC}"
    PREFIX="${OSPFX:-${PREFIX}}"

    if ${XSLDIR}/bin/teitorelaxng --odd $INNAME ; then
	mv $INNAME.relaxng $BASE.rng
	jing ${RELAX} ${BASE}.rng
    else
	echo "Error generating RELAXNG (XML syntax) and Schematron from $INNAME"
    fi
	 
    if ${XSLDIR}/bin/teitornc --odd $INNAME ; then
	if ~/bin/fix_rnc_whitespace.perl --patternprefix=${PREFIX} < $INNAME.rnc > $BASE.rnc ; then
	    rm $INNAME.rnc
	else
	    echo "Error fixing whitespace in $INNAME.rnc"
	fi
    else
	echo "Error generating RELAXNG (compact syntax) from $INNAME"
    fi

    if ${XSLDIR}/bin/teitohtml --odd --summaryDoc $INNAME ; then
	mv $INNAME.html $BASE.html
    else
	echo "Error generating HTML from $INNAME"
    fi

done

# process  main-driver  here

#echo "13. generate XInclude processed version of main driver."
#xmllint --xinclude main-driver.odd > /tmp/TiLBP.odd

echo "generate HTML from main driver."
# need a way to set showTitleAuthor=true
${XSLDIR}/bin/teitohtml --odd --summaryDoc main-driver.odd

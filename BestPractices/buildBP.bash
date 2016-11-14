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

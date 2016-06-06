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
    ROMACMD=${ROMACMD:-~/bin/roma2}
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-~/Documents/P5/Source/guidelines-en.xml}
    RELAX=${RELAX:--c /usr/local/share/emacs/23.2/etc/schema/relaxng.rnc}
elif [ ${HOSTNAME} = albus ] || [ ${HOSTNAME} = aberforth ]; then
    ROMACMD=${ROMACMD:-/usr/local/share/tei/Roma/roma2.sh}
    XSLDIR=${XSLDIR:-/usr/local/share/tei/Stylesheets}
    P5SRC=${P5SRC:-/usr/local/share/tei/P5/Source/guidelines-en.xml}
else
    ROMACMD=${ROMACMD:-/usr/bin/roma2}
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-/home/syd/SFTEI/trunk/P5/Source/guidelines-en.xml}
fi

# first, fix odds2/odd2odd.xsl, common2/header.xsl, and xhtml2/textstructure.xsl
sPWD=`pwd`
LINE=`egrep '^\+' odd2odd.xsl.patch | head -n 1 | perl -pe 's,^\+\s+,,;s,\s+$,,;s,<!--,.+,;s,-->,.+,;'`
cd ${XSLDIR}
if egrep -e "$LINE" odds2/odd2odd.xsl ; then
    echo "Found odds2/odd2odd.xsl already patched, skipping patces to it, common2/header.xsl, and xhtml2/textstructure.xsl"
else
    echo "Patching odds2/odd2odd.xsl ..."
    cd odds2/
    cp -p odd2odd.xsl odd2odd_hold.xsl
    patch <${sPWD}/odds2_odd2odd.xsl.patch
    echo "Patching common2/header.xsl ..."
    cd ../common2/
    cp -p header.xsl header_hold.xsl
    patch <${sPWD}/common2_header.xsl.patch
    echo "Patching xhtml2/textstructure.xsl ..."
    cd ../xhtml2/
    cp -p textstructure.xsl textstructure_hold.xsl
    patch <${sPWD}/xhtml2_textstructure.xsl.patch
fi
cd $sPWD

# WARNING: we should use the same process to fix
# xhtml2/oddprocessing.xsl, but I can't get the patch file to work. So
# you'll have to do this one manually. The change just consists of
# moving the 4 lines that output element specifications to in front of
# those for model classes.



for BASE in ; do
# for BASE in lib1 lib2 lib3 lib4 ; do
    INNAME=${BASE}.odd                # input filename
    # find the prefix specified in the ODD file, if any
    # (the variable OSPFX is for Odd file Specified PreFiX)
    OSPFX=`${STARLET} sel -N t=http://www.tei-c.org/ns/1.0 -t -m "//t:schemaSpec[1]/@prefix" -v "." ${INNAME}`
    # if we found one, use it; otherwise append the separator string to the BASE filename
    PREFIX="${BASE}${PSC}"
    PREFIX="${OSPFX:-${PREFIX}}"

    echo ${ROMACMD} --patternprefix=${PREFIX}         \
	--xsl=${XSLDIR} --noxsd --nodtd --dochtml     \
	--compile --docflags="showTitleAuthor=true" \
	--localsource=${P5SRC} --isoschematron ./${INNAME} .
    
    ${ROMACMD} --patternprefix=${PREFIX}         \
	--xsl=${XSLDIR} --noxsd --nodtd --dochtml     \
	--compile --docflags="showTitleAuthor=true" \
	--localsource=${P5SRC} --isoschematron ./${INNAME} . 
    
    echo "10. fix whitespace in RNC file."
    t=${BASE}.tmp
    i=${BASE}.rnc
    if mv ${i} ${t} ; then
	~/bin/fix_rnc_whitespace.perl --patternprefix=${PREFIX} < ${t} > ${i}
	rm ${t}
    else
	echo "$0: Error improving whitespace of RNC file; may be because the ident= of <schemaSpec> does not match the filename."
    fi

    echo "11. Use local CSS files in HTML."
    perl -p -i -e "s,http://www.tei-c.org/release/xml/tei/stylesheet,${XSLDIR},g;" ${BASE}.doc.html

    echo "12. validate .rng and .isosch files."
    jing ${RELAX} ${BASE}.rng
    # need to find a canonical place to put iso-schematron.rnc locallly, but for now:
    jing -c http://www.schematron.com/iso/iso-schematron.rnc ${BASE}.isosch
    done

# process  main-driver  here

echo "13. generate XInclude processed version of main driver."
xmllint --xinclude main-driver.odd > /tmp/TiLBP.odd

echo "14. generate HTML from it."
saxon -s:/tmp/TiLBP.odd -xsl:/Users/syd/Documents/Stylesheets/xhtml2/tei.xsl -o:main-driver.html showTitleAuthor=true

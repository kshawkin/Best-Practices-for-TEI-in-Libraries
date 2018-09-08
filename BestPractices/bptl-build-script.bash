#! /bin/bash

CMDNAME=`basename $0`

help="
# ${CMDNAME}
#
# This is a script intended to build the TEI-in-Libraries
# _Best_Practices_for_TEI_in_Libraries_ from the source ODD files on
# Syd's machines. You will probably have to change some tests or paths
# to get it to work on your system. Most of these paths can be changed
# by overriding the default on the commandline.
# In addition, you would need to have the following things installed:
# * xmllint
# * xmlstarlet
# * jing
# You need to either have the following installed, or provide
# pointers to web-accessible copies of them on the commandline:
# * TEI Stylesheets repo
# * TEI P5 source document
# And it is helpful to have a copy of the RELAX NG schema for the RELAX NG
# language itself available or pointed to on the commandline.
#
# Example usage:
# $ cd Best-Practices-for-TEI-in-Libraries/BestPractices/
# $ XSLDIR=~/Documents/Stylesheets_dev ${CMDNAME}
#
# To get lots of verbose debugging information, in addition to not
# deleting temporary files, use the -d switch. Note that switch
# parsing is *not* displayed.
#
# To get an output string that gives the command with several of the
# important variables shown with their defaults, use the -p switch; nothing
# else happens except the output. Thus, a reasonable approach to using
# this command would be to:
# 1) just issue it and see if it works out of the box
# 2) if not, use it with the -p switch
# 3) copy the output generated in (2) to the commandline, changing the
#    paths as needed
"

DEBUG=false
PRINTPATHS=false
while getopts "dphH" opt; do
    case $opt in
        d ) DEBUG=true
            ;;
        p ) PRINTPATHS=true
            ;;
        h ) printf "usage: $0 [-dphH]\nshould be issued from the working directory that contains the source BPTL ODD files; use the -H switch for more detailed help info\n"
            exit 1
            ;;
        H ) printf "$help"
            exit 1
            ;;
        * ) printf "usage: $0 [-dphH]\nshould be issued from the working directory that contains the source BPTL ODD files; use the -H switch for more detailed help info\n"
            exit 1
    esac
done
shift $((OPTIND - 1))


# if user asked for it, show her everything that happens hereafter
if [ $DEBUG = true ]; then set -o xtrace; fi

PSC=${PSC:-_}                     # prefix separator string (typically '.' or '_')
TMPDIR=${TMPDIR:-/tmp}            # temporary directory
TMP=${TiLBPtemp}$$.xml            # temporary sibling file
TMPTMP=${TMPDIR}/${TMP}           # temporary file in temp dir

if [ -e /Library/PreferencePanes/ ] ; then
    # on a Mac OS X system. Hope it is Syd's, as these paths are where he stores stuff.
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-~/Documents/TEI-GitHub/P5/p5subset.xml}
    RELAX=${RELAX:--c /Applications/Emacs.app/Contents/Resources/etc/schema/relaxng.rnc}
    JING=${JING:-/Applications/oxygen/lib/jing.jar}
elif [ ${HOSTNAME} = albus ] || [ ${HOSTNAME} = aberforth ] || [ ${HOSTNAME} = paramedic ] || [ ${HOSTNAME} = Nimbus2016 ]; then
    # on one of Syd's GNU/Linux systems, use whatever his symlinks point to
    XSLDIR=${XSLDIR:-~/Documents/Stylesheets}
    P5SRC=${P5SRC:-/home/syd/Documents/TEI_dev/P5/p5subset.xml}
    RELAX=${RELAX:--c /usr/share/emacs/24.5/etc/schema/relaxng.rnc}
    JING=${JING:-/opt/Oxygen_XML_Editor_20/lib/jing.jar}
elif egrep 'Ubuntu' /etc/issue || [ -e /etc/debian_veresion ]; then
    # on an Ubuntu or Debian system, use standard locations
    XSLDIR=${XSLDIR:-/usr/local/share/tei/Stylesheets}
    P5SRC=${P5SRC:-/usr/local/share/tei/P5/p5subset.xml}
    JING=${JING:-/usr/share/java/jing.jar}
else # dunno
    XSLDIR=${XSLDIR:-/usr/local/share/tei/Stylesheets}
    P5SRC=${P5SRC:-/usr/local/share/tei/P5/p5subset.xml}
    JING=${JING:-/usr/share/java/jing.jar}
fi

if [ ${PRINTPATHS} = true ]; then
    echo "XSLDIR=${XSLDIR} P5SRC=${P5SRC} RELAX=${RELAX} JING=${JING} ${0}"
    exit 13
fi

# find xml starlet cmd
if which xml ; then
    STARLET=`which xml`
elif which xmlstarlet ; then
    STARLET=`which xmlstarlet`
fi

for BASE in bptl-L1 bptl-L2 bptl-L3 bptl-L4 ; do
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

    echo "------ teitohtml --odd [NOT --summaryDoc] $INNAME"
    if ${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} $INNAME ; then
        mv $INNAME.html $BASE.html
    else
        echo "Error generating HTML from $INNAME"
    fi

done

# process  bptl-driver  here

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
xmllint --xinclude bptl-driver.odd | ${STARLET} ed -N t=http://www.tei-c.org/ns/1.0 --delete "//t:schemaSpec" > ${TMPTMP}
# Now we have a version of 'main-driver.odd' in TMPTMP that has 
# XIncludes included, but has no <schemaSpec>s.
# Generate HTML from it:
${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} ${TMPTMP}
# use correct name and nuke TMPTMP file:
mv ${TMPTMP}.html bptl-driver.html
rm ${TMPTMP}

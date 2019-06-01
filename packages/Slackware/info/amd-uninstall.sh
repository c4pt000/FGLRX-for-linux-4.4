#!/bin/sh

# Copyright (c) 2009-2011 Emanuele Tomasi

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

PKG_NAME=''

# For gettext
export TEXTDOMAIN=ATI_SlackBuild
export TEXTDOMAINDIR=`dirname $0`/ATI_SlackBuild/locale

# Sanity check: I need gettext
if ! gettext --version &>/dev/null; then
    echo 'gettext: command not found!'
    exit 1
fi

# Sanity check: I need also sed, grep and mktemp
ERROR=0
for cmd in sed grep;
do
    if ! $cmd --version &>/dev/null; then
	echo -n "${cmd}: "
	gettext 'command not found.'
	ERROR=1
    fi
done
if ! mktemp -V &>/dev/null; then
    echo -n 'mktemp: '
    gettext 'command not found.'
    ERROR=1
fi
if [ $ERROR -eq 1 ]; then
    exit 1
fi

DRYRUN=0
FORCE=0
INFO_FILE=/var/log/removed_scripts/${PKG_NAME}
if [ "x${1}" != 'x' ]; then
    case $1 in
	--dryrun)
	    DRYRUN=1
	    INFO_FILE=/var/log/scripts/${PKG_NAME}
	    ;;

	--force)
	    FORCE=1
	    ;;
	*)
	    echo -n "$1: "
	    gettext 'invalid option.'
	    exit 1
    esac
fi

if [ $DRYRUN -eq 0 ]; then
    if [ `id -u` -ne 0 ]; then
	gettext 'Only root can do it!'
	exit 1
    fi

    # Copying the necessary files under /tmp
    if ! echo $0 | grep '^/tmp/' >/dev/null; then
	TMP_DIR=`mktemp -d -p /tmp`
	cp -r $0 /usr/share/ati/ATI_SlackBuild/locale $TMP_DIR
	exec sh ${TMP_DIR}/amd-uninstall.sh $* # Exec uninstall script under /tmp
    fi

    # Here, we are under /tmp
    TMP_DIR=`dirname $0`
    TEXTDOMAINDIR=${TMP_DIR}/locale # Reset gettext info
fi

# Removing fglrx package
echo -n "`gettext 'Removing pakage: '`"
echo $PKG_NAME
if [ $DRYRUN -eq 0 ]; then
    removepkg fglrx || exit 1
fi

# Restoring backup libraries
if [ -f ${INFO_FILE} ]; then
    RESTORED_FILE=0
    for file in `sed -n '/^( cd .*ln .*fglrx\//{s;.*cd \([^ ]*\).*fglrx/[^ ]* \([^ ]*\).*;/\1/\2;p}' ${INFO_FILE}`
    do
	DIR_NAME=`dirname $file`
	LIB_NAME=`basename $file`

        if [ -f ${DIR_NAME}/FGL.renamed.${LIB_NAME} ]; then
	    if [ $RESTORED_FILE  -eq 0 ]; then
		echo
		RESTORED_FILE=1
	    fi
	    echo -n "`gettext 'Restoring library: '`"
	    echo $file
	    if [ $DRYRUN -eq 0 ]; then
		( cd ${DIR_NAME}; mv FGL.renamed.${LIB_NAME} ${LIB_NAME} )
	    fi
        fi
    done
fi

if [ $DRYRUN -eq 0 ]; then
    rm -r ${TMP_DIR}
fi
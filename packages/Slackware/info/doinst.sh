#! /bin/sh

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

config() {
    NEW="$1"
    OLD="`dirname $NEW`/`basename $NEW .new`"
    [ ! -f $NEW ] && return

  # If there's no config file by that name, mv it over:
    if [ ! -f $OLD ]; then
	mv $NEW $OLD
    elif [ "`cat $OLD | md5sum`" = "`cat $NEW | md5sum`" ]; then # toss the redundant copy
	rm $NEW
    fi
  # Otherwise, we leave the .new copy for the admin to consider...
}

for file in etc/ati/*.new
do
    if [ $file = '*.new' ]; then
	break
    fi
    config $file
done

# Run depmod
depmod

export TEXTDOMAIN=ATI_SlackBuild
export TEXTDOMAINDIR=/usr/share/ati/ATI_SlackBuild/locale

echo -e "\n################################################################################"
echo -e "`gettext \"NOTE: you have to modify the X server configuration file to use the ATI drivers:\n\n\t\taticonfig --initial\n\n      can it help you. Run aticonfig without options for more details.\"`"

_USING_X=0
_HAVING_MODULE=0
if ps -C X > /dev/null; then
    _USING_MODULE=1
fi

if grep '^fglrx\>' /proc/modules > /dev/null; then
    _HAVING_MODULE=1
fi

if [ $_USING_MODULE -eq 1 ]; then
    echo -en "`gettext \"\nNOTE: you are running the X server\"`"
    if [ $_HAVING_MODULE -eq 1 ]; then
	echo -n "`gettext ' and you have the module fglrx in memory.'`"
    else
	echo -n '.'
    fi

    if [ $_HAVING_MODULE -eq 1 ]; then
	echo -e "`gettext \"\n      If you want to use the new drivers, you will must kill the X server,\n      so running:\n\n\t\tmodprobe -r fglrx\n\n      before restart it.\"`"
    else
	echo -e "`gettext \" If you want to use the new drivers, you will\n      must rerun it.\"`"
    fi
elif [ $_HAVING_MODULE -eq 1 ]; then
    modprobe -r fglrx
fi

BACKUP=0
for file in `sed -n '/^( cd .*ln .*fglrx\//{s;.*cd \([^ ]*\).*fglrx/[^ ]* \([^ ]*\).*;/\1/\2;p}' "$0"`
do
    if [ -f $file ]; then
	if [ $BACKUP -eq 0 ]; then
	    echo
	    BACKUP=1
	fi

	echo -n "`gettext 'Backup library: '`"
	echo $file

	DIR_NAME=`dirname $file`
	LIB_NAME=`basename $file`
	( cd $DIR_NAME; mv $LIB_NAME FGL.renamed.${LIB_NAME} )
    fi
done

if [ $BACKUP -eq 1 ]; then
    echo -e "\n`gettext \"NOTE: some library are been renamed to FGL.renamed.library_name.\n      To remove this package, you can use:\n\n\t\taticonfig --uninstall\n\n      or, with the releases >= 11.3, with:\n\n\t\tati-driver-installer-<release>-<architecture>.run --uninstall\"`"
fi
echo -e "################################################################################\n"

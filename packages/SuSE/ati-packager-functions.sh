#!/bin/sh
#
# Copyright (c) 2010-2014, Sebastian Siebert (freespacer@gmx.de)
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Check the size of the console
SIZE=`stty size 2> /dev/null || echo 0 0`
LINES=`echo "${SIZE}" | cut -f1 -d" "`
COLUMNS=`echo "${SIZE}" | cut -f2 -d" "`
if [ ${LINES} -eq 0 ]; then
    LINES=24
fi
if [ ${COLUMNS} -eq 0 ]; then
    COLUMNS=80
fi

VERBOSE_LEVEL="1"
if [ "${VERBOSE}" = "2" ]; then
    VERBOSE_LEVEL="2"
    VERBOSE="yes"
fi

print_okay()
{
    if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
        echo -e "\033[${COLUMNS}C\033[15D[\e[1;32m OK \e[0m]"
    fi
}

print_failure()
{
    if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
        echo -e "\033[${COLUMNS}C\033[15D[\e[1;31m FAILURE \e[0m]"
    fi
}

print_missing()
{
    if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
        echo -e "\033[${COLUMNS}C\033[15D[\e[1;33m MISSING \e[0m]"
    fi
}

print_aborted()
{
    if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
        echo -e "\033[${COLUMNS}C\033[15D[\e[1;33m ABORTED \e[0]"
    fi
}

debugMsg()
{
    if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
        echo -n -e "$@"
    fi
}

checkReturnOutput()
{
    if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
        if [ "${VERBOSE_LEVEL}" = "2" ]; then
            if [ -n "$2" ]; then
                if [ "$1" -ne 0 ]; then
                    echo -n -e "ERROR: "
                fi
                echo -n -e "$2"
            fi
        fi
        if [ "$1" -ne 0 ]; then
            print_failure
            exit 1
        fi
        print_okay
    fi
}

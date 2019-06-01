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

export LC_ALL=C
export LANG=C

#check for permissions before continuing
if [ "`whoami`" != "root" ]; then
    echo "[Warning] AMD Catalyst(TM) Proprietary Driver Uninstall : must be run as root to execute this script"
    exit 1
fi

printHelp()
{
    echo "AMD Catalyst(TM) Proprietary Driver Uninstall script supports the following arguments:"
    echo "--help                           : print help messages"
    echo "--force                          : uninstall without checking dependencies"
    echo "--dryrun                         : tests uninstall but does not uninstall"
}


USE_FORCE="no"
DO_DRY_RUN="no"

while [ "$#" -gt "0" ]; do

    case "$1" in
    -h|--help)
        printHelp
        exit 0
        ;;
    --force)
        USE_FORCE="yes"
        shift 1
        ;;
    --dryrun)
        DO_DRY_RUN="yes"
        shift 1
        ;;
    *|--*)
        echo "$1: unsupported option passed to AMD Catalyst(TM) Proprietary Driver Uninstall"
        exit 1
        ;;
    esac
done

if [ "${DO_DRY_RUN}" = "yes" -a "${USE_FORCE}" = "yes" ]; then
   echo "AMD Catalyst(TM) Proprietary Driver does not support"
   echo "--dryrun and --force commands together."
   echo "Please use --dryrun only for uninstall details."
   exit 1
fi

RPM_BIN="`which rpm`"
RPM_OPTION=""
PACKAGES_FAILED=""

if [ "${DO_DRY_RUN}" = "yes" ]; then
    RPM_OPTION="${RPM_OPTION} --test"

    echo "Simulating uninstall of AMD Catalyst(TM) Proprietary Driver."
    echo "Dryrun only, uninstall is not done."
elif [ "${USE_FORCE}" = "yes" ]; then
    RPM_OPTION="${RPM_OPTION} --nodeps"

    echo "Forcing uninstall of AMD Catalyst(TM) Proprietary Driver."
    echo "No integrity verification is done."
fi


if [ -n "${RPM_BIN}" -a -x "${RPM_BIN}" ]; then

    for PACKAGE in `${RPM_BIN} -qa | grep fglrx 2>/dev/null`
    do
        if [ "${USE_FORCE}" = "no" ]; then
            VERIFYING_OUTPUT="`${RPM_BIN} -V ${PACKAGE} 2>&1`"
            if [ -n "${VERIFYING_OUTPUT}" ]; then
                PACKAGES_FAILED="${PACKAGES_FAILED}   ${PACKAGE} : verification failed\n   => Affected file(s):\n`echo "${VERIFYING_OUTPUT}" | sed -e 's/^/      /g'`\n"
            fi
        fi

        if [ -z "`echo "${PACKAGES_FAILED}" | grep "${PACKAGE}"`" ]; then
            REMOVING_OUTPUT="`${RPM_BIN} -e ${RPM_OPTION} ${PACKAGE} 2>&1`"
            if [ "$?" -ne 0 ]; then
                PACKAGES_FAILED="${PACKAGES_FAILED}   ${PACKAGE} : unexpected error with rpm -e ${RPM_OPTION}\n:   => Output:\n`echo "${REMOVING_OUTPUT}" | sed -e 's/^/      /g'`\n"
            fi
        fi

    done

    if [ -n "${PACKAGES_FAILED}" ]; then
        echo "One or more files have been altered since installation /"
        echo "One or more unexpected error occurred during uninstall."
        echo "Uninstall not completed."
        echo " "
        echo "Affected package(s):"
        echo -e "${PACKAGES_FAILED}"
        exit 1
    else
        if [ "${DO_DRY_RUN}" = "yes" ]; then
            echo "Dryrun uninstall of AMD Catalyst(TM) Proprietary Driver complete."
        else
            echo "Uninstall of AMD Catalyst(TM) Proprietary Driver complete."
            echo "System must be rebooted to avoid system instability and potential data loss."
        fi
        exit 0
    fi

else
    echo "RPM is missing from the system. Uninstall not completed."
    exit 1
fi

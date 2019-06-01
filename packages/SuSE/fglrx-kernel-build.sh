#!/bin/sh
#
# Copyright (c) 2010-2014 Sebastian Siebert (freespacer@gmx.de)
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

# Set local language always to C
export LC_ALL=C
export LANG=C

# Detected some important binaries or scripts with full path
BASENAME_BIN="`which basename`"
CAT_BIN="`which cat`"
CP_BIN="`which cp`"
DEPMOD_BIN="`which depmod`"
ECHO_BIN="`which echo`"
GREP_BIN="`which grep`"
MAKE_BIN="`which make`"
MODINFO_BIN="`which modinfo`"
PRINTF_BIN="`which printf`"
RM_BIN="`which rm`"
RPM_BIN="`which rpm`"
SED_BIN="`which sed`"
SEQ_BIN="`which seq`"
SORT_BIN="`which sort`"
UNAME_BIN="`which uname`"
WC_BIN="`which wc`"

# Set standard values
BUILD_FOR_ALL_KERNELS="no"
ERROR_CODE=0
FGLRX_CONFIG="/etc/sysconfig/fglrxconfig"
FORCE_BUILD="no"
SUMMARY_REPORT=""
USE_VANILLA_KERNELS="no"

MSG_OKAY="[\033[1;32m OK \033[0m]"
MSG_FAILURE="[\033[1;31m FAILURE \033[0m]"

# Test if we have a real config file
if [ -r "${FGLRX_CONFIG}" -a -f "${FGLRX_CONFIG}" ]; then
    . ${FGLRX_CONFIG}
fi

function displayUsage()
{

    ${CAT_BIN} <<USAGE
Usage: $(${BASENAME_BIN} $0) [options ...]

Without option(s) build only the fglrx kernel module for the running kernel.

Options:
  -a/--all        build the fglrx kernel module for all available kernels
                  otherwise it build only for the running kernel.
  -f/--force      force to build the fglrx kernel module.
  -h/--help       this help text

USAGE

}

function box_filling()
{
    if [ "$1" = "first" ]; then
        ${PRINTF_BIN} "\n\n\n"
    fi
    ${PRINTF_BIN} '*%.0s' $(${SEQ_BIN} 1 80) && ${ECHO_BIN} -n -e "\n"
    if [ "$1" = "last" ]; then
        ${PRINTF_BIN} "\n\n\n"
    fi
}

function box_content()
{
    ${PRINTF_BIN} "*"
    if [ $# -eq 0 ]; then
        ${PRINTF_BIN} ' %.0s' $(${SEQ_BIN} 1 78)
    elif [ $# -eq 2 ]; then
        LEFT="$1"
        RIGHT="$2"
        ${PRINTF_BIN} ' %.0s' $(${SEQ_BIN} 1 3)
        ${PRINTF_BIN} "${LEFT}"
        ${PRINTF_BIN} ' %.0s' $(${SEQ_BIN} 1 $[11-${#LEFT}])
        ${PRINTF_BIN} "${RIGHT}"
        ${PRINTF_BIN} ' %.0s' $(${SEQ_BIN} 1 $[64-${#RIGHT}])
    fi
    ${PRINTF_BIN} "*\n"
}

# Handle arguments/parameters
while [ "$#" -gt "0" ]; do
    case "$1" in
        --all|-a)
            BUILD_FOR_ALL_KERNELS="yes"
            shift 1
        ;;
        --force|-f)
            FORCE_BUILD="yes"
            shift 1
        ;;
        --help|-h)
            displayUsage
            exit 0
        ;;
        *)
            ${ECHO_BIN} "Error: Option \"$1\" is unknown"
            ${ECHO_BIN} -n "try '$(basename $0) -h' or '$(basename $0) --help'"
            ${ECHO_BIN} " for more information"
            exit 1
        ;;
    esac
done

# Remove all available fglrx kernel modules before we build a new fglrx kernel module
if [ "${BUILD_FOR_ALL_KERNELS}" = "yes" -a "${FORCE_BUILD}" = "yes" ]; then
    find /lib/modules/ -iname "fglrx.ko" -print0 | xargs -0 -r rm
elif [ "${BUILD_FOR_ALL_KERNELS}" = "no" -a "${FORCE_BUILD}" = "yes" ]; then
    find /lib/modules/`uname -r`/ -iname "fglrx.ko" -print0 | xargs -0 -r rm
fi

# Get number of CPU cores to speed up compilation on multi-core machines.
NUM_CORES="`${CAT_BIN} /proc/cpuinfo | ${GREP_BIN} '^processor' \
                | ${WC_BIN} -l | ${GREP_BIN} -E '^[0-9]+$'`";

# If CPU cores could not detected, used only 1 core for compilation.
if [ ! "${NUM_CORES}" -gt 0 ]; then
    NUM_CORES=1
fi

${PRINTF_BIN} "\nUsed CPUs/Cores for compilation  =>  [\033[1;32m ${NUM_CORES} \033[0m]"

# Get list of installed kernels
KERNEL_LIST="`${RPM_BIN} -q kernel kernel-desktop kernel-default kernel-pae kernel-smp kernel-bigsmp kernel-vanilla kernel-debug | \
                ${GREP_BIN} -v 'not installed' | ${SORT_BIN} -f -t . -k 1,1 -k 2,2n -k 3,3n -k 4,4n`"

# Get list of installed vanilla kernels
if [ "${USE_VANILLA_KERNELS}" = "yes" ]; then
    LINUX_SOURCE_DIRS="`find /usr/src \
                        -maxdepth 1 \
                        -mindepth 1 \
                        -type d \
                        -iname "linux*" | grep -v 'obj' | sort`"
    # Iterate over all available kernel directories
    for KERNEL_DIR in ${LINUX_SOURCE_DIRS}
    do
        # Detecting of a vanilla kernel
        if [ -f "${KERNEL_DIR}/include/generated/utsrelease.h" ]; then
            pushd ${KERNEL_DIR} >/dev/null
                # Push it to the kernel list
                VANILLA_KERNEL="fglrxvanilla-`make kernelrelease`"
                KERNEL_LIST="${KERNEL_LIST} ${VANILLA_KERNEL}"
            popd >/dev/null
        fi
    done
fi

# Get current kernel version
CURRENT_KERNEL_VERSION="`${UNAME_BIN} -r`"

# Iterate over all installed kernels to build the fglrx kernel modul
for KERNEL in ${KERNEL_LIST}
do
    # Test if we build for rpm installed kernel or vanilla kernel
    if [ -z "`echo "${KERNEL}" | grep 'fglrxvanilla'`" ]; then
        # Get the library of the iterated kernel
        KERNEL_LIBRARY="`${RPM_BIN} --list -q ${KERNEL} | ${SORT_BIN} -f -t . -k 1,1 -k 2,2n -k 3,3n -k 4,4n | \
                            ${GREP_BIN} -m 1 '/lib/modules/'`"
        # Get the version of the iterated kernel
        KERNEL_VERSION="`${ECHO_BIN} "${KERNEL_LIBRARY}" | \
                            ${SED_BIN} -e 's|/lib/modules/||g'`"
        LINUX_SOURCE="${KERNEL_LIBRARY}/build"
        LINUX_INCLUDE="${KERNEL_LIBRARY}/source/include"
        KERNEL_DETECTED="RPM package"
    else
        KERNEL_VERSION="`echo "${KERNEL}" | sed -e 's/fglrxvanilla-//g'`"
        LINUX_SOURCE="/lib/modules/${KERNEL_VERSION}/build"
        LINUX_INCLUDE="/lib/modules/${KERNEL_VERSION}/source/include"
        KERNEL_DETECTED="Vanilla kernel"
    fi

    # Test if we build for all kernels
    if [ "${BUILD_FOR_ALL_KERNELS}" = "no" ]; then
        # Test if this is the running kernel
        if [ "${CURRENT_KERNEL_VERSION}" != "${KERNEL_VERSION}" ]; then
            continue
        fi
    fi

    # Test if we are in normal mode
    if [ "${FORCE_BUILD}" = "no" ]; then
        # Test if the version of the found module matches the version
        # of the running kernel otherwise build the module
        VERMAGIC="`${MODINFO_BIN} -k ${KERNEL_VERSION} -F vermagic fglrx \
                    2>/dev/null | \
                    ${GREP_BIN} ${KERNEL_VERSION}`"
        if [ -n "${VERMAGIC}" ]; then
            continue
        fi
    fi

    # Display important information about the iterated kernel
    box_filling "first"
    box_content
    box_content "Kernel:" "${KERNEL_VERSION}"
    box_content "Source:" "${LINUX_SOURCE}"
    box_content "Include:" "${LINUX_INCLUDE}"
    box_content
    box_filling "last"

    # Resolve if we are building for a kernel with a fix for CVE-2010-3081
    # On kernels with the fix, use arch_compat_alloc_user_space instead
    # of compat_alloc_user_space since the latter is GPL-only.
    COMPAT_ALLOC_USER_SPACE=compat_alloc_user_space
    SOURCE_FILE=${LINUX_INCLUDE}/../arch/x86/include/asm/compat.h
    if [ ! -e ${SOURCE_FILE} ]; then
        SOURCE_FILE=${LINUX_INCLUDE}/asm-x86_64/compat.h
    fi
    if [ ! -e ${SOURCE_FILE} ]; then
        ${ECHO_BIN} "Warning:"
        ${ECHO_BIN} -n "kernel includes at ${LINUX_INCLUDE}"
        ${ECHO_BIN} " not found or incomplete"
        ${ECHO_BIN} "file: ${SOURCE_FILE}"
        ${ECHO_BIN} -n -e "\n"
    else
        if [ `${CAT_BIN} ${SOURCE_FILE} | \
                ${GREP_BIN} -c arch_compat_alloc_user_space` -gt 0 ]; then
            COMPAT_ALLOC_USER_SPACE=arch_compat_alloc_user_space
        fi
        ${ECHO_BIN} -n "file ${SOURCE_FILE} says:"
        ${ECHO_BIN} "COMPAT_ALLOC_USER_SPACE=${COMPAT_ALLOC_USER_SPACE}"
    fi

    # Now we build the fglrx kernel module for the iterated kernel
    # Change to the build root
    pushd /usr/src/kernel-modules/fglrx/2.6.x
        # Clean up stuff from previous builds
        ${MAKE_BIN} clean

        # Copy sources into our build directory
        ${CP_BIN} ../{*.h,*.c,*.a} .

        # Create our report
        SUMMARY_REPORT="${SUMMARY_REPORT}\n   Kernel     => ${KERNEL_VERSION}"
        SUMMARY_REPORT="${SUMMARY_REPORT}\n   Detected   => ${KERNEL_DETECTED}\n"

        # Build the module
        MODFLAGS="-DMODULE -DATI -DFGL"
        MODFLAGS="${MODFLAGS} -DCOMPAT_ALLOC_USER_SPACE=${COMPAT_ALLOC_USER_SPACE}"
        ${MAKE_BIN} \
            -j${NUM_CORES} \
            -C ${LINUX_SOURCE} \
            M=${PWD} \
            MODFLAGS="${MODFLAGS}"

        # Decide wether the build was successful
        if [ $? -ne 0 ]; then
            ${ECHO_BIN} -n -e "\n"
            ${ECHO_BIN} "******************************"
            ${ECHO_BIN} "Build of kernel module failed!"
            ${ECHO_BIN} "******************************"
            ${ECHO_BIN} -n -e "\n"
            SUMMARY_REPORT="${SUMMARY_REPORT}   Build      => ${MSG_FAILURE}\n"
            SUMMARY_REPORT="${SUMMARY_REPORT}   Install    => ${MSG_FAILURE}\n"
            ERROR_CODE=1
        else
            SUMMARY_REPORT="${SUMMARY_REPORT}   Build      => ${MSG_OKAY}\n"

            # Install the module
            ${MAKE_BIN} \
                -j${NUM_CORES} \
                -C ${LINUX_SOURCE} \
                M=${PWD} \
                modules_install

            # Decide wether the installation was successful
            if [ $? -ne 0 ]; then
                ${ECHO_BIN} -n -e "\n"
                ${ECHO_BIN} "*************************************"
                ${ECHO_BIN} "Installation of kernel module failed!"
                ${ECHO_BIN} "*************************************"
                ${ECHO_BIN} -n -e "\n"
                SUMMARY_REPORT="${SUMMARY_REPORT}   Install    => ${MSG_FAILURE}\n"
                ERROR_CODE=1
            else
                SUMMARY_REPORT="${SUMMARY_REPORT}   Install    => ${MSG_OKAY}\n"
            fi
        fi

        # Clean up stuff
        ${MAKE_BIN} clean
        if [ -f modules.order ]; then
            ${RM_BIN} -f modules.order
        fi
    popd

    # Call depmod
    ${ECHO_BIN} "Calling 'depmod -a ${KERNEL_VERSION}' this may take a while..."
    ${DEPMOD_BIN} -a ${KERNEL_VERSION}
done

# Print summary report
${PRINTF_BIN} "\n\nSummary report:\n"
${PRINTF_BIN} '=%.0s' $(seq 1 80) && ${PRINTF_BIN} "\n"
if [ -z "${SUMMARY_REPORT}" ]; then
    ${PRINTF_BIN} "Nothing to do because the fglrx kernel module was already"
    ${PRINTF_BIN} " successfully built!\n\n\nIf you want to force"
    ${PRINTF_BIN} " compiling the fglrx kernel module,"
    ${PRINTF_BIN} " try \"fglrx-kernel-build.sh --force\"\n"
else
    ${PRINTF_BIN} "${SUMMARY_REPORT}"
fi

exit ${ERROR_CODE}

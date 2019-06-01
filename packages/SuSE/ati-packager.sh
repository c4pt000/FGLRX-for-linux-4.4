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

. `dirname $0`/ati-packager-functions.sh
. `dirname $0`/supportedOS.sh

# Function: getSupportedPackages()
# Purpose: lists distribution supported packages
getSupportedPackages()
{
    for CURRENT_SUSE in ${SUSE_LIST}
    do
        # get the SUSE-Version
        SUSE_VERSION=`echo "${CURRENT_SUSE}" | cut -f1 -d"-"`
        ARCH=`echo "${CURRENT_SUSE}" | cut -f2- -d"-"`

        # list all available version of openSUSE and SLE
        echo "${SUSE_VERSION}-${ARCH}"
    done
}

# Function: buildPackage()
# Purpose: build the requested package if it is supported
buildPackage()
{
    PACKAGE_NAME=$1

    debugMsg "Verbose mode:  on" && print_okay
    debugMsg "Verbose level: ${VERBOSE_LEVEL}" && print_okay

    if [ "${VERBOSE_LEVEL}" = "2" ]; then
        VERBOSE_2_LINE_BREAK='\n'
    fi

    if [ -n "`echo "${RELEASE}" | grep -E '^[0-9\.]+$'`" ]; then
        debugMsg "Release: ${RELEASE}" && print_okay
    else
        RELEASE="`./ati-packager-helper.sh --release`"
    fi

    if [ -n "${KERNEL_DEVEL}" ]; then
        if [ "${KERNEL_DEVEL}" = "no" ]; then
            KERNEL_DEVEL=""
            debugMsg "Kernel requirements: (deactivated)" && print_okay
        else
            KERNEL_DEVEL="${KERNEL_DEVEL}"
            debugMsg "Kernel requirements: ${KERNEL_DEVEL}" && print_okay
        fi
    else
        KERNEL_DEVEL="kernel-source kernel-syms\n\
%if %suse_version < 1130\n\
%if %suse_version > 1010\n\
Requires:       linux-kernel-headers\n\
%endif\n\
%else\n\
Requires:       kernel-devel\n\
%endif"
    fi

    debugMsg "Get information about the machine architecture and the version of SUSE and XOrg ...\n"
    for CURRENT_SUSE in ${SUSE_LIST}
    do
        # get the SUSE-Version
        SUSE_VERSION=`echo "${CURRENT_SUSE}" | cut -f1 -d"-"`
        ARCH=`echo "${CURRENT_SUSE}" | cut -f2 -d"-"`
        if [ "${ARCH}" = "IA32" ]; then
            XORG="xpic"
        elif [ "${ARCH}" = "AMD64" ]; then
            XORG="xpic_64a"
        fi

        # list all available version of openSUSE and SLE
        if [ "${PACKAGE_NAME}" = "${SUSE_VERSION}-${ARCH}" ]; then
            debugMsg "   Package name: ${PACKAGE_NAME}\n"
            debugMsg "   Distribution: ${SUSE_VERSION}\n"
            debugMsg "   Architecture: ${ARCH}\n"
            debugMsg "   XOrg version: ${XORG}"
            print_okay
            break 2
        fi
    done

    debugMsg "Assemble the package name for rpm build ...\n"
    if [ "${ARCH}" = "IA32" ]; then
        PACKAGE_NAME="fglrx_xpic_${SUSE_VERSION}"
    elif [ "${ARCH}" = "AMD64" ]; then
        PACKAGE_NAME="fglrx64_xpic_${SUSE_VERSION}"
    fi
    PACKAGE_NAME_CORE=`echo ${PACKAGE_NAME} | sed "s/_xpic_/_core_/g"`
    PACKAGE_NAME_GRAPHICS=`echo ${PACKAGE_NAME} | sed "s/_xpic_/_graphics_/g"`
    PACKAGE_NAME_AMDCCCLE=`echo ${PACKAGE_NAME} | sed "s/_xpic_/_amdcccle_/g"`
    PACKAGE_NAME_OPENCL=`echo ${PACKAGE_NAME} | sed "s/_xpic_/_opencl_/g"`

    if [ "${BUILD_META}" = "true" ]; then
        debugMsg "   Package name (Meta):     ${PACKAGE_NAME}\n"
    fi
    if [ "${BUILD_CORE}" = "true" ]; then
        debugMsg "   Package name (Core):     ${PACKAGE_NAME_CORE}\n"
    fi
    if [ "${BUILD_GRAPHICS}" = "true" ]; then
        debugMsg "   Package name (Graphics): ${PACKAGE_NAME_GRAPHICS}\n"
    fi
    if [ "${BUILD_AMDCCCLE}" = "true" ]; then
        debugMsg "   Package name (AMDCCCLE): ${PACKAGE_NAME_AMDCCCLE}\n"
    fi
    if [ "${BUILD_OPENCL}" = "true" ]; then
        debugMsg "   Package name (OpenCL):   ${PACKAGE_NAME_OPENCL}\n"
    fi

    # set needed variables
    DISTRO_PATH=`cd $(dirname $0) 2>/dev/null && pwd` \
        || checkReturnOutput $? "Could not get the path of distro packaging!"
    debugMsg "Path to the distro packaging:\n   ${DISTRO_PATH}" && print_okay
    INSTALLER_PATH=`pwd` \
        || checkReturnOutput $? "Could not get the path of installer!"
    debugMsg "Path to the installer:\n   ${INSTALLER_PATH}" && print_okay
    TMP_BUILD_OUTPUT="$(mktemp /tmp/amd_pkg_build.out.XXXXXX)" \
        || checkReturnOutput $? "Could not create a temp file in /tmp for the build output!"
    debugMsg "Temporary path to the output from the build:\n   ${TMP_BUILD_OUTPUT}" && print_okay
    TMP_BUILD_PATH="$(mktemp -d /tmp/amd_fglrx.XXXXXX)" \
        || checkReturnOutput $? "Could not create a temp directory in /tmp for the build of rpm file!"
    debugMsg "Temporary path to the build:\n   ${TMP_BUILD_PATH}" && print_okay
    TMP_SPEC_FILE="$(mktemp /tmp/amd_fglrx.spec.XXXXXX)" \
        || checkReturnOutput $? "Could not create a temp file in /tmp for the spec file!"
    debugMsg "Temporary path to the spec file:\n   ${TMP_SPEC_FILE}" && print_okay

    debugMsg "Get the architecture for the AMD arch path: "
    if [ "${ARCH}" = "IA32" ]; then
        AMD_ARCH="x86"
    elif [ "${ARCH}" = "AMD64" ]; then
        AMD_ARCH="x86_64"
    fi
    debugMsg "${AMD_ARCH}" && print_okay

    SPEC_FILE="${DISTRO_PATH}/fglrx.spec"
    debugMsg "Path to the spec file: ${SPEC_FILE}" && print_okay

    VERBOSE_OPTION=""
    if [ "${VERBOSE_LEVEL}" = "2" ]; then
        if [ "${VERBOSE}" = "yes" -o "${VERBOSE}" = "true" -o "${VERBOSE}" = "1" ]; then
            VERBOSE_OPTION="-v"
        fi
    fi

    # create needed directory
    debugMsg "Create needed directory ...${VERBOSE_2_LINE_BREAK}"
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/etc/{init.d,modprobe.d,pam.d,OpenCL/vendors} \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/{bin,include,sbin} \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/lib/dri \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/src/kernel-modules/fglrx \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/share/{applications,ati,man,pixmaps} \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-amdcccle \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-core/patches \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-graphics/articles \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-meta \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-opencl \
        || checkReturnOutput $?
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/X11R6/lib/fglrx \
        || checkReturnOutput $?
    if [ "${ARCH}" = "IA32" ]; then
        mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/lib/xorg/modules/{drivers,linux,updates} \
            || checkReturnOutput $?
#        mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions \
#            || checkReturnOutput $?
    elif [ "${ARCH}" = "AMD64" ]; then
        mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/lib64/dri \
            || checkReturnOutput $?
        mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/X11R6/lib64/fglrx \
            || checkReturnOutput $?
        mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/{drivers,linux,updates} \
            || checkReturnOutput $?
#        mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions \
#            || checkReturnOutput $?
    fi
    mkdir ${VERBOSE_OPTION} -p ${TMP_BUILD_PATH}/var/adm/fillup-templates \
        || checkReturnOutput $?
    print_okay

    # copy all needed files into $TMP_BUILD_PATH
    debugMsg "Copy all needed files into temporary build path ...${VERBOSE_2_LINE_BREAK}"
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/etc ${TMP_BUILD_PATH} \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/lib/modules/fglrx/build_mod/* ${TMP_BUILD_PATH}/usr/src/kernel-modules/fglrx \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/X11R6/bin/* ${TMP_BUILD_PATH}/usr/bin \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/include/* ${TMP_BUILD_PATH}/usr/include \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/sbin/* ${TMP_BUILD_PATH}/usr/sbin \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/applications/* ${TMP_BUILD_PATH}/usr/share/applications \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/ati/* ${TMP_BUILD_PATH}/usr/share/ati \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/doc/amdcccle/* ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-amdcccle \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/doc/fglrx/LICENSE.TXT ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-amdcccle \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/doc/fglrx/LICENSE.TXT ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-core \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/doc/fglrx/* ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-graphics \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/doc/fglrx/LICENSE.TXT ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-meta \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/doc/fglrx/LICENSE.TXT ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-opencl \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/icons/* ${TMP_BUILD_PATH}/usr/share/pixmaps \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/share/man/* ${TMP_BUILD_PATH}/usr/share/man \
        || checkReturnOutput $?
#    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/common/usr/src/ati/* ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-core \
#        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/lib/modules/fglrx/build_mod/* ${TMP_BUILD_PATH}/usr/src/kernel-modules/fglrx \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/bin/* ${TMP_BUILD_PATH}/usr/bin \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/bin/* ${TMP_BUILD_PATH}/usr/bin \
        || checkReturnOutput $?
    if [ "${ARCH}" = "IA32" ]; then
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/etc/OpenCL/vendors/* ${TMP_BUILD_PATH}/etc/OpenCL/vendors \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib/{libAMD*,libXvBAW*,libati*} ${TMP_BUILD_PATH}/usr/lib \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib/modules/dri/* ${TMP_BUILD_PATH}/usr/lib/dri \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib/libfglrx* ${TMP_BUILD_PATH}/usr/X11R6/lib \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib/fglrx/fglrx* ${TMP_BUILD_PATH}/usr/X11R6/lib/fglrx \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/lib/* ${TMP_BUILD_PATH}/usr/lib \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/${XORG}/usr/X11R6/lib/modules/* ${TMP_BUILD_PATH}/usr/lib/xorg/modules \
            || checkReturnOutput $?
        mv ${VERBOSE_OPTION} ${TMP_BUILD_PATH}/usr/lib/xorg/modules/extensions ${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/ \
            || checkReturnOutput $?
    elif [ "${ARCH}" = "AMD64" ]; then
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/etc/OpenCL/vendors/* ${TMP_BUILD_PATH}/etc/OpenCL/vendors \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib64/{libAMD*,libXvBAW*,libati*} ${TMP_BUILD_PATH}/usr/lib64 \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib64/modules/dri/* ${TMP_BUILD_PATH}/usr/lib64/dri \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib64/libfglrx* ${TMP_BUILD_PATH}/usr/X11R6/lib64 \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/X11R6/lib64/fglrx/fglrx* ${TMP_BUILD_PATH}/usr/X11R6/lib64/fglrx \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/lib64/* ${TMP_BUILD_PATH}/usr/lib64 \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/x86/etc/OpenCL/vendors/* ${TMP_BUILD_PATH}/etc/OpenCL/vendors \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/x86/usr/X11R6/lib/{libAMD*,libXvBAW*,libati*} ${TMP_BUILD_PATH}/usr/lib \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/x86/usr/X11R6/lib/modules/dri/* ${TMP_BUILD_PATH}/usr/lib/dri \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/x86/usr/X11R6/lib/libfglrx* ${TMP_BUILD_PATH}/usr/X11R6/lib \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/x86/usr/X11R6/lib/fglrx/fglrx* ${TMP_BUILD_PATH}/usr/X11R6/lib/fglrx \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/x86/usr/lib/* ${TMP_BUILD_PATH}/usr/lib \
            || checkReturnOutput $?
        cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/${XORG}/usr/X11R6/lib64/modules/* ${TMP_BUILD_PATH}/usr/lib64/xorg/modules \
            || checkReturnOutput $?
        mv ${VERBOSE_OPTION} ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/extensions ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/ \
            || checkReturnOutput $?
    fi
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/sbin/* ${TMP_BUILD_PATH}/usr/sbin \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} -R "${INSTALLER_PATH}"/arch/${AMD_ARCH}/usr/share/ati/* ${TMP_BUILD_PATH}/usr/share/ati \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/amd-uninstall.sh ${TMP_BUILD_PATH}/usr/share/ati \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/atieventsd.sh ${TMP_BUILD_PATH}/etc/init.d/atieventsd \
        || checkReturnOutput $?
    # replace authatieventsd.sh
    rm ${VERBOSE_OPTION} -f ${TMP_BUILD_PATH}/etc/ati/authatieventsd.sh \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/authatieventsd.sh ${TMP_BUILD_PATH}/etc/ati/authatieventsd.sh \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/boot.fglrxrebuild ${TMP_BUILD_PATH}/etc/init.d \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/fglrx-kernel-build.sh ${TMP_BUILD_PATH}/usr/bin \
        || checkReturnOutput $?
    if [ "${ARCH}" = "IA32" ]; then
        cp ${VERBOSE_OPTION} -f "${DISTRO_PATH}"/switchlibGL ${TMP_BUILD_PATH}/usr/lib/fglrx \
            || checkReturnOutput $?
    elif [ "${ARCH}" = "AMD64" ]; then
        cp ${VERBOSE_OPTION} -f "${DISTRO_PATH}"/switchlibGL ${TMP_BUILD_PATH}/usr/lib64/fglrx \
            || checkReturnOutput $?
    fi
    if [ "${ARCH}" = "IA32" ]; then
        cp ${VERBOSE_OPTION} -f "${DISTRO_PATH}"/switchlibglx ${TMP_BUILD_PATH}/usr/lib/fglrx \
            || checkReturnOutput $?
    elif [ "${ARCH}" = "AMD64" ]; then
        cp ${VERBOSE_OPTION} -f "${DISTRO_PATH}"/switchlibglx ${TMP_BUILD_PATH}/usr/lib64/fglrx \
            || checkReturnOutput $?
    fi
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/README.SuSE ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-graphics \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/fglrx.png ${TMP_BUILD_PATH}/usr/share/pixmaps \
        || checkReturnOutput $?
    cp ${VERBOSE_OPTION} "${DISTRO_PATH}"/sysconfig.fglrxconfig ${TMP_BUILD_PATH}/var/adm/fillup-templates \
        || checkReturnOutput $?
    echo "blacklist radeon" >${TMP_BUILD_PATH}/etc/modprobe.d/50-fglrx.conf \
        || checkReturnOutput $?
    if [ -n "$(echo ${PACKAGE_NAME} | grep 'SLE')" ]; then
        echo "install fglrx /sbin/modprobe --ignore-install --allow-unsupported-modules fglrx" >>${TMP_BUILD_PATH}/etc/modprobe.d/50-fglrx.conf \
            || checkReturnOutput $?
    fi

    echo "This file marks the fglrx packages fglrx-core, fglrx-graphics, fglrx-amdcccle, fglrx-opencl to be installed" > ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-meta/fglrx-meta.txt
    print_okay

    # copy patch files to the $TMP_BUILD_PATH
    debugMsg "Copy patch files to the temporary build path ...${VERBOSE_2_LINE_BREAK}"
    cp ${VERBOSE_OPTION} -R "${DISTRO_PATH}"/*.patch ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-core/patches
    checkReturnOutput $?

    # clean up temp dir
    debugMsg "Remove unneeded files in the temporary build path ...${VERBOSE_2_LINE_BREAK}"
    if [ -f "${TMP_BUILD_PATH}/usr/src/kernel-modules/fglrx/make.sh" ]; then
        rm ${VERBOSE_OPTION} ${TMP_BUILD_PATH}/usr/src/kernel-modules/fglrx/make.sh \
            || checkReturnOutput $?
    fi
    if [ -d "${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-graphics/examples" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/share/doc/packages/fglrx-graphics/examples \
            || checkReturnOutput $?
    fi
    if [ -f "${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions/fglrx-libglx.so" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions/fglrx-libglx.so \
            || checkReturnOutput $?
    fi
    if [ -f "${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions/libglx.so" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions/libglx.so \
            || checkReturnOutput $?
    fi
    if [ -f "${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions/fglrx/libglx.so" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/lib/xorg/modules/updates/extensions/fglrx/libglx.so \
            || checkReturnOutput $?
    fi
    if [ -f "${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions/fglrx-libglx.so" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions/fglrx-libglx.so \
            || checkReturnOutput $?
    fi
    if [ -f "${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions/libglx.so" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions/libglx.so \
            || checkReturnOutput $?
    fi
    if [ -f "${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions/fglrx/libglx.so" ]; then
        rm ${VERBOSE_OPTION} -r ${TMP_BUILD_PATH}/usr/lib64/xorg/modules/updates/extensions/fglrx/libglx.so \
            || checkReturnOutput $?
    fi
    if [ -d "${TMP_BUILD_PATH}/usr/lib/fglrx" ]; then
        if [ "${ARCH}" = "AMD64" ]; then
            rm ${VERBOSE_OPTION} -rf ${TMP_BUILD_PATH}/usr/lib/fglrx \
                || checkReturnOutput $?
        fi
    fi
    print_okay

    # check fglrx version of AMD Catalyst and add a appending zero if necessary
    AMD_DRIVER_VERSION="`./ati-packager-helper.sh --version`"
    if [ "${#AMD_DRIVER_VERSION}" -eq "4" ]; then
        AMD_DRIVER_VERSION="${AMD_DRIVER_VERSION}0"
    fi

    # substitute variables in the specfile
    debugMsg "Substitute variables in the temporary spec file ...${VERBOSE_2_LINE_BREAK}"
    sed -f - "${DISTRO_PATH}/fglrx.spec" > ${TMP_SPEC_FILE} <<END_SED_SCRIPT
s!%PACKAGE_NAME_CORE!${PACKAGE_NAME_CORE}!
s!%PACKAGE_NAME_GRAPHICS!${PACKAGE_NAME_GRAPHICS}!
s!%PACKAGE_NAME_AMDCCCLE!${PACKAGE_NAME_AMDCCCLE}!
s!%PACKAGE_NAME_OPENCL!${PACKAGE_NAME_OPENCL}!
s!%PACKAGE_NAME!${PACKAGE_NAME}!
s!%AMD_DRIVER_VERSION!${AMD_DRIVER_VERSION}!
s!%AMD_DRIVER_RELEASE!${RELEASE}!
s!%AMD_DRIVER_DESCRIPTION!`./ati-packager-helper.sh --description`!
s!%AMD_DRIVER_URL!`./ati-packager-helper.sh --url`!
s!%AMD_DRIVER_VENDOR!`./ati-packager-helper.sh --vendor`!
s!%AMD_DRIVER_SUMMARY!`./ati-packager-helper.sh --summary`!
s!%AMD_DRIVER_KERNEL_DEVEL!${KERNEL_DEVEL}!
s!%AMD_DRIVER_BUILD_ROOT!${TMP_BUILD_PATH}!
END_SED_SCRIPT
    if [ $? -ne 0 ]; then
        print_failure
        exit 1
    fi
    print_okay

    # build the package
    debugMsg "Build the RPM package now ...${VERBOSE_2_LINE_BREAK}"
    if [ "${ARCH}" = "IA32" ]; then
        if [ "${VERBOSE_LEVEL}" = "2" ]; then
            rpmbuild -bb --target i586 ${TMP_SPEC_FILE} 2>&1 | tee ${TMP_BUILD_OUTPUT}
            RPMBUILD_PID=$!
        else
            rpmbuild -bb --target i586 ${TMP_SPEC_FILE} > ${TMP_BUILD_OUTPUT} 2>&1 &
            RPMBUILD_PID=$!
        fi
    elif [ "${ARCH}" = "AMD64" ]; then
        if [ "${VERBOSE_LEVEL}" = "2" ]; then
            rpmbuild -bb --target x86_64 ${TMP_SPEC_FILE} 2>&1 | tee ${TMP_BUILD_OUTPUT}
            RPMBUILD_PID=$!
        else
            rpmbuild -bb --target x86_64 ${TMP_SPEC_FILE} > ${TMP_BUILD_OUTPUT} 2>&1 &
            RPMBUILD_PID=$!
        fi
    fi

    # RPMBUILD_PID=$(`which pidof` `which rpmbuild`)
    # check for running rpmbuild and display a rotated line
    if [ -z "${VERBOSE}" ]; then
        echo -n -e "Build the RPM package now ..."
    else
        if [ "${VERBOSE_LEVEL}" != "2" ]; then
            debugMsg " |"
        fi
    fi
    while [ -n "`kill -0 ${RPMBUILD_PID} 2>/dev/null && echo 'running'`" ]
    do
        if [ -z "${VERBOSE}" ]; then
            echo -n -e "."
        else
            debugMsg "."
        fi
        sleep 2s
    done
    if [ -z "${VERBOSE}" ]; then
        echo -e ". "
    else
        debugMsg ". "
    fi

    if [ -n "`grep 'RPM build errors' ${TMP_BUILD_OUTPUT}`" ]; then
        echo -n -e "\n"
        tail -n 20 ${TMP_BUILD_OUTPUT}
        echo "Package build failed!"
        print_failure
        rm -f ${TMP_SPEC_FILE} > /dev/null
        rm -f ${TMP_BUILD_OUTPUT} > /dev/null
        rm -rf ${TMP_BUILD_PATH} > /dev/null
        rm -f ${PACKAGE_FILE}
        exit 1
    fi
    print_okay

    # Move the created packages to the directory where the self-extracting driver archive is located
    debugMsg "After-build diagnostics and processing ...\n"
    INSTALLER_PARENT_PATH=`cd "${INSTALLER_PATH}/.." 2>/dev/null && pwd`
    PACKAGE_STR=`sed -n -e "s/Wrote:\s*\(.*\)/\1/p" ${TMP_BUILD_OUTPUT}`
    PACKAGE_FILE_STR=""
    for PACKAGE_FILE_WITH_PATH in ${PACKAGE_STR}
    do
        PACKAGE_FILE=$(basename ${PACKAGE_FILE_WITH_PATH})

        if [ -n "`echo ${PACKAGE_FILE} | grep '_xpic_'`" ]; then
            if [ "${BUILD_META}" = "false" ]; then
                rm ${VERBOSE_OPTION} -f ${PACKAGE_FILE_WITH_PATH}
                continue
            fi
        fi
        if [ -n "`echo ${PACKAGE_FILE} | grep '_core_'`" ]; then
            if [ "${BUILD_CORE}" = "false" ]; then
                rm ${VERBOSE_OPTION} -f ${PACKAGE_FILE_WITH_PATH}
                continue
            fi
        fi
        if [ -n "`echo ${PACKAGE_FILE} | grep '_graphics_'`" ]; then
            if [ "${BUILD_GRAPHICS}" = "false" ]; then
                rm ${VERBOSE_OPTION} -f ${PACKAGE_FILE_WITH_PATH}
                continue
            fi
        fi
        if [ -n "`echo ${PACKAGE_FILE} | grep '_amdcccle_'`" ]; then
            if [ "${BUILD_AMDCCCLE}" = "false" ]; then
                rm ${VERBOSE_OPTION} -f ${PACKAGE_FILE_WITH_PATH}
                continue
            fi
        fi
        if [ -n "`echo ${PACKAGE_FILE} | grep '_opencl_'`" ]; then
            if [ "${BUILD_OPENCL}" = "false" ]; then
                rm ${VERBOSE_OPTION} -f ${PACKAGE_FILE_WITH_PATH}
                continue
            fi
        fi
        echo -n -e "Package ${INSTALLER_PARENT_PATH}/${PACKAGE_FILE} has been successfully generated\n"
        if [ -z "${PACKAGE_FILE_STR}" ]; then
            PACKAGE_FILE_STR="${PACKAGE_FILE}"
        else
            PACKAGE_FILE_STR="${PACKAGE_FILE_STR} ${PACKAGE_FILE}"
        fi
        mv ${PACKAGE_FILE_WITH_PATH} "${INSTALLER_PARENT_PATH}"
    done
    echo -n -e "\n\nInstall or update the RPM package as follows:\n\n   "
    if [ -n "`zypper --version 2>&1 | grep '0.6'`" ]; then
        echo -n -e "rpm -i ${PACKAGE_FILE_STR}\n\n"
    else
        echo -n -e "zypper install ${PACKAGE_FILE_STR}\n\n"
    fi
    print_okay

    # clean-up
    debugMsg "Remove unneeded paths and files ...${VERBOSE_2_LINE_BREAK}"
    rm ${VERBOSE_OPTION} -f ${TMP_SPEC_FILE} \
        || checkReturnOutput $?
    rm ${VERBOSE_OPTION} -f ${TMP_BUILD_OUTPUT} \
        || checkReturnOutput $?
    rm ${VERBOSE_OPTION} -rf ${TMP_BUILD_PATH} \
        || checkReturnOutput $?
    print_okay

    debugMsg "Finished!" && print_okay

    exit 0
}

# Standard
BUILD_PACKAGE=""
BUILD_META="true"
BUILD_CORE="true"
BUILD_GRAPHICS="true"
BUILD_AMDCCCLE="true"
BUILD_OPENCL="true"

while [ "$#" -gt "0" ]; do
    case "$1" in
        --get-supported)
            shift 1
            getSupportedPackages
            exit 0
            ;;
        --get-maintainer)
            shift 1
            echo "Sebastian Siebert <freespacer@gmx.de>"
            exit 0
            ;;
        --buildpkg)
            PACKAGE=$2
            if [ "${PACKAGE}" = "SUSE-autodetection" ]; then
                echo "Auto detection mode:"
                if [ -n "`which lsb_release`" ]; then
                    SUSE_NAME=`lsb-release -d | cut -f2 | cut -f1 -d" "`
                    SUSE_VERSION=`lsb-release -r | cut -f2`

                    if [ "${SUSE_NAME}" = "openSUSE" ]; then
                        AMD_SUSE_NAME="SUSE"
                    elif [ "${SUSE_NAME}" = "Balsam" ]; then
                        AMD_SUSE_NAME="SUSE"
                    else
                        AMD_SUSE_NAME="SLE"
                    fi

                    AMD_SUSE_VERSION=`echo "${SUSE_VERSION}" | sed -e 's/\.//g'`

                    if [ "${#AMD_SUSE_VERSION}" -eq 8 ]; then
                        AMD_SUSE_VERSION="TUMBLEWEED"
                    fi

                    ARCH="$(uname -m)"
                    case "${ARCH}" in
                        i?86)
                            AMD_ARCH="IA32"
                            ;;
                        x86_64)
                            AMD_ARCH="AMD64"
                            ;;
                    esac

                    PACKAGE="${AMD_SUSE_NAME}${AMD_SUSE_VERSION}-${AMD_ARCH}"

                    echo "   Distribution: ${SUSE_NAME}"
                    echo "   Version:      ${SUSE_VERSION}"
                    echo "   Architecture: ${ARCH}"
                    echo "   Package name: ${AMD_SUSE_NAME}${AMD_SUSE_VERSION}-${AMD_ARCH}"
                fi
            fi

            if [ "${PACKAGE}" != "" ]; then
                SUPPORT_FLAG="false"
                for SUPPORTED_LIST in `getSupportedPackages`
                do
                    if [ "${SUPPORTED_LIST}" = "${PACKAGE}" ]; then
                        SUPPORT_FLAG="true"
                        break
                    fi
                done
                if [ "${SUPPORT_FLAG}" = "true" ]; then
                    BUILD_PACKAGE="${PACKAGE}"
                    #buildPackage ${PACKAGE}
                else
                    echo "Requested package is not supported."
                    exit 0
                fi
            else
                echo "Please provide package name"
                exit 0
            fi
            shift 2
            ;;
        --NoXServer|--noxserver)
            BUILD_META="false"
            BUILD_CORE="true"
            BUILD_GRAPHICS="false"
            BUILD_AMDCCCLE="false"
            BUILD_OPENCL="false"
            shift 1
            ;;
        --graphics)
            BUILD_META="false"
            BUILD_CORE="true"
            BUILD_GRAPHICS="true"
            BUILD_AMDCCCLE="false"
            BUILD_OPENCL="false"
            shift 1
            ;;
        --amdcccle)
            BUILD_META="false"
            BUILD_CORE="true"
            BUILD_GRAPHICS="true"
            BUILD_AMDCCCLE="true"
            BUILD_OPENCL="false"
            shift 1
            ;;
        --OpenCL|--opencl)
            BUILD_META="false"
            BUILD_CORE="true"
            BUILD_GRAPHICS="false"
            BUILD_AMDCCCLE="false"
            BUILD_OPENCL="true"
            shift 1
            ;;
        *|--*)
            echo "${ACTION}: unsupported option passed by ati-installer.sh"
            exit 0
            ;;
    esac
done

if [ -n "${BUILD_PACKAGE}" ]; then
    buildPackage ${BUILD_PACKAGE}
fi

exit 0

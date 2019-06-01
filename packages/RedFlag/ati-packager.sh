#!/bin/sh
#
# Purpose
#   Create packages for Fedora Core distributions in a contained environment
#
# Usage
#   See README.distro document

# prevent problems due to locales when grepping for 'Wrote:'
export LC_ALL=C

#Function: getSupportedPackages()
#Purpose: lists distribution supported packages
getSupportedPackages()
{
    #Determine absolute path of <installer root>/<distro>
    RelDistroDir=`dirname $0`
    AbsDistroDir=`cd ${RelDistroDir} 2>/dev/null && pwd`

    #List all spec files in the <installer root>/<distro> directory
    for SpecFile in `ls ${AbsDistroDir}/*.spec 2>/dev/null`; do
        SpecFile=`basename ${SpecFile}`    # Name of the corresponding X directory
        X_DIR=${SpecFile%.*.spec}
        X_NAME=${SpecFile#x*.}             # Well known X or distro name
        X_NAME=${X_NAME%.spec}

        if [ "${X_DIR}" -a "${X_NAME}" -a -d ${AbsDistroDir}/../../${X_DIR} ]; then
            echo ${X_NAME}
        fi
    done
}

#Function: buildPackage()
#Purpose: build the requested package if it is supported
buildPackage()
{
    X_NAME=$1                                                # Well known X or distro name
    RelDistroDir=`dirname $0`                                # Relative path to the distro directory
    AbsDistroDir=`cd ${RelDistroDir} 2>/dev/null && pwd`     # Absolute path to the distro directory
    InstallerRootDir=`pwd`                                   # Absolute path of the <installer root> directory
    TmpPkgBuildOut=${AbsDistroDir}/fglrx/fglrx-pkgbuild.log  # Temporary file to output diagnostics of the package build utility
    TmpDrvFilesDir=${AbsDistroDir}/fglrx                     # Temporary directory to merge files from the common, arch and x* directories
    TmpPkgSpec=${AbsDistroDir}/fglrx/fglrx.spec              # Resulting spec file after variable substitution
    EXIT_CODE=0                                              # Script exit code

    #Detect X directory name corresponding to X_NAME
    X_DIR=`ls ${AbsDistroDir}/x*.${X_NAME}.spec`
    X_DIR=`basename ${X_DIR}`
    X_DIR=${X_DIR%.*.spec}

    #Detect target architechture
    echo ${X_DIR} | grep _64 > /dev/null;
    if [ $? -eq 1 ]; then
        ARCH=i386
        ARCHDIR=x86
    else
        ARCH=x86_64
        ARCHDIR=x86_64
    fi

    PKG_SPEC="${AbsDistroDir}/${X_DIR}.${X_NAME}.spec"      # Package specification file for the requested package

    #[Re]create the merging directory, or clean it up
    rm -rf ${TmpDrvFilesDir} > /dev/null
    mkdir ${TmpDrvFilesDir}

    #Merge files from different source directories
    cp -R ${InstallerRootDir}/common/* ${TmpDrvFilesDir}
    cp -R ${InstallerRootDir}/arch/${ARCHDIR}/* ${TmpDrvFilesDir}
    cp -R ${InstallerRootDir}/${X_DIR}/* ${TmpDrvFilesDir}

	#change the name of libGL.so.1.2
	cd ${TmpDrvFilesDir}/usr/X11R6/lib/
	mv libGL.so.1.2 libGL.so.1.2.ati
	cd -

    # Copy atieventsd scripts
    mkdir -p ${TmpDrvFilesDir}/etc/rc.d/init.d
    cp ${AbsDistroDir}/atieventsd.init ${TmpDrvFilesDir}/etc/rc.d/init.d/atieventsd
    cp -f ${AbsDistroDir}/authatieventsd.sh ${TmpDrvFilesDir}/etc/ati/

    # Copy ati-powermode.sh acpi script (not working on Fedora)
    #mkdir -p ${TmpDrvFilesDir}/etc/acpi/{actions,events}
    #cp ${AbsDistroDir}/ati-powermode.sh ${TmpDrvFilesDir}/etc/acpi/actions/ati-powermode.sh

    #Substitute variables in the specfile
    sed -f - ${PKG_SPEC} > ${TmpPkgSpec} <<END_SED_SCRIPT
s!%ATI_DRIVER_VERSION!`./ati-packager-helper.sh --version`!
s!%ATI_DRIVER_RELEASE!`./ati-packager-helper.sh --release`!
s!%ATI_DRIVER_DESCRIPTION!`./ati-packager-helper.sh --description`!
s!%ATI_DRIVER_URL!`./ati-packager-helper.sh --url`!
s!%ATI_DRIVER_VENDOR!`./ati-packager-helper.sh --vendor`!
s!%ATI_DRIVER_SUMMARY!`./ati-packager-helper.sh --summary`!
s!%ATI_DRIVER_BUILD_ROOT!${TmpDrvFilesDir}!
END_SED_SCRIPT

    #Build the package
    rpmbuild -bb --buildroot ${TmpDrvFilesDir} --dbpath /var/lib/rpm \
             --target ${ARCH} ${TmpPkgSpec} > ${TmpPkgBuildOut} 2>&1
#             --rcfile ${AbsDistroDir}/ati.rpmrc \

    #Retrieve the absolute path to the built package
    if [ $? -eq 0 ]; then
        PACKAGE_STR=`grep "Wrote: .*\.rpm" ${TmpPkgBuildOut} | sed -r 's!Wrote:(.*)!\1!'`
    else
        EXIT_CODE=1
    fi

    #After-build diagnostics and processing
    if [ ${EXIT_CODE} -eq 0 ]; then
        AbsInstallerParentDir=`cd ${InstallerRootDir}/.. 2>/dev/null && pwd`    # Absolute path to the installer parent directory
        for pkg in ${PACKAGE_STR}; do
            cp ${pkg} ${AbsInstallerParentDir}    # Copy the created package to the same directory as the installer
            echo "Package ${AbsInstallerParentDir}/`basename ${pkg}` has been successfully generated"
        done
    else
        echo "Package build failed!"
        echo "Package build utility output:"
        cat ${TmpPkgBuildOut}
        EXIT_CODE=1
    fi

    #Clean-up
    rm -rf ${TmpDrvFilesDir} > /dev/null

    exit ${EXIT_CODE}
}

#Starting point of this script, process the {action} argument

#Requested action
action=$1

case "${action}" in
--get-supported)
    getSupportedPackages
    ;;
--buildpkg)
    package=$2
    if [ "${package}" != "" ]
    then
        support_flag=false
        for supported_list in `getSupportedPackages`
        do
            if [ "${supported_list}" = "${package}" ]
            then
                support_flag=true
                break
            fi
        done
        if [ "${support_flag}" = "true" ]
        then
            buildPackage ${package}
        else
            echo "Requested package is not supported."
        fi
    else
            echo "Please provide package name"
    fi
    exit 0
    ;;
*|--*)
    echo ${action}: unsupported option passed by ati-installer.sh
    exit 0
    ;;
esac

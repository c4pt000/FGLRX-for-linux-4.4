#!/bin/sh
#
# Purpose
#   Sample packaging script
#
# Usage
#   See README.distro document

DRV_RELEASE="`./ati-packager-helper.sh --version`"
DEBEMAIL="`./ati-packager-helper.sh --vendor` <`./ati-packager-helper.sh --url`>"

WOODY="woody"
SARGE="sarge oldstable"  # no longer advertised or supported
ETCH="etch stable"
LENNY="lenny testing"
SID="sid unstable"
EXPERIMENTAL="experimental"

# set locale to sane value
export LANG=C
export LC_ALL=C

# set umask to sane value
umask 002

#Function: getSupportedPackages()
#Purpose: lists distribution supported packages
getSupportedPackages()
{
    echo $SID $ETCH $LENNY $EXPERIMENTAL
}

makeChangelog()
{
    printf "%b\n" "fglrx-installer (${DRV_RELEASE}-`./ati-packager-helper.sh --release`) experimental; urgency=low\n" \
	> ${TmpDrvFilesDir}/debian/changelog
    printf "%b\n" "  * new release\n" \
	>> ${TmpDrvFilesDir}/debian/changelog
    printf "%b\n" " -- ${DEBEMAIL}  `date --rfc-822`\n" \
	>> ${TmpDrvFilesDir}/debian/changelog
}


#Function: buildPackage()
#Purpose: build the requested package if it is supported
buildPackage()
{
    export X_NAME=$1                            # Well known X or distro name
    RelDistroDir=`dirname $0`			# Relative path to the distro directory
    AbsDistroDir=`cd ${RelDistroDir} 2>/dev/null && pwd` # Absolute path to the distro directory
    InstallerRootDir=`pwd`    			# Absolute path of the <installer root> directory
    TmpPkgBuildOut="/tmp/pkg_build.out"	        # Temporary file to output diagnostics of the package build utility
    TmpDrvFilesDir=`mktemp -d -t fglrx.XXXXXX`  # Temporary directory to merge files from the common and x* directories

    #Detect target architechture if not set  
    if [ -z "$ARCH" ]; then
        ARCH=`dpkg-architecture -qDEB_BUILD_ARCH`
    fi
    if [ "$ARCH" = "x86_x64" ]; then
        ARCH="amd64"
    fi

    #Detect x* dir name corresponding to X_NAME
    case ${X_NAME} in
        woody|3.0) echo "Error: ${X_NAME} is no longer supported by this installer" ; exit 1 ;;
        etch|stable|4.0) X_DIR=x710; X_NAME=etch;;
        lenny|testing) X_DIR=x710; X_NAME=lenny;;
        sid|unstable) X_DIR=x710; X_NAME=sid;;
        experimental) X_DIR=x710; X_NAME=experimental;;
        *) echo "Error: invalid package name passed to --buildpkg" ; exit 1 ;;
    esac

    case ${ARCH} in
	amd64) ARCH_DIR=x86_64; X_DIR=${X_DIR}_64a;;
	i386)  ARCH_DIR=x86;;
        *) echo "Error: unsupported architecture: ${ARCH}" ; exit 1 ;;
    esac

    PKG_BUILD_UTIL="dpkg-buildpackage" # Package build utility
    PKG_BUILD_OPTIONS="-a${ARCH} -b -nc -tc -uc -d"
    EXIT_CODE=0	# Script exit code
   
    if [ "$USER" != "root" ]; then
        if [ -x "`which fakeroot`" ]; then
            PKG_BUILD_OPTIONS="$PKG_BUILD_OPTIONS -rfakeroot"
        else
            echo "Error: need root permissions or the \`fakeroot' package installed"
            exit 1
        fi
    fi

    #Merge files from different source directories
    cp -f -R ${InstallerRootDir}/${X_DIR}/* ${TmpDrvFilesDir}
    cp -f -R ${InstallerRootDir}/arch/${ARCH_DIR}/* ${TmpDrvFilesDir}
    cp -f -R ${InstallerRootDir}/common/* ${TmpDrvFilesDir}

    if [ "$ARCH" = "amd64" ]; then
        cp -f -R ${InstallerRootDir}/arch/x86/usr/X11R6/lib \
                ${TmpDrvFilesDir}/usr/X11R6/
    fi

    # Merge package files from the appropriate directories
    chmod -R u+w ${AbsDistroDir}
	cp -f -R ${AbsDistroDir}/dists/${X_NAME} ${TmpDrvFilesDir}/debian
    cp -f -R ${AbsDistroDir}/module ${TmpDrvFilesDir}

    # generate a temporary changelog with version information
    makeChangelog
    
    #Build the package
    cd ${TmpDrvFilesDir}
    ${PKG_BUILD_UTIL} ${PKG_BUILD_OPTIONS} > ${TmpPkgBuildOut} 2>&1

    if [ $? -eq 0 ]; then
        #String containing info where the package was created
        PACKAGE_FILES=`grep 'building package .* in .*\.deb' ${TmpPkgBuildOut} | sed -e 's/.*in \`\(.*\.deb\).*/\1/'`

    	AbsInstallerParentDir=`cd ${InstallerRootDir}/.. 2>/dev/null && pwd` 	# Absolute path to the installer parent directory

        for i in ${PACKAGE_FILES}; do
            mv $i ${AbsInstallerParentDir}	# move the created package to the directory where the self-extracting driver archive is located
            echo "Package ${AbsInstallerParentDir}/`basename ${i}` has been successfully generated"
        done
	
        mv ../fglrx-installer*.changes ${AbsInstallerParentDir}
    else
        echo "Package build failed!"
        echo "Package build utility output:"
        cat ${TmpPkgBuildOut} 
        EXIT_CODE=1
    fi
    
    #Clean-up
    rm -rf ${TmpDrvFilesDir} > /dev/null
    rm -f ${TmpPkgBuildOut} > /dev/null
    
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
        for supported_list in $ETCH $LENNY $SID $EXPERIMENTAL
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


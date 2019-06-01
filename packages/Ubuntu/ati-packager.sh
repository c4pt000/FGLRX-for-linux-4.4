#!/bin/sh
#
# Purpose
#   Create packages and install dependencies
#   for the Ubuntu Linux distribution
#
# Usage
#   See README.distro document

# set locale to sane value
export LANG=C
export LC_ALL=C

# set umask to sane value
umask 002

DRV_RELEASE=`./ati-packager-helper.sh --version`
PADDED_DRV_RELEASE=`printf '%5.3f' "$DRV_RELEASE" 2>/dev/null`
DEBEMAIL="`./ati-packager-helper.sh --vendor` <`./ati-packager-helper.sh --url`>"
REVISION="`./ati-packager-helper.sh --release`"


#Root command
if [ "$USER" != "root" ]; then
    if [ -x /usr/bin/sudo ]; then
        ROOT="/usr/bin/sudo"
    else
        echo "Unable to install sudo.  Please manually install and try again."
        exit ${ATI_INSTALLER_ERR_PREP}
    fi
else
    ROOT="sh -c"
fi

#Synaptic availablity
if [ -x /usr/sbin/synaptic ]; then
    SYNAPTIC="TRUE"
else
    SYNAPTIC=""
fi

#Top level directories used by multiple methods
InstallerRootDir="`pwd`"              # Absolute path of the <installer root> directory
AbsInstallerParentDir="`cd "${InstallerRootDir}"/.. 2>/dev/null && pwd`"    # Absolute path to the installer parent directory

#Function: getAPIVersion()
#Purpose: return the current API compatibility level that we support
getAPIVersion()
{
    #level 1 is --get-supported and --buildpkg
    #exit 1

    #level 2 adds --identify, --buildprep, --installprep, --installpkg and --getAPIVersion
    exit 2
}

#Function: buildDepends()
#Purpose: checks that all build dependencies are resolved
buildDepends()
{
    release=$1

    if [ "$release" = "source" ]; then
        release=`lsb`
    fi

    #if we don't know what we're working with, assume it's supported by the source target
    if [ ! -d packages/Ubuntu/dists/$release ]; then
        release="source"
    fi

    if [ ! -x /usr/bin/dpkg-checkbuilddeps ]; then
        if [ "$2" != "--dryrun" ]; then
            if [ ! -z "$SYNAPTIC" ] && [ ! -z "$DISPLAY" ]; then
                TEMPFILE=`/bin/tempfile`
                cat > $TEMPFILE << EOF
dpkg-dev install
EOF
                $ROOT "sh -c '/usr/sbin/synaptic --set-selections --non-interactive --hide-main-window < $TEMPFILE'"
                rm $TEMPFILE -f
            else
                $ROOT apt-get -y install dpkg-dev
            fi
            #do a check again in case we have failed here
            if [ ! -x /usr/bin/dpkg-checkbuilddeps ]; then
                echo "Unable to install dpkg-dev.  Please manually install and try again."
                exit ${ATI_INSTALLER_ERR_PREP}
            fi
        else
            echo "We would have installed dpkg-dev here."
        fi
    fi
    if [ "$2" = "--dryrun" ] && [ ! -x /usr/bin/dpkg-checkbuilddeps ]; then
        echo "We would have installed more dependencies here, but since dpkg-dev"
        echo "is not installed we would not proceed until this happened"
    fi
    missing_dependencies=$(dpkg-checkbuilddeps packages/Ubuntu/dists/$release/control 2>&1 | awk -F: '{ print $3 }' | sed 's/([^)]*)//g' | sed 's/|\s[^\s]*//g')
    #'
    if [ ! -z "$missing_dependencies" ]; then
        if [ "$2" != "--dryrun" ]; then
            echo "Resolving build dependencies..."
            if [ ! -z "$SYNAPTIC" ] && [ ! -z "$DISPLAY" ]; then
                TEMPFILE=`/bin/tempfile`
                echo $missing_dependencies | sed 's/$/\ /' | sed 's/\ /\ install\r\n/g' > $TEMPFILE
                $ROOT "sh -c '/usr/sbin/synaptic --set-selections --non-interactive --hide-main-window < $TEMPFILE'"
                rm $TEMPFILE -f
            else
                $ROOT apt-get -y install $missing_dependencies
            fi
            #do a check again, abort if we still have some not installed
            missing_dependencies=$(dpkg-checkbuilddeps packages/Ubuntu/dists/$release/control 2>&1 | awk -F: '{ print $3 }' | sed 's/([^)]*)//g' | sed 's/|\s[^\s]*//g')
            #'
            if [ ! -z "$missing_dependencies" ]; then
                echo "Unable to resolve $missing_dependencies.  Please manually install and try again."
                exit ${ATI_INSTALLER_ERR_PREP}
            fi
            echo "Continuing package build"
        else
            echo "We would have installed $missing_dependencies here"
            exit 0
        fi
    fi
}

#Function: getSupportedPackages()
#Purpose: lists distribution supported packages
getSupportedPackages()
{
    current=`lsb`
    if [ -n "$current" ]; then
        echo -n `ls packages/Ubuntu/dists | grep -v $current`
        echo " $current"
    else
        echo `ls packages/Ubuntu/dists`
    fi
}

makeChangelog()
{
    printf "%b\n" "fglrx-installer (2:${PADDED_DRV_RELEASE}-0ubuntu${REVISION}) ${1}; urgency=low\n" \
    > "${TmpDrvFilesDir}/debian/changelog"
    printf "%b\n" "  * New upstream release.\n" \
    >> "${TmpDrvFilesDir}/debian/changelog"
    printf "%b\n" " -- ${DEBEMAIL}  `date --rfc-822`\n" \
    >> "${TmpDrvFilesDir}/debian/changelog"
    cat "${TmpDrvFilesDir}/debian/changelog.in" >> "${TmpDrvFilesDir}/debian/changelog"
}

installPrep()
{
    #check for dkms
    if [ ! -x /usr/sbin/dkms ]; then
        if [ "$2" != "--dryrun" ]; then
            if [ ! -z "$SYNAPTIC" ] && [ ! -z "$DISPLAY" ]; then
                TEMPFILE=`/bin/tempfile`
                cat > $TEMPFILE << EOF
dkms install
EOF
                $ROOT "sh -c '/usr/sbin/synaptic --set-selections --non-interactive --hide-main-window < $TEMPFILE'"
                rm $TEMPFILE -f
            else
                $ROOT "apt-get -y install dkms"
            fi
        else
            echo "We would have installed DKMS here"
            exit 0
        fi
    fi
}

installPackages()
{
    if [ "$2" = "--dryrun" ]; then
        echo "We would have installed the generated packages here"
        exit 0
    fi
    #Detect target architecture if not set
    if [ -z "$ARCH" ]; then
        ARCH=`dpkg --print-architecture`
    fi
    file="fglrx-installer_${PADDED_DRV_RELEASE}-0ubuntu${REVISION}_${ARCH}.changes"
    if [ ! -f "${AbsInstallerParentDir}/$file" ]; then
        echo "Unable to find ${AbsInstallerParentDir}/$file.  Please manually install"
        exit 1
    fi
    cd "${AbsInstallerParentDir}"
    packages=$(cat $file | grep extra | awk '{print $5}' | grep -v dev | grep -v lib | tr "\n" " ")
    $ROOT "sh -c 'dpkg -i ${packages}'"
    echo ${packages}
    RET=$?
    if [ ! $RET -eq 0 ]; then
        echo "Error installing packages"
        exit 1
    fi
    echo "Removing the generated changes file"
    rm ${file} -f
    RET=$?
    if [ ! $RET -eq 0 ]; then
        echo "Error removing the changes file"
        exit 1
    fi
}


#Function: buildPackage()
#Purpose: build the requested package if it is supported
buildPackage()
{
    NO_X=""

    if [ "$2" = "--NoXServer" ]; then
        echo "Building X independent packages"
        NO_X="TRUE"
    fi

    export X_NAME=$1                    # Well known X or distro name (exported for dpkg rules)
    RelDistroDir="`dirname $0`"           # Relative path to the distro directory
    AbsDistroDir=`cd "${RelDistroDir}" 2>/dev/null && pwd` # Absolute path to the distro directory
    TmpPkgBuildOut="/tmp/pkg_build.out"         # Temporary file to output diagnostics of the package build utility
    TmpDrvFilesDir=`mktemp -d -t fglrx.XXXXXX`  # Temporary directory to merge files from the common and x* directories
    DpkgVersion=`dpkg --version | head -n1 | cut -f7  -d" "`
    LegacyDpkg=$(dpkg --compare-versions "$DpkgVersion" lt "1.18" && echo "yes" || echo "no")

    #Detect x* dir name corresponding to X_NAME
    X_DIR=xpic
    case ${X_NAME} in
#        gutsy)  X_DIR=x690;;
#        hardy)  X_DIR=x690;;
#	intrepid)X_DIR=x740;;
#	jaunty) X_DIR=x740;;
#	karmic) X_DIR=x740;;
#	lucid)  X_DIR=x750;;
        source) X_NAME=`lsb`;;
    esac

    #Detect target architecture if not set
    if [ -z "$ARCH" ]; then
        ARCH=`dpkg --print-architecture`
    fi
    if [ "$ARCH" = "x86_x64" ]; then
        ARCH="amd64"
    fi

    case ${ARCH} in
    amd64) ARCH_DIR=x86_64;;
    i386)  ARCH_DIR=x86;;
        *) echo "Error: unsupported architecture: ${ARCH}" ; exit 1 ;;
    esac

    PKG_BUILD_UTIL="dpkg-buildpackage" # Package build utility
    PKG_BUILD_OPTIONS="-a${ARCH} -tc -uc -d"

    if [ "$1" = "source" ]; then
        PKG_BUILD_OPTIONS="${PKG_BUILD_OPTIONS} -us -S"
    else
        PKG_BUILD_OPTIONS="${PKG_BUILD_OPTIONS} -nc -b"
    fi
    EXIT_CODE=0 # Script exit code

    if [ "$USER" != "root" ]; then
        if [ -x "`which fakeroot`" ]; then
            PKG_BUILD_OPTIONS="$PKG_BUILD_OPTIONS -rfakeroot"
        else
            echo "Error: need root permissions or the \`fakeroot' package installed"
            exit 1
        fi
    fi

    #Merge files from different source directories
    cp -f -R "${InstallerRootDir}/${X_DIR}" "${TmpDrvFilesDir}"
    cp -f -R "${InstallerRootDir}/${X_DIR}_64a" "${TmpDrvFilesDir}"
    cp -f -R "${InstallerRootDir}/arch" "${TmpDrvFilesDir}"
    cp -f -R "${InstallerRootDir}/common/"* "${TmpDrvFilesDir}"

    # Merge package files from the appropriate directories
    # If this target doesn't "yet" exist, then copy from the source target
    chmod -R u+w "${AbsDistroDir}"
    if [ -d "${AbsDistroDir}/dists/${X_NAME}" ]; then
        cp -f -R -H -L "${AbsDistroDir}/dists/${X_NAME}" "${TmpDrvFilesDir}/debian"
    else
        cp -f -R -H -L "${AbsDistroDir}/dists/source" "${TmpDrvFilesDir}/debian"
    fi

    # generate a temporary changelog with version information
    makeChangelog ${X_NAME}

    #Build the package
    cd "${TmpDrvFilesDir}"

    #if we are a source package, make a .orig.tar.gz too
    if [ "$1" = "source" ]; then
        tar --exclude=debian --exclude=*orig.tar.gz -czf ../fglrx-installer_${PADDED_DRV_RELEASE}.orig.tar.gz ./
        echo "building fglrx-installer in fglrx-installer_${PADDED_DRV_RELEASE}.orig.tar.gz" > ${TmpPkgBuildOut}
    fi

    debclean >> ${TmpPkgBuildOut} 2>&1

    if [ -n "$NO_X" ] && [ "$1" != "source" ]; then
        #Call only the no-x target
        fakeroot debian/rules binary-no-x >> ${TmpPkgBuildOut} 2>&1
    else
        ${PKG_BUILD_UTIL} ${PKG_BUILD_OPTIONS} >> ${TmpPkgBuildOut} 2>&1
    fi

    if [ $? -eq 0 ]; then
        #String containing info where the package was created
        if [ "$1" = "source" ]; then
            PACKAGE_FILES=`grep 'building fglrx\-installer in' ${TmpPkgBuildOut} | sed -e 's/.*\ in\ //'`
        else
            if [ "$LegacyDpkg" = "yes" ]; then
                PACKAGE_FILES=`grep 'building package .* in .*\.deb' ${TmpPkgBuildOut} | sed -e 's/.*in \`\(.*\.deb\).*/\1/'`
            else
                PACKAGE_FILES=`grep 'building package .* in .*\.deb' ${TmpPkgBuildOut} | cut -d/ -f2 | sed s/\'.//g `
            fi
        fi

        # Remove duplicates
        PACKAGE_FILES="$(echo "$PACKAGE_FILES" | xargs -n1 | sort -u)"

        for i in ${PACKAGE_FILES}; do

            # move the created package to the directory where the self-extracting driver archive is located
            if [ "$1" = "source" ]; then
                mv ../$i "${AbsInstallerParentDir}"
            else
                if [ "$LegacyDpkg" = "yes" ]; then
                    mv $i "${AbsInstallerParentDir}"
                else
                    mv ../$i "${AbsInstallerParentDir}"
                fi
            fi
            echo "Package "${AbsInstallerParentDir}"/`basename ${i}` has been successfully generated"
        done

        mv ../fglrx-installer*.changes "${AbsInstallerParentDir}" 2>/dev/null

    else
        echo "Package build failed!"
        echo "Package build utility output:"
        cat ${TmpPkgBuildOut}
        exit 1
    fi

    #Clean-up
    rm -rf "${TmpDrvFilesDir}" > /dev/null
    rm -f ${TmpPkgBuildOut} > /dev/null
}

lsb()
{
    lsb_launcher=`which lsb_release 2>/dev/null`
    if [ ! -z "$lsb_launcher" ] && [ "`lsb_release -i -s`" = "Ubuntu" ]; then
        echo `lsb_release -s -c`
    elif [ -f /etc/lsb-release ] && [ "`grep ID /etc/lsb-release | awk -F"=" '{ print $2 }'`" = "Ubuntu" ]; then
        echo `grep CODENAME /etc/lsb-release | awk -F"=" '{ print $2 }'`
    fi
}

identify()
{
    if [ x`lsb` = x"$1" ]
    then
        exit 0
    fi
    exit ${ATI_INSTALLER_ERR_VERS}

}

getMaintainer()
{
    echo "Alberto Milone <alberto.milone@canonical.com>"
    exit 0
}

#Starting point of this script, process the {action} argument

#Requested action
action=$1

case "${action}" in
#API v1+ stuff:
--get-supported)
    getSupportedPackages
    ;;
--buildpkg)
    buildPackage $2 $3
    ;;
#API v2+ stuff:
--getAPIVersion)
    getAPIVersion
    ;;
--get-maintainer)
    getMaintainer
    ;;
--identify)
    identify $2
    ;;
--buildprep)
    buildDepends $2 $3
    ;;
--installprep)
    installPrep $2 $3
    ;;
--installpkg)
    #install packages
    installPackages $2
    #turn us on in xorg.conf
    if [ -z "$3" ] || [ "$3" != "--dryrun" ]; then
        if [ -x /usr/bin/aticonfig ]; then
            aticonfig --initial
        fi
    fi
    ;;
*|--*)
    echo ${action}: unsupported option passed by ati-installer.sh
    exit 0
    ;;
esac

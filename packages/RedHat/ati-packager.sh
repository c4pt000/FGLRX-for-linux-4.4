#!/bin/sh
#
# Copyright (c) 2008-2009, 2010, 2011, 2012 Advanced Micro Devices, Inc.
#
# Purpose
#    Create packages for RedHat Linux distribution
#
# Usage
#    See README.distro document

#Function: getSupportedPackages()
#Purpose: lists distribution supported packages
getSupportedPackages()
{
    #Determine absolute path of <installer root>/<distro>
    RelDistroDir=`dirname $0`
    AbsDistroDir=`cd "${RelDistroDir}" 2>/dev/null && pwd`


    #List all spec files in the <installer root>/<distro> directory
    for SpecFile in `ls "${AbsDistroDir}"/*.spec 2>/dev/null`; do
		SpecFile=`basename "${SpecFile}"`
		
		X_DIR="${SpecFile%.*.spec}"	# Name of the x* directory corresponding the requested package
		X_NAME="${SpecFile#x*.}"
		X_NAME="${X_NAME%.spec}"		# Well known X or distro name
		
        if [ "${X_DIR}" -a "${X_NAME}" -a -d "${AbsDistroDir}"/../../"${X_DIR}" ]; then
    	    echo ${X_NAME}
        fi
    done
}


#Function: verifyVersion()
#Purpose: ensure that the distro version passed is supported
verifyVersion()
{
    for supported_list in `getSupportedPackages`
    do
        if [ "${supported_list}" = "${1}" ]
        then
            return 0
        fi
    done
    return ${ATI_INSTALLER_ERR_VERS}
}

#Function: buildPackage()
#Purpose: build the requested package if it is supported
buildPackage()
{
    X_NAME=$1							# Well known X or distro name
    RelDistroDir=`dirname $0`					# Relative path to the distro directory
    AbsDistroDir=`cd "${RelDistroDir}" 2>/dev/null && pwd` 	# Absolute path to the distro directory
    InstallerRootDir=`pwd`    					# Absolute path of the <installer root> directory
    TmpPkgBuildOut="/tmp/pkg_build.out"			# Temporary file to output diagnostics of the package build utility
    TmpDrvFilesDir=/tmp/fglrx					# Temporary directory to merge files from the common, arch and x* directories    
    TmpPkgSpec=/tmp/fglrx.spec					# Final  spec file as a result of the original spec file after variables substituted    
    EXIT_CODE=0							# Script exit code
	
	#Detect x* dir name corresponding to X_NAME
	X_DIR=`ls "${AbsDistroDir}"/x*.${X_NAME}.spec`
	X_DIR=`basename "${X_DIR}"`
    X_DIR=${X_DIR%.*.spec}

    #Detect target architechture    
    echo "${X_DIR}" | grep _64 > /dev/null
    if [ $? -eq 1 ]; then
    	ARCH=i386
    	ARCHDIR=x86
        ARCH_LIB=lib
    else
        ARCH=x86_64
    	ARCHDIR=x86_64
        ARCH_LIB=lib64
        X_DIR64=${X_DIR}_64a
    fi
    
    PKG_SPEC="${AbsDistroDir}/${X_DIR}.${X_NAME}.spec"	# Package specification file for the requested package
    
    #[Re]create the merging directory, or clean it up
	rm -rf ${TmpDrvFilesDir} > /dev/null
	mkdir ${TmpDrvFilesDir}

    # RHEL5 and RHEL6 RPM packages
    echo ${X_DIR} | grep 'xpic' > /dev/null;
    if [ $? -eq 0 ]; then
        cp -R "${InstallerRootDir}"/common/* ${TmpDrvFilesDir}
        cp -R "${InstallerRootDir}"/arch/${ARCHDIR}/* ${TmpDrvFilesDir}
        cp -R "${InstallerRootDir}"/${X_DIR}/* ${TmpDrvFilesDir}
		
        if [ "${ARCH}" = "x86_64" ]; then
            cp -R "${InstallerRootDir}"/arch/x86/usr/X11R6/lib ${TmpDrvFilesDir}/usr/X11R6
            mkdir -p ${TmpDrvFilesDir}/usr/lib
            cp "${InstallerRootDir}"/arch/x86/usr/lib/lib* ${TmpDrvFilesDir}/usr/lib/
            
            cp "${InstallerRootDir}"/arch/x86/etc/OpenCL/vendors/* ${TmpDrvFilesDir}/etc/OpenCL/vendors/
        fi

        # Move files from the common, arch and x* directories as required for modular installs
        if [ -d ${TmpDrvFilesDir}/usr/X11R6/lib/modules/dri ]; then
            mkdir -p ${TmpDrvFilesDir}/usr/lib/dri
            mv -f ${TmpDrvFilesDir}/usr/X11R6/lib/modules/dri/* ${TmpDrvFilesDir}/usr/lib/dri
        fi
        if [ -d ${TmpDrvFilesDir}/usr/X11R6/lib64/modules/dri ]; then
            mkdir -p ${TmpDrvFilesDir}/usr/lib64/dri
            mv -f ${TmpDrvFilesDir}/usr/X11R6/lib64/modules/dri/* ${TmpDrvFilesDir}/usr/lib64/dri
        fi

        mkdir -p ${TmpDrvFilesDir}/usr/${ARCH_LIB}/xorg/modules
        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/modules/{drivers,linux} \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}/xorg/modules
        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/modules/glesx* \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}/xorg/modules
        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/modules/amdxmm* \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}/xorg/modules

        mkdir -p ${TmpDrvFilesDir}/usr/${ARCH_LIB}/xorg/modules/extensions/fglrx
        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/modules/extensions/fglrx/fglrx-libglx* \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}/xorg/modules/extensions/fglrx
        
        
        #Move the directory for the OpenGL libraries
        if [ -f ${TmpDrvFilesDir}/usr/X11R6/lib/fglrx/fglrx-libGL.so.1.2 ]; then
            mkdir -p ${TmpDrvFilesDir}/usr/lib/fglrx
            mv -f ${TmpDrvFilesDir}/usr/X11R6/lib/fglrx/fglrx-libGL.so.1.2 ${TmpDrvFilesDir}/usr/lib/fglrx/
        fi
        if [ -f ${TmpDrvFilesDir}/usr/X11R6/lib64/fglrx/fglrx-libGL.so.1.2 ]; then
            mkdir -p ${TmpDrvFilesDir}/usr/lib64/fglrx/
            mv -f ${TmpDrvFilesDir}/usr/X11R6/lib64/fglrx/fglrx-libGL.so.1.2 ${TmpDrvFilesDir}/usr/lib64/fglrx/
        fi

        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/lib*.a \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}

        
    	mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/libatiadl*.* \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}


        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/libAMDXvBA*.* \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}

        mv ${TmpDrvFilesDir}/usr/X11R6/${ARCH_LIB}/libXvBAW*.* \
           ${TmpDrvFilesDir}/usr/${ARCH_LIB}

                           

        if [ "${ARCH}" = "x86_64" ]; then
            mv ${TmpDrvFilesDir}/usr/X11R6/lib/lib*.a \
               ${TmpDrvFilesDir}/usr/lib
               

            mv ${TmpDrvFilesDir}/usr/X11R6/lib/libatiadl*.* \
               ${TmpDrvFilesDir}/usr/lib
        

            mv ${TmpDrvFilesDir}/usr/X11R6/lib/libAMDXvBA*.* \
               ${TmpDrvFilesDir}/usr/lib

            mv ${TmpDrvFilesDir}/usr/X11R6/lib/libXvBAW*.* \
               ${TmpDrvFilesDir}/usr/lib

        fi

        # Move the binaries to /usr/bin
        mkdir -p ${TmpDrvFilesDir}/usr/bin
        mv ${TmpDrvFilesDir}/usr/X11R6/bin/* \
            ${TmpDrvFilesDir}/usr/bin
		#Assign sticky bit to amd-console-helper
		chmod a+s ${TmpDrvFilesDir}/usr/bin/amd-console-helper

        #Substitute variables in the specfile
        echo "requires: compat-libstdc++-33" > ${TmpPkgSpec}
        sed -f - "${PKG_SPEC}" >> ${TmpPkgSpec} <<END_SED_SCRIPT
s!%ATI_DRIVER_VERSION!`./ati-packager-helper.sh --version`!
s!%ATI_DRIVER_RELEASE!`./ati-packager-helper.sh --release`!
s!%ATI_DRIVER_DESCRIPTION!`./ati-packager-helper.sh --description`!
s!%ATI_DRIVER_URL!`./ati-packager-helper.sh --url`!
s!%ATI_DRIVER_VENDOR!`./ati-packager-helper.sh --vendor`!
s!%ATI_DRIVER_SUMMARY!`./ati-packager-helper.sh --summary`!
s!%ATI_DRIVER_BUILD_ROOT!${TmpDrvFilesDir}!
END_SED_SCRIPT

        ### blacklisting - required for disabling radeon on systems with KMS ###                
        mkdir -p ${TmpDrvFilesDir}/etc/modprobe.d
        blacklistfile="${TmpDrvFilesDir}/etc/modprobe.d/blacklist-fglrx.conf"
        echo "# Advanced Micro Devices, Inc."> ${blacklistfile}
        echo "# radeon conflicts with AMD Linux Graphics Driver" >> ${blacklistfile}
        echo "blacklist radeon" >> ${blacklistfile}

        ### amdconfig to symlink to aticonfig ###                
        ln -s /usr/bin/aticonfig ${TmpDrvFilesDir}/usr/bin/amdconfig

        ### amd-uninstall ###
        AMD_UNINSTALL="amd-uninstall.sh"
        mkdir -p ${TmpDrvFilesDir}/usr/share/ati
        cp ${AbsDistroDir}/${AMD_UNINSTALL} ${TmpDrvFilesDir}/usr/share/ati/

        #substitute the package name in script with the one here
        if [ "${ARCH}" = "x86_64" ]; then
            sed -i "s/%AMD_RHEL_DRV_NAME/'fglrx64_p_i_c'/g" ${TmpDrvFilesDir}/usr/share/ati/${AMD_UNINSTALL}
        else
            sed -i "s/%AMD_RHEL_DRV_NAME/'fglrx_p_i_c'/g" ${TmpDrvFilesDir}/usr/share/ati/${AMD_UNINSTALL}
        fi

        
        #generate %files section of rpm
        find ${TmpDrvFilesDir} -type f -name "*" | grep -v "fireglcontrol" | sed -e "s!${TmpDrvFilesDir}!!" | to_rpm_file_list >> ${TmpPkgSpec} 
        find ${TmpDrvFilesDir} -type l -name "*" | sed -e "s!${TmpDrvFilesDir}!!" | to_rpm_file_list >> ${TmpPkgSpec}

        ### create user profile with write access ###                
        touch ${TmpDrvFilesDir}/etc/ati/atiapfuser.blb
        echo "%config %attr(666, root, root) /etc/ati/atiapfuser.blb" >> ${TmpPkgSpec}
        
        if [ $? -eq 0 ]; then

            #Build the package
            #RHEL5/RHEL6 RPM packages
            rpmbuild -bb --buildroot ${TmpDrvFilesDir} --target ${ARCH} ${TmpPkgSpec} > ${TmpPkgBuildOut} 2>&1
            
            #Retrieve the absolute path to the built package
            if [ $? -eq 0 ]; then
                PACKAGE_STR=`grep ".*: .*\.rpm" ${TmpPkgBuildOut}` 	#String containing info where the package was created
                PACKAGE_FILE=`expr "${PACKAGE_STR}" : '.*: \(.*\)'`	#Absolute path to the create package file
            else
		        EXIT_CODE=1
            fi

        else
            #failed to find and set permissions for files to be installed             
            echo "Unexpected files found for rpmbuild. rpm package not built."
            EXIT_CODE=1
        fi
        
    else

        #unsupported
        echo "Unsupported RedHat distribution specified."
        EXIT_CODE=1

    fi
    
    
    #After-build diagnostics and processing
    if [ ${EXIT_CODE} -eq 0 ]; then
    	AbsInstallerParentDir=`cd "${InstallerRootDir}"/.. 2>/dev/null && pwd` 	# Absolute path to the installer parent directory
        cp ${PACKAGE_FILE} "${AbsInstallerParentDir}"	# Copy the created package to the directory where the self-extracting driver archive is located
        echo "Package ${AbsInstallerParentDir}/`basename "${PACKAGE_FILE}"` has been successfully generated"
        echo "${AbsInstallerParentDir}/`basename "${PACKAGE_FILE}"`" > "${AbsInstallerParentDir}"/tmpBuiltRedHatpkg.txt
    else
        echo "Package build failed!"
        echo "Package build utility output:"
        cat ${TmpPkgBuildOut} 
		EXIT_CODE=1
    fi
	
	#Clean-up
    rm -f ${TmpPkgSpec} > /dev/null
    rm -f ${TmpPkgBuildOut} > /dev/null
    rm -rf ${TmpDrvFilesDir} > /dev/null
    return ${EXIT_CODE}
}

#Function: installPackage()
#Purpose: install a successfully built package
installPackage()
{
    which rpm &> /dev/null
    if [ $? -eq 0 ]
    then
        InstallerRootDir=`pwd`                              #Absolute path of the <installer root> directory where tmpBuiltRedHatpkg.txt is
        AbsInstallerParentDir=`cd "${InstallerRootDir}"/.. 2>/dev/null && pwd`
       
        if [ -f "${AbsInstallerParentDir}"/tmpBuiltRedHatpkg.txt ]          #File that contains the absolute path to the package file
        then
            package=`cat "${AbsInstallerParentDir}"/tmpBuiltRedHatpkg.txt`

            #check if the path to the package contains spaces, 
            #different versions of shell handle spaces differently 
            if [ `echo ${package} | wc -w` -gt 1  ]
            then
            
                #test if it will install or will get errors
                rpm -Uvh --test "${package}" > /dev/null 2>&1
                rpmRetVal=$?
                if [ ${rpmRetVal} -ne 0 ]
                then
                    #escape the spaces and try 
                    package=`sed 's/ /\\\\ /g' "${AbsInstallerParentDir}"/tmpBuiltRedHatpkg.txt`
                fi
            fi
            
            #test if RPM will install or will get errors
            rpm -Uvh --test "${package}" > /dev/null 2>&1
            rpmRetVal=$?
            if [ ${rpmRetVal} -eq 0 ]
            then
                #test passed, install for real
                rpm -Uvh "${package}" 
                rpmRetVal=$?
            
                if [ ${rpmRetVal} -eq 0 ]
                then
                    echo "Installation successful, please initialize the driver using \"aticonfig --initial\""
                    echo "A reboot of the system is recommended after running aticonfig."
                    rm -f "${AbsInstallerParentDir}"/tmpBuiltRedHatpkg.txt > /dev/null
                fi
            else
                echo "Install Error: rpm test install, ${package}, of package failed"                
            fi
            
            return ${rpmRetVal}
 
        else
            echo "Cannot locate tmpBuiltRedHatpkg.txt"
        fi
    else    
        echo "Install Error: rpm package required.  Please install rpm and try again"
    fi    
    return 1
}

#Function: installPrep()
#Purpose: ensure that requirements for the driver to function are in place
installPrep()
{
    retStatus=1
    
    
    InstallerRootDir=`pwd`                              #Absolute path of the <installer root> directory where tmpBuiltRedHatpkg.txt is
    AbsInstallerParentDir=`cd "${InstallerRootDir}"/.. 2>/dev/null && pwd`

    # check if package is supported on the system
    if [ `uname -m` = "x86_64" ]; then
        DCM_BIN=amd_dcm64
    else
        DCM_BIN=amd_dcm32
    fi    
    
    if [ -x "${InstallerRootDir}/${DCM_BIN}" ]
    then
        ${InstallerRootDir}/$DCM_BIN 2>/dev/null
        result=$?
        
        if [ ${result} -ne 0 ]
        then
            # system does not have supported adapter
            echo "Install Error: Your graphics adapter is not supported by this driver. Installation will not proceed."
            return ${ATI_INSTALLER_ERR_PREP}
        fi
    else
        echo "Installer binary, amd_dcm, cannot be located. Installation will not proceed."
        return ${ATI_INSTALLER_ERR_PREP}        
    fi


    #glibc v. 2.2 or 2.3
    glibcVersion=`rpm -q glibc | cut -d"-" -f2`
    
    for ver in ${glibcVersion}
    do
       if [ `echo ${ver} | cut -d"." -f1` -eq 2 ]
       then
           if [ `echo ${ver} | cut -d"." -f2` -ge 2 ]
           then
               retStatus=0
           fi      
       fi
    done
    
    if [ $retStatus -eq 1 ]
    then
       echo "please upgrade to glibc 2.2 or higher"
    fi
  
    #Linux Kernel 2.6 or higher
    kernelRelease=`uname -r`
    if [ `echo ${kernelRelease} | cut -d"." -f1` -eq 2 ]
    then
        if [ `echo ${kernelRelease} | cut -d"." -f2` -lt 6 ]
        then
            echo "please upgrade to kernel 2.6 or higher"
            retStatus=1
        fi
    elif [ `echo ${kernelRelease} | cut -d"." -f1` -lt 2 ]
    then
        echo "please upgrade to kernel 2.6 or higher"
        retStatus=1
    fi


    #kernel headers
    rpm -q kernel-devel &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install kernel-devel package"
        retStatus=1
    fi
    
    #XOrg 6.9 or higher
    tmpPackage=`lsb_release -rs`
    tmpPackage=`echo ${tmpPackage} | cut -d"." -f1`
    if [ "${tmpPackage}" = "5" -o "${tmpPackage}" = "6" ]
    then
        rpm -q xorg-x11-server-Xorg &> /dev/null
        if [ $? -ne 0 ]
        then
            rpm -q xorg-x11 &> /dev/null
            if [ $? -ne 0 ]
            then
                which Xorg &> /dev/null
                if [ $? -ne 0 ]
                then
                    echo "please install XOrg 6.9 or newer"
                    retStatus=1
                fi
            fi
        fi
    fi

    #libstdc++
    rpm -q libstdc++ &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install libstd++ package"
        retStatus=1
    fi
    #libgcc
    rpm -q libgcc &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install libgcc package"
        retStatus=1
    fi
    #fontconfig
    rpm -q fontconfig &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install fontconfig package"
        retStatus=1
    fi
    #freetype
    rpm -q freetype &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install freetype package"
        retStatus=1
    fi
    #zlib
    rpm -q zlib &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install zlib package"
        retStatus=1
    fi
    #gcc
    rpm -q gcc &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install gcc package"
        retStatus=1
    fi
    
    #make
    rpm -q make &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "please install make package"
        retStatus=1
    fi
    
    #mesa-libGL
    if [ "${tmpPackage}" = "5" -o "${tmpPackage}" = "6" ]
    then
        rpm -q mesa-libGL &> /dev/null
        if [ $? -ne 0 ]
        then
            rpm -q xorg-x11-Mesa-libGL &> /dev/null
            if [ $? -ne 0 ]
            then
                echo "please install mesa-libGL package"
                retStatus=1
            fi
        fi
    fi

    if [ ${retStatus} -eq 0 ]
    then
        return 0
    else
        echo "Installation Error: please install preceeding packages"
        return ${ATI_INSTALLER_ERR_PREP}
    fi
    
   
}



#Function: removePreviousInstall()
#Purpose: check if there is a previous install, uninstall if possible, otherwise error
removePreviousInstall()
{
    #Determine absolute path of <installer root>/<distro>
    RelDistroDir=`dirname $0`
    AbsDistroDir=`cd "${RelDistroDir}" 2>/dev/null && pwd`
    ScriptDir="${AbsDistroDir}"/../../
	
    #check if there is a previous installation, if not running with force
    if [ "$FORCE_ATI_UNINSTALL" = "y" ]; then
        result=0
    else
        #not running with force, check if there is a previous driver
        if [ -x "${ScriptDir}detect_previous.sh" ]; then
            echo "Detecting if there are previous installations of fglrx driver..."
            sh "${ScriptDir}detect_previous.sh"
            result=$?
        else
            #could not find the script
            echo "Install Error: required detect_previous script not found."
            result=1
        fi
    fi

    if [ $result -eq 0 ]; then
        # detected previous installation, and can uninstall successfully or
        # running with force, uninstall any previous driver without checking

        FGLRX_UNINSTALL_SCRIPT="/usr/share/ati/fglrx-uninstall.sh"
        if [ -x "${FGLRX_UNINSTALL_SCRIPT}" ]; then
            echo "Removing a previous installation of fglrx driver..."
            FORCE_ATI_UNINSTALL=Y
            export FORCE_ATI_UNINSTALL
            sh "$FGLRX_UNINSTALL_SCRIPT" > /dev/null
        fi    
        #ignore return result because nothing can be done at this stage
        #previous driver uninstalled and needs to be overwritten by new install
        result=0
    else
        echo "A previous install of the fglrx driver has been detected. 
Please uninstall the older version before installing this version. 
Optionally, run the installer with --force to overwrite the existing driver.
Forcing install is not recommended."        
        
    fi
    
    return $result
}


#Function: buildPrep()
#Purpose: encsure that requirements to build the package are in place
buildPrep()
{
    if [ "${1}" = "--dryrun" ] || [ "${1}" = "" ]
    then
        which rpmbuild &> /dev/null
        if [ $? -eq 0 ]
        then
            if [ "${1}" = "--dryrun" ]
            then
                echo "Driver package would be built successfully"                
            fi
            return 0
        else
            if [ "${1}" = "--dryrun" ]
            then
                echo "Build Failure: rpmbuild is missing, to successfully build, install the rpm package"
                return ${ATI_INSTALLER_ERR_PREP}                                    
            else
                echo "Build Failure: rpmbuild is missing, please install the rpm package"
                return ${ATI_INSTALLER_ERR_PREP}
            fi
        fi        
    else
        echo "Error: Unrecognized build option parameter ${1}"
        return ${ATI_INSTALLER_ERR_BUILDOP}
    fi
}

#Function: getAPIVersion()
#Purpose: return the the current API version of this script
getAPIVersion()
{
    return 2
}

#Function: getMaintainer()
#Purpose: return the the current maintainer of this script
getMaintainer()
{
    echo "AMD"
    return 0
}


#Function: identify()
#Purpose: returns 0 if the running Kernel is RHEL and the same version passed as a parameter
identify()
{
    tmpDistro=`lsb_release -is 2>/dev/null`
    if [ "${tmpDistro}" = "" ]; then
	if [ -f /etc/redhat-release ]; then 
	   tmpDistro=RedHatEnterprise
	fi
    fi
    echo ${tmpDistro} | grep RedHatEnterprise &> /dev/null
    if [ "$?" -eq 0 ]
    then
        tmpPackage=`lsb_release -rs`                        #get distro version  eg. 5.1
        tmpPackage=`echo ${tmpPackage} | cut -d"." -f1`     #get major version number eg. 5
        arch=`uname -i`                                     #32 bit or 64
	if [ "${tmpPackage}" = "" ]; then
	   tmpPackage=`cat /etc/redhat-release | cut -d"." -f1 | cut -d" " -f7`
	fi
	if [ "${tmpPackage}" = "7" ]
        then
            if [ "${arch}" = "x86_64" ]
            then
                if [ "${1}" = "RHEL7_64a" ]
                then
                    return 0
                else
                    return ${ATI_INSTALLER_ERR_VERS}
                fi
            elif [ "${arch}" = "i386" ]
            then
                 if [ "${1}" = "RHEL7" ]
                then
                    return 0
                else
                    return ${ATI_INSTALLER_ERR_VERS}
                fi
            else
                return ${ATI_INSTALLER_ERR_VERS}
            fi
        elif [ "${tmpPackage}" = "6" ]
        then
            if [ "${arch}" = "x86_64" ]
            then
                if [ "${1}" = "RHEL6_64a" ]
                then
                    return 0
                else
                    return ${ATI_INSTALLER_ERR_VERS}
                fi
            elif [ "${arch}" = "i386" ]
            then
                 if [ "${1}" = "RHEL6" ]
                then
                    return 0
                else
                    return ${ATI_INSTALLER_ERR_VERS}
                fi
            else
                return ${ATI_INSTALLER_ERR_VERS}
            fi
        elif [ "${tmpPackage}" = "5" ]
        then
            if [ "${arch}" = "x86_64" ]
            then
                if [ "${1}" = "RHEL5_64a" ]
                then
                    return 0
                else
                    return ${ATI_INSTALLER_ERR_VERS}
                fi
            elif [ "${arch}" = "i386" ]
            then
                 if [ "${1}" = "RHEL5" ]
                then
                    return 0
                else
                    return ${ATI_INSTALLER_ERR_VERS}
                fi
            else
                return ${ATI_INSTALLER_ERR_VERS}
            fi
        else
            return ${ATI_INSTALLER_ERR_VERS}
        fi
    else
        return ${ATI_INSTALLER_ERR_DIST}
    fi
}


#Function: mode_from_basename()
#Purpose: returns mode based on file's extension or file name
mode_from_basename() {
    
    local m
    case "${1##*/}" in
      (Makefile)        m='644';;
      (*.o)             m='644';;
      (*.a)             m='644';;
      (*.a.GCC?)        m='644';;
      (*.[ch])		m='644';;
      (*.cap)		m='644';;
      (*.conf)		m='644';;
      (*.desktop)       m='644';;
      (*.sh)		m='755';;
      (*.so)	        m='755';;
      (*.so.*)          m='755';;
      (*.tgz)		m='644';;
      (*.xbm.example)   m='644';;
      (*.xml)		m='644';;
      (switchlib*)		m='755';;
      (*.icd)		m='644';;
      (*.blb)		m='644';;
    esac
    MODE="$m"

}



#Function: mode_from_directory()
#Purpose: returns mode based on directory path
mode_from_directory() {
    
    local m
    case "${1%/*}" in
      (/usr/share/doc/*)       doc='%doc '; m='644';;
      (/etc/ati)		            m='644';;
      (/etc/security/console.apps)	    m='644';;
      (/usr/bin)			    m='755';;     
      (/usr/sbin)			    m='755';;
      (/usr/X11R6/bin)		            m='755';;
      (/usr/share/applications)             m='644';;
      (/usr/share/ati/*)	            m='644';;
      (/usr/share/icons)                    m='644';;
      (/usr/share/man/man?)                 m='644';;
    esac
    MODE="$m"
}

#Function: to_rpm_file_list()
#Purpose: returns file name with (doc) attr directive
to_rpm_file_list() {
    local file o g
    while read file; do
        o=root g=root doc= MODE=

        # find file mode based on file extension or directory
        mode_from_basename "$file"
        [ -n "$MODE" ] || mode_from_directory "$file"
        [ -n "$MODE" ] || {
            return 1
        }
	    
       echo "${doc}%attr($MODE, $o, $g) $file"
   done
   
   return 0
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
        verifyVersion ${package}
        if [ $? -eq 0 ]
        then
            buildPackage ${package}
            exit $?
        else
            echo "Requested package is not supported."
            exit ${ATI_INSTALLER_ERR_VERS}
        fi
    else
		echo "Please provide package name."
        exit ${ATI_INSTALLER_ERR_VERS}
    fi    
    ;;
--installpkg) # <version>
    package=$2
    
    if [ "${package}" != "" ]
    then
        #check if user has superuser privileges
        if [ "`whoami`" != "root" ]; then
            #do not run this script without root privileges
            #return 0 and installer will handle telling user that they need to be root
            echo "[Warning] ATI  Proprietary Drive: must be run as root to install package."
            exit ${ATI_INSTALLER_ERR_SUPERUSER}
        fi

        verifyVersion ${package}
        if [ $? -eq 0 ]
        then
            removePreviousInstall
            result=$?
            if [ $result -eq 0 ]; then
              
                #no older driver installed or running with force
                #install new package
                installPackage ${package}
                exit $?
            else
               exit ${ATI_INSTALLER_ERR_PREV_INSTALL}
            fi
        else
            echo "Requested package is not supported."
            exit ${ATI_INSTALLER_ERR_VERS}
        fi
    else
		echo "Please provide package name."
        exit ${ATI_INSTALLER_ERR_VERS}
    fi
    ;;
--installprep) #<version> <--dryrun>
    package=$2
    if [ "${package}" != "" ]
    then
        verifyVersion ${package}
        if [ $? -eq 0 ]
        then
            installPrep ${package} $3
            exit $?
        else
            echo "Requested package is not supported."
            exit ${ATI_INSTALLER_ERR_VERS}
        fi
    else
		echo "Please provide package name."
        exit ${ATI_INSTALLER_ERR_VERS}
    fi
    ;;
--buildprep) #<version><--dryrun>
    package=$2
    if [ "${package}" != "" ]
    then
        verifyVersion ${package}
        if [ $? -eq 0 ]
        then
            buildPrep $3  #buildPrep doesn't actually need the version
            exit $?
        else
            echo "Requested package is not supported."
            exit ${ATI_INSTALLER_ERR_VERS}
        fi
    else
		echo "Please provide package name."
        exit ${ATI_INSTALLER_ERR_VERS}
    fi    
    ;;  
--getAPIVersion)
    getAPIVersion
    exit $?
    ;;
--get-maintainer)
    getMaintainer
    exit $?
    ;;    
--identify)# <version>
    package=$2
    if [ "${package}" != "" ]
    then
        verifyVersion ${package}
        if [ $? -eq 0 ]
        then
            identify ${package}
            exit $?
        else
            echo "Requested package is not supported."
            exit ${ATI_INSTALLER_ERR_VERS}
        fi
    else
		echo "Please provide package name."
        exit ${ATI_INSTALLER_ERR_VERS}
    fi    
    ;;
*|--*)
    echo ${action}: unsupported option passed by ati-installer.sh
    exit 1
    ;;
esac


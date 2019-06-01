#!/bin/sh
#
#Policy layer information:
# Completion date: August 2006
#
# Copyright (c) 2008-2009, 2010, 2011, 2012 Advanced Micro Devices, Inc.
#
#Purpose: this script is called after .run archive is extracted, "--argument" is passed to this script
#      it handles "install," "listpkg," and "buildpkg <package name>"
#Parameters: 
#   Input:
#       $1 - driver version
#       $2 - operation to perform (--install, --listpkg, --buildpkg, --buildandinstallpkg)
#       $3 - <package name> if the operation is --buildpkg or --buildandinstallpkg
#            If the appropriate ati-packager.sh file has been updated to version 2 or higher
#            $3 can be --dryrun to simulate the operation
#       $4 - If the ati-packager.sh associated with <package name> has been updated to version 2
#            or higher $4 can be --dryrun 
#   Return:
#       status - 1 if error occurs, 0 if not
#   External variables:
#       all variables listed in ExportVars; these are set by default_policy.sh
#       and possibly also by packages/*/ati-packager.sh if the current distro
#       matches (as defined by --iscurrentdistro) one of the distros in the
#       packages folder

checksh()
{
    . ./check.sh $@
}

Setup_with_CD_and_CDV_set()
{
    WRITE_DEFAULT_POLICY="0"
    WriteNewInstPath
    . $TMP_INST_PATH_OVERRIDE
    ExportVars
}


CreateInstallLog()
{

   # Clean up the log directory and create the log file

   # make sure we're not doing "rm -rf /"; that would be bad
   if [ "${ATI_UNINST}" = "/" ]
   then
       echo "Error: UNINST_PATH is / in create_log.sh; aborting" 1>&2
       echo "rm operation to prevent unwanted data loss" 1>&2

      exit 1
   fi

   # if ${UNINST_PATH} directory doesn't exist, create it
   if [ ! -d ${ATI_UNINST} ]
   then
      mkdir -p ${ATI_UNINST}
   fi

   # if ${LOG_FILE} already exists, remove it 
   if [ -e ${ATI_LOG}/fglrx-install.log ]
   then
      rm -f ${ATI_LOG}/fglrx-install.log  
   fi

   # create ${LOG_FILE}
   touch ${ATI_LOG}/fglrx-install.log
}

#Installs the distribution specific packages if user accepts to install the package.
InstallDistPackage()
{
        pkg_list=`execIdentify 2>/dev/null`

        checkDistroResult ${pkg_list}
        if [ $? -eq 0 ]
        then
            # Get distro/package values
            distro=`echo ${pkg_list} | cut -d"/" -f1`
            package=`echo ${pkg_list} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                echo "Installing package for: ${distro}/${package}"
                packager=packages/${distro}/ati-packager.sh
		#if the distro is ubuntu take backup of the genearted packages as if th epackage installation is successfull, deletes the generated package
		if [ "${distro}" = "Ubuntu" ]; then
			InstallerRootDir="`pwd`"              # Absolute path of the <installer root> directory
			AbsInstallerParentDir="`cd "${InstallerRootDir}"/.. 2>/dev/null && pwd`"    # Absolute path to the installer parent directory
			DRV_RELEASE=`./ati-packager-helper.sh --version`
			PADDED_DRV_RELEASE=`printf '%5.3f' "$DRV_RELEASE" 2>/dev/null`

			pacakge1="fglrx_${PADDED_DRV_RELEASE}-0ubuntu${REVISION}_${ARCH}.deb"
			echo "$pacakge1"
			pacakge2="fglrx-amdcccle_${PADDED_DRV_RELEASE}-0ubuntu${REVISION}_${ARCH}.deb"
			echo "$pacakge2"
			pacakge3="fglrx-dev_${PADDED_DRV_RELEASE}-0ubuntu${REVISION}_${ARCH}.deb"
			echo "$pacakge3"
			pacakge4="fglrx-core_${PADDED_DRV_RELEASE}-0ubuntu${REVISION}_${ARCH}.deb"
			echo "$pacakge4"
			
			if [ -f "${AbsInstallerParentDir}/$pacakge1" ]; then 
			   cp -av pacakge1 pacakge1.bak 2>/dev/null
			fi
			if [ -f "${AbsInstallerParentDir}/$pacakge2" ]; then 
			   cp -av pacakge2 pacakge2.bak 2>/dev/null
			fi
			if [ -f "${AbsInstallerParentDir}/$pacakge3" ]; then 
			   cp -av pacakge3 pacakge3.bak 2>/dev/null
			fi	
			if [ -f "${AbsInstallerParentDir}/$pacakge4" ]; then 
			   cp -av pacakge4 pacakge4.bak 2>/dev/null
			fi
		fi 

		#Install the generated package
                execInstallPkg ${packager} ${package}
		#if the ubuntu package installation is successfull, move the backup files to original
		if [ "${distro}" = "Ubuntu" ]; then
			mv pacakge1.bak pacakge1 2>/dev/null
			echo "$pacakge1"
			mv pacakge2.bak pacakge2 2>/dev/null
			echo "$pacakge2"
			mv pacakge3.bak pacakge3 2>/dev/null
			echo "$pacakge3"
			mv pacakge4.bak pacakge4 2>/dev/null
			echo "$pacakge4"
		fi
	    fi
	fi  
}

RunLoki()
{
    LOKI_USE=$1
    loki_installer_ncurses=0

    if [ -z "${LC_CTYPE}" -a -z "${LANG}" ]; then
        LANG=".UTF-8"
        export LANG
    fi

    if [ "${_ARCH}" = "x86_64" ]; then
        ARCH_DIR=x86_64
    else
        ARCH_DIR=x86
    fi

    
    if [ "${DISPLAY}" != "" ] 
    then
	if [ "$LOKI_USE" = "installation" ]; then
	    cp setup.data/install_gtk.xml setup.data/install.xml
	fi

	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:setup.data/bin/${ARCH_DIR}/glibc-2.1 ./setup.data/bin/${ARCH_DIR}/glibc-2.1/setup.gtk 2>/dev/null
	status=$?
	
	if [ $status -ne 0 -a $status -ne 1 -a $status -ne 3 ]; then
	# Workaround: try text-based setup if graphical mode failed,
	# exclude that end user aborts the graphical setup manually,
	    # return value for this is "3" for 64-bit OS, "1" for 32-bit OS 
	    loki_installer_ncurses=1
	else

	    #check if an error occurred 
	    if [ $status -ne 0 -a -f "${ATI_LOG}/fglrx-install.log" ]; then
	    
		error_line=`cat "${ATI_LOG}/fglrx-install.log" | grep "^\[Error\]"`
		if [ -n "$error_line" ]; then
		    #error occurred
		    status=1
		else
		    #user cancelled, reset error code
		    status=0
		fi
	    else
	       #ask reboot if installing from X and reboot required
	       #check if reboot required
	       if [ -f "${ATI_LOG}/fglrx-install.log" ]; then
		  reboot_line=`cat "${ATI_LOG}/fglrx-install.log" | grep "^\[Reboot\]"`
		  update_line=`cat "${ATI_LOG}/fglrx-install.log" | grep "update initramfs not required"`
		  ZENITY_BIN=`which zenity 2> /dev/null`
		  if [ -n "$reboot_line" -o "$update_line" ]; then
		     if [ `id -u` -eq 0 -a -n "${ZENITY_BIN}" -a -x "${ZENITY_BIN}" ]; then
			${ZENITY_BIN} --question --text "Actions taken by AMD  Proprietary Driver requires a reboot. Would you like to reboot now?  Other users may be logged on."
			ans=$?

			# cases for user to select
			case $ans in
			   0)
			      #set the reboot flag
			      reboot=1
			   ;;
			esac 
		     fi
		  else		
			#ask to install the generated distribution specific packge if the package is generated successfully			
			package_line=`cat "${ATI_LOG}/fglrx-install.log" | grep "successfully generated" | cut -f2 -d" " | rev | cut -d/ -f1 | rev`
			if [ -n "$package_line" ]; then	
			    packageinstall=0	
			    if [ `id -u` -eq 0 -a -n "${ZENITY_BIN}" -a -x "${ZENITY_BIN}" ]; then
				${ZENITY_BIN} --question --text "Do you want to install the generated package? Click Yes to install the package."
				ans=$?

				# cases for user to select
				case $ans in
				   0)
				      #set the install package flag
				      packageinstall=1
				   ;;
				esac
			    fi

			    if [ ${packageinstall} -eq 1 ]
			    then
				InstallDistPackage
			    fi 

			 fi
		      fi
		  fi			
	       fi
	    fi
    else
	# DISPLAY not set, try ncurses instead 
	loki_installer_ncurses=1
    fi

    if [ ${loki_installer_ncurses} -eq 1 ]
    then
        if [ "$LOKI_USE" = "installation" ]; then
            cp setup.data/install_txt.xml setup.data/install.xml
        fi

        ./setup.data/bin/${ARCH_DIR}/setup 2>/dev/null
        status=$?
        
        # note for console installer if Loki is being used for installation
        if [ $status -eq 0 -a "$LOKI_USE" = "installation" ]; then
            echo "For further configuration of the driver, please run aticonfig from a terminal window or AMD CCC:LE from the Desktop Manager Menu."

            #check if reboot required
            if [ -f "${ATI_LOG}/fglrx-install.log" ]; then            
                reboot_line=`cat "${ATI_LOG}/fglrx-install.log" | grep "^\[Reboot\]"`
                if [ -n "$reboot_line" ]; then
                    echo "System must be rebooted to avoid system instability and potential data loss."
		else
		   #ask to install the generated distribution specific packge if the package is generated successfully			
		   package_line=`cat "${ATI_LOG}/fglrx-install.log" | grep "successfully generated" | cut -f2 -d" " | rev | cut -d/ -f1 | rev`
		   if [ -n "$package_line" ]; then
		    while true;do
			read -p "Do you want us to install the package generated?[Yes/No]" yn
			case $yn in 
			[Yy]* ) InstallDistPackage; break;;
			[Nn]* ) exit ;;
			    * ) echo "Please enter yes or no." ;;
			esac
		    done
		   fi
                fi
            fi
        fi
        echo "See ${ATI_LOG}/fglrx-install.log for installation details."
    fi
    
    return $status
}

ExportVars()
{
    export X_VERSION
    export _ARCH
    export X_LAYOUT
    export ATI_XLIB_32
    export ATI_XLIB_64
    export ATI_3D_DRV_32
    export ATI_3D_DRV_64
    export ATI_XLIB
    export ATI_X_BIN
    export ATI_SBIN
    export ATI_KERN_MOD
    export ATI_2D_DRV
    export ATI_X_MODULE
    export ATI_DRM_LIB
    export ATI_CP_LNK
    export ATI_CP_KDE3_LNK
    export ATI_GL_INCLUDE
    export ATI_ATIGL_INCLUDE
    export ATI_CP_KDE_LNK
    export ATI_DOC
    export ATI_CP_DOC
    export ATI_CP_GNOME_LNK
    export ATI_ICON
    export ATI_MAN
    export ATI_SRC
    export ATI_X11_INCLUDE
    export ATI_CP_BIN
    export ATI_CP_I18N
    export ATI_LOG
    export ATI_CONFIG
    export OPENCL_CONFIG
    export OPENCL_LIB_32
    export OPENCL_LIB_64
    export OPENCL_BIN
    export ATI_SECURITY_CFG
    export ATI_UNINST
    export ATI_PX_SUPPORT
    export ATI_XLIB_EXT_32
    export ATI_XLIB_EXT_64    

}

CleanTmpInstPath()
{
    rm -f $TMP_INST_PATH_DEFAULT
    rm -f $TMP_INST_PATH_OVERRIDE
}

WriteNewInstPath()
{
    if [ "$WRITE_DEFAULT_POLICY" = "1" ]
    then
        FINAL_FILENAME="inst_path_default"
        OUT_FILE=$TMP_INST_PATH_DEFAULT
        POLICY_SCRIPT="./default_policy.sh"
        DISTRO_IN_INST_PATH="Default policy"
    else
        FINAL_FILENAME="inst_path_override"
        OUT_FILE=$TMP_INST_PATH_OVERRIDE
        POLICY_SCRIPT="packages/${CURRENT_DISTRO}/ati-packager.sh"
        DISTRO_IN_INST_PATH="Distribution:   ${CURRENT_DISTRO}"
    fi

    POLICY_FIRST_LINE=`${POLICY_SCRIPT} --printpolicy \
        "${CURRENT_DISTRO_VERSION}" | head -n 1`

    if [ "--printpolicy: unsupported option passed by ati-installer.sh" = "$POLICY_FIRST_LINE" ]
    then
        echo
        echo "Error: ${POLICY_SCRIPT} supports --iscurrentdistro but not"
        echo "--printpolicy; the script must support either both or none of"
        echo "these options; check if your distribution has an update for"
        echo "these drivers"
        echo

        CleanTmpInstPath

        exit 1
    elif [ "`echo $POLICY_FIRST_LINE | grep "error:" `" != ""  ]
    then
        
        echo 
        echo "$POLICY_FIRST_LINE (${CURRENT_DISTRO_VERSION})"
        echo "Installation will not proceed."
        echo

        CleanTmpInstPath
        exit 1
    fi

    TIMESTAMP=`date`

    cat - > $OUT_FILE << INST_PATH_HEADER_END
# /etc/ati/${FINAL_FILENAME}
#
# Created ${TIMESTAMP} with the following configuration:
#
# Driver version: ${DRV_RELEASE}
# ${DISTRO_IN_INST_PATH}
# Policy version: ${CURRENT_DISTRO_VERSION}

INST_PATH_HEADER_END
    
    ${POLICY_SCRIPT} --printpolicy ${CURRENT_DISTRO_VERSION} >> $OUT_FILE
}

GetDefaultPolicyVersion()
{
    GET_DEFAULT_POLICY=1
    MULTIPLE_MATCHES=0

    GetDistroPolicy

    RETURN_CODE=$?

    if [ 0 -eq $RETURN_CODE ]
    then
        return 0
    elif [ 64 -eq $RETURN_CODE ]
    then
        # 64 means distro supports --printversion but the current
        #  distro does not match

        echo
        echo "Error: The default policy script is unable to provide a policy"
        echo "for the current configuration; the default policy must be"
        echo "updated to support the current configuration before installation"
        echo "can continue"
        echo

        CleanTmpInstPath

        exit 1
    elif [ 65 -eq $RETURN_CODE ]
    then
        # 65 means distro does not support --printversion

        echo
        echo "Error: The default policy script does not support --printversion;"
        echo "the default policy script must support --printversion for the"
        echo "installation to continue"
        echo

        CleanTmpInstPath

        exit 1
    else
        echo
        echo "Unexpected error code returned by GetDistroPolicy for default"
        echo "policy query; error code returned was $RETURN_CODE"
        echo

        CleanTmpInstPath

        exit 1
    fi
}

#GetVersionForPolicy() ${1}=distro name
#This function takes a distribution name and calls --identify on that distro's ati-packager.sh
#it takes the results and echo's a response as expected by the rest of the policy interpretation code
GetVersionForPolicy()
{
    distro=${1}
    output=`packages/${distro}/ati-packager.sh --identify | tail -n 1`
    if [ "${output}" = "--identify: unsupported option passed by ati-installer.sh" ]
    then
        echo ${output}
    else
        for package in `packages/$distro/ati-packager.sh --get-supported`
        do
            packages/$distro/ati-packager.sh --identify ${package}            
            retval=$?
            if [ ${retval} -eq 0 ]
            then
                echo "distro query result: yes, version: ${package}"
                return 0
            fi
        done
        echo "distro query result: no"
    fi
}

#GetDistroPolicy()
#Decides whether to use a custom policy or the default
GetDistroPolicy()
{
    if [ -z "$GET_DEFAULT_POLICY" -o "1" != "$GET_DEFAULT_POLICY" ]
    then
        if [ "`grep '\-\-printpolicy' ./packages/$distro/ati-packager.sh`" != "" ]
        then
            SCRIPT_NAME="packages/$distro/ati-packager.sh"
            PARAM_NAME="--identify"
            output=`GetVersionForPolicy $distro`
        else
            output="--identify: unsupported option passed by ati-installer.sh"
        fi
    else
        SCRIPT_NAME="./default_policy.sh"
        PARAM_NAME="--printversion"
        output=`./default_policy.sh --printversion`
    fi

    header=`echo $output | cut -d\  -f1-3`
    result=`echo $output | cut -d\  -f4`

    # the current distro is $distro, according to $distro/ati-packager.sh
    if [ "distro query result:" = "$header" -a "yes," = "$result" ]
    then
        # $version is the X in "distro query result: yes, version: X"
        version=`echo $output | cut -d\  -f6-`
        if [ -z "$version" ]
        then
            echo
            echo "Error in packages/$distro/ati-packager.sh: empty version"
            echo "string found; positive match for distribution must be"
            echo "printed in the following form:"
            echo
            echo "distro query result: yes, version: X"
            echo
            echo "where X is a string with no spaces"
            echo

            CleanTmpInstPath

            exit 1
        fi

        if [ 0 -eq $MULTIPLE_MATCHES ]
        then
            if [ -z $CURRENT_DISTRO ]
            then
                CURRENT_DISTRO_VERSION=$version

                if [ -z "$GET_DEFAULT_POLICY" -o "1" != "$GET_DEFAULT_POLICY" ]
                then
                    CURRENT_DISTRO=$distro
                    NO_OVERRIDE_POLICY=0
                else
                    CURRENT_DISTRO=""
                    NO_OVERRIDE_POLICY=1
                fi

                return 0
            else
                MULTIPLE_MATCHES=1

                # backup existing setup.glade file
                mv setup.data/setup.glade setup.data/setup.glade.bak
                mv setup.data/pre-setup.glade setup.data/setup.glade

                # make source and destination directories for installation
                mkdir tmp
                MM_SRC=`mktemp -d tmp/mm_src.XXXXXX`
                MM_DST=`mktemp -d -t mm_dst.XXXXXX`

                # output the second last distro/version found to a file
                cat - > ${MM_SRC}/${CURRENT_DISTRO} << FILE_END
CURRENT_DISTRO=${CURRENT_DISTRO}
CURRENT_DISTRO_VERSION=${CURRENT_DISTRO_VERSION}
FILE_END

                # output the last distro/version found to a file
                cat - > ${MM_SRC}/${distro} << FILE_END
CURRENT_DISTRO=${distro}
CURRENT_DISTRO_VERSION=${version}
FILE_END

                # print header for Loki's XML file
                cat - > setup.data/setup.xml << SETUP_XML_END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<install
    desc="Distribution selection"
    version="${DRV_RELEASE}"
    splash="atilogo.xpm"
    path="${MM_DST}"
    nopromptoverwrite="yes"
    nouninstall="yes"
    superuser="yes">

  <exclusive>
    <option>
      ${CURRENT_DISTRO}, version: ${CURRENT_DISTRO_VERSION}
      <files path=".">${MM_SRC}/${CURRENT_DISTRO}</files>
    </option>
    <option>
      ${distro}, version: ${version}
      <files path=".">${MM_SRC}/${distro}</files>
    </option>
SETUP_XML_END

                # 66 means that multiple matches have been found
                return 66
            fi
        else
            # output the last distro/version found to a file
            cat - > ${MM_SRC}/${distro} << FILE_END
CURRENT_DISTRO=${distro}
CURRENT_DISTRO_VERSION=${version}
FILE_END

            # add the corresponding option to Loki setup
            cat - >> setup.data/setup.xml << SETUP_XML_END
    <option>
      ${distro}, version: ${version}
      <files path=".">${MM_SRC}/${distro}</files>
    </option>
SETUP_XML_END

            # 66 means that multiple matches have been found
            return 66
        fi
    elif [ "distro query result:" = "$header" -a "no" = "$result" ]
    then
        # 64 means distro supports --identify but the current distro
        #  does not match

        # the return value is discarded when GetDistroPolicy is called by
        #  DetectDistro, but it is used when GetDistroPolicy is called after
        #  a user defines CURRENT_DISTRO themselves to determine whether their
        #  selection is valid

        return 64
    elif [ "--identify: unsupported option passed by ati-installer.sh" = "$output" ]
    then
        # 65 means distro does not support --identify

        # the return value is discarded when GetDistroPolicy is called by
        #  DetectDistro, but it is used when GetDistroPolicy is called after
        #  a user defines CURRENT_DISTRO themselves to determine whether their
        #  selection is valid

        return 65
    else
        echo
        echo "Error in $SCRIPT_NAME: unexpected output"
        echo "received from script on $PARAM_NAME call; output must"
        echo "be of the following form:"
        echo
        echo "distro query result: no   OR"
        echo "distro query result: yes, version: X   OR"
        echo "$PARAM_NAME: unsupported option passed by ati-installer.sh"
        echo

        CleanTmpInstPath

        exit 1
    fi
}

# NOTE: if DetectDistro is used, its return value MUST be checked; if it is 64,
#  the handling will be much different than if it is 0
DetectDistro()
{
    GET_DEFAULT_POLICY=0
    NO_OVERRIDE_POLICY=1
    CURRENT_DISTRO=""
    MULTIPLE_MATCHES=0

    for dir in `find packages -mindepth 1 -maxdepth 1 -type d -print`
    do
        distro=`basename $dir`

        GetDistroPolicy
    done

    if [ 1 -eq $MULTIPLE_MATCHES ]
    then
        # print Loki XML footer (the rest of the file has been printed)
        cat - >> setup.data/setup.xml << SETUP_XML_END
  </exclusive>

</install>
SETUP_XML_END

        # run Loki to get the user's distribution selection
        RunLoki

        # there is now one file in MM_DST, the file that contains the
        #  CURRENT_DISTRO and CURRENT_DISTRO_VERSION that the user selected;
        #  we find it...
        SELECTION_FILE=`ls -1 ${MM_DST} | head -n 1`

        # ...and source it, but only if SELECTION_FILE is non-empty
        if [ -n "${SELECTION_FILE}" ]
        then
            . ${MM_DST}/${SELECTION_FILE}
        fi

        # remove Loki's XML file
        rm -f setup.data/setup.xml

        # remove the temporary source and destination folders
        rm -rf ${MM_SRC}
        rm -rf ${MM_DST}
        rmdir tmp

        # move the glade files back to their original locations
        mv setup.data/setup.glade setup.data/pre-setup.glade
        mv setup.data/setup.glade.bak setup.data/setup.glade

        # cleanup inst_path_override (will be re-created later)
        echo -n > ${TMP_INST_PATH_OVERRIDE}

        # if SELECTION_FILE is empty, user probably cancelled the Loki installer
        #  so we will silently exit
        if [ -z "${SELECTION_FILE}" ]
        then
            CleanTmpInstPath
            exit 0
        fi

        # return 64 to indicate that multiple matches were found
        return 64
    fi

    # we can make the following assertions at this point:
    # - if no matches were found, CURRENT_DISTRO="", NO_OVERRIDE_POLICY=1, and
    #   CURRENT_DISTRO_VERSION=Y for some non-null version Y
    # - if one match X was found with non-null version Y, CURRENT_DISTRO=X,
    #   NO_OVERRIDE_POLICY=0, and CURRENT_DISTRO_VERSION=Y
    # - if more than one match was found, the script has already quit
    # - if any matches were found with null version, the script has already quit
}



printHelp()
{
    #Commented arguments in this list are availible to distro package maintainers to implement but are not exposed to end users
    echo "This script supports the following arguments:"
    echo "--help                                        : print help messages"
    echo "--listpkg                                     : print out a list of generatable packages"
    echo "--buildpkg [package] [--dryrun]               : if generatable, the package will be created"
    echo "--buildpkg package --NoXServer                : if generatable, the package will be created without XServer"
    #echo "--installpkg <package> [--force]             : if already generated, the package will be installed"
    echo "--buildandinstallpkg [package] [--dryrun] [--force] : if generatable, the package will be creadted and installed"
    #echo "--getAPIVersion <distro>                      : returns the API version number of given distro"
    echo "--install                                     : install the driver"
}

#execIdentify
#cycles through all supported versions of all distros and returns a list of which think they are running currently
execIdentify()
{
    pkg_list=""
    for distro in `ls packages`
    do
        packager=packages/${distro}/ati-packager.sh
        if [ -e ${packager} ]
        then
            execGetAPIVersion ${packager}
            if [ $? -gt 1 ]
            then
                for package in `./${packager} --get-supported`
                do
                    ./${packager} --identify ${package}
                    if [ $? -eq 0 ]
                    then  
                        pkg_list="${pkg_list} ${distro}/${package}"
                    fi
                done
            fi
        fi
    done

    echo ${pkg_list}
    return 0
}

#checkDistroResult() ${1}=pkg_list
#takes a list of possible packages returns if there is exactly 1 package in the list or else ERROR
checkDistroResult()
{
    found=`echo ${1} | wc -w`
    if [ ${found} -eq 0 ]
    then 
        echo "Error: Packaging scripts failed to identify current distro/version.  Please provide a distro/version from --listpkg as a parameter"
        return ${ATI_INSTALLER_ERR_FIND_DIST}
    elif [ ${found} -eq 1 ]
    then
        return 0    
    else
        echo "Error: Unable to identify currently running distribution.  Please provide one of the following as a parameter: ${1}"
        return ${ATI_INSTALLER_ERR_FIND_MULTI}
    fi
}
#execGetAPIVersion  ${1}=packages/<distro>/ati-packager.sh
#returns the API version of ${1}
execGetAPIVersion()
{
    if [ -e ${1} ]
    then
        if [ "`grep getAPIVersion ./${1}`" != "" ]
        then 
            ./${1} --getAPIVersion
            return $?
        else
            return 1
        fi
    else
        return 1
    fi
}


#execGetMaintainer  ${1}=packages/<distro>/ati-packager.sh
#returns the maintainer of ${1}
execGetMaintainer()
{
   if [ -e ${1} ]; then
   
      if [ -n "`grep '\-\-get\-maintainer' ${1}`" ]; then
        
         newMaintainer=`./${packager} --get-maintainer 2> /dev/null`
         if [ $? -eq 0 -a -n "${newMaintainer}" ]; then
		      echo ${newMaintainer}
    		   return 0
         fi
      fi
	   
   fi

	return 1
}


#execVerifyVersion  ${1}=packages/<distro>/ati-packager.sh  ${2}=distro version
#verifies that ${1} is an existing file
#checks if the supplied ${2} is in the list of supported Distro version by file ${1} 
execVerifyVersion()
{
    if [ -e ${1} ]
    then
        for version in `./${1} --get-supported`
        do
            if [ "${2}" = ${version} ]
            then
                return 0
            fi
        done
        echo "Error: Distro Version entered incorrectly or not supported, use --listpkg to identify valid distro versions"
        return ${ATI_INSTALLER_ERR_VERS}
    else
        return ${ATI_INSTALLER_ERR_FILE}
    fi
}

#execBuildPrep  ${1}=packages/<distro>/ati-packager.sh  ${2}=distro version  ${3}="--dryrun" or ""
#uses the supplied ati-packager.sh to check requirements for building the package are met.
#verifies ${1} and ${2}; ${3} is verified by calling function
execBuildPrep()             
{
    if [ -e ${1} ]
    then
        execVerifyVersion ${1} ${2}
        if [ $? -eq 0 ]
        then
            ./${1} --buildprep ${2} ${3}
            return $?
        else
            return ${ATI_INSTALLER_ERR_VERS}
        fi
    else
        echo "Error: Cannot prep the build of the package - ${1} is missing"
        return ${ATI_INSTALLER_ERR_FILE}
    fi

}
#execBuildPkg  ${1}=packages/<distro>/ati-packager.sh  ${2}=distro version
#goes to packages/distro/ati-packager.sh to generate the requested package
#verifies both parameters
execBuildPkg()             
{

    if [ -e ${1} ]
    then
        execVerifyVersion ${1} ${2}
        if [ $? -eq 0 ]
        then
            ./${1} --buildpkg ${2}
            return $?
        else
            return ${ATI_INSTALLER_ERR_VERS}
        fi
    else
        echo "Error: Cannot build the package - ${1} is missing"
        return ${ATI_INSTALLER_ERR_FILE}
    fi    
}

#execInstallPrep ${1}=packages/<distro>/ati-packager.sh  ${2}=distro version  ${3}="--dryrun" or ""
#uses the supplied ati-packager.sh to requirements for driver operation are met.
#verifies ${1} and ${2}; ${3} is verified by execBuildAndInstall
execInstallPrep()
{
    if [ -e ${1} ]
    then
        execVerifyVersion ${1} ${2}
        if [ $? -eq 0 ]
        then
            ./${1} --installprep ${2} ${3}
            return $?
        else
            return ${ATI_INSTALLER_ERR_VERS}
        fi
    else
        echo "Error: Cannot prep the installation of the package - ${1} is missing"
        return ${ATI_INSTALLER_ERR_FILE}
    fi
}

#execInstallPkg ${1}=packages/<distro>/ati-packager.sh  ${2}=distro version
#uses the supplied ati-packager.sh to install the available package
#verifies both ${1} and ${2}
execInstallPkg()            
{
    if [ -e ${1} ]
    then
        execVerifyVersion ${1} ${2}
        if [ $? -eq 0 ]
        then
            ./${1} --installpkg ${2}
            return $?
        else
            return ${ATI_INSTALLER_ERR_VERS}
        fi
    else
        echo "Error: Cannot install the package - ${1} is missing"
        return ${ATI_INSTALLER_ERR_FILE}
    fi
}

#execBuildAndInstall ${1}=packages/<distro>/ati-packager.sh  ${2}=distro version ${3}=--dryrun
#If buildandinstall option --dryrun is provided it is error checked here. 
execBuildAndInstall()
{
    if [ "${3}" = "" ] || [ "${3}" = "--dryrun" ]
    then
        execBuildPrep ${1} ${2} ${3}
        buildPrepResult=$?
        if [ ${buildPrepResult} -ne 0 ]
        then
            return ${buildPrepResult}
        fi

        if [ "${3}" = "" ]
        then
            execBuildPkg ${1} ${2}
            buildPkgResult=$?
            if [ ${buildPkgResult} -ne 0 ]
            then
                return ${buildPkgResult}
            fi
        fi

        execInstallPrep ${1} ${2} ${3}
        instPrepResult=$?
        if [ ${instPrepResult} -ne 0 ]
        then
            return ${instPrepResult}
        fi

        if [ "${3}" = "" ]
        then
            execInstallPkg ${1} ${2}
            instPkgResult=$?
            if [ ${instPkgResult} -ne 0 ]
            then
                return ${instPkgResult}
            fi
        fi

        return 0
    else
        echo "Error: Unrecognized build option parameter ${3}"
        printHelp
        return ${ATI_INSTALLER_ERR_BUILDOP}
    fi
}

# Script execution starts here

alias echo=/bin/echo

# ensure the working directory is where the script resides
scriptdir=`dirname "$0"`
curdir=`pwd`
if [ -n "$scriptdir" -a "$scriptdir" != "$curdir" ]; then
    cd "$scriptdir"
fi

echo -e "====================================================================="
echo -e "\033[31m AMD  Proprietary Driver Installer/Packager \033[0m"
echo -e "====================================================================="

#Detect headless configuration
GetHeadLessConfig() {

        devid=`lspci -vmnn -d 1002:* | awk 'BEGIN { FS="\n";RS=""} {if(($2 ~ /VGA/) || ($2 ~ /Display/) && $3 ~ /AMD/) print $4}' | sed 's/.*\[\([^]]*\)\].*/\1/g' | sort | uniq`
        isDevFound=""
        retval=0
        for did in $devid
        do
                isdevidfound=`cat headlessDID.config | egrep -i "^$did" | cut -f2 -d':'`
                if [ -n "$isdevidfound" ]
                then
                        isDevFound=`lspci -vmnn -d 1002:$did | awk 'BEGIN { FS="\n";RS=""} {if(($2 ~ /VGA/) || ($2 ~ /Display/) && $3 ~ /AMD/) print $6}' | sed 's/.*\[\([^]]*\)\].*/\1/g' | sort | uniq`
                        for sdid in $isDevFound
                        do
                                if [ -n "$isDevFound" ] && [ "`echo "$isdevidfound" | egrep -i "^$sdid$"`" ]
                                then
                                        retval=1
                                        break
                                fi
                        done
                fi
        done
        #echo "$retval"
        return "$retval"
}

# Create installer symlinks

# Custom package directory
if [ -z ${ATI_CUSTOM_PKG_DIR} ]; then
    ATI_CUSTOM_PKG_DIR=/etc/ati/custom-package
fi
if [ -d ${ATI_CUSTOM_PKG_DIR} ]; then
    if [ -x "${ATI_CUSTOM_PKG_DIR}/ati-packager.sh" ]; then

        # this used to be "ln -s ${ATI_CUSTOM_PKG_DIR} packages/custom-package";
        #  it has been changed because symlinks don't behave precisely the same
        #  way as regular directories, which means that copying an arbitrary
        #  packages/X folder to ${ATI_CUSTOMER_PKG_DIR} and running the
        #  installer using the symlink method might not work; for example,
        #  "ls -l packages/custom-package/.." should be equivalent to
        #  "ls -l packages", but if the above symlink method is used, it is
        #  actually equivalent to "ls -l ${ATI_CUSTOM_PKG_DIR}/.."

        mkdir packages/custom-package
        cp -rp ${ATI_CUSTOM_PKG_DIR}/* packages/custom-package
    else
        echo "Warning: ${ATI_CUSTOM_PKG_DIR}/ati-packager.sh is missing or not a script."
    fi
fi

declare tester_var=7 2>/dev/null                      #testing if declare is available

if [ $? -eq 0 ]
then
    #set error code variables
    declare -r -i ATI_INSTALLER_ERR_PREP=1            #Error: Could not complete prep for build
    declare -r -i ATI_INSTALLER_ERR_FILE=2            #Error: Cannot build the package - ${<path>/ati-packager.sh} is missing
    declare -r -i ATI_INSTALLER_ERR_DIST=3            #Error: The distribution ${distro} is not supported
    declare -r -i ATI_INSTALLER_ERR_FIND_DIST=4       #Error: Packaging scripts failed to identify current distro/version.  Please provide a distro/version from --listpkg as a parameter
    declare -r -i ATI_INSTALLER_ERR_FIND_MULTI=5      #Error: Unable to identify currently running kernel.  Please provide one of the following as a parameter: ${pkg_list}
    declare -r -i ATI_INSTALLER_ERR_VERS=6            #Error: Distro Version entered incorrectly or not supported, use --listpkg to identify valid distro versions
    declare -r -i ATI_INSTALLER_ERR_BUILDOP=7         #Error: Unrecognized build option parameter
    declare -r -i ATI_INSTALLER_ERR_API=8             #Error: Build Option ${1} not supported currently by packager
    declare -r -i ATI_INSTALLER_ERR_PREV_INSTALL=9    #Error: Previous installation detected and must be uninstalled first
    declare -r -i ATI_INSTALLER_ERR_SUPERUSER=10      #Error: User is missing superuser privileges 

else
    ATI_INSTALLER_ERR_PREP=1                          #declare unavailable so cant produce static error variables.
    ATI_INSTALLER_ERR_FILE=2
    ATI_INSTALLER_ERR_DIST=3
    ATI_INSTALLER_ERR_FIND_DIST=4
    ATI_INSTALLER_ERR_FIND_MULTI=5
    ATI_INSTALLER_ERR_VERS=6
    ATI_INSTALLER_ERR_BUILDOP=7
    ATI_INSTALLER_ERR_API=8
    ATI_INSTALLER_ERR_PREV_INSTALL=9
    ATI_INSTALLER_ERR_SUPERUSER=10
fi
    export ATI_INSTALLER_ERR_PREP
    export ATI_INSTALLER_ERR_FILE
    export ATI_INSTALLER_ERR_DIST
    export ATI_INSTALLER_ERR_FIND_DIST
    export ATI_INSTALLER_ERR_FIND_MULTI
    export ATI_INSTALLER_ERR_VERS
    export ATI_INSTALLER_ERR_BUILDOP
    export ATI_INSTALLER_ERR_API
    export ATI_INSTALLER_ERR_PREV_INSTALL
    export ATI_INSTALLER_ERR_SUPERUSER

DRV_RELEASE=$1
ACTION=$2

# Process input command
reboot=0
status=0
case "${ACTION}" in

--install)
    SIGNATURE=$3
    if [ "`echo $@ | grep '\-\-force'`" != "" ]; then   
        FORCE_ATI_UNINSTALL=y
        export FORCE_ATI_UNINSTALL
    fi

    if [ ! -z "${X_VERSION}" ]
    then
        export X_VERSION
        USER_SPECIFIED_X_VERSION=1
        SAVED_X_VERSION=${X_VERSION}
    fi

    if [ -z "$KERNEL_PATH" ]; then
        kernel_release=`uname -r`
        kernel_release_major=${kernel_release%%.*}
        kernel_release_rest=${kernel_release#*.}
        kernel_release_minor=${kernel_release_rest%%-*}
        kernel_release_minor=${kernel_release_minor%%.*}
        
        if [ "$kernel_release_major" -lt 2 -o \
            \( "$kernel_release_major" -eq 2 -a "$kernel_release_minor" -lt 6 \) ];
            then
            echo "Your kernel version $kernel_release is not supported by this driver release."
            echo "Only 2.6.0 and newer kernels are supported."
            echo "If you want to install for a different kernel than the one currently running,"
            echo "please use the KERNEL_PATH environment variable to override, e.g.:"
            echo "export KERNEL_PATH=/lib/modules/2.6.22/build"

            CleanTmpInstPath
            exit 1
        fi
    fi

    TMP_INST_PATH_DEFAULT=`mktemp -t inst_path_default.XXXXXX`
    TMP_INST_PATH_OVERRIDE=`mktemp -t inst_path_override.XXXXXX`
    export TMP_INST_PATH_DEFAULT
    export TMP_INST_PATH_OVERRIDE


    if [ -n "${INST_PATH_DEFAULT_FILE}" -o -n "${INST_PATH_OVERRIDE_FILE}" ]
    then
        if ! [ -n "${INST_PATH_DEFAULT_FILE}" -a \
            -n "${INST_PATH_OVERRIDE_FILE}" ]
        then
            echo
            echo "When the variable INST_PATH_DEFAULT_FILE or"
            echo "INST_PATH_OVERRIDE_FILE is set, both variables must be set;"
            echo "since only one of these was set, installation cannot continue"
            echo

            CleanTmpInstPath

            exit 1
        fi

        cp -p ${INST_PATH_DEFAULT_FILE} ${TMP_INST_PATH_DEFAULT}
        RETVAL_DEFAULT=$?
        cp -p ${INST_PATH_OVERRIDE_FILE} ${TMP_INST_PATH_OVERRIDE}
        RETVAL_OVERRIDE=$?

        if [ ${RETVAL_DEFAULT} -ne 0 -o ${RETVAL_OVERRIDE} -ne 0 ]
        then
            echo
            echo "Copying INST_PATH_DEFAULT_FILE or INST_PATH_OVERRIDE_FILE"
            echo "was unsuccessful; check the permissions on the files to"
            echo "ensure root can read them and then restart the installer"
            echo

            CleanTmpInstPath

            exit 1
        fi

        . $TMP_INST_PATH_DEFAULT
        . $TMP_INST_PATH_OVERRIDE
        ExportVars

        echo "NOTE: Using INST_PATH_DEFAULT_FILE and INST_PATH_OVERRIDE_FILE"

    # file overrides not set so we determine which distribution we're running on
    elif [ "$USE_DEFAULT_POLICY" = "1" ]
    then
        if [ ! -z "$CURRENT_DISTRO" ]
        then
            echo
            echo "Error: You can't use the default policy and use a specific"
            echo "distribution's policy at the same time; unset CURRENT_DISTRO"
            echo "or USE_DEFAULT_POLICY and run the installer again"
            echo

            CleanTmpInstPath

            exit 1
        fi

        # print warning message about not using override to inst_path_override
        TIMESTAMP=`date`
        cat - > $TMP_INST_PATH_OVERRIDE << INST_PATH_HEADER_END
# /etc/ati/inst_path_override
#
# Created ${TIMESTAMP} with the following configuration:
#
# Driver version: ${DRV_RELEASE}
# No override policy used because USE_DEFAULT_POLICY was set to 1

INST_PATH_HEADER_END

        # if the user has not set CURRENT_DISTRO_VERSION, then we set it; if
        #  the user has set CURRENT_DISTRO_VERSION, then presumably they know
        #  what they're doing (since they also set USE_DEFAULT_POLICY if they
        #  reach this point in the code) so no validation is done; validation
        #  can wait until WriteNewInstPath below, which preforms validation

        if [ -z $CURRENT_DISTRO_VERSION ]
        then
            # get version of default policy to use
            GetDefaultPolicyVersion

            # assert: CURRENT_DISTRO_VERSION is set; the above exits on error
        fi

        # print default policy to file; source policy
        WRITE_DEFAULT_POLICY="1"
        WriteNewInstPath
        . $TMP_INST_PATH_DEFAULT
        ExportVars

    elif [ -z $CURRENT_DISTRO ]
    then
        # get version of default policy to use
        GetDefaultPolicyVersion

        # assert: CURRENT_DISTRO_VERSION is now set; the above exits on error

        # print default policy to file; source policy
        WRITE_DEFAULT_POLICY="1"
        WriteNewInstPath
        . $TMP_INST_PATH_DEFAULT
        ExportVars

	#create log here
	if [ `id -u` -eq 0 ]; then
	    CreateInstallLog
	fi

	# run the pre-requisite script for LOKI UI support[checks only language support]
	sh ./sw_preq_check.sh 2>/dev/null
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
	   exit 0
	fi

        # detect the current distro and set CURRENT_DISTRO accordingly
        DetectDistro

        DD_RETVAL=$?

        if [ "${DD_RETVAL}" = "64" ]
        then
            # multiple matches found, process as if CURRENT_DISTRO and
            #  CURRENT_DISTRO_VERSION were set
            Setup_with_CD_and_CDV_set

            # add warning to inst_path_override
            cat - >> $TMP_INST_PATH_OVERRIDE << INST_PATH_END

# Warning: multiple matches found by detection scripts; distro is user-selected

INST_PATH_END
        else
            # no multiple matches found, continue as usual
            if [ "$NO_OVERRIDE_POLICY" = "1" ]
            then
                # print warning message about not using override
                cat - > $TMP_INST_PATH_OVERRIDE << INST_PATH_HEADER_END
# /etc/ati/inst_path_override
#
# Created ${TIMESTAMP} with the following configuration:
#
# Driver version: ${DRV_RELEASE}
# No override policy used because no distributions matched the current distro

INST_PATH_HEADER_END
            else
                WRITE_DEFAULT_POLICY="0"
                WriteNewInstPath
                . $TMP_INST_PATH_OVERRIDE
                ExportVars
            fi
        fi
    else # USE_DEFAULT_POLICY != 1 and user specified CURRENT_DISTRO
        # setup default policy

        # save existing CURRENT_VERSION and CURRENT_DISTRO_VERSION values
        SAVED_CURRENT_DISTRO=${CURRENT_DISTRO}
        SAVED_CURRENT_DISTRO_VERSION=${CURRENT_DISTRO_VERSION}

        # unset variables so that user-defined variables are not used
        CURRENT_DISTRO=
        CURRENT_DISTRO_VERSION=

        # get version of default policy to use
        GetDefaultPolicyVersion

        # assert: CURRENT_DISTRO_VERSION is now set; the above exits on error

        # print default policy to file; source policy
        WRITE_DEFAULT_POLICY="1"
        WriteNewInstPath
        . $TMP_INST_PATH_DEFAULT
        ExportVars

        # restore CURRENT_VERSION and CURRENT_DISTRO_VERSION values
        CURRENT_DISTRO=${SAVED_CURRENT_DISTRO}
        CURRENT_DISTRO_VERSION=${SAVED_CURRENT_DISTRO_VERSION}


        if [ ! -d packages/$CURRENT_DISTRO ]
        then
            echo
            echo "Error: The distribution specified in the CURRENT_DISTRO"
            echo "environment variable does not match any of the distributions"
            echo "recognized by this installer.  The recognized distributions"
            echo "are the following:"
            echo

            for dir in `find packages -mindepth 1 -maxdepth 1 -type d -print`
            do
                distro=`basename $dir`
                echo "    $distro"
            done

            echo

            CleanTmpInstPath

            exit 1
        elif [ -z $CURRENT_DISTRO_VERSION ]
        then
            # user specified CURRENT_DISTRO, but not CURRENT_DISTRO_VERSION so
            #  we'll try to get a CURRENT_DISTRO_VERSION from the CURRENT_DISTRO
            #  that they specified

            distro=$CURRENT_DISTRO

            GET_DEFAULT_POLICY="0"
            NO_OVERRIDE_POLICY=1
            CURRENT_DISTRO=""
            MULTIPLE_MATCHES=0

            GetDistroPolicy

            RETURN_CODE=$?

            # restore old CURRENT_DISTRO value
            CURRENT_DISTRO=${distro}

            if [ 0 -eq $RETURN_CODE ]
            then
                # no error; do nothing and fall through to the rest of the
                #  installation

                true    # do nothing, successfully
            elif [ 64 -eq $RETURN_CODE ]
            then
                # 64 means distro supports --iscurrentdistro but the current
                # distro does not match

                echo
                echo "Error: The distribution specified in CURRENT_DISTRO"
                echo "${distro} is not the current distribution according"
                echo "to packages/$distro/ati-packager.sh --identify"
                echo

                CleanTmpInstPath

                exit 1
            elif [ 65 -eq $RETURN_CODE ]
            then
                # 65 means distro does not provide a policy

                echo
                echo "Error: The distribution specified in CURRENT_DISTRO"
                echo "${distro} does not provide a policy to use for"
                echo "installation; try running the installer again with"
                echo "CURRENT_DISTRO unset"
                echo

                CleanTmpInstPath

                exit 1
            else
                echo
                echo "Unexpected error code returned by GetDistroPolicy;"
                echo "error code returned was $RETURN_CODE"
                echo

                CleanTmpInstPath

                exit 1
            fi

            WRITE_DEFAULT_POLICY="0"
            WriteNewInstPath
            . $TMP_INST_PATH_OVERRIDE
            ExportVars

            # add note to inst_path_override
            cat - >> $TMP_INST_PATH_OVERRIDE << INST_PATH_END

# Note: user specified CURRENT_DISTRO on the command line so the installer used
#  its value instead of detecting it; CURRENT_DISTRO_VERSION was detected

INST_PATH_END

        else
            # user specified both CURRENT_DISTRO and CURRENT_DISTRO_VERSION;
            #  we will assume the user knows what they're doing and not bother
            #  validating whether the CURRENT_DISTRO_VERSION actually matches
            #  one that would be returned by --iscurrentdistro; if it doesn't,
            #  it will be caught later on anyway

            # note: one could specify a CURRENT_DISTRO_VERSION that is never
            #  returned by --iscurrentdistro but is handled by --getpolicy to
            #  provide hidden functionality

            Setup_with_CD_and_CDV_set

            # add note to inst_path_override
            cat - >> $TMP_INST_PATH_OVERRIDE << INST_PATH_END

# Note: user specified both CURRENT_DISTRO and CURRENT_DISTRO_VERSION on the
#  command line so the installer used both values instead of detecting them

INST_PATH_END
        fi
    fi

    # The uninstall script "fglrx-uninstall.sh" will be saved to ${SETUP_INSTALLPATH}${ATI_UNINST}
    # by copy_uninstall_file.sh during the install process 


    if [ "$USER_SPECIFIED_X_VERSION" = "1" ]; then
        X_VERSION=${SAVED_X_VERSION}

        # get check.sh to print human-readable X_VERSION/_ARCH, with hint that
        #  X_VERSION has was overridden so it prints it as such
        checksh --nodetect --override

        cat - >> $TMP_INST_PATH_OVERRIDE << INST_PATH_FOOTER_END
# user overrode X_VERSION to the following:
X_VERSION=${X_VERSION}

INST_PATH_FOOTER_END
        
    else
        # get check.sh to print human-readable X_VERSION/_ARCH given policy
        checksh --nodetect
    fi


    if [ -z "${X_VERSION}" ]
    then
        echo
        echo "X_VERSION variable was not set by the default policy or by"
        echo "the override policy; perhaps the version of X being used is not"
        echo "a well-known one; the X_VERSION variable must be set in the"
        echo "override policy if you wish to continue; see README.distro for"
        echo "details"
        echo

        CleanTmpInstPath

        exit 1
    else
        case "${_ARCH}" in
        i?86 | x86_64) 
            if [ ${_ARCH} = "x86_64" ]; then
                ArchDir=x86_64
                XLibDir=lib64
            else
                ArchDir=x86
                XLibDir=lib
            fi

            # Verify the directory for the detected X is included with the installer
            if [ -d ${X_VERSION} -o -L ${X_VERSION} ]; then

                TmpDrvFilesDir=install
                rm -rf ${TmpDrvFilesDir}
                mkdir -p ${TmpDrvFilesDir}

                ### Begin creating directories for the files to go in ###
                ATI_VAR_LIST="${ATI_XLIB_32} ${ATI_XLIB_64} ${ATI_3D_DRV_32} ${ATI_3D_DRV_64} ${ATI_X_BIN} ${ATI_SBIN} ${ATI_KERN_MOD} ${ATI_2D_DRV} ${ATI_X_MODULE} ${ATI_DRM_LIB} ${ATI_CP_KDE3_LNK} ${ATI_GL_INCLUDE} ${ATI_ATIGL_INCLUDE} ${ATI_CP_LNK} ${ATI_CP_KDE_LNK} ${ATI_DOC} ${ATI_CP_DOC} ${ATI_CP_GNOME_LNK} ${ATI_ICON} ${ATI_MAN} ${ATI_SRC} ${ATI_X11_INCLUDE} ${ATI_CP_BIN} ${ATI_CP_I18N} ${ATI_LIB} ${ATI_SECURITY_CFG} ${ATI_XLIB_EXT_32} ${ATI_XLIB_EXT_64} ${ATI_PX_SUPPORT} ${OPENCL_CONFIG} ${OPENCL_LIB_32} ${OPENCL_LIB_64} ${OPENCL_BIN}"

                #the vars that are to be used for dirs out of the installer dir

                for ATI_VAR in ${ATI_VAR_LIST}; do
                    mkdir -p ${TmpDrvFilesDir}/${ATI_VAR}
                done

		          #installing to libglx a subdirectory
		          mkdir -p ${TmpDrvFilesDir}/${ATI_XLIB_32}/fglrx
		          mkdir -p ${TmpDrvFilesDir}/${ATI_XLIB_64}/fglrx

                #directory exceptions go here
                mkdir -p ${TmpDrvFilesDir}/${ATI_KERN_MOD}/build_mod

                # we also copy files to /etc/ati (although not in variable list)
                mkdir -p ${TmpDrvFilesDir}/etc/ati

                ### Done creating directories ###
		GetHeadLessConfig
		is_headless=$?

		if [ "$is_headless" = "1" ]
		then
		        NoAMDXorg=y
		        export NoAMDXorg
			#echo "exporting value $NoAMDXorg"
		fi
		#NoAMDXorg suppory flag-Dell Server Issue
		#Take back up of original libGL*
		if [ "$NoAMDXorg" = "y" ] && ! [ "`cat /etc/*-release | grep "Ubuntu"`" ]; then 
			#echo "taking backup of libGL libraries..."
			mkdir /usr/lib/NoAMDXorgBak 2>> /dev/null
			mkdir /usr/lib64/NoAMDXorgBak 2>> /dev/null
			cp /usr/lib/libGL.so.1.2.0 /usr/lib/NoAMDXorgBak 2>> /dev/null
			cp /usr/lib64/libGL.so.1.2.0 /usr/lib64/NoAMDXorgBak 2>> /dev/null	
		fi				

                ### Begin copying files to specified paths in config ###

                # arch
                if [ ${ArchDir} = "x86_64" ]; then
                    
                    cp -R arch/${ArchDir}/usr/X11R6/lib64/libfglrx*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}
                    cp -R arch/${ArchDir}/usr/X11R6/lib64/fglrx/fglrx-libGL*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}/fglrx
                    cp -R arch/${ArchDir}/usr/X11R6/lib64/libatiadl*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}
                    cp -R arch/${ArchDir}/usr/lib64/libatiuki*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}
                    cp -R arch/${ArchDir}/usr/lib64/libatical*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}
                    cp -R arch/${ArchDir}/usr/X11R6/lib64/libAMDXvBA*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}
                    cp -R arch/${ArchDir}/usr/X11R6/lib64/libXvBAW*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_64}
                    cp -R arch/${ArchDir}/usr/X11R6/lib64/modules/dri/*.* \
                          ${TmpDrvFilesDir}/${ATI_3D_DRV_64}
                    cp -R arch/${ArchDir}/usr/lib64/fglrx/switchlib* \
                          ${TmpDrvFilesDir}/${ATI_PX_SUPPORT}
                      
                    cp -R arch/${ArchDir}/usr/share/ati/lib64/libQt*.* \
                          ${TmpDrvFilesDir}/${ATI_LIB}

                    ## OpenCL sdk files
                    cp -R arch/${ArchDir}/usr/lib64/libamdocl*.* \
                          ${TmpDrvFilesDir}/${OPENCL_LIB_64}
                    cp -R arch/${ArchDir}/usr/lib64/libOpenCL*.* \
                          ${TmpDrvFilesDir}/${OPENCL_LIB_64}
                    cp -R arch/${ArchDir}/etc/OpenCL/vendors/* \
                          ${TmpDrvFilesDir}/${OPENCL_CONFIG}
                      
                    ### Copy 32-bit libraries even if using a 64-bit system 
                    
                    cp -R arch/x86/usr/X11R6/lib/libfglrx*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/x86/usr/X11R6/lib/fglrx/fglrx-libGL*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}/fglrx
                    cp -R arch/x86/usr/X11R6/lib/libatiadl*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/x86/usr/lib/libatiuki*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/x86/usr/lib/libatical*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}                              
                    cp -R arch/x86/usr/X11R6/lib/libAMDXvBA*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/x86/usr/X11R6/lib/libXvBAW*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/x86/usr/X11R6/lib/modules/dri/*.* \
                          ${TmpDrvFilesDir}/${ATI_3D_DRV_32}
                    cp -R arch/x86/usr/lib/libamdocl*.* \
                          ${TmpDrvFilesDir}/${OPENCL_LIB_32}
                    cp -R arch/x86/usr/lib/libOpenCL*.* \
                          ${TmpDrvFilesDir}/${OPENCL_LIB_32}
                    cp -R arch/x86/etc/OpenCL/vendors/* \
                          ${TmpDrvFilesDir}/${OPENCL_CONFIG}
                          
                else

                    cp -R arch/${ArchDir}/usr/X11R6/lib/libfglrx*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/${ArchDir}/usr/X11R6/lib/fglrx/fglrx-libGL*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}/fglrx
                    cp -R arch/${ArchDir}/usr/X11R6/lib/libatiadl*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/${ArchDir}/usr/lib/libatiuki*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/${ArchDir}/usr/lib/libatical*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/${ArchDir}/usr/X11R6/lib/libAMDXvBA*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/${ArchDir}/usr/X11R6/lib/libXvBAW*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_32}
                    cp -R arch/${ArchDir}/usr/X11R6/lib/modules/dri/*.* \
                          ${TmpDrvFilesDir}/${ATI_3D_DRV_32}
                    cp -R arch/${ArchDir}/usr/lib/fglrx/switchlib* \
                          ${TmpDrvFilesDir}/${ATI_PX_SUPPORT}

                    cp -R arch/${ArchDir}/usr/share/ati/lib/libQt*.* \
                          ${TmpDrvFilesDir}/${ATI_LIB}

                    ## OpenCL sdk files
                    cp -R arch/${ArchDir}/usr/lib/libamdocl*.* \
                          ${TmpDrvFilesDir}/${OPENCL_LIB_32}
                    cp -R arch/${ArchDir}/usr/lib/libOpenCL*.* \
                          ${TmpDrvFilesDir}/${OPENCL_LIB_32}
                    cp -R arch/${ArchDir}/etc/OpenCL/vendors/* \
                          ${TmpDrvFilesDir}/${OPENCL_CONFIG}
                fi
                cp -R arch/${ArchDir}/usr/bin/clinfo \
                      ${TmpDrvFilesDir}/${OPENCL_BIN}               
                cp -R arch/${ArchDir}/usr/X11R6/bin/* \
                      ${TmpDrvFilesDir}/${ATI_X_BIN}
	        if [ -n "$NoAMDXorg" ]; then
	           rm -rf ${TmpDrvFilesDir}/${ATI_X_BIN}/amdcccle			
	        fi
                cp -R common/usr/sbin/* \
                      ${TmpDrvFilesDir}/${ATI_SBIN}
                cp -R arch/${ArchDir}/usr/sbin/* \
                      ${TmpDrvFilesDir}/${ATI_SBIN}
                cp -R arch/${ArchDir}/lib/modules/fglrx/build_mod/*.* \
                      ${TmpDrvFilesDir}/${ATI_KERN_MOD}/build_mod

                # x version
                if [ ${ArchDir} = "x86_64" ]; then		
                    mkdir ${TmpDrvFilesDir}/${ATI_XLIB_EXT_64}/fglrx
                    cp -R ${X_VERSION}/usr/X11R6/${XLibDir}/modules/extensions/fglrx/*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_EXT_64}/fglrx/
                else
                    mkdir ${TmpDrvFilesDir}/${ATI_XLIB_EXT_32}/fglrx
                    cp -R ${X_VERSION}/usr/X11R6/${XLibDir}/modules/extensions/fglrx/*.* \
                          ${TmpDrvFilesDir}/${ATI_XLIB_EXT_32}/fglrx/
                fi
                cp -R ${X_VERSION}/usr/X11R6/${XLibDir}/modules/drivers/*.* \
                      ${TmpDrvFilesDir}/${ATI_2D_DRV}
                cp -R ${X_VERSION}/usr/X11R6/${XLibDir}/modules/glesx* \
                      ${TmpDrvFilesDir}/${ATI_X_MODULE}
                cp -R ${X_VERSION}/usr/X11R6/${XLibDir}/modules/amdxmm* \
                      ${TmpDrvFilesDir}/${ATI_X_MODULE}
                cp -R ${X_VERSION}/usr/X11R6/${XLibDir}/modules/linux/*.* \
                      ${TmpDrvFilesDir}/${ATI_DRM_LIB}
                
                # common
                cp -R common/etc/ati/* \
                      ${TmpDrvFilesDir}/etc/ati
                cp -R common/lib/modules/fglrx/* \
                      ${TmpDrvFilesDir}/${ATI_KERN_MOD}
                cp -p common/etc/security/console.apps/amdcccle-su \
                      ${TmpDrvFilesDir}/${ATI_SECURITY_CFG}
                
                # common/usr
                cp -R common/usr/include/GL/*.* \
                      ${TmpDrvFilesDir}/${ATI_GL_INCLUDE}             
                cp -R common/usr/include/ATI/GL/*.* \
                      ${TmpDrvFilesDir}/${ATI_ATIGL_INCLUDE}
	        if [ -z "$NoAMDXorg" ]; then
                   cp -R common/usr/share/applications/*.desktop \
       	              ${TmpDrvFilesDir}/${ATI_CP_LNK}
	        fi
                cp -R common/usr/share/ati/amdcccle/*.qm \
                      ${TmpDrvFilesDir}/${ATI_CP_I18N}
                cp -R common/usr/share/doc/fglrx/* \
                      ${TmpDrvFilesDir}/${ATI_DOC}
	        if [ -z "$NoAMDXorg" ]; then
                   cp -R common/usr/share/icons/*.* \
        	      ${TmpDrvFilesDir}/${ATI_ICON}
	        fi
                cp -R common/usr/share/man/* \
                      ${TmpDrvFilesDir}/${ATI_MAN}
                cp -R common/usr/src/ati/*.* \
                      ${TmpDrvFilesDir}/${ATI_SRC}
                cp -R common/usr/X11R6/bin/* \
                      ${TmpDrvFilesDir}/${ATI_CP_BIN}
                cp -R common/usr/share/doc/amdcccle/* \
                      ${TmpDrvFilesDir}/${ATI_CP_DOC}

                ### Done copying ###


                ### blacklisting - required for disabling radeon on systems with KMS ###                
                mkdir -p ${TmpDrvFilesDir}/etc/modprobe.d
                blacklistfile="${TmpDrvFilesDir}/etc/modprobe.d/blacklist-fglrx.conf"
                echo "# Advanced Micro Devices, Inc."> ${blacklistfile}
                echo "# radeon conflicts with AMD Linux Graphics Driver" >> ${blacklistfile}
                echo "blacklist radeon" >> ${blacklistfile}
				echo "blacklist amdgpu" >> ${blacklistfile}

                ### amdconfig to symlink to aticonfig ###                
                ln -s ${ATI_X_BIN}/aticonfig ${TmpDrvFilesDir}/${ATI_X_BIN}/amdconfig

		#amdcccle security file only for Ubuntu
		if [ "`cat /etc/*-release | grep "Ubuntu" `" ]; then 
 			   mkdir -p ${TmpDrvFilesDir}/usr/share/polkit-1/actions
			   cp -R com.ubuntu.amdcccle.pkexec.policy \
				${TmpDrvFilesDir}/usr/share/polkit-1/actions
		fi

                # for Xorg 7, the .so files are put in ${ATI_3D_DRV_32} (and
                #  possibly also ${ATI_3D_DRV_64}); however, some of the code
                #  looks for the files in the hard-coded paths
                #  /usr/X11R6/lib/modules/dri and /usr/X11R6/lib64/modules/dri
                #  so we are creating symlinks so the code can still find those
                #  .so files
                if [ "$X_LAYOUT" = "modular" ]
                then
                    mkdir -p ${TmpDrvFilesDir}/usr/X11R6/lib/modules/dri
                    ln -s ${ATI_3D_DRV_32}/fglrx_dri.so ${TmpDrvFilesDir}/usr/X11R6/lib/modules/dri/fglrx_dri.so

                    if [ ! -z ${ATI_3D_DRV_64} ]
                    then
                        mkdir -p ${TmpDrvFilesDir}/usr/X11R6/lib64/modules/dri
                        ln -s ${ATI_3D_DRV_64}/fglrx_dri.so ${TmpDrvFilesDir}/usr/X11R6/lib64/modules/dri/fglrx_dri.so
                    fi
                fi

                # replace strings in setup.glade (XML file)
                SETUP_GLADE="./setup.data/setup.glade"
                ATI_LOG_EXP=$( echo ${ATI_LOG} | sed -e 's/\//\\\//g' )

                rm -f ${SETUP_GLADE}_new
                sed s/\${ATI_LOG}/${ATI_LOG_EXP}/g ${SETUP_GLADE} >> ${SETUP_GLADE}_new
                rm -f ${SETUP_GLADE}
                mv -f ${SETUP_GLADE}_new ${SETUP_GLADE}

                # Generate xml scripts for Loki Setup
                ./lokixml.sh ${X_VERSION} ${DRV_RELEASE} ${TmpDrvFilesDir} 2>/dev/null

                # Run the installer
                RunLoki installation
                status=$?

                # Remove the temporary directory

                # make sure we're not doing "rm -rf /"; that would be bad
                if [ "${TmpDrvFilesDir}" = "/" ]
                then
                    echo "Error: TmpDrvFilesDir is / in ati-installer.sh;" 1>&2
                    echo "aborting rm operation to prevent data loss" 1>&2

                    exit 1
                fi

                rm -rf ${TmpDrvFilesDir}
            else
                echo ""
                echo "Detected version of X does not have a matching '${X_VERSION}' directory"
                echo "You may override the detected version using the following syntax:"
                echo "     X_VERSION=<xdir> ./amd-driver-installer-<ver>-<arch>.run [--install]"
                echo ""
                echo "The following values may be used for <xdir>:"
                
                for xdir in `ls -d x*`; do
                    echo -e "    ${xdir}\t`./map_xname.sh ${xdir}`"
                done
                 
                status=1
            fi
            ;;
        *)
            echo "Architecture '${_ARCH}' is not supported"
            status=1
            ;;
        esac
    fi

    CleanTmpInstPath

    ;;
--listpkg)
    #iterate through all ati-packager.sh under packages/distro/ to return all package types
    #categorize by distro, show its maintainer, and its status
    echo -e "List of generatable packages:\n"
    for distro in `ls packages`
    do
        #for several entries for maintainer, use "; " as a delimeter, for example "1st; 2nd"
        case "${distro}" in
        ATI)
            maintainer="ATI"
            verified_status=1
            ;;
        Debian)
            maintainer="Aric Cyr <aric.cyr@gmail.com>;Mario Limonciello <superm1@gmail.com>"
            verified_status=0
            ;;
        Fedora)
            maintainer="Niko Mirthes <nmirthes@gmail.com>;Michael Larabel <michael@phoronix.com>"
            verified_status=0
            ;;
        Gentoo)
            maintainer="UNKNOWN"
            verified_status=0
            ;;
        Mandriva)
            maintainer="Anssi Hannula <anssi@mandriva.org>"
            verified_status=0
            ;;
        RedHat)
            maintainer="ATI"
            verified_status=1
            ;;
        RedFlag)
            maintainer="Bowen Zhu <bwzhu@redflag-linux.com>"
            verified_status=0
            ;;
        Slackware)
            maintainer="Emanuele Tomasi <tomasi@cli.di.unipi.it>;Federico Rota <federico.rota01@gmail.com>"
            verified_status=0
            ;;
        SuSE)
            maintainer="Sebastian Siebert <freespacer@gmx.de>"
            verified_status=0
            ;;
        Ubuntu)
            maintainer="Mario Limonciello <superm1@gmail.com>;Aric Cyr <aric.cyr@gmail.com>;Alberto Milone <alberto.milone@canonical.com>"
            verified_status=0
            ;;
        custom-package)
            maintainer="Your Self <your@email>"
            verified_status=0
            ;;
        *)
            maintainer="UNKNOWN"
            verified_status=0
            ;;
        esac

        if [ -d packages/${distro} ]
        then
            packager=packages/${distro}/ati-packager.sh
            if [ -e ${packager} ]
            then
            
               pkg_list=""
               for package in `./${packager} --get-supported`
               do
                  pkg_list="${pkg_list}\t${distro}/${package}\n"
               done

               newMaintainer=`execGetMaintainer ${packager}`

               if [ $? -eq 0 -a -n "${newMaintainer}" ]; then
        			   maintainer=${newMaintainer}
        		   fi

                if [ ${pkg_list} ]
                then
                    echo -e "Package Maintainer(s): ${maintainer}" | sed "s/;/\n                      /g"

                    if [ ${verified_status} -eq 1 ]; then
                        echo "Status: Verified"
                    else
                        echo "Status: *UNVERIFIED*"
                    fi
                    echo -e "${distro} Packages:"

                    echo -e "${pkg_list}"
                fi
            fi
        fi
    done
    echo -e "For example, to build a Debian Etch package, run the following:"
    echo -e "% ./amd-driver-installer-<version>-<architecture>.run --buildpkg Debian/etch\n"
      ;;
--buildpkg)

    case "$#" in

    2)  #means --buildpkg was called without package_info or --dryrun
        pkg_list=`execIdentify 2>/dev/null`

        checkDistroResult ${pkg_list}
        if [ $? -eq 0 ]
        then
            # Get distro/package values
            distro=`echo ${pkg_list} | cut -d"/" -f1`
            package=`echo ${pkg_list} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                echo "Generating package: ${distro}/${package}"
                packager=packages/${distro}/ati-packager.sh
                execBuildPrep ${packager} ${package}
                prepResult=$?
                if [ ${prepResult} -ne 0 ]
                then
                    status=1
                    break #set error to ${prepResult}
                fi
                execBuildPkg ${packager} ${package}
                buildResult=$?
                if [ ${buildResult} -ne 0 ]
                then
                    status=1
                    break #set error to ${buildResult}
                fi
            else
                echo "Error: The distribution ${distro} is not supported"
                status=1
                break #error was ATI_INSTALLER_ERR_DIST
            fi
        else                            #else in an error condition and msg was relayed by checkDistroResult()
            status=1
            break
        fi
        ;;
    3)
        if [ "${3}" = "--dryrun" ]
        then
            pkg_list=`execIdentify`

            checkDistroResult ${pkg_list}
            if [ $? -eq 0 ]
            then
                distro=`echo ${pkg_list} | cut -d"/" -f1`
                package=`echo ${pkg_list} | cut -d"/" -f2`
                if [ "${distro}" -a -d packages/${distro} ]
                then
                    packager=packages/${distro}/ati-packager.sh
                    echo "Simulating Generation of package: ${distro}/${package}"
                    execBuildPrep ${packager} ${package} ${3}
                    prepResult=$?
                    if [ ${prepResult} -ne 0 ]
                    then
                        status=1
                        break #set error to ${prepResult}
                    fi
                else
                    echo "Error: The distribution ${distro} is not supported"
                    status=1
                    break #error was ATI_INSTALLER_ERR_DIST
                fi
            else                            #else in an error condition and msg was relayed by checkDistroResult()
                status=1
                break
            fi
        else
            package_info=$3

            # Get distro/package values
            distro=`echo ${package_info} | cut -d"/" -f1`
            package=`echo ${package_info} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                echo "Generating package: ${distro}/${package}"
                packager=packages/${distro}/ati-packager.sh
                execGetAPIVersion ${packager}
                if [ $? -gt 1 ]
                then
                    execBuildPrep ${packager} ${package}
                    prepResult=$?
                    if [ ${prepResult} -ne 0 ]
                    then
                        status=1
                        break #set error to ${prepResult}
                    fi
                fi
                execBuildPkg ${packager} ${package}
                buildResult=$?
                if [ ${buildResult} -ne 0 ]
                then
                    status=1
                    break #set error to ${buildResult}
                fi
            else
                echo "Error: The distribution ${distro} is not supported"
                status=1
                break #error was ATI_INSTALLER_ERR_DIST
            fi
        fi
        ;;
    4)        
        if [ "${4}" = "--dryrun" ]
        then
            package_info=$3

            # Get distro/package values
            distro=`echo ${package_info} | cut -d"/" -f1`
            package=`echo ${package_info} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                packager=packages/${distro}/ati-packager.sh
                execGetAPIVersion ${packager}
                if [ $? -gt 1 ]
                then
                    echo "Simulating Generation of package: ${distro}/${package}"
                    execBuildPrep ${packager} ${package} ${4}
                    prepResult=$?
                    if [ ${prepResult} -ne 0 ]
                    then
                        status=1
                        break #set error to ${prepResult}
                    fi
                else
                    echo "Error: Build Option ${4}, not supported currently by packager"
                    status=1
                    break #error was ATI_INSTALLER_ERR_API
                fi
            else
                echo "Error: The distribution ${distro} is not supported"
                status=1
                break #error was ATI_INSTALLER_ERR_DIST
            fi
        elif [ "${4}" = "--NoXServer" ]
	then
		package_info=$3

            	# Get distro/package values
            	distro=`echo ${package_info} | cut -d"/" -f1`
            	package=`echo ${package_info} | cut -d"/" -f2`
            	if [ "${distro}" -a -d packages/${distro} ]
            	then
                   echo "Generating package: ${distro}/${package}"
		#ToDo:we can remove these if-else section, as we are maintaining 2 scripts on RHEL.
		#we can club it to one going forward like Ubuntu and SuSE.
		   if [ "$distro" = "RedHat" ]; then 
                       packager=packages/${distro}/ati-packager-NoX.sh
                       ./${packager} --buildpkg ${package}
		   else
                       packager=packages/${distro}/ati-packager.sh
                       ./${packager} --buildpkg ${package} $4
		   fi

#		Need to uncomment these soon
#                   execGetAPIVersion ${packager}
#                   if [ $? -gt 1 ]
#                   then
#                      execBuildPrep ${packager} ${package}
#                      prepResult=$?
#                      if [ ${prepResult} -ne 0 ]
#                      then
#                         status=1
#                         break #set error to ${prepResult}
#                      fi
#                   fi
#                   execBuildPkg ${packager} ${package}
#                   ./${packager} --buildpkg ${package}
                   buildResult=$?
                   if [ ${buildResult} -ne 0 ]
                   then
                      status=1
                      break #set error to ${buildResult}
                   fi
               else
                   echo "Error: The distribution ${distro} is not supported"
                   status=1
                   break #error was ATI_INSTALLER_ERR_DIST
               fi
	else
            echo "Error: Unrecognized build option parameter ${4}"
            printHelp
            status=1
            break #error was ATI_INSTALLER_ERR_BUILDOP
        fi                
	;;
    *)
        echo "Error: Unrecognized build option parameters"
        printHelp
        status=1
        break #error was ATI_INSTALLER_ERR_BUILDOP
        ;;
    esac
    ;;
--buildandinstallpkg)

    numArgs="$#"
    args=$@
    if [ "`echo $args | grep '\-\-force'`" != "" ]; then
        FORCE_ATI_UNINSTALL=y
        export FORCE_ATI_UNINSTALL
        #remove force command from args
        args=`echo $args | sed "s/'--force'//g"`
        numArgs=$(($numArgs-1))
    fi

    case ${numArgs} in

    2)  #means --buildandinstallpkg was called without package_info or --dryrun
        pkg_list=`execIdentify 2>/dev/null`

        checkDistroResult ${pkg_list}
        if [ $? -eq 0 ]
        then
            # Get distro/package values
            distro=`echo ${pkg_list} | cut -d"/" -f1`
            package=`echo ${pkg_list} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                echo "Generating and Installing package: ${distro}/${package}"
                packager=packages/${distro}/ati-packager.sh
                execBuildAndInstall ${packager} ${package}
                BandIResult=$?
                if [ ${BandIResult} -ne 0 ]
                then
                    status=1
                    break #set error to ${BandIResult}
                fi
            else
                echo "Error: The distribution ${1} is not supported"
                status=1
                break #error was ATI_INSTALLER_ERR_DIST
            fi
        else                            #else in an error condition and msg was relayed by checkDistroResult()
            status=1
            break
        fi
        ;;
    3)
        if [ "`echo $args | grep '\-\-dryrun'`" != "" ]
        then
            pkg_list=`execIdentify`

            checkDistroResult ${pkg_list}
            if [ $? -eq 0 ]
            then
                distro=`echo ${pkg_list} | cut -d"/" -f1`
                package=`echo ${pkg_list} | cut -d"/" -f2`
                if [ "${distro}" -a -d packages/${distro} ]
                then
                    packager=packages/${distro}/ati-packager.sh
                    echo "Simulating Generation and Installation of package: ${distro}/${package}"
                    execBuildAndInstall ${packager} ${package} --dryrun
                    BandIResult=$?
                    if [ ${BandIResult} -ne 0 ]
                    then
                        status=1
                        break #set error to ${BandIResult}
                    fi
                else
                    echo "Error: The distribution ${1} is not supported"        
                    status=1
                    break #error was ATI_INSTALLER_ERR_DIST
                fi
            else                        #else in an error condition and msg was relayed by checkDistroResult()
                status=1
                break 
            fi
        else
            package_info=$3

            # Get distro/package values
            distro=`echo ${package_info} | cut -d"/" -f1`
            package=`echo ${package_info} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                packager=packages/${distro}/ati-packager.sh
                execGetAPIVersion ${packager}
                if [ $? -gt 1 ]
                then
                    echo "Generating and Installing package: ${distro}/${package}"
                    execBuildAndInstall ${packager} ${package}
                    BandIResult=$?
                    if [ ${BandIResult} -ne 0 ]
                    then
                        status=1
                        break #set error to ${BandIResult}
                    fi
                else
                    echo "Error: Build Option ${ACTION} not supported currently by packager"
                    status=1
                    break #error was ATI_INSTALLER_ERR_API
                fi
            else
                echo "Error: The distribution ${distro} is not supported"
                status=1
                break #error was ATI_INSTALLER_ERR_DIST
            fi
        fi
        ;;
    4)        
        if [ "`echo $args | grep '\-\-dryrun'`" != "" ]
        then
            package_info=$3

            # Get distro/package values
            distro=`echo ${package_info} | cut -d"/" -f1`
            package=`echo ${package_info} | cut -d"/" -f2`
            if [ "${distro}" -a -d packages/${distro} ]
            then
                packager=packages/${distro}/ati-packager.sh
                execGetAPIVersion ${packager}
                if [ $? -gt 1 ]
                then
                    echo "Simulating Generation and Installation of package: ${distro}/${package}"
                    execBuildAndInstall ${packager} ${package} --dryrun
                    BandIResult=$?
                    if [ ${BandIResult} -ne 0 ]
                    then
                        status=1
                        break #set error to ${BandIResult}
                    fi
                else
                    echo "Error: Build Option ${ACTION} not supported currently by packager"
                    status=1
                    break #error was ATI_INSTALLER_ERR_API
                fi
            else
                echo "Error: The distribution ${distro} is not supported"
                status=1
                break #error was ATI_INSTALLER_ERR_DIST
            fi
        else
            echo "Error: Unrecognized build option parameter"
            printHelp
            status=1
            break #error was ATI_INSTALLER_ERR_BUILDOP
        fi                
        ;;
    *)
        echo "Error: Unrecognized build option parameter"
        printHelp
        status=1
        break #error was ATI_INSTALLER_ERR_BUILDOP
        ;;
    esac
    ;;
--installpkg)

    if [ "`echo $@ | grep '\-\-force'`" != "" ]; then
        FORCE_ATI_UNINSTALL=y
        export FORCE_ATI_UNINSTALL
    fi
    
    package_info=$3

    # Get distro/package values
    distro=`echo ${package_info} | cut -d"/" -f1`
    package=`echo ${package_info} | cut -d"/" -f2`
    if [ "${distro}" -a -d packages/${distro} ]
    then
        packager=packages/${distro}/ati-packager.sh
        execGetAPIVersion ${packager}
        if [ $? -gt 1 ]
        then
        
            execInstallPrep ${packager} ${package}
            prepResult=$?
            if [ ${prepResult} -ne 0 ]
            then
                status=1
                break #set error to ${prepResult}
            fi
            execInstallPkg ${packager} ${package}
            installResult=$?
            if [ ${installResult} -ne 0 ]
            then
                status=1
                break #set error to ${installResult}
            fi
        else
            echo "Action ${2} not supported by current API of ${3}"
            status=1
            break
        fi
    else
        echo "Error: The distribution ${distro} is not supported"
        status=1
        break #error was ATI_INSTALLER_ERR_DIST
    fi
    ;;
--getAPIVersion)
    if [ "${3}" -a -d packages/${3} ]
    then
        packager=packages/${3}/ati-packager.sh
        execGetAPIVersion ${packager}
        echo "Installer API version for distribution ${3} is $?"
    else
        echo "Error: The distribution ${3} is not supported"
            status=1
        break #error was ATI_INSTALLER_ERR_DIST
    fi
    ;;
--help)
    printHelp
    ;;
*)
    echo "Unrecognized parameter '${ACTION}' to ati-installer.sh"
    printHelp
    status=1
    ;;  
esac

#write status to file to be read by .run
echo ${status} > ATI_STATUS

#check if user agreed to reboot
if [ $reboot -eq 1 ]; then
   SHUTDOWN_BIN=`which shutdown 2> /dev/null`
   if [ $? -ne 0 ]; then
      SHUTDOWN_BIN="/sbin/shutdown"
   fi
   ${SHUTDOWN_BIN} -r now "System rebooting" &
fi

exit ${status}


#!/bin/sh
#
# Copyright (c) 2008, 2010, 2011, 2012 Advanced Micro Devices, Inc.
#
#Purpose: Invoked by ati-installer.sh
#   It dynamically generate setup.xml, install.xml and package.xml, used by Loki Setup(both gtk/ncurses version)
#   It presumes that ati-installer.sh verified that the detected version of X is supported    
#Input:  
#   $1 - the detected X version from ati-installer.sh 
#   $2 - driver release version from ati-installer.sh
#   $3 - the directory containing merged common and X specific file trees
#Return: 
#   Always exit 0

RunComponentConfig()
{
    . ./component_config.sh $@
}

GenerateFileList()
{
    root_dir=$1
    files=$2
    EXEFILE_PATTERN=$3

    eval files=\$${files}
    eval EXEFILE_PATTERN=\$${EXEFILE_PATTERN}

    for libfile in ${files}; do
        dirpath=`dirname ${libfile}`
        mode=""
        if [ "${EXEFILE_PATTERN}" -a "`echo ${root_dir}/${libfile} | grep \"${EXEFILE_PATTERN}\"`" ]; then
            mode=" mode=\"755\""
        fi
        echo "    <files path=\"${dirpath}\"${mode}>${root_dir}/${libfile}</files>"
    done
}

GenerateComponentXML()
{
    component=$1
    install_root=$2

    files=files_${component}
    desc=desc_${component}
    exe_pattern=exe_${component}
    required=req_${component}

    eval install_files=\$${files}
    eval desc=\$${desc}
    eval required=\$${required}

 # Calculate component size
    size=0
    for f in ${install_files}; do
        fsize=`du -b "${install_root}/${f}" | awk '$0 {print $1}'`
        size=`expr ${size} + ${fsize}`
    done
    
    # only include the required flag if its value is true
    printf "  <option size=\"${size}\" install=\"true\""
    if [ "${required}" = "true" ]; then
        printf " required=\"true\""
    fi
    printf ">\n    ${desc}"
    
    if [ -x pre_${component}.sh ]; then 
        echo "    <script message=\"Preprocessing ${desc}\">sh pre_${component}.sh</script>"
    fi
    
    GenerateFileList ${install_root} ${files} ${exe_pattern}
    
    if [ -x post_${component}.sh ]; then 
        echo "    <script message=\"Postprocessing ${desc}\">sh post_${component}.sh</script>"
    fi
    
    echo "    <script message=\"Copying uninstall files for ${desc}\">sh copy_uninstall_files.sh ${component} ${install_root}</script>"
    echo "  </option>"
}

###############################################################################
# Script execution starts here

DETECTX=$1
DRV_RELEASE=$2
INSTALL_FILES=$3

. ${TMP_INST_PATH_DEFAULT}
. ${TMP_INST_PATH_OVERRIDE}

# Set the license (EULA) path to be the same as ATI_LOG
# Strip out the starting / as we need a relative path
LIC_FILE="LICENSE.TXT"
LIC_PATH="${SETUP_INSTALLPATH}`printf ${ATI_LOG} | sed -re 's!^/!!' `/"

# Copy the file over to the subdir so Loki can install it to
# the relative path for the eula element
mkdir -p "${LIC_PATH}" 2>/dev/null

#set {LIC_PATH}directory permissions to be the same as other directories in extracted folder
#otherwise, if root access was granted, the directory and license will not be deleted
#when installer exists and separate process is used to delete the extracted folder
parentdir=`echo  "$LIC_PATH" | cut -d /  -f 1`
if [ -n "$parentdir" ]; then
    groupowner=`find "${LIC_FILE}" -printf "%g"`

    if [ -n "$groupowner" ]; then
        CHGRP=`which chgrp 2>/dev/null`
        if [ $? -eq 0 ] ; then
            $CHGRP -R "$groupowner" "$parentdir"
        fi
    fi

    fileowner=`find "${LIC_FILE}" -printf "%u"`
    if [ -n "$fileowner" ]; then
        CHOWN=`which chown 2>/dev/null`
        if [ $? -eq 0 ] ; then
            $CHOWN -R "$fileowner" "$parentdir"
        fi
    fi
fi

cp -p "${LIC_FILE}" "${LIC_PATH}" 2>/dev/null

#generate 3 xml files to support a meta install 
#setup.xml   : entry point of the install, provide 2 options: either install driver or generate package
#install.xml : install driver
#package.xml : generate packages 
SETUP_XML=setup.data/setup.xml
INSTALL_XML=setup.data/install.xml
INSTALL_GTK_XML=setup.data/install_gtk.xml
INSTALL_TXT_XML=setup.data/install_txt.xml
PACKAGE_XML=setup.data/package.xml

# Set variables describing components
RunComponentConfig ${INSTALL_FILES}


CURR_OS_NAME=$(lsb_release -i | awk '{ print $3 }')
#echo "$CURR_OS_NAME"

#The RedHat distribution name will be long and cut it to just RedHat only to read from config file
if [[ ${CURR_OS_NAME} == RedHat* ]]; then
   CURR_OS_NAME=RedHat
elif [ -f /etc/redhat-release ]; then
   CURR_OS_NAME=RedHat
fi
if [ "$CURR_OS_NAME" = "Ubuntu" -o "$CURR_OS_NAME" = "RedHat" ]; then
###############################################################################
#generate setup.xml
cat - > ${SETUP_XML} << SETUP_XML_END
<?xml version="1.0" standalone="yes"?>
<install 
	desc="AMD  Proprietary Driver ${DRV_RELEASE}" 
	nobinaries="yes" 
	version="${DRV_RELEASE}" 
	nouninstall="yes" 
	splash="atilogo.xpm" 
	path="" 
	nopromptoverwrite="yes" 
	superuser="yes" 
	meta="yes">
	
  <option product="${PACKAGE_XML}" install="true">Generate Distribution Specific Driver Package (Recommended)</option>	
  <option product="${INSTALL_XML}">Install Driver ${DRV_RELEASE} on `./map_xname.sh ${DETECTX}`</option>
</install>
SETUP_XML_END
###############################################################################
else
###############################################################################
#generate setup.xml
cat - > ${SETUP_XML} << SETUP_XML_END
<?xml version="1.0" standalone="yes"?>
<install 
	desc="AMD  Proprietary Driver ${DRV_RELEASE}" 
	nobinaries="yes" 
	version="${DRV_RELEASE}" 
	nouninstall="yes" 
	splash="atilogo.xpm" 
	path="" 
	nopromptoverwrite="yes" 
	superuser="yes" 
	meta="yes">

  <option product="${INSTALL_XML}"  install="true">Install Driver ${DRV_RELEASE} on `./map_xname.sh ${DETECTX}`</option>	
  <option product="${PACKAGE_XML}">Generate Distribution Specific Driver Package</option>	

</install>
SETUP_XML_END

fi
###############################################################################
#generate install_gtk.xml
# The dummy URL here makes sure that installation and package generation
# show a different page in the graphical installer when the installation
# or package generation is complete. There won't be a button to show release
# notes. I removed it in the setup.glade file.    -- FK
cat - > ${INSTALL_GTK_XML} << INSTALL_XML_END
<?xml version="1.0" standalone="yes"?>

<install 
	desc="AMD  Proprietary Driver ${DRV_RELEASE}" 
	nobinaries="yes" 
	version="${DRV_RELEASE}" 
	nouninstall="yes" 
	splash="atilogo.xpm" 
	path="" 
	nopromptoverwrite="yes" 
	url="dummy" 
	localurl="${ATI_LOG}/fglrx-install.log" 
	auto_url="false" 
	express="yes" 
	postinstall="sh config_install.sh > /dev/null">

  <eula keepdirs="yes">${LIC_PATH}${LIC_FILE}</eula>
 
  <require command="sh detect_gpu.sh">
  Your graphics adapter is not supported by this driver. Installation will not proceed. 
  </require>    
 
 
  <require command="sh detect_previous.sh">
  A previous install of the fglrx driver has
  been detected. Please uninstall the older
  version before installing this version.
  Optionally, run the installer with --force
  option to overwrite the existing driver.
  Forcing install is not recommended.
  See ${ATI_LOG}/fglrx-install.log for
  more details.
  </require>    

  <require command="sh detect_requirements.sh">
  Please install the required pre-requisites before proceeding with AMD Proprietary Driver installation.
  Install the required pre-requisites before installing the fglrx driver. Optionally, run the installer with --force option to install without the tools. 
  Forcing install will disable AMD hardware acceleration and may make your system unstable. Not recommended.  
  Please check ${ATI_LOG}/fglrx-install.log for more details. 
  </require>     

  <post_install_msg command=". ./verify_install.sh">
    There were errors during installation.  Details can be found in ${ATI_LOG}/fglrx-install.log
  </post_install_msg>

`for component in ${COMPONENTS}; do GenerateComponentXML ${component} ${INSTALL_FILES}; done`
</install>
INSTALL_XML_END

###############################################################################
#generate install_txt.xml
# In text mode we remove the URL so the question whether to launch a web
# browser does not pop up.
cat - > ${INSTALL_TXT_XML} << INSTALL_XML_END
<?xml version="1.0" standalone="yes"?>

<install 
	desc="AMD  Proprietary Driver ${DRV_RELEASE}" 
	nobinaries="yes" 
	version="${DRV_RELEASE}" 
	nouninstall="yes" 
	splash="atilogo.xpm" 
	path="" 
	nopromptoverwrite="yes" 
	express="yes" 
	postinstall="sh config_install.sh > /dev/null">

  <eula keepdirs="yes">${LIC_PATH}${LIC_FILE}</eula>

  <require command="sh detect_gpu.sh">
  Your graphics adapter is not supported by this driver. Installation will not proceed. 
  </require>    
 
  <require command="sh detect_previous.sh">
  A previous install of the fglrx driver has
  been detected. Please uninstall the older
  version before installing this version.
  Optionally, run the installer with --force
  option to overwrite the existing driver.
  Forcing install is not recommended.
  See ${ATI_LOG}/fglrx-install.log for more
  details.
  </require>

  <require command="sh detect_requirements.sh">
  Please install the required pre-requisites before 
  proceeding with AMD Proprietary Driver installation.
  Install the required pre-requisites before installing 
  the fglrx driver. Optionally, run the
  installer with --force option to install 
  without the tools.
  Forcing install will disable AMD hardware 
  acceleration and may make your system 
  unstable. Not recommended.
  Please check file ${ATI_LOG}/fglrx-install.log for more details.
  </require>     
  
  <post_install_msg command=". ./verify_install.sh">
    There were errors during installation.  Details can be found in ${ATI_LOG}/fglrx-install.log
  </post_install_msg>

`for component in ${COMPONENTS}; do GenerateComponentXML ${component} ${INSTALL_FILES}; done`
</install>
INSTALL_XML_END

###############################################################################
#generate package.xml
cat - > ${PACKAGE_XML} << PACKAGE_XML_HDR_END
<?xml version="1.0" standalone="yes"?>
<install 
	desc="AMD  Proprietary Driver ${DRV_RELEASE}" 
	nobinaries="yes" 
	version="${DRV_RELEASE}" 
	nouninstall="yes" 
	splash="atilogo.xpm" 
	path="" 
	nopromptoverwrite="yes" 
	localurl="${ATI_LOG}/fglrx-install.log">

  <eula keepdirs="yes">${LIC_PATH}${LIC_FILE}</eula>

  <require command="sh detect_requirements_package.sh">
  Please install pre-requisites before 
  proceeding with AMD Proprietary Driver Package Generation.
  Please check file ${ATI_LOG}/fglrx-install.log for more details.
  </require>    
 
  <post_install_msg command=". ./verify_install.sh">
	There were errors during package generation.  Details can be found in ${ATI_LOG}/fglrx-install.log
  </post_install_msg>

  <exclusive>Package Generation
PACKAGE_XML_HDR_END

DEFAULT_GROUP="false"

#nested <exclusive> is not supported in Loki Setup
#therefore in gtk package generation we have to sacrifice the second level <exclusive>
#meaning only distros are mututally exclusive but distro/package packages are not mututally exclusive
for distro in `ls packages/ `; do

    # only supported distributions (RedHat and SuSE) are listed in the list of
    # generatable packages in the installer because the complete list does not
    # fit on the screen, even if your resolution is 1280x1024 (it might fit on
    # the screen if you have a higher resolution); listing only RedHat and SuSE
    # allows the list to fit on an 800x600 screen, given the packages available
    # at the time of this writing
    case "$distro" in
        RedHat | \
        SuSE   )
            # 1 exclusive item is needed to be selected by default
            # so the very first exclusive group is set to default
            echo "    <option install=\"${DEFAULT_GROUP}\">" >> ${PACKAGE_XML}
            echo "      ${distro} Packages" >> ${PACKAGE_XML}
 
            DEFAULT_GROUP="false"

            for supportedpkg in `./packages/${distro}/ati-packager.sh --get-supported`;  do
            
                #do not add unsupported packages from UI to reduce size of dialog
                echo ${supportedpkg} | grep 'SUSE103\|SUSE110' > /dev/null;
                if [ $? -ne 0 ]; then

                    cat - >> ${PACKAGE_XML} << PACKAGE_XML_END
      <option install="false">
        ${distro}/${supportedpkg}
        <script message="Generating package ${distro}/${supportedpkg}">sh ati-packager-wrapper.sh ${distro}/${supportedpkg}</script>
        <!-- 
          For the Loki installer, there has to be a file specified for a selected option to be installable
	      For now, a dummy AMD_LICENSE.TXT file is specified, to make the Loki "install" button clickable
        -->
        <files path="${LIC_PATH}">${LIC_FILE}</files>
      </option>
PACKAGE_XML_END
                fi
            done

            echo "    </option>" >> ${PACKAGE_XML}
        ;;
    esac

done

write_detect_option=0
for distro in `ls packages/ `; do

           
    packager=packages/${distro}/ati-packager.sh
    if [ -e ${packager} ]
    then
        if [ "`grep getAPIVersion ${packager}`" != "" ]
        then 
            ./${packager} --getAPIVersion
            if [ $? -gt 1 ]
            then
                pkg_list=""
                for supportedpkg in `./${packager} --get-supported`;   do
        
                    output=`./${packager} --identify ${supportedpkg} 2> /dev/null`
                    if [ $? -eq 0 -a -d ./packages/${distro} ]
                    then
                        pkg_list="${pkg_list} ${distro}/${supportedpkg}"
                    fi
                done
        
                found=`echo ${pkg_list} | wc -w`  
                if [ ${found} -eq 1 ]
                then
                    distro=`echo ${pkg_list} | cut -d"/" -f1`
                    package=`echo ${pkg_list} | cut -d"/" -f2`
        
                    if [ "${distro}" -a -d ./packages/${distro} ]
                    then
                        #found a package that can be built
                        write_detect_option=1
            
            #provide option to detect and build package
cat - >> ${PACKAGE_XML} << DETECT_OPTION
    <option install="true">
        Build package for detected OS: ${distro}/${package}
        <script message="Generating package ${distro}/${package}">sh ati-packager-wrapper.sh ${distro}/${package}</script>
        <!-- 
          For the Loki installer, there has to be a file specified for a selected option to be installable
	      For now, a dummy AMD_LICENSE.TXT file is specified, to make the Loki "install" button clickable
        -->	      	      	      
        <files path="${LIC_PATH}">${LIC_FILE}</files>
      </option>
DETECT_OPTION

                        break
                    fi
                fi
            fi
        fi
    fi
done


if [ ${write_detect_option} -eq 0 ]
then 
    #unknown distribution
cat - >> ${PACKAGE_XML} << UNSUPPORTED_OPTION
    <option install="false">
        Packages for other distributions
        <!-- 
          The WARN tag causes a pop-up message to be displayed whenever the
          "Packages for other distributions" option is selected, containing the
          text within the start and end tags.  Since the "Packages for other
          distributions" option is a top-level option (like "RedHat" or "SuSE"),
          it is not a valid install target on its own (valid install targets
          include RedHat/RHEL3, which is a sub-option of RedHat).  Since it is
          not a valid install target, the "Continue" button will be grayed out
          when "Packages for other distributions" is selected so the user
          cannot proceed using that option.  To sum up, when "Packages for
          other distributions" is displayed, the following message will appear
          in a pop-up and the user must either select another distribution for
          which to generate a package or the user must exit the installer.

          NOTE: In the Ncurses GUI, the message is truncated after
          "...generatable packages."  The user should still be able to figure
          out that they need to use [dash][dash]buildpkg from the output of
          [dash][dash]listpkg so this issue is minor.  In the Gnome GUI, the
          message is not truncated.
        -->
        <warn>
          To generate packages for distributions other than RedHat and SuSE,
          restart the installer from the command line with the --listpkg option
          (ie. "./amd-driver-installer-&lt;version&gt;-&lt;architecture&gt;.run
          --listpkg") to view the complete list of generatable packages.
          Then use the --buildpkg option to build a package from the list.
          The --listpkg option provides instructions for using --buildpkg.
        </warn>
    </option>
UNSUPPORTED_OPTION

fi

echo "  </exclusive>" >> ${PACKAGE_XML}
echo "</install>" >> ${PACKAGE_XML}	

###############################################################################
exit 0


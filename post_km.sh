#!/bin/sh
DRV_RELEASE="15.302"

##############################################################
# COMMON HEADER: Initialize variables and declare subroutines

BackupInstPath()
{
    if [ ! -d /etc/ati ]
    then
        # /etc/ati is not a directory or doesn't exist so no backup is required
        return 0
    fi

    if [ -n "$1" ]
    then
        FILE_PREFIX=$1
    else
        # client did not pass in FILE_PREFIX parameter and /etc/ati exists
        return 64
    fi

    if [ ! -f /etc/ati/$FILE_PREFIX ]
    then
        return 0
    fi

    COUNTER=0

    ls /etc/ati/$FILE_PREFIX.backup-${COUNTER} > /dev/null 2>&1
    RETURN_CODE=$?
    while [ 0 -eq $RETURN_CODE ]
    do
        COUNTER=$((${COUNTER}+1))
        ls /etc/ati/$FILE_PREFIX.backup-${COUNTER} > /dev/null 2>&1
        RETURN_CODE=$?
    done

    cp -p /etc/ati/$FILE_PREFIX /etc/ati/$FILE_PREFIX.backup-${COUNTER}

    RETURN_CODE=$?

    if [ 0 -ne $RETURN_CODE ]
    then
        # copy failed
        return 65
    fi

    return 0
}



UpdateInitramfs()
{
    UPDATE_INITRAMFS=`which update-initramfs 2> /dev/null`
    DRACUT=`which dracut 2> /dev/null`
    MKINITRD=`which mkinitrd 2> /dev/null`

    kernel_release=`uname -r`
    kernel_version=`echo $kernel_release | cut -d"." -f 1`
    kernel_release_rest=`echo $kernel_release | cut -d"." -f 2`   
    kernel_major_rev=`echo $kernel_release_rest | cut -d"-" -f 1`
    kernel_major_rev=`echo $kernel_major_rev | cut -d"." -f 1` 

    if [ $kernel_version -gt 2 ]; then
        #not used
        kernel_minor_rev=0
    else
        kernel_minor_rev=`echo $kernel_release | cut -d"." -f 3 | cut -d"-" -f 1`
    fi

    if [ $kernel_version -gt 2 -o \( $kernel_version -eq 2 -a $kernel_major_rev -ge 6 -a $kernel_minor_rev -ge 32 \) ]; then

        if [ -n "${UPDATE_INITRAMFS}" -a -x "${UPDATE_INITRAMFS}" ]; then
            #update initramfs for current kernel by specifying kernel version
            ${UPDATE_INITRAMFS} -u -k `uname -r` > /dev/null 

            #update initramfs for latest kernel (default)
            ${UPDATE_INITRAMFS} -u > /dev/null
            
            echo "[Reboot] Kernel Module : update-initramfs" >> ${LOG_FILE} 
        elif [ -n "${DRACUT}" -a -x "${DRACUT}" ]; then
            #RedHat/Fedora
            ${DRACUT} -f > /dev/null            
            echo "[Reboot] Kernel Module : dracut" >> ${LOG_FILE}
             

        elif [ -n "${MKINITRD}" -a -x "${MKINITRD}" ]; then
            #Novell
            ${MKINITRD} > /dev/null
            
            echo "[Reboot] Kernel Module : mkinitrd" >> ${LOG_FILE}
            
        fi
    else
        echo "[Message] Kernel Module : update initramfs not required" >> ${LOG_FILE}
    fi

}



# i.e., lib for 32-bit and lib64 for 64-bit.
if [ `uname -m` = "x86_64" ];
then
  LIB=lib64
else
  LIB=lib
fi

# LIB32 always points to the 32-bit libraries (native in 32-bit,
# 32-on-64 in 64-bit) regardless of the system native bitwidth.
# Use lib32 and lib64; if lib32 doesn't exist assume lib is for lib32
if [ -d "/usr/lib32" ]; then
  LIB32=lib32
else
  LIB32=lib
fi

#process INSTALLPATH, if it's "/" then need to purge it
#SETUP_INSTALLPATH is a Loki Setup environment variable
INSTALLPATH=${SETUP_INSTALLPATH}
if [ "${INSTALLPATH}" = "/" ]
then
    INSTALLPATH=""
fi

# project name and derived defines
MODULE=fglrx
IP_LIB_PREFIX=lib${MODULE}_ip

# general purpose paths
XF_BIN=${INSTALLPATH}${ATI_X_BIN}
XF_LIB=${INSTALLPATH}${ATI_XLIB}
OS_MOD=${INSTALLPATH}`dirname ${ATI_KERN_MOD}`
USR_LIB=${INSTALLPATH}/usr/${LIB}
MODULE=`basename ${ATI_KERN_MOD}`

#FGLRX install log
LOG_PATH=${INSTALLPATH}${ATI_LOG}
LOG_FILE=${LOG_PATH}/fglrx-install.log
if [ ! -e ${LOG_PATH} ]
then
  mkdir -p ${LOG_PATH} 2>/dev/null 
fi
if [ ! -e ${LOG_FILE} ]
then
  touch ${LOG_FILE}
fi

#DKMS version
DKMS_VER=`dkms -V 2> /dev/null | cut -d " " -f2`

#DKMS expects kernel module sources to be placed under this directory
DKMS_KM_SOURCE=/usr/src/${MODULE}-${DRV_RELEASE}

# END OF COMMON HEADER
#######################

###Begin: post_km ###

##ONLY on SLED there is kernel flag set for not to load un-supported modules.
#To load our module, first we need to edit the allow_unsupported_modules under /etc/modprobe.d/ to 1.
#You can find KB article on it on NOvell site.
##EPR#412475

if [ "`cat /etc/*-release | grep -i "SUSE Linux Enterprise Server"`" ]
then
       echo "allow_unsupported_modules kernel options is added for fglrx.ko SLES via 50-fglrx.conf" >> ${LOG_FILE}
	if ! [ -f /etc/modprobe.d/50-fglrx.conf ]
	then
		 echo "install fglrx /sbin/modprobe --ignore-install --allow-unsupported-modules fglrx"  >> /etc/modprobe.d/50-fglrx.conf
	elif ! [ "`cat /etc/modprobe.d/50-fglrx.conf | grep -E "install fglrx /sbin/modprobe --ignore-install --allow-unsupported-modules fglrx"`" ]
	then
		 echo "install fglrx /sbin/modprobe --ignore-install --allow-unsupported-modules fglrx"  >> /etc/modprobe.d/50-fglrx.conf
	fi
fi

if [ "" != "${FGLRXKODELAY}" ]; then
    #prepare for delay fglrx ko build
    
    FGLRXKO_SCRIPT_NAME="fglrxkobuild"
    FGLRXKO_BUILD_SCRIPT="/etc/init.d/${FGLRXKO_SCRIPT_NAME}"
    FGLRXKO_BUILD_SYMLINK="/etc/rc${FGLRXKODELAY}.d/S40${FGLRXKO_SCRIPT_NAME}"
    FGLRXKO_BUILD_SYMLINK_CREATE=""
    FGLRXKO_BUILD_SYMLINK_DELETE=""
    
    #if file does not exist, then CONFIG_INSTALL is statically set in script
    FILE_configinstall_sh="config_install.sh"
    if [ -x ${FILE_configinstall_sh} ]; then
        BEGIN_configinstall_sh=`grep -n "^###Begin: config_install_sh" ${FILE_configinstall_sh} | cut -d":" -f1`
        END_configinstall_sh=`grep -n "^###End: config_install_sh" ${FILE_configinstall_sh} | cut -d":" -f1`    
        CONFIG_INSTALL=`sed -n ${BEGIN_configinstall_sh},${END_configinstall_sh}p ${FILE_configinstall_sh}`
    fi   
   
    FGLRXKO_BUILD_SCRIPT_HEADER="
#!/bin/sh
# Copyright (c) 2010 Advanced Micro Devices, Inc.
# Purpose: this script is called on first reboot of installing Catalyst driver
#          it builds and installs fglrx kernel module

### BEGIN INIT INFO
# Provides:          ${FGLRXKO_SCRIPT_NAME}
# Required-Start:
# Required-Stop: 
# Should-Start:
# Should-Stop:
# Default-Start:     ${FGLRXKODELAY}
# Default-Stop:      
# Description:       build fglrx kernel module when booting to runlevel ${FGLRXKODELAY} 
### END INIT INFO
"

    #determine which method to use for creation of symlinks, 
    #which will determine how symlink is deleted

    UPDATE_RC_BIN=`which update-rc.d 2> /dev/null`
    if [ $? -eq 0 ] && [ -x "${UPDATE_RC_BIN}" ]; then
        #on debian based system, use update-rc.d to create script startup links
        FGLRXKO_BUILD_SYMLINK_CREATE="update-rc.d ${FGLRXKO_SCRIPT_NAME} start 40 ${FGLRXKODELAY} ."
        
        #script must be deleted prior calling update-rc.d to remove 
        FGLRXKO_BUILD_DELETE="
rm -f ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null
update-rc.d -f ${FGLRXKO_SCRIPT_NAME} remove > /dev/null
rm -f ${FGLRXKO_BUILD_SYMLINK} 2> /dev/null"
             
    elif [ -e /etc/insserv.conf ]; then
        #on SUSE based system, use insserv to create script startup links
        FGLRXKO_BUILD_SYMLINK_CREATE="insserv ${FGLRXKO_BUILD_SCRIPT}"
        
        #script cannot be deleted until removed from insserv or there will be boot errors
        FGLRXKO_BUILD_DELETE="
insserv -rf ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null
rm -f ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null"

    else
        #manually create symlink
        FGLRXKO_BUILD_SYMLINK_CREATE="ln -s ${FGLRXKO_BUILD_SCRIPT} ${FGLRXKO_BUILD_SYMLINK}"
        FGLRXKO_BUILD_DELETE="
rm -f ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null 
rm -f ${FGLRXKO_BUILD_SYMLINK} 2> /dev/null"
    fi

    FGLRXKO_BUILD_SCRIPT_FOOTER="
# delete symlinks and scripts
${FGLRXKO_BUILD_DELETE}

#configure the driver
${CONFIG_INSTALL}
   
exit \${EXIT_STATUS}"

fi

if [ -z ${DKMS_VER} ]; then
	# No DKMS detected
	
    # check if radeon driver is loaded
    if [ "`lsmod | grep radeon`" != "" ]
    then
        # remove radeon driver  
        echo "Unloading radeon module..." >> ${LOG_FILE}
	    /sbin/rmmod radeon >> ${LOG_FILE} 2>&1 
    fi
    
    
    if [ "`lsmod | grep drm`" != "" ]
    then    
        echo "Unloading drm module..." >> ${LOG_FILE}
        /sbin/rmmod drm >> ${LOG_FILE} 2>&1
    fi	   	
	
	# === kernel module ===
    if [ "" != "${FGLRXKODELAY}" ]; then
        #delaying kernel module build till first reboot
        # Create fglrxkobuild script 
        cat - > ${FGLRXKO_BUILD_SCRIPT}<<__FGLRXKO_BUILD_EOF

${FGLRXKO_BUILD_SCRIPT_HEADER}

echo "[Message] Kernel Module : Starting delayed fglrx ko build." >> ${LOG_FILE}

cd ${OS_MOD}/${MODULE}

EXIT_STATUS=0

sh make_install.sh 1>&2 >/dev/null 

if [ \$? -ne 0 ]; then 
    echo "[Message] Kernel Module : Precompiled kernel module version mismatched." >> ${LOG_FILE}

    if test -d ${OS_MOD}/`uname -r`/build; then 

        # build kernel module
        echo "[Message] Kernel Module : Found kernel module build environment, generating kernel module now." >> ${LOG_FILE}

        cd ${OS_MOD}/${MODULE}/build_mod
        sh make.sh --nohints >> ${LOG_FILE}

        if [ \$? -eq 0 ]; then
            cd ${OS_MOD}/${MODULE}
            sh make_install.sh >> ${LOG_FILE}
            make_install=\$?

            if [ \$make_install -eq 2 ]; then
                echo "[Error] Kernel Module : Reboot required. " >> ${LOG_FILE}
                EXIT_STATUS=0
                
            elif [ \$make_install -ne 0 ]; then
                echo "[Error] Kernel Module : Failed to install compiled kernel module - please consult readme." >> ${LOG_FILE}
                EXIT_STATUS=1
            fi        
        else
            echo "[Error] Kernel Module : Failed to compile kernel module - please consult readme." >> ${LOG_FILE}
            EXIT_STATUS=1
        fi
    else
        echo "[Error] Kernel Module : Kernel module build environment not found - please consult readme." >> ${LOG_FILE}
        EXIT_STATUS=1
    fi
fi

/sbin/depmod
echo "[Message] Kernel Module : Completed delayed fglrx ko build." >> ${LOG_FILE}
	   
${FGLRXKO_BUILD_SCRIPT_FOOTER}

__FGLRXKO_BUILD_EOF

        #set the file as executable
        chmod +x ${FGLRXKO_BUILD_SCRIPT}
        
        #create the symlink to load the script
        `${FGLRXKO_BUILD_SYMLINK_CREATE}`

    else
	    echo "[Message] Kernel Module : Trying to install a precompiled kernel module." >> ${LOG_FILE}
        cd ${OS_MOD}/${MODULE}

        #make_install.sh information should be contained in readme, not in fglrx-install.log
        sh make_install.sh 1>&2 >/dev/null 

        if [ $? -ne 0 ]; then 
            echo "[Message] Kernel Module : Precompiled kernel module version mismatched." >> ${LOG_FILE}

            if test -d ${OS_MOD}/`uname -r`/build; then 
                # build kernel module
                echo "[Message] Kernel Module : Found kernel module build environment, generating kernel module now." >> ${LOG_FILE}
                cd ${OS_MOD}/${MODULE}/build_mod
                sh make.sh --nohints >> ${LOG_FILE}

                if [ $? -eq 0 ]; then
                    cd ${OS_MOD}/${MODULE}
                    sh make_install.sh >> ${LOG_FILE}
                    make_install=$?

                    if [ $make_install -eq 2 ]; then
                        echo "[Error] Kernel Module : Reboot required. " >> ${LOG_FILE}
                    elif [ $make_install -ne 0 ]; then
                        echo "[Error] Kernel Module : Failed to install compiled kernel module - please consult readme." >> ${LOG_FILE}
                    fi        
                else
                    echo "[Error] Kernel Module : Failed to compile kernel module - please consult readme." >> ${LOG_FILE}
	            fi
            else
	            echo "[Error] Kernel Module : Kernel module build environment not found - please consult readme." >> ${LOG_FILE}
            fi
	    fi
	   
	    /sbin/depmod	    
    fi
    
else
	# DKMS detected
	# DKMS compatible kernel module postinstallation actions
	DKMS_STATUS=0

	# If there is any previous fglrx module installed, remove it
    fglversions=`dkms status -m ${MODULE} | cut -d "," -f 2`
    for ver in ${fglversions}
    do
        dkms remove -m ${MODULE} -v ${ver} --all --rpm_safe_upgrade > /dev/null
        if [ $? -gt 0 ]; then
            echo "Errors during DKMS module removal" >> ${LOG_FILE}
        fi
        DKMS_PREV_SOURCE=/usr/src/${MODULE}-${ver}
        rm -R -f ${DKMS_PREV_SOURCE} 2>/dev/null
    done

	# Copy kernel module sources from the legacy location to where DKMS expects them

	# make sure we're not doing "rm -rf /"; that would be bad
	if [ "/" = "${DKMS_KM_SOURCE}" ]
	then
		echo "Error: DKMS_KM_SOURCE is / in post.sh; aborting rm operation" 1>&2
		echo "to prevent unwanted data loss" 1>&2

		exit 1
	fi

	rm -R -f ${DKMS_KM_SOURCE} 2> /dev/null	# Clean up old contents first
	cp -R ${OS_MOD}/${MODULE}/build_mod ${DKMS_KM_SOURCE}

	# DKMS installation takes kernel module sources from /usr/src/<module>-<ver>
	# Therefore, we can remove our legacy directory already at this stage

	# make sure we're not doing "rm -rf /"; that would be bad
	if [ -z "${OS_MOD}" -a -z "${MODULE}" ]
	then
		echo "Error: OS_MOD and MODULE are both empty in post.sh; aborting" 1>&2
		echo "rm operation to prevent unwanted data loss" 1>&2

		exit 1
	fi

	rm -R -f ${OS_MOD}/${MODULE} 2> /dev/null

	# Create dkms.conf
	cat - > ${DKMS_KM_SOURCE}/dkms.conf<<__DKMS_CONF_EOF
PACKAGE_NAME="${MODULE}"
PACKAGE_VERSION="${DRV_RELEASE}"

CLEAN="rm -f *.*o"

BUILT_MODULE_NAME[0]="${MODULE}"
MAKE[0]="cd \${dkms_tree}/\${PACKAGE_NAME}/\${PACKAGE_VERSION}/build; sh make.sh --nohints --uname_r=\${kernelver} --norootcheck"
DEST_MODULE_LOCATION[0]="/kernel/drivers/char/drm"
AUTOINSTALL="yes"
__DKMS_CONF_EOF

	# Create Makefile to support build for 2.6
	cat - > ${DKMS_KM_SOURCE}/Makefile<<__MAKEFILE_EOF
# "Fake" makefile required by DKMS to build modules for 2.6 kernels

all:
	@sh make.sh
__MAKEFILE_EOF

	# Add the module to DKMS
	dkms add -m ${MODULE} -v ${DRV_RELEASE} --rpm_safe_upgrade >> ${LOG_FILE}
	
	if [ $? -ne 0 ]; then
    	echo "[Error] Kernel Module : Failed to add ${MODULE}-${DRV_RELEASE} to DKMS" >> ${LOG_FILE}
		DKMS_STATUS=1
	else
	
        if [ "" != "${FGLRXKODELAY}" ]; then
            #delaying kernel module build till first reboot
            
            # Create fglrxkobuild script 
	        cat - > ${FGLRXKO_BUILD_SCRIPT}<<__FGLRXKO_BUILD_EOF

${FGLRXKO_BUILD_SCRIPT_HEADER}

echo "[Message] Kernel Module : Starting delayed fglrx ko build using DKMS." >> ${LOG_FILE}

#check if dkms autoinstaller has already built and installed fglrx
#if fglrx ko exists in DKMS, a descriptive string with a status is returned (added, built, installed, etc)
DKMS_FGLRX_STATUS=\`dkms status -m ${MODULE} -v ${DRV_RELEASE}\`

#build the module

dkms build -m ${MODULE} -v ${DRV_RELEASE} >> ${LOG_FILE} 2>&1
EXIT_STATUS=\$?

#if the module is already built, error code 3 is returned when rebuilding
if [ \${EXIT_STATUS} -eq 0 ] || \
    [ \${EXIT_STATUS} -eq 3 -a "\${DKMS_FGLRX_STATUS}" != "" ]; then

    # Install the module
    echo "[Message] Kernel Module : Installing fglrx ko build using DKMS." >> ${LOG_FILE}
	dkms install -m ${MODULE} -v ${DRV_RELEASE} >> ${LOG_FILE} 2>&1
    EXIT_STATUS=\$?
    
    # if the module is already installed, error code 5 is returned
    if [ \${EXIT_STATUS} -eq 0 ] || \
        [ \${EXIT_STATUS} -eq 5 -a "\${DKMS_FGLRX_STATUS}" != "" ]; then
    
        EXIT_STATUS=0
	else
	    echo "[Error] Kernel Module : Failed to install ${MODULE}-${DRV_RELEASE} using DKMS" >> ${LOG_FILE}
    fi
   
else
    echo "[Error] Kernel Module : Failed to build ${MODULE}-${DRV_RELEASE} with DKMS" >> ${LOG_FILE}
fi

if [ \${EXIT_STATUS} -ne 0 ]; then
    echo "[Error] Kernel Module : Removing ${MODULE}-${DRV_RELEASE} from DKMS" >> ${LOG_FILE}
    dkms remove -m ${MODULE} -v ${DRV_RELEASE} --all --rpm_safe_upgrade >> ${LOG_FILE} 2>&1
fi

echo "[Message] Kernel Module : Completed delayed fglrx ko build using DKMS." >> ${LOG_FILE}

${FGLRXKO_BUILD_SCRIPT_FOOTER}

__FGLRXKO_BUILD_EOF

            #set the file as executable
            chmod +x ${FGLRXKO_BUILD_SCRIPT}
        
            #create the symlink to load the script
            `${FGLRXKO_BUILD_SYMLINK_CREATE}`

	    else
		   # Build the module
		   dkms build -m ${MODULE} -v ${DRV_RELEASE} >> ${LOG_FILE}

		   if [ $? -ne 0 ]; then
    		   echo "[Error] Kernel Module : Failed to build ${MODULE}-${DRV_RELEASE} with DKMS" >> ${LOG_FILE}
			   DKMS_STATUS=2
		   else
                # Install the module
			    dkms install -m ${MODULE} -v ${DRV_RELEASE} >> ${LOG_FILE}

                if [ $? -ne 0 ]; then
                    echo "[Error] Kernel Module : Failed to install ${MODULE}-${DRV_RELEASE} using DKMS" >> ${LOG_FILE}
   				    DKMS_STATUS=3
	   		    fi
	   	    fi
	   fi

		if [ ${DKMS_STATUS} -gt 0 ]; then
   			echo "[Error] Kernel Module : Removing ${MODULE}-${DRV_RELEASE} from DKMS" >> ${LOG_FILE}
			dkms remove -m ${MODULE} -v ${DRV_RELEASE} --all --rpm_safe_upgrade >> ${LOG_FILE}
		fi
	fi

	if [ ${DKMS_STATUS} -gt 0 ]; then
   		echo "DKMS part of installation failed.  Please refer to ${LOG_FILE} for details"
	fi
	

fi

#run an update to the initial ramdisk
UpdateInitramfs

###End: post_km ###
exit 0

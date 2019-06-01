#!/bin/sh
#
# Copyright (c) 2011 Advanced Micro Devices, Inc.
#
# Purpose
#    AMD script to detect a previous installation of fglrx driver
#
# Usage
#    

#check if root
if [ "`whoami`" != "root" ]; then
    #do not run this script without root privileges
    #return 0 and installer will handle telling user that they need to be root
    exit 0
fi

#for steam os, remove inbox driver to avoid conflicting
#4-9-14,we will do this check only in case on non-redhat OS becuase lsb_release may not present on RHEL
if [ ! -f /etc/redhat-release ]; then
    DisString=`lsb_release -i`
    DID=`echo $DisString | awk '{ print $3 }'`
    if [ "$DID" = "SteamOS" ]
    then
        inboxdriver=`apt-cache search fglrx | awk '{ print $1 }'`
        apt-get -y remove $inboxdriver > /dev/null 2>&1
    fi
fi

#set the log file and other expected file pathes
if [ -n "${TMP_INST_PATH_DEFAULT}" -a -n "${TMP_INST_PATH_OVERRIDE}"  ]; then 
    . ${TMP_INST_PATH_DEFAULT}
    . ${TMP_INST_PATH_OVERRIDE}
    LOG_PATH=${SETUP_INSTALLPATH}${ATI_LOG}
else
    LOG_PATH=/usr/share/ati
fi

if [ ! -e ${LOG_PATH} ]
then
    mkdir -p ${LOG_PATH} 2>/dev/null 
fi

LOG_FILE=${LOG_PATH}/fglrx-install.log
AMD_UNINSTALL_SCRIPT="/usr/share/ati/amd-uninstall.sh"
FGLRX_UNINSTALL_SCRIPT="/usr/share/ati/fglrx-uninstall.sh"


# ensure the working directory is where the script resides
scriptdir=`dirname $0`
curdir=`pwd`
if [ -n "$scriptdir" -a "$scriptdir" != "$curdir" ]; then
    cd "$scriptdir"
fi


if [ -x "$AMD_UNINSTALL_SCRIPT" ]; then
    #found amd-uninstaller
    
    echo "Detected a previous installation, $AMD_UNINSTALL_SCRIPT" >> ${LOG_FILE}
    
    if [ "$FORCE_ATI_UNINSTALL" != "y" ]; then
        #check if can do uninstall without errors

        if [ "`grep getUninstallVersion $AMD_UNINSTALL_SCRIPT`" != "" ]
        then 
            sh ${AMD_UNINSTALL_SCRIPT} --getUninstallVersion
            version=$?
        else
            version=1
        fi

        if [ $version -ge 2 ]; then
            sh ${AMD_UNINSTALL_SCRIPT} --dryrun --quick >> /dev/null 
        else
            sh ${AMD_UNINSTALL_SCRIPT} --dryrun >> /dev/null
        fi
        result=$?
        
        if [ $result -eq 0 ]; then
            echo "Dryrun uninstall succeeded continuing with installation." >> ${LOG_FILE}
            exit 0
        else
            #cannot uninstall without running force
            echo "
[Error]A previous installation of fglrx driver detected.
User must uninstall using $AMD_UNINSTALL_SCRIPT with force 
or run install with force option. 
Forcing the installation is not recommended.
" >>  ${LOG_FILE}

            exit 1
   
        fi

    else
        #forcing install, so do not need to run dryrun test for uninstall
        echo "Installation with force option." >> ${LOG_FILE}
        result=0
    fi        
        

elif [ -x "$FGLRX_UNINSTALL_SCRIPT" ]; then


    #found fglrx-uninstall without amd-uninstall
    #older installation that does not support --dryrun to test uninstall
    #only try to uninstall if the user runs with force
    
    echo "Detected a previous installation, $FGLRX_UNINSTALL_SCRIPT" >> ${LOG_FILE}
    

    if [ "$FORCE_ATI_UNINSTALL" = "y" ]; then
        echo "Installation with force option." >> ${LOG_FILE}

        exit 0
    else
        #requires uninstall to be forced and/or
        #could not find the pre_install script
        #cannot uninstall without running force
        
        echo "
[Error]A previous installation of fglrx driver detected.
User must uninstall using $FGLRX_UNINSTALL_SCRIPT
or run install with force option. 
Forcing the installation is not recommended.
" >>  ${LOG_FILE}

        exit 1
    fi

elif [ -z "$FORCE_ATI_UNINSTALL"  ]; then
 
    #try to detect fglrx.ko
    fglrxko=`lsmod | grep "fglrx"`
    if [ -n "$fglrxko" ] ; then
    
        #currently running fglrx

        echo "
[Error]A previous installation of fglrx driver detected to be loaded.
User must uninstall existing fglrx driver 
or run install with force option. 
Forcing the installation is not recommended.
" >>  ${LOG_FILE}

        exit 1
    fi

    #check if there are any fglrx installed on system
     
    #DKMS version
    DKMS_VER=`dkms -V 2> /dev/null | cut -d " " -f2`

    if [ -n "${DKMS_VER}" ]; then
        #dkms is installed
        #check dkms tree for fglrx module
        result=`dkms status -m fglrx | grep installed`
        if [ -n "${result}" ]; then
            #fglrx is installed using dkms

            echo "
[Error]A previous installation of fglrx driver detected to be installed in dkms.
User must uninstall existing fglrx driver 
or run install with force option.
Forcing the installation is not recommended.
Output of 'dkms status -m fglrx'
    ${result}
" >>  ${LOG_FILE}

            exit 1
        fi
        
    fi
 
    curKernelVersion=`uname -r`
    result=`find /lib/modules/${curKernelVersion} -name "fglrx.ko"`
    if [ -n "${result}" ]; then
       #fglrx is installed

        echo "
[Error]A previous installation of fglrx driver detected to be installed.
User must uninstall existing fglrx driver 
or run install with force option.
Forcing the installation is not recommended.
Output of 'find /lib/modules/${curKernelVersion} -name \"fglrx.ko\"
        $result
" >>  ${LOG_FILE}

        exit 1
    fi

fi 

#no instance of uninstaller or fglrx ko found
exit 0



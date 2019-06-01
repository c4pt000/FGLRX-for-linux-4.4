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

###Begin: post_drv1 ###

# cover SuSE special case...
if [ `ls -1 ${INSTALLPATH}/usr/X11R6/bin/switch2* 2>/dev/null | grep "" -c 2>/dev/null` -gt 0 ]
then
  if [ -e ${INSTALLPATH}/usr/X11R6/bin/switch2xf86-4 ]
  then
    ${INSTALLPATH}/usr/X11R6/bin/switch2xf86-4
  fi

  if [ -e ${INSTALLPATH}/usr/X11R6/bin/switch2xf86_glx ]
  then
    echo "[Warning] Driver : swiching OpenGL library support to XFree86 4.x.x DRI method" >> ${LOG_FILE}
   else
    echo "[Warning] Driver : can't switch OpenGL library support to XFree86 4.x.x DRI method" >> ${LOG_FILE}
    echo "[Warning]        : because package xf86_glx-4.*.i386.rpm is not installed." >> ${LOG_FILE}
    echo "[Warning]        : please install and run switch2xf86_glx afterwards." >> ${LOG_FILE}
  fi
fi

  GLDRISEARCHPATH=${INSTALLPATH}${ATI_3D_DRV_32}
  LDLIBSEARCHPATHX=${INSTALLPATH}${ATI_XLIB_32}

if [ -n "${ATI_XLIB_64}" -a -n "${ATI_3D_DRV_64}" ]
then
  GLDRISEARCHPATH=${GLDRISEARCHPATH}:${INSTALLPATH}${ATI_3D_DRV_64}
  LDLIBSEARCHPATHX=${LDLIBSEARCHPATHX}:${INSTALLPATH}${ATI_XLIB_64}
fi

# set environment variable LD_LIBRARY_PATH
# add ATI_PROFILE script located in
#  - /etc/profile.d if dir exists, else
#  - /etc/ati and add a line in /etc/profile for sourcing

ATI_PROFILE_START="### START ATI FGLRX ###"
ATI_PROFILE_END="### END ATI FGLRX ###"
ATI_PROFILE_FNAME="ati-fglrx"

ATI_PROFILE="### START ATI FGLRX ###
### Automatically modified by ATI Proprietary driver scripts
### Please do not modify between START ATI FGLRX and END ATI FGLRX

#setting LD_LIBRARY_PATH is not required for ATI FGLRX
#if [ \$LD_LIBRARY_PATH ]
#then
#  if ! set | grep LD_LIBRARY_PATH | grep ${LDLIBSEARCHPATHX} > /dev/null
#  then
    #LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${LDLIBSEARCHPATHX}       
    #export LD_LIBRARY_PATH
#  fi
#else 
  #LD_LIBRARY_PATH=${LDLIBSEARCHPATHX}
  #export LD_LIBRARY_PATH
#fi

if [ \$LIBGL_DRIVERS_PATH ]
then
  if ! set | grep LIBGL_DRIVERS_PATH | grep ${GLDRISEARCHPATH} > /dev/null
  then
    LIBGL_DRIVERS_PATH=\$LIBGL_DRIVERS_PATH:${GLDRISEARCHPATH}
    export LIBGL_DRIVERS_PATH
  fi
else
  LIBGL_DRIVERS_PATH=${GLDRISEARCHPATH}
  export LIBGL_DRIVERS_PATH
fi

### END ATI FGLRX ###
"

# replaces any previous script if existing
ATI_PROFILE_FILE1="/etc/profile.d/${ATI_PROFILE_FNAME}.sh"
ATI_PROFILE_FILE2="/etc/ati/${ATI_PROFILE_FNAME}.sh"

if [ -d `dirname ${ATI_PROFILE_FILE1}` ];
then
  printf "${ATI_PROFILE}" > ${ATI_PROFILE_FILE1}
  chmod +x ${ATI_PROFILE_FILE1}

elif [ -d `dirname ${ATI_PROFILE_FILE2}` ];
then
  printf "${ATI_PROFILE}" > ${ATI_PROFILE_FILE2}
  chmod +x ${ATI_PROFILE_FILE2}

  PROFILE_COMMENT=" # Do not modify - set by ATI FGLRX"
  PROFILE_LINE="\. /etc/ati/${ATI_PROFILE_FNAME}\.sh ${PROFILE_COMMENT}"
  if ! grep -e "${PROFILE_LINE}" /etc/profile > /dev/null
  then
     PROFILE_LINE=". ${ATI_PROFILE_FILE2} ${PROFILE_COMMENT}"
     printf "${PROFILE_LINE}\n" >> /etc/profile
  fi
fi

#create user profile with write access if user profile does not exist
#or running with force, without preserve
if [ ! -f "${ATI_CONFIG}/atiapfuser.blb" -o "${FORCE_ATI_UNINSTALL}" = "y" ]; then

    rm -f "${ATI_CONFIG}/atiapfuser.blb" 
    touch "${ATI_CONFIG}/atiapfuser.blb"
    chmod a+w "${ATI_CONFIG}/atiapfuser.blb"
fi




###End: post_drv1 ###
###Begin: post_drv2 ###

# manage lib dir contents
XF_BIN=${INSTALLPATH}${ATI_X_BIN}
XF_LIB=${INSTALLPATH}${ATI_XLIB}
XF_LIB32=${INSTALLPATH}${ATI_XLIB_32}
XF_LIB_EXT=${INSTALLPATH}${ATI_X_MODULE}/extensions
XF_LIB_EXT32=${INSTALLPATH}${ATI_XLIB_EXT_32}

USR_LIB=${INSTALLPATH}/usr/${LIB}
USR_LIB32=${INSTALLPATH}/usr/${LIB32}

# cleanup standard symlinks
rm -f $XF_LIB/libGL.so
rm -f $XF_LIB/libGL.so.1
rm -f $USR_LIB/libGL.so
rm -f $USR_LIB/libGL.so.1

# create standard symlinks

#      *** NOTICE ***      #
# If our libGL.so.1.2 changes version, or the GL libraries 
# change, this code becomes obsolete.
  ln -s $XF_LIB/fglrx/fglrx-libGL.so.1.2 $XF_LIB/libGL.so.1.2  
  ln -s $XF_LIB/libGL.so.1.2 $XF_LIB/libGL.so.1
  ln -s $XF_LIB/libGL.so.1 $XF_LIB/libGL.so  
  
#MM creation of sym links
if [ -d $XF_LIB/dri/ ]; then
   ln -s $XF_LIB/libXvBAW.so.1.0 $XF_LIB/dri/fglrx_drv_video.so
fi
  
   if [ "${XF_LIB}" != "${USR_LIB}" ]; then
      ln -s $XF_LIB/fglrx/fglrx-libGL.so.1.2 $USR_LIB/libGL.so.1.2
      ln -s $USR_LIB/libGL.so.1.2 $USR_LIB/libGL.so.1
      ln -s $USR_LIB/libGL.so.1 $USR_LIB/libGL.so

	if [ -d $USR_LIB/dri/ ]; then
	   ln -s $USR_LIB/libXvBAW.so.1.0 $USR_LIB/dri/fglrx_drv_video.so
	fi
    fi

#Create proper sym link to avoid conflict with libglx.so
if [ -e $XF_LIB_EXT/fglrx/fglrx-libglx.so ]; then
  ln -s $XF_LIB_EXT/fglrx/fglrx-libglx.so $XF_LIB_EXT/libglx.so
fi

# cleanup/create symlinks for 32-on-64 only if needed
if [ "$LIB" != "$LIB32" ];
then
  rm -f $XF_LIB32/libGL.so
  rm -f $XF_LIB32/libGL.so.1
  rm -f $USR_LIB32/libGL.so
  rm -f $USR_LIB32/libGL.so.1

  #      *** NOTICE ***      #
  # If our libGL.so.1.2 changes version, or the GL libraries
  # change, this code becomes obsolete.
    ln -s $XF_LIB32/fglrx/fglrx-libGL.so.1.2 $XF_LIB32/libGL.so.1.2
    ln -s $XF_LIB32/libGL.so.1.2 $XF_LIB32/libGL.so.1
    ln -s $XF_LIB32/libGL.so.1 $XF_LIB32/libGL.so

    if [ "${XF_LIB32}" != "${USR_LIB32}" ]; then
        ln -s $XF_LIB32/fglrx/fglrx-libGL.so.1.2 $USR_LIB32/libGL.so.1.2
        ln -s $USR_LIB32/libGL.so.1.2 $USR_LIB32/libGL.so.1
        ln -s $USR_LIB32/libGL.so.1 $USR_LIB32/libGL.so
    fi

  #Create proper sym link to avoid conflict with libglx from Xorg package
  if [ -e $XF_LIB_EXT32/fglrx/fglrx-libglx.so ]; then
    ln -s $XF_LIB_EXT32/fglrx/fglrx-libglx.so $XF_LIB_EXT32/libglx.so
  fi
fi

#MM creation on UB systems
##ToDO:this can be avoided by having proper global variable
if [ `uname -m` = "x86_64" -a \
    -d "/usr/lib/x86_64-linux-gnu" ];
then 
	ln -s /usr/lib/libXvBAW.so.1.0 /usr/lib/x86_64-linux-gnu/dri/fglrx_drv_video.so
elif [ -d "/usr/lib/i386-linux-gnu" ]; 
then
	ln -s /usr/lib/libXvBAW.so.1.0 /usr/lib/i386-linux-gnu/dri/fglrx_drv_video.so
fi

#try to fixup the glx/GL alternative after symlinks created
DisString=`lsb_release -i`
DID=`echo $DisString | awk '{ print $3 }'`
glxSlave="/usr/lib/xorg/modules/linux/libglx.so glx--linux-libglx.so /usr/lib/xorg/modules/extensions/fglrx/fglrx-libglx.so"
i386GLSlave="/usr/lib/i386-linux-gnu/libGL.so.1 glx--libGL.so.1-i386-linux-gnu /usr/lib/i386-linux-gnu/fglrx/fglrx-libGL.so.1.2"
x8664GLSlave="/usr/lib/x86_64-linux-gnu/libGL.so.1 glx--libGL.so.1-x86_64-linux-gnu /usr/lib/fglrx/fglrx-libGL.so.1.2"
x86_64eglslave="/usr/lib/x86_64-linux-gnu/libEGL.so.1 glx--libEGL.so.1-x86_64-linux-gnu /usr/lib/mesa-diverted/x86_64-linux-gnu/libEGL.so.1"

if [ "$DID" = "SteamOS" ]
then
    update-alternatives --install /usr/lib/glx glx /usr/lib/fglrx 99 --slave $glxSlave --slave $i386GLSlave --slave $x8664GLSlave --slave $x86_64eglslave > /dev/null
	update-alternatives --set glx /usr/lib/fglrx > /dev/null
	
	  iglxslave="/usr/lib/xorg/modules/drivers/fglrx_drv.so glx--fglrx_drv.so /usr/lib/fglrx/fglrx_drv.so"
	  i386iGLslave="/usr/lib/i386-linux-gnu/libGL.so.1 glx--libGL.so.1-i386-linux-gnu /usr/lib/mesa-diverted/i386-linux-gnu/libGL.so.1"
	  x8664iGLslave="/usr/lib/x86_64-linux-gnu/libGL.so.1 glx--libGL.so.1-x86_64-linux-gnu /usr/lib/mesa-diverted/x86_64-linux-gnu/libGL.so.1"
	  
	update-alternatives --install /usr/lib/glx glx /usr/lib/fglrx/igpu 90 --slave $iglxslave --slave $i386iGLslave --slave $x8664iGLslave --slave $x86_64eglslave > /dev/null
    update-alternatives --set glx /usr/lib/fglrx/igpu > /dev/null
fi

#for those systems that don't look
/sbin/ldconfig -n ${XF_LIB}

#not really needed? (only libGL, which was manually linked above)
if [ "${LIB}" != "${LIB32}" ]; then
  /sbin/ldconfig -n ${XF_LIB32}
fi

# rebuild any remaining library symlinks
/sbin/ldconfig

#set sticky bit for amd-console-helper
chmod a+s $XF_BIN/amd-console-helper

#reset driver version in database
ATICONFIG_BIN=`which aticonfig` 2> /dev/null
if [ -n "${ATICONFIG_BIN}" -a -x "${ATICONFIG_BIN}" ]; then

   ${ATICONFIG_BIN} --del-pcs-key=LDC,ReleaseVersion > /dev/null 2>&1
   ${ATICONFIG_BIN} --del-pcs-key=LDC,Catalyst_Version > /dev/null 2>&1

fi

###End: post_drv2 ###
exit 0

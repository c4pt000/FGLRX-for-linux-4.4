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

###Begin: pre_drv ###
# manage lib dir contents

  # determine which lib dirs are of relevance in current system
  /sbin/ldconfig -v -N -X 2>/dev/null | sed -e 's/ (.*)$//g' | sed -n -e '/^\/.*:$/s/:$//p' >libdirs.txt


  # remove all invalid paths to simplify the following code    
  found_xf86_libdir=0;
  echo -n >libdirs2.txt
  for libdir in `cat libdirs.txt`;
  do
    if [ -d $libdir ]
    then
      echo $libdir >>libdirs2.txt
    fi
  done
  
  
  # have a look for the directory containing libGL.so
  for libdir in `cat libdirs2.txt`;
  do 
    for libfile in `ls -1 $libdir/libGL.so* 2>/dev/null`;
    do

     libname=`find $libfile -printf %f`

      # If the file is libGL.so, save to /usr/share/ati/libGLdir.txt
      # location is used to restore libGL.so symlink on uninstall
      if [ libname="libGL.so" ]; then
        echo $libdir>/usr/share/ati/libGLdir.txt
      fi

    done
  done
  

  # past installers installed to xorg directory, 
  # need to do some legacy cleanup in those directories
  if [ "${X_LAYOUT}" = "modular" ]
  then
  
      if [ -d "${ATI_XLIB_32}/xorg" ]; 
      then
            echo "${ATI_XLIB_32}/xorg" >> libdirs2.txt
      fi
      
      if [ -d "${ATI_XLIB_64}/xorg" ]; 
      then
          echo "${ATI_XLIB_64}/xorg" >> libdirs2.txt
      fi
  fi
      
 
  
  # browse all dirs and cleanup existing libGL.so* symlinks
  for libdir in `cat libdirs2.txt`;
  do 
    for libfile in `ls -1 $libdir/libGL.so* 2>/dev/null`;
    do

      libname=`find $libfile -printf %f`
      # act on file, depending on its type
      if [ -h $libdir/$libname ]
      then
        # delete symlinks
        rm -f $libdir/$libname 2>/dev/null
      else
        if [ -f $libdir/$libname ]
        then
          # remove/rename regular files
          # depending on backup file
          if [ -e $libdir/FGL.renamed.$libname -a -s $libdir/FGL.renamed.$libname ]
          then
            # if already a backup exists and the size is greater than zero, simply delete the file
            rm -f $libdir/$libname 2>/dev/null
            
          else
              if [ -e $libdir/FGL.renamed.$libname -a  ! -s $libdir/FGL.renamed.$libname ]
              then
                  # backup exists but the size is zero, delete before trying to do a new backup
                  rm -f  $libdir/FGL.renamed.$libname 2>/dev/null
              fi
              
              # if there is no backup then perform a backup
              mv $libdir/$libname $libdir/FGL.renamed.$libname 2>/dev/null
          fi
        else
          echo "[Warning] Driver : lib file ${libdir}/${libname} is of unknown type and therefore not handled." >> ${LOG_FILE}
        fi
      fi
    done
  done

  # cleanup helper files
  rm -f libdirs.txt libdirs2.txt 2>/dev/null

  # we dont intend to make backups of our own previously installed files
  # therefore check if there is NO backup of libGL.so.1.2 and then create a dummy
  # we need to look at the other library naming convention too for libGL - EPR#374554 
  if [ ! -f $XF_LIB/FGL.renamed.libGL.so.1.2  -a ! -f $XF_LIB/FGL.renamed.libGL.so.1.2.0 ];
  then
    touch $XF_LIB/FGL.renamed.libGL.so.1.2 2>/dev/null
  fi

  ###################################################################################
  #prepration for libglx installation. We only have this for 6.8 and higher.
  LIBGLX="libglx.so"
 
  #Determine if there already exists a backup for libglx.so . If so, just delete the current files
  if [ -e $ATI_XLIB_EXT_32/FGL.renamed.$LIBGLX ]; then      
      rm -f $ATI_XLIB_EXT_32/$LIBGLX 2>/dev/null
      rm -f $ATI_XLIB_EXT_32/`echo $LIBGLX | sed -e s/libglx/libglx.fgl/g` 2>/dev/null
  fi

  if [ -e $ATI_XLIB_EXT_64/FGL.renamed.$LIBGLX ]; then
      rm -f $ATI_XLIB_EXT_64/$LIBGLX 2>/dev/null
      rm -f $ATI_XLIB_EXT_64/`echo $LIBGLX | sed -e s/libglx/libglx.fgl/g` 2>/dev/null
  fi

  #Backup original LIBGLX if not already backed up
  if [ ! -f $ATI_XLIB_EXT_32/FGL.renamed.$LIBGLX -a -f $ATI_XLIB_EXT_32/$LIBGLX ]; then
      mv $ATI_XLIB_EXT_32/$LIBGLX $ATI_XLIB_EXT_32/FGL.renamed.$LIBGLX 2>/dev/null
  fi

  if [ ! -f $ATI_XLIB_EXT_64/FGL.renamed.$LIBGLX -a -f $ATI_XLIB_EXT_64/$LIBGLX ]; then
      mv $ATI_XLIB_EXT_64/$LIBGLX $ATI_XLIB_EXT_64/FGL.renamed.$LIBGLX 2>/dev/null
  fi     
 



###End: pre_drv ###
exit 0

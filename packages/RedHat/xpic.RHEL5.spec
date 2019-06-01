#############################################################################
# spec file header                                                          #
#                                                                           #
# Copyright (c) 2008-2009, 2010, 2011, 2012 Advanced Micro Devices, Inc.    #
#                                                                           #
#############################################################################
Name: fglrx_p_i_c
Summary: %ATI_DRIVER_SUMMARY
Version: %ATI_DRIVER_VERSION
Release: %ATI_DRIVER_RELEASE
License: Other License(s), see package
Vendor: %ATI_DRIVER_VENDOR
URL: %ATI_DRIVER_URL
Requires: gcc, make, kernel-devel
Conflicts: fglrx-glc22
Conflicts: fglrx
Conflicts: fglrx64_p_i_c
Group: Servers
ExclusiveArch: i386

# local rpm options
%define __check_files   %{nil}

#############################################################################
# spec file description                                                     #
#############################################################################
%description
%ATI_DRIVER_DESCRIPTION

#############################################################################
# pre install actions                                                       #
#############################################################################
%pre

DRV_RELEASE=%ATI_DRIVER_VERSION

# policy layer initialization
_XVER_USER_SPEC="none"
NO_PRINT="1"
###Begin: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

DetectX()
{
x_binaries="X Xorg"
x_dirs="/usr/X11R6/bin/ /usr/local/bin/ /usr/X11/bin/ /usr/bin/ /bin/"


for the_x_binary in ${x_binaries}; do
    x_full_dirs=""
    for x_tmp in ${x_dirs}; do
        x_full_dirs=${x_full_dirs}" "${x_tmp}${the_x_binary}
    done
    x_full_dirs=${x_full_dirs}" "`which ${the_x_binary}`
    for x_bin in ${x_full_dirs}; do 
        if [ -x ${x_bin} ];
        then
           # try to detect XOrg up to 7.2
           x_ver_num=`${x_bin} -version 2>&1 | grep 'X Window System Version [0-9]\.' | sed -e 's/^.*X Window System Version //' | cut -d' ' -f1`

            if [ -n "$x_ver_num" ]
            then
                X_VERSION="Xorg $x_ver_num"
                x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                x_min=`echo ${x_ver_num} | cut -d '.' -f2`

                if [ ${x_maj} -eq 1 -a ${x_min} -le 3 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"
                    X_VERSION="Xserver $x_ver_num"

                elif [ ${x_maj} -eq 6 -a ${x_min} -eq 9 ]; then
                    x_internal="xpic"
                    X_LAYOUT="monolithic"

                elif [ ${x_maj} -eq 7 -a ${x_min} -le 2 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"

                fi

            fi
        

            if [ -z "${X_VERSION}" ]
            then

              
                # XOrg 7.2 or lower has not been detected, try to detect XOrg 7.3 and greater
                x_ver_num=`${x_bin} -version 2>&1 | grep 'X\.Org X Server [0-9]\.[0-9]' | sed -e 's/^.*X\.Org X Server //'`
                X_VERSION="XServer $x_ver_num"
                	
                if [ "$x_ver_num" ]
                then
                    x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                    x_min=`echo ${x_ver_num} | cut -d '.' -f2`    

		    # Add XServer 1.17 support with user restriction on non-supported version
                    if [ \( ${x_maj} -eq 1 -a ${x_min} -ge 3 \) -a \( ${x_maj} -eq 1 -a ${x_min} -le 18 \) ]; then
                        
                        x_internal="xpic"
                        X_LAYOUT="modular"                        
                    fi
                fi
            fi
        fi
       
        if [ -n "${X_VERSION}" ]
        then
           break
        fi

    done
    
    if [ -n "${X_VERSION}" ]
    then
       break
    fi
done

# Produce the final X version string
if [ -n "${X_VERSION}" ]; then

    if [ "${NO_PRINT}" != "1" ]; then
        echo "X Server: ${X_VERSION}"
    fi
    
    if [ -n "$x_internal" ]; then
        X_VERSION=$x_internal
    fi

fi


}

########################################################################
# Begin of the main script


if [ "${NO_PRINT}" != "1" ]; then
    echo "Detected configuration:"
fi

# Detect system architecture
if [ "${NO_DETECT}" != "1" ]; then
    _ARCH=`uname -m`
fi

if [ "${NO_PRINT}" != "1" ]; then
    case ${_ARCH} in
        i?86)	arch_bits="32-bit";;
        x86_64)	arch_bits="64-bit";;
    esac

    echo "Architecture: ${_ARCH} (${arch_bits})"
fi

# Try to detect version of X, if X_VERSION is not set explicitly by the user
if [ -z "${X_VERSION}" ]; then

    # Detect X version
    if [ "${NO_DETECT}" != "1" ]; then
        DetectX
    
        if [ -z "${X_VERSION}" ]; then
            if [ "${NO_PRINT}" != "1" ]; then
                echo "X Server: unable to detect"
            fi
        elif [ "${_ARCH}" = "x86_64" ]; then
                X_VERSION=${X_VERSION}_64a
                  
        fi
    fi

else
    # If X_VERSION was set by the user, don't try to detect X, just use user's value
    if [ "${NO_PRINT}" != "1" ]; then

        # see --nodetect and --override in check.sh header for explanation
        if [ "${NO_DETECT}" = "1" ]; then
            if [ "${OVERRIDE}" = "1" ]; then
                OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
            else
                OVERRIDE_STRING=""
            fi
        else
            OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
        fi

        if [ -x map_xname.sh ]; then
            echo "X Server${OVERRIDE_STRING}: `./map_xname.sh ${X_VERSION}`"
        else
            echo "X Server${OVERRIDE_STRING}: ${X_VERSION} (lookup failed)"
        fi
    fi
fi

# unset values in case this script is sourced again
unset NO_PRINT
unset NO_DETECT
unset OVERRIDE

###End: check_sh - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###

# Version of the policy interface that this script supports; see WARNING in
#  default_policy.sh header for more details
DEFAULT_POLICY_INTERFACE_VERSION=2

###End: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: printversion - DO NOT REMOVE; used in b30specfile.sh ###
    _XVER_DETECTED=$X_VERSION

    if [ "${_ARCH}" = "x86_64" -a -d "/usr/lib32" ]
    then
        _LIBDIR32=lib32
    else
        _LIBDIR32=lib
    fi

    _UNAME_R=`uname -r`

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details
    POLICY_VERSION="default:v${DEFAULT_POLICY_INTERFACE_VERSION}:${_ARCH}:${_LIBDIR32}:${_XVER_DETECTED}:${_XVER_USER_SPEC}:${_UNAME_R}:${X_LAYOUT}"
###End: printversion - DO NOT REMOVE; used in b30specfile.sh ###
version=${POLICY_VERSION}
###Begin: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details

    INPUT_POLICY_NAME=`echo ${version} | cut -d: -f1`
    INPUT_INTERFACE_VERSION=`echo ${version} | cut -d: -f2`
    ARCH=`echo ${version} | cut -d: -f3`
    LIBDIR32=`echo ${version} | cut -d: -f4`
    XVER_DETECTED=`echo ${version} | cut -d: -f5`
    XVER_USER_SPEC=`echo ${version} | cut -d: -f6`
    UNAME_R=`echo ${version} | cut -d: -f7`
    X_LAYOUT=`echo ${version} | cut -d: -f8`
    REMAINDER=`echo ${version} | cut -d: -f9`

    ### Step 2: ensure variables from version string are sane and compatible ###

    # verify policy name matches the one this script was designed for
    if [ "${INPUT_POLICY_NAME}" != "default" ]
    then
        echo "error: policy '${INPUT_POLICY_NAME}' is not supported."
        exit 1
    fi

    # verify interface version matches the one this script was designed for
    if [ "${INPUT_INTERFACE_VERSION}" != "v${DEFAULT_POLICY_INTERFACE_VERSION}" ]
    then
        echo "error: policy version '${INPUT_INTERFACE_VERSION}' is not supported."
        exit 1
    fi

    # check ARCH for sanity
    case "${ARCH}" in
    i?86 | x86_64)
        ;;
    "")
        echo "error: system architecture cannot be detected."
        exit 1
        ;;
    *)
        echo "error: ${ARCH} system architecture is not supported."
        exit 1
        ;;
    esac

    # check LIBDIR32 for sanity
    if [ "${LIBDIR32}" != "lib" -a "${LIBDIR32}" != "lib32" ]
    then
        echo "error: x86 lib directory '${LIBDIR32}' is invalid."
        exit 1
    fi

    # check XVER_DETECTED for sanity
    echo ${XVER_DETECTED} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_DETECTED} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 ]
    then
        echo "error: Detected X Server version '${XVER_DETECTED}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check XVER_USER_SPEC for sanity
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 -a "${XVER_USER_SPEC}" != "none" ]
    then
        echo "error: User-specified X Server version '${XVER_USER_SPEC}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check UNAME_R for sanity
    if [ -z "${UNAME_R}" ]
    then
        echo "error: kernel version cannot be detected."
        exit 1
    fi

    # check X_LAYOUT for sanity
    if [ -z "${X_LAYOUT}" ]
    then
        echo "error: X modular/monolithic layout cannot be detected."
        exit 1
    fi

    # verify there are no extra fields
    if [ -n "${REMAINDER}" ]
    then
        echo "error: unexpected parameter '${REMAINDER}' passed to installer."
        exit 1
    fi


    ### Step 3: determine variable values based on version string ###

    # determine which XVER will be used as the final X_VERSION
    if [ "${XVER_USER_SPEC}" != "none" ]
    then
        XVER=${XVER_USER_SPEC}
    else
        XVER=${XVER_DETECTED}
    fi
    
    #determine which lib32 and lib64 directory to be using
    if [ "${ARCH}" = "x86_64" -a \
        \( -L "/usr/lib64" -o ! -e "/usr/lib64" \)  -a \
        -d "/usr/lib" ];
    then
        LIBDIR32=lib32
        LIBDIR64=lib
    else
        LIBDIR64=lib64
    fi

    if [ "${X_LAYOUT}" = "modular" ]
    then
        LIB_PREFIX_32=/usr/${LIBDIR32}
        LIB_PREFIX_64=/usr/${LIBDIR64}
        DRV_PREFIX_32=/usr/${LIBDIR32}
        DRV_PREFIX_64=/usr/${LIBDIR64}

        #for some UB systems, require to install into different 32-bit lib path
        if [ "${ARCH}" = "x86_64" -a \
           -d "/usr/lib/x86_64-linux-gnu" ];
        then

           LIB_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_64=/usr/lib/x86_64-linux-gnu

        elif [ -d "/usr/lib/i386-linux-gnu" ];
        then

           DRV_PREFIX_32=/usr/lib/i386-linux-gnu

        fi

        ATI_X_BIN=/usr/bin
        ATI_X11_INCLUDE=/usr/include/X11/extensions

        MOD_PREFIX_32=${LIB_PREFIX_32}/xorg/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/xorg/modules
        
        OPENCL_LIB_32=${LIB_PREFIX_32}

    else
        LIB_PREFIX_32=/usr/X11R6/${LIBDIR32}
        LIB_PREFIX_64=/usr/X11R6/lib64
        DRV_PREFIX_32=/usr/X11R6/lib/modules
        DRV_PREFIX_64=/usr/X11R6/lib64/modules

        ATI_X_BIN=/usr/X11R6/bin
        ATI_X11_INCLUDE=/usr/X11R6/include/X11/extensions
		  	
        MOD_PREFIX_32=${LIB_PREFIX_32}/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/modules
        
        OPENCL_LIB_32=/usr/${LIBDIR32}

    fi

    # set paths specific to the architecture
    if [ "${ARCH}" = "x86_64" ]
    then
        ATI_XLIB=${LIB_PREFIX_64}
        MOD_PREFIX=${MOD_PREFIX_64}

        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=${LIB_PREFIX_64}
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=${DRV_PREFIX_64}/dri
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=${MOD_PREFIX_64}/extensions
        
        ATI_LIB=/usr/share/ati/lib64
        ATI_PX_SUPPORT=/usr/${LIBDIR64}/fglrx
        OPENCL_LIB_64=/usr/${LIBDIR64}

    else
        ATI_XLIB=${LIB_PREFIX_32}
        MOD_PREFIX=${MOD_PREFIX_32}
		  
        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=
        
        ATI_LIB=/usr/share/ati/lib
        ATI_PX_SUPPORT=/usr/lib/fglrx
        OPENCL_LIB_64=
    fi

    # set the variables; we need to do it this way (setting the variables
    #  then printing the variable/value pairs) because the b30specfile.sh needs
    #  the variables set

        ATI_SBIN=/usr/sbin
    ATI_KERN_MOD=/lib/modules/fglrx
      ATI_2D_DRV=${MOD_PREFIX}/drivers
    ATI_X_MODULE=${MOD_PREFIX}
     ATI_DRM_LIB=${MOD_PREFIX}/linux
      ATI_CP_LNK=/usr/share/applications
 ATI_CP_KDE3_LNK=/opt/kde3/share/applnk
  ATI_GL_INCLUDE=/usr/include/GL
  ATI_ATIGL_INCLUDE=/usr/include/ATI/GL
  ATI_CP_KDE_LNK=/usr/share/applnk
         ATI_DOC=/usr/share/doc/ati
      ATI_CP_DOC=${ATI_DOC}
ATI_CP_GNOME_LNK=/usr/share/gnome/apps
        ATI_ICON=/usr/share/icons
         ATI_MAN=/usr/share/man
         ATI_SRC=/usr/src/ati
      ATI_CP_BIN=${ATI_X_BIN}
     ATI_CP_I18N=/usr/share/ati/amdcccle
         ATI_LOG=/usr/share/ati
      ATI_CONFIG=/etc/ati
      OPENCL_BIN=/usr/bin
   OPENCL_CONFIG=/etc/OpenCL/vendors
ATI_SECURITY_CFG=/etc/security/console.apps
      ATI_UNINST=/usr/share/ati

###End: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###


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
#remove any existing install logs to have a clean snapshot
rm -rf ${LOG_FILE} > /dev/null
touch ${LOG_FILE}

###Begin: pre_install_1 - DO NOT REMOVE; used in b30specfile.sh ###
FGLRX_UNINSTALL_SCRIPT="/usr/share/ati/fglrx-uninstall.sh"

if [ -x "${FGLRX_UNINSTALL_SCRIPT}" ]; then
    
    #need to save the log file or will be removed
    TMP_LOGFILE=`mktemp`
    cp -f "${LOG_FILE}" "${TMP_LOGFILE}"
        
    FORCE_ATI_UNINSTALL=Y
    export FORCE_ATI_UNINSTALL
    sh "$FGLRX_UNINSTALL_SCRIPT" >> ${TMP_LOGFILE}
    
    if [ ! -e ${LOG_PATH} ]
    then
        mkdir -p ${LOG_PATH} 2>/dev/null
    fi
    cp -f "${TMP_LOGFILE}" "${LOG_FILE}"
    rm -f "${TMP_LOGFILE}"
        
    result=$?
fi
###End: pre_install_1 - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: pre_install_2 - DO NOT REMOVE; used in b30specfile.sh ###

###Begin: pre_doc2 ###
# backup inst_path_* files in case user wants to go back to a previous profile

  BackupInstPath inst_path_default
  BackupInstPath inst_path_override

###End: pre_doc2 ###
  
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

if [ -z ${DKMS_VER} ]; then
	# No DKMS detected
###Begin: pre_km ###
	# === kernel modules ===
	# stop kernel module
	/sbin/rmmod ${MODULE} 2> /dev/null

	# remove kernel module directory

	# make sure we're not doing "rm -rf /"; that would be bad
	if [ -z "${OS_MOD}" -a -z "${MODULE}" ]
	then
		echo "Error: OS_MOD and MODULE are both empty in pre.sh; aborting" 1>&2
		echo "rm operation to prevent unwanted data loss" 1>&2

		exit 1
	fi
  
	rm -R -f ${OS_MOD}/${MODULE} 2> /dev/null

	# remove kernel module from all existing kernel configurations
	rm -f ${OS_MOD}/*/kernel/drivers/char/drm/${MODULE}*.*o 2> /dev/null
###End: pre_km ###
# No DKMS preinstallation actions required
fi

###Begin: pre_cp ###
# === control panel application === 
# remove any existing version of the control panel binary
# Prior to 8.35 the control panel was called fireglcontrol*.  This app
# is now obsolete and will no longer be built, but we should clean up any
# old references if they are found.
rm -f ${INSTALLPATH}/usr/X11R6/bin/fireglcontrol* > /dev/null
rm -f ${INSTALLPATH}/usr/X11R6/bin/amdcccle > /dev/null

#enable console access for amdcccle-su on a PAM secured system
if [ -e /etc/pam.d/su ]; then
    ln -s /etc/pam.d/su /etc/pam.d/amdcccle-su
fi

###End: pre_cp ###

exit 0;


###End: pre_install_2 - DO NOT REMOVE; used in b30specfile.sh ###


#############################################################################
# post install actions                                                      #
#############################################################################
%post

DRV_RELEASE=%ATI_DRIVER_VERSION

# policy layer initialization
_XVER_USER_SPEC="none"
NO_PRINT="1"
###Begin: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

DetectX()
{
x_binaries="X Xorg"
x_dirs="/usr/X11R6/bin/ /usr/local/bin/ /usr/X11/bin/ /usr/bin/ /bin/"


for the_x_binary in ${x_binaries}; do
    x_full_dirs=""
    for x_tmp in ${x_dirs}; do
        x_full_dirs=${x_full_dirs}" "${x_tmp}${the_x_binary}
    done
    x_full_dirs=${x_full_dirs}" "`which ${the_x_binary}`
    for x_bin in ${x_full_dirs}; do 
        if [ -x ${x_bin} ];
        then
           # try to detect XOrg up to 7.2
           x_ver_num=`${x_bin} -version 2>&1 | grep 'X Window System Version [0-9]\.' | sed -e 's/^.*X Window System Version //' | cut -d' ' -f1`

            if [ -n "$x_ver_num" ]
            then
                X_VERSION="Xorg $x_ver_num"
                x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                x_min=`echo ${x_ver_num} | cut -d '.' -f2`

                if [ ${x_maj} -eq 1 -a ${x_min} -le 3 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"
                    X_VERSION="Xserver $x_ver_num"

                elif [ ${x_maj} -eq 6 -a ${x_min} -eq 9 ]; then
                    x_internal="xpic"
                    X_LAYOUT="monolithic"

                elif [ ${x_maj} -eq 7 -a ${x_min} -le 2 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"

                fi

            fi
        

            if [ -z "${X_VERSION}" ]
            then

              
                # XOrg 7.2 or lower has not been detected, try to detect XOrg 7.3 and greater
                x_ver_num=`${x_bin} -version 2>&1 | grep 'X\.Org X Server [0-9]\.[0-9]' | sed -e 's/^.*X\.Org X Server //'`
                X_VERSION="XServer $x_ver_num"
                	
                if [ "$x_ver_num" ]
                then
                    x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                    x_min=`echo ${x_ver_num} | cut -d '.' -f2`    

		    # Add XServer 1.17 support with user restriction on non-supported version
                    if [ \( ${x_maj} -eq 1 -a ${x_min} -ge 3 \) -a \( ${x_maj} -eq 1 -a ${x_min} -le 18 \) ]; then
                        
                        x_internal="xpic"
                        X_LAYOUT="modular"                        
                    fi
                fi
            fi
        fi
       
        if [ -n "${X_VERSION}" ]
        then
           break
        fi

    done
    
    if [ -n "${X_VERSION}" ]
    then
       break
    fi
done

# Produce the final X version string
if [ -n "${X_VERSION}" ]; then

    if [ "${NO_PRINT}" != "1" ]; then
        echo "X Server: ${X_VERSION}"
    fi
    
    if [ -n "$x_internal" ]; then
        X_VERSION=$x_internal
    fi

fi


}

########################################################################
# Begin of the main script


if [ "${NO_PRINT}" != "1" ]; then
    echo "Detected configuration:"
fi

# Detect system architecture
if [ "${NO_DETECT}" != "1" ]; then
    _ARCH=`uname -m`
fi

if [ "${NO_PRINT}" != "1" ]; then
    case ${_ARCH} in
        i?86)	arch_bits="32-bit";;
        x86_64)	arch_bits="64-bit";;
    esac

    echo "Architecture: ${_ARCH} (${arch_bits})"
fi

# Try to detect version of X, if X_VERSION is not set explicitly by the user
if [ -z "${X_VERSION}" ]; then

    # Detect X version
    if [ "${NO_DETECT}" != "1" ]; then
        DetectX
    
        if [ -z "${X_VERSION}" ]; then
            if [ "${NO_PRINT}" != "1" ]; then
                echo "X Server: unable to detect"
            fi
        elif [ "${_ARCH}" = "x86_64" ]; then
                X_VERSION=${X_VERSION}_64a
                  
        fi
    fi

else
    # If X_VERSION was set by the user, don't try to detect X, just use user's value
    if [ "${NO_PRINT}" != "1" ]; then

        # see --nodetect and --override in check.sh header for explanation
        if [ "${NO_DETECT}" = "1" ]; then
            if [ "${OVERRIDE}" = "1" ]; then
                OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
            else
                OVERRIDE_STRING=""
            fi
        else
            OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
        fi

        if [ -x map_xname.sh ]; then
            echo "X Server${OVERRIDE_STRING}: `./map_xname.sh ${X_VERSION}`"
        else
            echo "X Server${OVERRIDE_STRING}: ${X_VERSION} (lookup failed)"
        fi
    fi
fi

# unset values in case this script is sourced again
unset NO_PRINT
unset NO_DETECT
unset OVERRIDE

###End: check_sh - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###

# Version of the policy interface that this script supports; see WARNING in
#  default_policy.sh header for more details
DEFAULT_POLICY_INTERFACE_VERSION=2

###End: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: printversion - DO NOT REMOVE; used in b30specfile.sh ###
    _XVER_DETECTED=$X_VERSION

    if [ "${_ARCH}" = "x86_64" -a -d "/usr/lib32" ]
    then
        _LIBDIR32=lib32
    else
        _LIBDIR32=lib
    fi

    _UNAME_R=`uname -r`

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details
    POLICY_VERSION="default:v${DEFAULT_POLICY_INTERFACE_VERSION}:${_ARCH}:${_LIBDIR32}:${_XVER_DETECTED}:${_XVER_USER_SPEC}:${_UNAME_R}:${X_LAYOUT}"
###End: printversion - DO NOT REMOVE; used in b30specfile.sh ###
version=${POLICY_VERSION}
###Begin: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details

    INPUT_POLICY_NAME=`echo ${version} | cut -d: -f1`
    INPUT_INTERFACE_VERSION=`echo ${version} | cut -d: -f2`
    ARCH=`echo ${version} | cut -d: -f3`
    LIBDIR32=`echo ${version} | cut -d: -f4`
    XVER_DETECTED=`echo ${version} | cut -d: -f5`
    XVER_USER_SPEC=`echo ${version} | cut -d: -f6`
    UNAME_R=`echo ${version} | cut -d: -f7`
    X_LAYOUT=`echo ${version} | cut -d: -f8`
    REMAINDER=`echo ${version} | cut -d: -f9`

    ### Step 2: ensure variables from version string are sane and compatible ###

    # verify policy name matches the one this script was designed for
    if [ "${INPUT_POLICY_NAME}" != "default" ]
    then
        echo "error: policy '${INPUT_POLICY_NAME}' is not supported."
        exit 1
    fi

    # verify interface version matches the one this script was designed for
    if [ "${INPUT_INTERFACE_VERSION}" != "v${DEFAULT_POLICY_INTERFACE_VERSION}" ]
    then
        echo "error: policy version '${INPUT_INTERFACE_VERSION}' is not supported."
        exit 1
    fi

    # check ARCH for sanity
    case "${ARCH}" in
    i?86 | x86_64)
        ;;
    "")
        echo "error: system architecture cannot be detected."
        exit 1
        ;;
    *)
        echo "error: ${ARCH} system architecture is not supported."
        exit 1
        ;;
    esac

    # check LIBDIR32 for sanity
    if [ "${LIBDIR32}" != "lib" -a "${LIBDIR32}" != "lib32" ]
    then
        echo "error: x86 lib directory '${LIBDIR32}' is invalid."
        exit 1
    fi

    # check XVER_DETECTED for sanity
    echo ${XVER_DETECTED} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_DETECTED} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 ]
    then
        echo "error: Detected X Server version '${XVER_DETECTED}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check XVER_USER_SPEC for sanity
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 -a "${XVER_USER_SPEC}" != "none" ]
    then
        echo "error: User-specified X Server version '${XVER_USER_SPEC}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check UNAME_R for sanity
    if [ -z "${UNAME_R}" ]
    then
        echo "error: kernel version cannot be detected."
        exit 1
    fi

    # check X_LAYOUT for sanity
    if [ -z "${X_LAYOUT}" ]
    then
        echo "error: X modular/monolithic layout cannot be detected."
        exit 1
    fi

    # verify there are no extra fields
    if [ -n "${REMAINDER}" ]
    then
        echo "error: unexpected parameter '${REMAINDER}' passed to installer."
        exit 1
    fi


    ### Step 3: determine variable values based on version string ###

    # determine which XVER will be used as the final X_VERSION
    if [ "${XVER_USER_SPEC}" != "none" ]
    then
        XVER=${XVER_USER_SPEC}
    else
        XVER=${XVER_DETECTED}
    fi
    
    #determine which lib32 and lib64 directory to be using
    if [ "${ARCH}" = "x86_64" -a \
        \( -L "/usr/lib64" -o ! -e "/usr/lib64" \)  -a \
        -d "/usr/lib" ];
    then
        LIBDIR32=lib32
        LIBDIR64=lib
    else
        LIBDIR64=lib64
    fi

    if [ "${X_LAYOUT}" = "modular" ]
    then
        LIB_PREFIX_32=/usr/${LIBDIR32}
        LIB_PREFIX_64=/usr/${LIBDIR64}
        DRV_PREFIX_32=/usr/${LIBDIR32}
        DRV_PREFIX_64=/usr/${LIBDIR64}

        #for some UB systems, require to install into different 32-bit lib path
        if [ "${ARCH}" = "x86_64" -a \
           -d "/usr/lib/x86_64-linux-gnu" ];
        then

           LIB_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_64=/usr/lib/x86_64-linux-gnu

        elif [ -d "/usr/lib/i386-linux-gnu" ];
        then

           DRV_PREFIX_32=/usr/lib/i386-linux-gnu

        fi

        ATI_X_BIN=/usr/bin
        ATI_X11_INCLUDE=/usr/include/X11/extensions

        MOD_PREFIX_32=${LIB_PREFIX_32}/xorg/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/xorg/modules
        
        OPENCL_LIB_32=${LIB_PREFIX_32}

    else
        LIB_PREFIX_32=/usr/X11R6/${LIBDIR32}
        LIB_PREFIX_64=/usr/X11R6/lib64
        DRV_PREFIX_32=/usr/X11R6/lib/modules
        DRV_PREFIX_64=/usr/X11R6/lib64/modules

        ATI_X_BIN=/usr/X11R6/bin
        ATI_X11_INCLUDE=/usr/X11R6/include/X11/extensions
		  	
        MOD_PREFIX_32=${LIB_PREFIX_32}/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/modules
        
        OPENCL_LIB_32=/usr/${LIBDIR32}

    fi

    # set paths specific to the architecture
    if [ "${ARCH}" = "x86_64" ]
    then
        ATI_XLIB=${LIB_PREFIX_64}
        MOD_PREFIX=${MOD_PREFIX_64}

        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=${LIB_PREFIX_64}
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=${DRV_PREFIX_64}/dri
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=${MOD_PREFIX_64}/extensions
        
        ATI_LIB=/usr/share/ati/lib64
        ATI_PX_SUPPORT=/usr/${LIBDIR64}/fglrx
        OPENCL_LIB_64=/usr/${LIBDIR64}

    else
        ATI_XLIB=${LIB_PREFIX_32}
        MOD_PREFIX=${MOD_PREFIX_32}
		  
        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=
        
        ATI_LIB=/usr/share/ati/lib
        ATI_PX_SUPPORT=/usr/lib/fglrx
        OPENCL_LIB_64=
    fi

    # set the variables; we need to do it this way (setting the variables
    #  then printing the variable/value pairs) because the b30specfile.sh needs
    #  the variables set

        ATI_SBIN=/usr/sbin
    ATI_KERN_MOD=/lib/modules/fglrx
      ATI_2D_DRV=${MOD_PREFIX}/drivers
    ATI_X_MODULE=${MOD_PREFIX}
     ATI_DRM_LIB=${MOD_PREFIX}/linux
      ATI_CP_LNK=/usr/share/applications
 ATI_CP_KDE3_LNK=/opt/kde3/share/applnk
  ATI_GL_INCLUDE=/usr/include/GL
  ATI_ATIGL_INCLUDE=/usr/include/ATI/GL
  ATI_CP_KDE_LNK=/usr/share/applnk
         ATI_DOC=/usr/share/doc/ati
      ATI_CP_DOC=${ATI_DOC}
ATI_CP_GNOME_LNK=/usr/share/gnome/apps
        ATI_ICON=/usr/share/icons
         ATI_MAN=/usr/share/man
         ATI_SRC=/usr/src/ati
      ATI_CP_BIN=${ATI_X_BIN}
     ATI_CP_I18N=/usr/share/ati/amdcccle
         ATI_LOG=/usr/share/ati
      ATI_CONFIG=/etc/ati
      OPENCL_BIN=/usr/bin
   OPENCL_CONFIG=/etc/OpenCL/vendors
ATI_SECURITY_CFG=/etc/security/console.apps
      ATI_UNINST=/usr/share/ati

###End: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###


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

CONFIG_INSTALL=""

###################
# POSTINSTALLATION

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


###Begin: post_cp ###

# Workaround for Ubuntu bug (https://launchpad.net/bugs/592671)
# ccc-le shortcuts are not availabe because Ubuntu10.10 does not update menu entries properly
rm -f /usr/share/applications/desktop.*.cache > /dev/null

###End: post_cp ###

# SELinux workaround for RHEL5 only
###Begin: selinux - DO NOT REMOVE; used in b30specfile.sh ###

# Change security context when SELinux secutiry policy is enforcing.
# Source Context:AAsystem_u:system_r:unconfined_t:SystemLow-SystemHigh
# Target Context:AAsystem_u:object_r:lib_t
# Target Objects:AA$USR_LIB/xorg/modules/drivers/fglrx_drv.so, $USR_LIB/libGL.so.1.2, $USR_LIB/dri/fglrx_dri.so
# Affected RPM Packages:AAglibc, gnome-screensaver, xorg-x11-server [application]
# Policy RPM:AAselinux-policy-2.4.6-30.el5
# Selinux Enabled:AATrue
# Policy Type:AAtargeted
# MLS Enabled:AATrue
# Enforcing Mode:AAEnforcing
# Plugin Name:AAplugins.allow_execmod
#
# Allowing access if you trust share library to run correctly, we need to change the file context to textrel_shlib_t.

# is_selinux()
# SE Linux OS detection (RHEL5, RHEL5.x, etc.)
# The function expect the output from ls --context on a distribution with SELinux as the following 5 fields:
# mode        user group security context                file name
# -rw-r--r--  root root root:object_r:usr_t              /usr/share/ati/fglrx-install.log
# The field $4 on SELinux system is security context and on Non-SELinux system $4 is file name
is_selinux()
{
    local fglrx_log='/usr/share/ati/fglrx-install.log'
    ls --context $fglrx_log 2> /dev/null| awk -v logfile=$fglrx_log '{ print ($4 == logfile) ? "non-selinux" : "selinux" }'
}

if [ "${_ARCH}" = "x86_64" ]; then
       SE_USRLIB=/usr/lib64
else
       SE_USRLIB=/usr/lib
fi

    SE_OS=`is_selinux`

if [ "$SE_OS" = "selinux" ]; then
    echo "...."
    #Change security context if SELINUX is not disabled.
    SE_STAT=`getenforce`
    SELINUX_CMD=`which chcon`
    if [ $? = 0 ] && [ "${SE_STAT}" != "Disabled" ]; then
        ${SELINUX_CMD} -t textrel_shlib_t ${SE_USRLIB}/xorg/modules/drivers/fglrx_drv.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/fglrx/fglrx-libGL.so.1.2
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/dri/fglrx_dri.so
        ${SELINUX_CMD} -t textrel_shlib_t ${SE_USRLIB}/xorg/modules/glesx.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libatiadlxx.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libaticaldd.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libAMDXvBA.so.1.0
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libXvBAW.so.1.0
    fi

    #Redhat assumes libGL.so.1.2 of fglrx is at "/usr/lib(64)?/fglrx/libGL\.so(\.[^/]*)*)".
    #Workaround the problem by change file_contexts.local file for Now. May need to contact Redhat.
    CONTEXT_LOCAL="/etc/selinux/targeted/contexts/files/file_contexts.local"
    grep "/usr/lib(64)?/fglrx/fglrx-libGL.so.1.2" ${CONTEXT_LOCAL} >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "/usr/lib(64)?/fglrx/fglrx-libGL.so.1.2 system_u:object_r:textrel_shlib_t:s0" >> ${CONTEXT_LOCAL}
    fi
    grep "/usr/lib(64)?/xorg/modules/glesx.so" ${CONTEXT_LOCAL} >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "/usr/lib(64)?/xorg/modules/glesx.so system_u:object_r:textrel_shlib_t:s0" >> ${CONTEXT_LOCAL}
    fi
fi

echo "[Message] Driver : End of installation " >> ${LOG_FILE}
exit 0;

###End: selinux - DO NOT REMOVE; used in b30specfile.sh ###

#############################################################################
# Verify actions                                                            #
#############################################################################
%verifyscript

# policy layer initialization
_XVER_USER_SPEC="none"
NO_PRINT="1"
###Begin: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

DetectX()
{
x_binaries="X Xorg"
x_dirs="/usr/X11R6/bin/ /usr/local/bin/ /usr/X11/bin/ /usr/bin/ /bin/"


for the_x_binary in ${x_binaries}; do
    x_full_dirs=""
    for x_tmp in ${x_dirs}; do
        x_full_dirs=${x_full_dirs}" "${x_tmp}${the_x_binary}
    done
    x_full_dirs=${x_full_dirs}" "`which ${the_x_binary}`
    for x_bin in ${x_full_dirs}; do 
        if [ -x ${x_bin} ];
        then
           # try to detect XOrg up to 7.2
           x_ver_num=`${x_bin} -version 2>&1 | grep 'X Window System Version [0-9]\.' | sed -e 's/^.*X Window System Version //' | cut -d' ' -f1`

            if [ -n "$x_ver_num" ]
            then
                X_VERSION="Xorg $x_ver_num"
                x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                x_min=`echo ${x_ver_num} | cut -d '.' -f2`

                if [ ${x_maj} -eq 1 -a ${x_min} -le 3 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"
                    X_VERSION="Xserver $x_ver_num"

                elif [ ${x_maj} -eq 6 -a ${x_min} -eq 9 ]; then
                    x_internal="xpic"
                    X_LAYOUT="monolithic"

                elif [ ${x_maj} -eq 7 -a ${x_min} -le 2 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"

                fi

            fi
        

            if [ -z "${X_VERSION}" ]
            then

              
                # XOrg 7.2 or lower has not been detected, try to detect XOrg 7.3 and greater
                x_ver_num=`${x_bin} -version 2>&1 | grep 'X\.Org X Server [0-9]\.[0-9]' | sed -e 's/^.*X\.Org X Server //'`
                X_VERSION="XServer $x_ver_num"
                	
                if [ "$x_ver_num" ]
                then
                    x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                    x_min=`echo ${x_ver_num} | cut -d '.' -f2`    

		    # Add XServer 1.17 support with user restriction on non-supported version
                    if [ \( ${x_maj} -eq 1 -a ${x_min} -ge 3 \) -a \( ${x_maj} -eq 1 -a ${x_min} -le 18 \) ]; then
                        
                        x_internal="xpic"
                        X_LAYOUT="modular"                        
                    fi
                fi
            fi
        fi
       
        if [ -n "${X_VERSION}" ]
        then
           break
        fi

    done
    
    if [ -n "${X_VERSION}" ]
    then
       break
    fi
done

# Produce the final X version string
if [ -n "${X_VERSION}" ]; then

    if [ "${NO_PRINT}" != "1" ]; then
        echo "X Server: ${X_VERSION}"
    fi
    
    if [ -n "$x_internal" ]; then
        X_VERSION=$x_internal
    fi

fi


}

########################################################################
# Begin of the main script


if [ "${NO_PRINT}" != "1" ]; then
    echo "Detected configuration:"
fi

# Detect system architecture
if [ "${NO_DETECT}" != "1" ]; then
    _ARCH=`uname -m`
fi

if [ "${NO_PRINT}" != "1" ]; then
    case ${_ARCH} in
        i?86)	arch_bits="32-bit";;
        x86_64)	arch_bits="64-bit";;
    esac

    echo "Architecture: ${_ARCH} (${arch_bits})"
fi

# Try to detect version of X, if X_VERSION is not set explicitly by the user
if [ -z "${X_VERSION}" ]; then

    # Detect X version
    if [ "${NO_DETECT}" != "1" ]; then
        DetectX
    
        if [ -z "${X_VERSION}" ]; then
            if [ "${NO_PRINT}" != "1" ]; then
                echo "X Server: unable to detect"
            fi
        elif [ "${_ARCH}" = "x86_64" ]; then
                X_VERSION=${X_VERSION}_64a
                  
        fi
    fi

else
    # If X_VERSION was set by the user, don't try to detect X, just use user's value
    if [ "${NO_PRINT}" != "1" ]; then

        # see --nodetect and --override in check.sh header for explanation
        if [ "${NO_DETECT}" = "1" ]; then
            if [ "${OVERRIDE}" = "1" ]; then
                OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
            else
                OVERRIDE_STRING=""
            fi
        else
            OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
        fi

        if [ -x map_xname.sh ]; then
            echo "X Server${OVERRIDE_STRING}: `./map_xname.sh ${X_VERSION}`"
        else
            echo "X Server${OVERRIDE_STRING}: ${X_VERSION} (lookup failed)"
        fi
    fi
fi

# unset values in case this script is sourced again
unset NO_PRINT
unset NO_DETECT
unset OVERRIDE

###End: check_sh - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###

# Version of the policy interface that this script supports; see WARNING in
#  default_policy.sh header for more details
DEFAULT_POLICY_INTERFACE_VERSION=2

###End: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: printversion - DO NOT REMOVE; used in b30specfile.sh ###
    _XVER_DETECTED=$X_VERSION

    if [ "${_ARCH}" = "x86_64" -a -d "/usr/lib32" ]
    then
        _LIBDIR32=lib32
    else
        _LIBDIR32=lib
    fi

    _UNAME_R=`uname -r`

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details
    POLICY_VERSION="default:v${DEFAULT_POLICY_INTERFACE_VERSION}:${_ARCH}:${_LIBDIR32}:${_XVER_DETECTED}:${_XVER_USER_SPEC}:${_UNAME_R}:${X_LAYOUT}"
###End: printversion - DO NOT REMOVE; used in b30specfile.sh ###
version=${POLICY_VERSION}
###Begin: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details

    INPUT_POLICY_NAME=`echo ${version} | cut -d: -f1`
    INPUT_INTERFACE_VERSION=`echo ${version} | cut -d: -f2`
    ARCH=`echo ${version} | cut -d: -f3`
    LIBDIR32=`echo ${version} | cut -d: -f4`
    XVER_DETECTED=`echo ${version} | cut -d: -f5`
    XVER_USER_SPEC=`echo ${version} | cut -d: -f6`
    UNAME_R=`echo ${version} | cut -d: -f7`
    X_LAYOUT=`echo ${version} | cut -d: -f8`
    REMAINDER=`echo ${version} | cut -d: -f9`

    ### Step 2: ensure variables from version string are sane and compatible ###

    # verify policy name matches the one this script was designed for
    if [ "${INPUT_POLICY_NAME}" != "default" ]
    then
        echo "error: policy '${INPUT_POLICY_NAME}' is not supported."
        exit 1
    fi

    # verify interface version matches the one this script was designed for
    if [ "${INPUT_INTERFACE_VERSION}" != "v${DEFAULT_POLICY_INTERFACE_VERSION}" ]
    then
        echo "error: policy version '${INPUT_INTERFACE_VERSION}' is not supported."
        exit 1
    fi

    # check ARCH for sanity
    case "${ARCH}" in
    i?86 | x86_64)
        ;;
    "")
        echo "error: system architecture cannot be detected."
        exit 1
        ;;
    *)
        echo "error: ${ARCH} system architecture is not supported."
        exit 1
        ;;
    esac

    # check LIBDIR32 for sanity
    if [ "${LIBDIR32}" != "lib" -a "${LIBDIR32}" != "lib32" ]
    then
        echo "error: x86 lib directory '${LIBDIR32}' is invalid."
        exit 1
    fi

    # check XVER_DETECTED for sanity
    echo ${XVER_DETECTED} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_DETECTED} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 ]
    then
        echo "error: Detected X Server version '${XVER_DETECTED}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check XVER_USER_SPEC for sanity
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 -a "${XVER_USER_SPEC}" != "none" ]
    then
        echo "error: User-specified X Server version '${XVER_USER_SPEC}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check UNAME_R for sanity
    if [ -z "${UNAME_R}" ]
    then
        echo "error: kernel version cannot be detected."
        exit 1
    fi

    # check X_LAYOUT for sanity
    if [ -z "${X_LAYOUT}" ]
    then
        echo "error: X modular/monolithic layout cannot be detected."
        exit 1
    fi

    # verify there are no extra fields
    if [ -n "${REMAINDER}" ]
    then
        echo "error: unexpected parameter '${REMAINDER}' passed to installer."
        exit 1
    fi


    ### Step 3: determine variable values based on version string ###

    # determine which XVER will be used as the final X_VERSION
    if [ "${XVER_USER_SPEC}" != "none" ]
    then
        XVER=${XVER_USER_SPEC}
    else
        XVER=${XVER_DETECTED}
    fi
    
    #determine which lib32 and lib64 directory to be using
    if [ "${ARCH}" = "x86_64" -a \
        \( -L "/usr/lib64" -o ! -e "/usr/lib64" \)  -a \
        -d "/usr/lib" ];
    then
        LIBDIR32=lib32
        LIBDIR64=lib
    else
        LIBDIR64=lib64
    fi

    if [ "${X_LAYOUT}" = "modular" ]
    then
        LIB_PREFIX_32=/usr/${LIBDIR32}
        LIB_PREFIX_64=/usr/${LIBDIR64}
        DRV_PREFIX_32=/usr/${LIBDIR32}
        DRV_PREFIX_64=/usr/${LIBDIR64}

        #for some UB systems, require to install into different 32-bit lib path
        if [ "${ARCH}" = "x86_64" -a \
           -d "/usr/lib/x86_64-linux-gnu" ];
        then

           LIB_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_64=/usr/lib/x86_64-linux-gnu

        elif [ -d "/usr/lib/i386-linux-gnu" ];
        then

           DRV_PREFIX_32=/usr/lib/i386-linux-gnu

        fi

        ATI_X_BIN=/usr/bin
        ATI_X11_INCLUDE=/usr/include/X11/extensions

        MOD_PREFIX_32=${LIB_PREFIX_32}/xorg/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/xorg/modules
        
        OPENCL_LIB_32=${LIB_PREFIX_32}

    else
        LIB_PREFIX_32=/usr/X11R6/${LIBDIR32}
        LIB_PREFIX_64=/usr/X11R6/lib64
        DRV_PREFIX_32=/usr/X11R6/lib/modules
        DRV_PREFIX_64=/usr/X11R6/lib64/modules

        ATI_X_BIN=/usr/X11R6/bin
        ATI_X11_INCLUDE=/usr/X11R6/include/X11/extensions
		  	
        MOD_PREFIX_32=${LIB_PREFIX_32}/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/modules
        
        OPENCL_LIB_32=/usr/${LIBDIR32}

    fi

    # set paths specific to the architecture
    if [ "${ARCH}" = "x86_64" ]
    then
        ATI_XLIB=${LIB_PREFIX_64}
        MOD_PREFIX=${MOD_PREFIX_64}

        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=${LIB_PREFIX_64}
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=${DRV_PREFIX_64}/dri
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=${MOD_PREFIX_64}/extensions
        
        ATI_LIB=/usr/share/ati/lib64
        ATI_PX_SUPPORT=/usr/${LIBDIR64}/fglrx
        OPENCL_LIB_64=/usr/${LIBDIR64}

    else
        ATI_XLIB=${LIB_PREFIX_32}
        MOD_PREFIX=${MOD_PREFIX_32}
		  
        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=
        
        ATI_LIB=/usr/share/ati/lib
        ATI_PX_SUPPORT=/usr/lib/fglrx
        OPENCL_LIB_64=
    fi

    # set the variables; we need to do it this way (setting the variables
    #  then printing the variable/value pairs) because the b30specfile.sh needs
    #  the variables set

        ATI_SBIN=/usr/sbin
    ATI_KERN_MOD=/lib/modules/fglrx
      ATI_2D_DRV=${MOD_PREFIX}/drivers
    ATI_X_MODULE=${MOD_PREFIX}
     ATI_DRM_LIB=${MOD_PREFIX}/linux
      ATI_CP_LNK=/usr/share/applications
 ATI_CP_KDE3_LNK=/opt/kde3/share/applnk
  ATI_GL_INCLUDE=/usr/include/GL
  ATI_ATIGL_INCLUDE=/usr/include/ATI/GL
  ATI_CP_KDE_LNK=/usr/share/applnk
         ATI_DOC=/usr/share/doc/ati
      ATI_CP_DOC=${ATI_DOC}
ATI_CP_GNOME_LNK=/usr/share/gnome/apps
        ATI_ICON=/usr/share/icons
         ATI_MAN=/usr/share/man
         ATI_SRC=/usr/src/ati
      ATI_CP_BIN=${ATI_X_BIN}
     ATI_CP_I18N=/usr/share/ati/amdcccle
         ATI_LOG=/usr/share/ati
      ATI_CONFIG=/etc/ati
      OPENCL_BIN=/usr/bin
   OPENCL_CONFIG=/etc/OpenCL/vendors
ATI_SECURITY_CFG=/etc/security/console.apps
      ATI_UNINST=/usr/share/ati

###End: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###


#special libGL check to verify if user has changed libGL since install
uninstallResult=0
libGL_file="$ATI_XLIB/libGL.so.1.2"

if [ -L "$libGL_file" -a -e "$libGL_file" ]; then
	   
   #file is a valid symlink, check that it points to either FGL.renamed* 
   #or a file in /fglrx/ folder
   link_result=`readlink -f $libGL_file`
   
   filename_check=`basename $link_result | grep '^FGL.renamed.libGL.so'`
      
   if [ -z "$filename_check" ]; then
      #symlink does not point to FGL.renamed
      #check if it is pointing to the installed libGL.so
      dirname_check=`echo $link_result | grep '/fglrx/fglrx-libGL.so'`
      
      if [ -z "$dirname_check" ]; then
         #symlink does not point to a directory that we installed to
         #and does not point to the backed up file, FGL_Renamed
         #suspect libGL has been changed.
         echo "Symbolic link has been modified, $libGL_file, since last install." >&2
         uninstallResult=1
      fi
      
   fi
elif [ -e "$libGL_file"  ]; then
   echo "File has been modified, $libGL_file, since last install." >&2
   uninstallResult=1     
else
   #file is missing
   echo "File has been removed, $libGL_file, since last install." >&2 
   uninstallResult=1
fi

if [ $uninstallResult -eq 0 ]; then
   exit 0
else
   exit 1
fi

#############################################################################
# pre uninstall actions                                                     #
#############################################################################
%preun

DRV_RELEASE=%ATI_DRIVER_VERSION

# policy layer initialization
_XVER_USER_SPEC="none"
NO_PRINT="1"
###Begin: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

DetectX()
{
x_binaries="X Xorg"
x_dirs="/usr/X11R6/bin/ /usr/local/bin/ /usr/X11/bin/ /usr/bin/ /bin/"


for the_x_binary in ${x_binaries}; do
    x_full_dirs=""
    for x_tmp in ${x_dirs}; do
        x_full_dirs=${x_full_dirs}" "${x_tmp}${the_x_binary}
    done
    x_full_dirs=${x_full_dirs}" "`which ${the_x_binary}`
    for x_bin in ${x_full_dirs}; do 
        if [ -x ${x_bin} ];
        then
           # try to detect XOrg up to 7.2
           x_ver_num=`${x_bin} -version 2>&1 | grep 'X Window System Version [0-9]\.' | sed -e 's/^.*X Window System Version //' | cut -d' ' -f1`

            if [ -n "$x_ver_num" ]
            then
                X_VERSION="Xorg $x_ver_num"
                x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                x_min=`echo ${x_ver_num} | cut -d '.' -f2`

                if [ ${x_maj} -eq 1 -a ${x_min} -le 3 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"
                    X_VERSION="Xserver $x_ver_num"

                elif [ ${x_maj} -eq 6 -a ${x_min} -eq 9 ]; then
                    x_internal="xpic"
                    X_LAYOUT="monolithic"

                elif [ ${x_maj} -eq 7 -a ${x_min} -le 2 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"

                fi

            fi
        

            if [ -z "${X_VERSION}" ]
            then

              
                # XOrg 7.2 or lower has not been detected, try to detect XOrg 7.3 and greater
                x_ver_num=`${x_bin} -version 2>&1 | grep 'X\.Org X Server [0-9]\.[0-9]' | sed -e 's/^.*X\.Org X Server //'`
                X_VERSION="XServer $x_ver_num"
                	
                if [ "$x_ver_num" ]
                then
                    x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                    x_min=`echo ${x_ver_num} | cut -d '.' -f2`    

		    # Add XServer 1.17 support with user restriction on non-supported version
                    if [ \( ${x_maj} -eq 1 -a ${x_min} -ge 3 \) -a \( ${x_maj} -eq 1 -a ${x_min} -le 18 \) ]; then
                        
                        x_internal="xpic"
                        X_LAYOUT="modular"                        
                    fi
                fi
            fi
        fi
       
        if [ -n "${X_VERSION}" ]
        then
           break
        fi

    done
    
    if [ -n "${X_VERSION}" ]
    then
       break
    fi
done

# Produce the final X version string
if [ -n "${X_VERSION}" ]; then

    if [ "${NO_PRINT}" != "1" ]; then
        echo "X Server: ${X_VERSION}"
    fi
    
    if [ -n "$x_internal" ]; then
        X_VERSION=$x_internal
    fi

fi


}

########################################################################
# Begin of the main script


if [ "${NO_PRINT}" != "1" ]; then
    echo "Detected configuration:"
fi

# Detect system architecture
if [ "${NO_DETECT}" != "1" ]; then
    _ARCH=`uname -m`
fi

if [ "${NO_PRINT}" != "1" ]; then
    case ${_ARCH} in
        i?86)	arch_bits="32-bit";;
        x86_64)	arch_bits="64-bit";;
    esac

    echo "Architecture: ${_ARCH} (${arch_bits})"
fi

# Try to detect version of X, if X_VERSION is not set explicitly by the user
if [ -z "${X_VERSION}" ]; then

    # Detect X version
    if [ "${NO_DETECT}" != "1" ]; then
        DetectX
    
        if [ -z "${X_VERSION}" ]; then
            if [ "${NO_PRINT}" != "1" ]; then
                echo "X Server: unable to detect"
            fi
        elif [ "${_ARCH}" = "x86_64" ]; then
                X_VERSION=${X_VERSION}_64a
                  
        fi
    fi

else
    # If X_VERSION was set by the user, don't try to detect X, just use user's value
    if [ "${NO_PRINT}" != "1" ]; then

        # see --nodetect and --override in check.sh header for explanation
        if [ "${NO_DETECT}" = "1" ]; then
            if [ "${OVERRIDE}" = "1" ]; then
                OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
            else
                OVERRIDE_STRING=""
            fi
        else
            OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
        fi

        if [ -x map_xname.sh ]; then
            echo "X Server${OVERRIDE_STRING}: `./map_xname.sh ${X_VERSION}`"
        else
            echo "X Server${OVERRIDE_STRING}: ${X_VERSION} (lookup failed)"
        fi
    fi
fi

# unset values in case this script is sourced again
unset NO_PRINT
unset NO_DETECT
unset OVERRIDE

###End: check_sh - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###

# Version of the policy interface that this script supports; see WARNING in
#  default_policy.sh header for more details
DEFAULT_POLICY_INTERFACE_VERSION=2

###End: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: printversion - DO NOT REMOVE; used in b30specfile.sh ###
    _XVER_DETECTED=$X_VERSION

    if [ "${_ARCH}" = "x86_64" -a -d "/usr/lib32" ]
    then
        _LIBDIR32=lib32
    else
        _LIBDIR32=lib
    fi

    _UNAME_R=`uname -r`

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details
    POLICY_VERSION="default:v${DEFAULT_POLICY_INTERFACE_VERSION}:${_ARCH}:${_LIBDIR32}:${_XVER_DETECTED}:${_XVER_USER_SPEC}:${_UNAME_R}:${X_LAYOUT}"
###End: printversion - DO NOT REMOVE; used in b30specfile.sh ###
version=${POLICY_VERSION}
###Begin: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details

    INPUT_POLICY_NAME=`echo ${version} | cut -d: -f1`
    INPUT_INTERFACE_VERSION=`echo ${version} | cut -d: -f2`
    ARCH=`echo ${version} | cut -d: -f3`
    LIBDIR32=`echo ${version} | cut -d: -f4`
    XVER_DETECTED=`echo ${version} | cut -d: -f5`
    XVER_USER_SPEC=`echo ${version} | cut -d: -f6`
    UNAME_R=`echo ${version} | cut -d: -f7`
    X_LAYOUT=`echo ${version} | cut -d: -f8`
    REMAINDER=`echo ${version} | cut -d: -f9`

    ### Step 2: ensure variables from version string are sane and compatible ###

    # verify policy name matches the one this script was designed for
    if [ "${INPUT_POLICY_NAME}" != "default" ]
    then
        echo "error: policy '${INPUT_POLICY_NAME}' is not supported."
        exit 1
    fi

    # verify interface version matches the one this script was designed for
    if [ "${INPUT_INTERFACE_VERSION}" != "v${DEFAULT_POLICY_INTERFACE_VERSION}" ]
    then
        echo "error: policy version '${INPUT_INTERFACE_VERSION}' is not supported."
        exit 1
    fi

    # check ARCH for sanity
    case "${ARCH}" in
    i?86 | x86_64)
        ;;
    "")
        echo "error: system architecture cannot be detected."
        exit 1
        ;;
    *)
        echo "error: ${ARCH} system architecture is not supported."
        exit 1
        ;;
    esac

    # check LIBDIR32 for sanity
    if [ "${LIBDIR32}" != "lib" -a "${LIBDIR32}" != "lib32" ]
    then
        echo "error: x86 lib directory '${LIBDIR32}' is invalid."
        exit 1
    fi

    # check XVER_DETECTED for sanity
    echo ${XVER_DETECTED} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_DETECTED} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 ]
    then
        echo "error: Detected X Server version '${XVER_DETECTED}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check XVER_USER_SPEC for sanity
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 -a "${XVER_USER_SPEC}" != "none" ]
    then
        echo "error: User-specified X Server version '${XVER_USER_SPEC}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check UNAME_R for sanity
    if [ -z "${UNAME_R}" ]
    then
        echo "error: kernel version cannot be detected."
        exit 1
    fi

    # check X_LAYOUT for sanity
    if [ -z "${X_LAYOUT}" ]
    then
        echo "error: X modular/monolithic layout cannot be detected."
        exit 1
    fi

    # verify there are no extra fields
    if [ -n "${REMAINDER}" ]
    then
        echo "error: unexpected parameter '${REMAINDER}' passed to installer."
        exit 1
    fi


    ### Step 3: determine variable values based on version string ###

    # determine which XVER will be used as the final X_VERSION
    if [ "${XVER_USER_SPEC}" != "none" ]
    then
        XVER=${XVER_USER_SPEC}
    else
        XVER=${XVER_DETECTED}
    fi
    
    #determine which lib32 and lib64 directory to be using
    if [ "${ARCH}" = "x86_64" -a \
        \( -L "/usr/lib64" -o ! -e "/usr/lib64" \)  -a \
        -d "/usr/lib" ];
    then
        LIBDIR32=lib32
        LIBDIR64=lib
    else
        LIBDIR64=lib64
    fi

    if [ "${X_LAYOUT}" = "modular" ]
    then
        LIB_PREFIX_32=/usr/${LIBDIR32}
        LIB_PREFIX_64=/usr/${LIBDIR64}
        DRV_PREFIX_32=/usr/${LIBDIR32}
        DRV_PREFIX_64=/usr/${LIBDIR64}

        #for some UB systems, require to install into different 32-bit lib path
        if [ "${ARCH}" = "x86_64" -a \
           -d "/usr/lib/x86_64-linux-gnu" ];
        then

           LIB_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_64=/usr/lib/x86_64-linux-gnu

        elif [ -d "/usr/lib/i386-linux-gnu" ];
        then

           DRV_PREFIX_32=/usr/lib/i386-linux-gnu

        fi

        ATI_X_BIN=/usr/bin
        ATI_X11_INCLUDE=/usr/include/X11/extensions

        MOD_PREFIX_32=${LIB_PREFIX_32}/xorg/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/xorg/modules
        
        OPENCL_LIB_32=${LIB_PREFIX_32}

    else
        LIB_PREFIX_32=/usr/X11R6/${LIBDIR32}
        LIB_PREFIX_64=/usr/X11R6/lib64
        DRV_PREFIX_32=/usr/X11R6/lib/modules
        DRV_PREFIX_64=/usr/X11R6/lib64/modules

        ATI_X_BIN=/usr/X11R6/bin
        ATI_X11_INCLUDE=/usr/X11R6/include/X11/extensions
		  	
        MOD_PREFIX_32=${LIB_PREFIX_32}/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/modules
        
        OPENCL_LIB_32=/usr/${LIBDIR32}

    fi

    # set paths specific to the architecture
    if [ "${ARCH}" = "x86_64" ]
    then
        ATI_XLIB=${LIB_PREFIX_64}
        MOD_PREFIX=${MOD_PREFIX_64}

        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=${LIB_PREFIX_64}
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=${DRV_PREFIX_64}/dri
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=${MOD_PREFIX_64}/extensions
        
        ATI_LIB=/usr/share/ati/lib64
        ATI_PX_SUPPORT=/usr/${LIBDIR64}/fglrx
        OPENCL_LIB_64=/usr/${LIBDIR64}

    else
        ATI_XLIB=${LIB_PREFIX_32}
        MOD_PREFIX=${MOD_PREFIX_32}
		  
        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=
        
        ATI_LIB=/usr/share/ati/lib
        ATI_PX_SUPPORT=/usr/lib/fglrx
        OPENCL_LIB_64=
    fi

    # set the variables; we need to do it this way (setting the variables
    #  then printing the variable/value pairs) because the b30specfile.sh needs
    #  the variables set

        ATI_SBIN=/usr/sbin
    ATI_KERN_MOD=/lib/modules/fglrx
      ATI_2D_DRV=${MOD_PREFIX}/drivers
    ATI_X_MODULE=${MOD_PREFIX}
     ATI_DRM_LIB=${MOD_PREFIX}/linux
      ATI_CP_LNK=/usr/share/applications
 ATI_CP_KDE3_LNK=/opt/kde3/share/applnk
  ATI_GL_INCLUDE=/usr/include/GL
  ATI_ATIGL_INCLUDE=/usr/include/ATI/GL
  ATI_CP_KDE_LNK=/usr/share/applnk
         ATI_DOC=/usr/share/doc/ati
      ATI_CP_DOC=${ATI_DOC}
ATI_CP_GNOME_LNK=/usr/share/gnome/apps
        ATI_ICON=/usr/share/icons
         ATI_MAN=/usr/share/man
         ATI_SRC=/usr/src/ati
      ATI_CP_BIN=${ATI_X_BIN}
     ATI_CP_I18N=/usr/share/ati/amdcccle
         ATI_LOG=/usr/share/ati
      ATI_CONFIG=/etc/ati
      OPENCL_BIN=/usr/bin
   OPENCL_CONFIG=/etc/OpenCL/vendors
ATI_SECURITY_CFG=/etc/security/console.apps
      ATI_UNINST=/usr/share/ati

###End: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###


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
####################
# PREUNINSTALLATION

###Begin: preun_doc ###
# backup inst_path_* files in case user wants to go back to a previous profile

  BackupInstPath inst_path_default
  BackupInstPath inst_path_override
###End: preun_doc ###

if [ -z ${DKMS_VER} ]; then
###Begin: preun_km ###
	#stop kernel mode driver
	/sbin/rmmod ${MODULE} 2> /dev/null
###End: preun_km ###
#No preuninstallation steps for the DKMS case
fi

exit 0;

#############################################################################
# post uninstall actions                                                    #
#############################################################################
%postun

DRV_RELEASE=%ATI_DRIVER_VERSION

# policy layer initialization
_XVER_USER_SPEC="none"
NO_PRINT="1"
###Begin: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

DetectX()
{
x_binaries="X Xorg"
x_dirs="/usr/X11R6/bin/ /usr/local/bin/ /usr/X11/bin/ /usr/bin/ /bin/"


for the_x_binary in ${x_binaries}; do
    x_full_dirs=""
    for x_tmp in ${x_dirs}; do
        x_full_dirs=${x_full_dirs}" "${x_tmp}${the_x_binary}
    done
    x_full_dirs=${x_full_dirs}" "`which ${the_x_binary}`
    for x_bin in ${x_full_dirs}; do 
        if [ -x ${x_bin} ];
        then
           # try to detect XOrg up to 7.2
           x_ver_num=`${x_bin} -version 2>&1 | grep 'X Window System Version [0-9]\.' | sed -e 's/^.*X Window System Version //' | cut -d' ' -f1`

            if [ -n "$x_ver_num" ]
            then
                X_VERSION="Xorg $x_ver_num"
                x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                x_min=`echo ${x_ver_num} | cut -d '.' -f2`

                if [ ${x_maj} -eq 1 -a ${x_min} -le 3 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"
                    X_VERSION="Xserver $x_ver_num"

                elif [ ${x_maj} -eq 6 -a ${x_min} -eq 9 ]; then
                    x_internal="xpic"
                    X_LAYOUT="monolithic"

                elif [ ${x_maj} -eq 7 -a ${x_min} -le 2 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"

                fi

            fi
        

            if [ -z "${X_VERSION}" ]
            then

              
                # XOrg 7.2 or lower has not been detected, try to detect XOrg 7.3 and greater
                x_ver_num=`${x_bin} -version 2>&1 | grep 'X\.Org X Server [0-9]\.[0-9]' | sed -e 's/^.*X\.Org X Server //'`
                X_VERSION="XServer $x_ver_num"
                	
                if [ "$x_ver_num" ]
                then
                    x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                    x_min=`echo ${x_ver_num} | cut -d '.' -f2`    

		    # Add XServer 1.17 support with user restriction on non-supported version
                    if [ \( ${x_maj} -eq 1 -a ${x_min} -ge 3 \) -a \( ${x_maj} -eq 1 -a ${x_min} -le 18 \) ]; then
                        
                        x_internal="xpic"
                        X_LAYOUT="modular"                        
                    fi
                fi
            fi
        fi
       
        if [ -n "${X_VERSION}" ]
        then
           break
        fi

    done
    
    if [ -n "${X_VERSION}" ]
    then
       break
    fi
done

# Produce the final X version string
if [ -n "${X_VERSION}" ]; then

    if [ "${NO_PRINT}" != "1" ]; then
        echo "X Server: ${X_VERSION}"
    fi
    
    if [ -n "$x_internal" ]; then
        X_VERSION=$x_internal
    fi

fi


}

########################################################################
# Begin of the main script


if [ "${NO_PRINT}" != "1" ]; then
    echo "Detected configuration:"
fi

# Detect system architecture
if [ "${NO_DETECT}" != "1" ]; then
    _ARCH=`uname -m`
fi

if [ "${NO_PRINT}" != "1" ]; then
    case ${_ARCH} in
        i?86)	arch_bits="32-bit";;
        x86_64)	arch_bits="64-bit";;
    esac

    echo "Architecture: ${_ARCH} (${arch_bits})"
fi

# Try to detect version of X, if X_VERSION is not set explicitly by the user
if [ -z "${X_VERSION}" ]; then

    # Detect X version
    if [ "${NO_DETECT}" != "1" ]; then
        DetectX
    
        if [ -z "${X_VERSION}" ]; then
            if [ "${NO_PRINT}" != "1" ]; then
                echo "X Server: unable to detect"
            fi
        elif [ "${_ARCH}" = "x86_64" ]; then
                X_VERSION=${X_VERSION}_64a
                  
        fi
    fi

else
    # If X_VERSION was set by the user, don't try to detect X, just use user's value
    if [ "${NO_PRINT}" != "1" ]; then

        # see --nodetect and --override in check.sh header for explanation
        if [ "${NO_DETECT}" = "1" ]; then
            if [ "${OVERRIDE}" = "1" ]; then
                OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
            else
                OVERRIDE_STRING=""
            fi
        else
            OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
        fi

        if [ -x map_xname.sh ]; then
            echo "X Server${OVERRIDE_STRING}: `./map_xname.sh ${X_VERSION}`"
        else
            echo "X Server${OVERRIDE_STRING}: ${X_VERSION} (lookup failed)"
        fi
    fi
fi

# unset values in case this script is sourced again
unset NO_PRINT
unset NO_DETECT
unset OVERRIDE

###End: check_sh - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###

# Version of the policy interface that this script supports; see WARNING in
#  default_policy.sh header for more details
DEFAULT_POLICY_INTERFACE_VERSION=2

###End: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###
###Begin: printversion - DO NOT REMOVE; used in b30specfile.sh ###
    _XVER_DETECTED=$X_VERSION

    if [ "${_ARCH}" = "x86_64" -a -d "/usr/lib32" ]
    then
        _LIBDIR32=lib32
    else
        _LIBDIR32=lib
    fi

    _UNAME_R=`uname -r`

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details
    POLICY_VERSION="default:v${DEFAULT_POLICY_INTERFACE_VERSION}:${_ARCH}:${_LIBDIR32}:${_XVER_DETECTED}:${_XVER_USER_SPEC}:${_UNAME_R}:${X_LAYOUT}"
###End: printversion - DO NOT REMOVE; used in b30specfile.sh ###
version=${POLICY_VERSION}
###Begin: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###

    # NOTE: increment DEFAULT_POLICY_INTEFACE_VERSION when interface changes;
    #  see WARNING in header of default_policy.sh for details

    INPUT_POLICY_NAME=`echo ${version} | cut -d: -f1`
    INPUT_INTERFACE_VERSION=`echo ${version} | cut -d: -f2`
    ARCH=`echo ${version} | cut -d: -f3`
    LIBDIR32=`echo ${version} | cut -d: -f4`
    XVER_DETECTED=`echo ${version} | cut -d: -f5`
    XVER_USER_SPEC=`echo ${version} | cut -d: -f6`
    UNAME_R=`echo ${version} | cut -d: -f7`
    X_LAYOUT=`echo ${version} | cut -d: -f8`
    REMAINDER=`echo ${version} | cut -d: -f9`

    ### Step 2: ensure variables from version string are sane and compatible ###

    # verify policy name matches the one this script was designed for
    if [ "${INPUT_POLICY_NAME}" != "default" ]
    then
        echo "error: policy '${INPUT_POLICY_NAME}' is not supported."
        exit 1
    fi

    # verify interface version matches the one this script was designed for
    if [ "${INPUT_INTERFACE_VERSION}" != "v${DEFAULT_POLICY_INTERFACE_VERSION}" ]
    then
        echo "error: policy version '${INPUT_INTERFACE_VERSION}' is not supported."
        exit 1
    fi

    # check ARCH for sanity
    case "${ARCH}" in
    i?86 | x86_64)
        ;;
    "")
        echo "error: system architecture cannot be detected."
        exit 1
        ;;
    *)
        echo "error: ${ARCH} system architecture is not supported."
        exit 1
        ;;
    esac

    # check LIBDIR32 for sanity
    if [ "${LIBDIR32}" != "lib" -a "${LIBDIR32}" != "lib32" ]
    then
        echo "error: x86 lib directory '${LIBDIR32}' is invalid."
        exit 1
    fi

    # check XVER_DETECTED for sanity
    echo ${XVER_DETECTED} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_DETECTED} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 ]
    then
        echo "error: Detected X Server version '${XVER_DETECTED}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check XVER_USER_SPEC for sanity
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic_64a$'
    RETVAL64=$?
    echo ${XVER_USER_SPEC} | grep -q -e '^xpic$'
    RETVAL32=$?
    if [ -z "${XVER_DETECTED}" ]
    then
        echo "error: X Server version cannot be detected."
        exit 1

    elif [ ${RETVAL64} -ne 0 -a ${RETVAL32} -ne 0 -a "${XVER_USER_SPEC}" != "none" ]
    then
        echo "error: User-specified X Server version '${XVER_USER_SPEC}' is not supported. Supported versions are X.Org 6.9 or later, up to XServer 1.10"
        exit 1
    fi

    # check UNAME_R for sanity
    if [ -z "${UNAME_R}" ]
    then
        echo "error: kernel version cannot be detected."
        exit 1
    fi

    # check X_LAYOUT for sanity
    if [ -z "${X_LAYOUT}" ]
    then
        echo "error: X modular/monolithic layout cannot be detected."
        exit 1
    fi

    # verify there are no extra fields
    if [ -n "${REMAINDER}" ]
    then
        echo "error: unexpected parameter '${REMAINDER}' passed to installer."
        exit 1
    fi


    ### Step 3: determine variable values based on version string ###

    # determine which XVER will be used as the final X_VERSION
    if [ "${XVER_USER_SPEC}" != "none" ]
    then
        XVER=${XVER_USER_SPEC}
    else
        XVER=${XVER_DETECTED}
    fi
    
    #determine which lib32 and lib64 directory to be using
    if [ "${ARCH}" = "x86_64" -a \
        \( -L "/usr/lib64" -o ! -e "/usr/lib64" \)  -a \
        -d "/usr/lib" ];
    then
        LIBDIR32=lib32
        LIBDIR64=lib
    else
        LIBDIR64=lib64
    fi

    if [ "${X_LAYOUT}" = "modular" ]
    then
        LIB_PREFIX_32=/usr/${LIBDIR32}
        LIB_PREFIX_64=/usr/${LIBDIR64}
        DRV_PREFIX_32=/usr/${LIBDIR32}
        DRV_PREFIX_64=/usr/${LIBDIR64}

        #for some UB systems, require to install into different 32-bit lib path
        if [ "${ARCH}" = "x86_64" -a \
           -d "/usr/lib/x86_64-linux-gnu" ];
        then

           LIB_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_32=/usr/lib/i386-linux-gnu
           DRV_PREFIX_64=/usr/lib/x86_64-linux-gnu

        elif [ -d "/usr/lib/i386-linux-gnu" ];
        then

           DRV_PREFIX_32=/usr/lib/i386-linux-gnu

        fi

        ATI_X_BIN=/usr/bin
        ATI_X11_INCLUDE=/usr/include/X11/extensions

        MOD_PREFIX_32=${LIB_PREFIX_32}/xorg/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/xorg/modules
        
        OPENCL_LIB_32=${LIB_PREFIX_32}

    else
        LIB_PREFIX_32=/usr/X11R6/${LIBDIR32}
        LIB_PREFIX_64=/usr/X11R6/lib64
        DRV_PREFIX_32=/usr/X11R6/lib/modules
        DRV_PREFIX_64=/usr/X11R6/lib64/modules

        ATI_X_BIN=/usr/X11R6/bin
        ATI_X11_INCLUDE=/usr/X11R6/include/X11/extensions
		  	
        MOD_PREFIX_32=${LIB_PREFIX_32}/modules
        MOD_PREFIX_64=${LIB_PREFIX_64}/modules
        
        OPENCL_LIB_32=/usr/${LIBDIR32}

    fi

    # set paths specific to the architecture
    if [ "${ARCH}" = "x86_64" ]
    then
        ATI_XLIB=${LIB_PREFIX_64}
        MOD_PREFIX=${MOD_PREFIX_64}

        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=${LIB_PREFIX_64}
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=${DRV_PREFIX_64}/dri
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=${MOD_PREFIX_64}/extensions
        
        ATI_LIB=/usr/share/ati/lib64
        ATI_PX_SUPPORT=/usr/${LIBDIR64}/fglrx
        OPENCL_LIB_64=/usr/${LIBDIR64}

    else
        ATI_XLIB=${LIB_PREFIX_32}
        MOD_PREFIX=${MOD_PREFIX_32}
		  
        ATI_XLIB_32=${LIB_PREFIX_32}
        ATI_XLIB_64=
        ATI_3D_DRV_32=${DRV_PREFIX_32}/dri
        ATI_3D_DRV_64=
        ATI_XLIB_EXT_32=${MOD_PREFIX_32}/extensions
        ATI_XLIB_EXT_64=
        
        ATI_LIB=/usr/share/ati/lib
        ATI_PX_SUPPORT=/usr/lib/fglrx
        OPENCL_LIB_64=
    fi

    # set the variables; we need to do it this way (setting the variables
    #  then printing the variable/value pairs) because the b30specfile.sh needs
    #  the variables set

        ATI_SBIN=/usr/sbin
    ATI_KERN_MOD=/lib/modules/fglrx
      ATI_2D_DRV=${MOD_PREFIX}/drivers
    ATI_X_MODULE=${MOD_PREFIX}
     ATI_DRM_LIB=${MOD_PREFIX}/linux
      ATI_CP_LNK=/usr/share/applications
 ATI_CP_KDE3_LNK=/opt/kde3/share/applnk
  ATI_GL_INCLUDE=/usr/include/GL
  ATI_ATIGL_INCLUDE=/usr/include/ATI/GL
  ATI_CP_KDE_LNK=/usr/share/applnk
         ATI_DOC=/usr/share/doc/ati
      ATI_CP_DOC=${ATI_DOC}
ATI_CP_GNOME_LNK=/usr/share/gnome/apps
        ATI_ICON=/usr/share/icons
         ATI_MAN=/usr/share/man
         ATI_SRC=/usr/src/ati
      ATI_CP_BIN=${ATI_X_BIN}
     ATI_CP_I18N=/usr/share/ati/amdcccle
         ATI_LOG=/usr/share/ati
      ATI_CONFIG=/etc/ati
      OPENCL_BIN=/usr/bin
   OPENCL_CONFIG=/etc/OpenCL/vendors
ATI_SECURITY_CFG=/etc/security/console.apps
      ATI_UNINST=/usr/share/ati

###End: printpolicy - DO NOT REMOVE; used in b30specfile.sh ###


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
#####################
# POSTUNINSTALLATION

# when this is the last package instance then undo any thing that the installscript did
if [ $1 -eq 0 ];
then
  echo "Detected uninstall of last package instance"
  echo "Restoring system environment..."

###Begin: postun_rn ###

  # === release notes ===
  rm -rf ${INSTALLPATH}${ATI_DOC}/release-notes > /dev/null

###End: postun_rn ###


###Begin: postun_cp ###

  # remove links, icon, and localization files
  rm -f ${INSTALLPATH}${ATI_CP_LNK}/amdcccle.desktop > /dev/null
  rm -f ${INSTALLPATH}${ATI_CP_LNK}/amdccclesu.desktop > /dev/null
  rm -f ${INSTALLPATH}${ATI_ICON}/ccc_large.xpm > /dev/null
  rm -f ${INSTALLPATH}${ATI_CP_I18N}/*.qm > /dev/null
  rmdir --ignore-fail-on-non-empty ${INSTALLPATH}${ATI_CP_I18N} 2>/dev/null
  rmdir --ignore-fail-on-non-empty ${INSTALLPATH}${ATI_LIB} 2>/dev/null

  # remove legacy links and icon for cccle, we should clean up any
  # old references if they are found.
  rm -f ${INSTALLPATH}${ATI_CP_KDE_LNK}/amdcccle.kdelnk > /dev/null
  rm -f ${INSTALLPATH}${ATI_CP_GNOME_LNK}/amdcccle.desktop > /dev/null
  rm -f ${INSTALLPATH}${ATI_ICON}/ccc_small.xpm > /dev/null
  rm -f ${INSTALLPATH}${ATI_CP_KDE3_LNK}/amdcccle_kde3.desktop > /dev/null

  # remove legacy links and icon
  # Prior to 8.35 the control panel was called fireglcontrol*.  This app
  # is now obsolete and will no longer be built, but we should clean up any
  # old references if they are found.
  rm -f ${INSTALLPATH}${ATI_CP_KDE_LNK}/fireglcontrol.kdelnk > /dev/null
  rm -f ${INSTALLPATH}${ATI_CP_GNOME_LNK}/fireglcontrol.desktop > /dev/null
  rm -f ${INSTALLPATH}${ATI_ICON}/ati.xpm > /dev/null
  rm -f ${INSTALLPATH}${ATI_CP_KDE3_LNK}/fireglcontrol_kde3.desktop > /dev/null
  # remove legacy sources
  # Prior to 8.35 the control panel source code had to be included as it
  # used the open version of Qt.  amdcccle doesn't have this requirement so
  # source files are no longer shipped, but we should clean up any old
  # references if they are found.
  rm -f ${INSTALLPATH}${ATI_SRC}/fglrx_panel_sources.tgz > /dev/null

  #remove link created for PAM secured system
  rm -f /etc/pam.d/amdcccle-su > /dev/null


  #Remove MM symlinks on UB systems
  if [ `uname -m` = "x86_64" -a \
    -d "/usr/lib/x86_64-linux-gnu" ];
    then 
	rm -f /usr/lib/x86_64-linux-gnu/dri/fglrx_drv_video.so > /dev/null
  elif [ -d "/usr/lib/i386-linux-gnu" ];
    then
	rm -f /usr/lib/i386-linux-gnu/dri/fglrx_drv_video.so > /dev/null
  fi

  #Remove MM symlinks on non-UB systems
  if [ `uname -m` = "x86_64" -a \
    -d "/usr/lib64/dri" ];
    then 
	rm -f /usr/lib64/dri/fglrx_drv_video.so > /dev/null
  else 
	rm -f /usr/lib/dri/fglrx_drv_video.so > /dev/null
  fi

###End: postun_cp ###

###Begin: postun_km ###
if [ -z ${DKMS_VER} ]; then
  # === kernel module ===
  # remove kernel module directory
  if [ -d ${OS_MOD}/${MODULE} ]; then

		# make sure we're not doing "rm -rf /"; that would be bad
		if [ -z "${OS_MOD}" -a -z "${MODULE}" ]
		then
			echo "Error: OS_MOD and MODULE are both empty in post_un.sh;" 1>&2
			echo "aborting rm operation to prevent unwanted data loss" 1>&2

			exit 1
		fi

    rm -R -f ${OS_MOD}/${MODULE}
  fi
  
  # remove kernel module from all existing kernel configurations
  KernelListFile=/usr/share/ati/KernelVersionList.txt             #File where kernel versions are saved
  if [ -f ${KernelListFile} ]
  then
       for multiKern in `cat ${KernelListFile}`
       do
           rm -f ${multiKern}/${MODULE}*.*o
       done
       rm -f ${KernelListFile}
  fi

  #refresh modules.dep to remove fglrx*.ko link from modules.dep
  /sbin/depmod
else
    dkms remove -m ${MODULE} -v ${DRV_RELEASE} --all --rpm_safe_upgrade > /dev/null
		
    if [ $? -gt 0 ]; then
        echo "Errors during DKMS module removal"
    fi

	# We shouldn't delete module sources from the source tree, because they may be
	# refered by DKMS for other kernels
	##!! However!  We can check status of the module, and if there are no refs, we can delete the source!
    # make sure we're not doing "rm -rf /"; that would be bad
    if [ "/" = "${DKMS_KM_SOURCE}" ]
    then
        echo "Error: DKMS_KM_SOURCE is / in post.sh; aborting rm operation" 1>&2
        echo "to prevent unwanted data loss" 1>&2
        exit 1
    fi

    dkms status -m ${MODULE} | grep -i "${MODULE}"
    if [ $? -ne 0 ];
    then
        rm -R -f ${DKMS_KM_SOURCE} 2> /dev/null        # Clean up contents
    fi

fi

#update the initramfs if applicable
if [ -z "${ATI_PRESERVE}" -o "${ATI_PRESERVE}" != "Y" ]; then
    UpdateInitramfs
fi

# Remove fglrxbuild startup script in case it was never run or failed
FGLRXKO_SCRIPT_NAME="fglrxkobuild"
FGLRXKO_BUILD_SCRIPT="/etc/init.d/${FGLRXKO_SCRIPT_NAME}"

if [ -e /etc/insserv.conf ]; then
    #on SUSE based system, use insserv to create script startup links
    insserv -rf ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null
fi

#must delete script after running insserv and must delete script before running update-rc
rm -f ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null

UPDATE_RC_BIN=`which update-rc.d 2> /dev/null`
if [ $? -eq 0 ] && [ -x "${UPDATE_RC_BIN}" ]; then
    #on debian based system, use update-rc.d was used to create links
    update-rc.d -f ${FGLRXKO_SCRIPT_NAME} remove > /dev/null
fi

# for any links manually created, delete 
rm -f ${FGLRXKO_BUILD_SCRIPT} 2> /dev/null
rm -f /etc/rc[0-5].d/S[0-9][0-9]${FGLRXKO_SCRIPT_NAME} 2> /dev/null


###End: postun_km ###

###Begin: postun_drv ###

  # determine which lib dirs are of relevance in current system
  /sbin/ldconfig -v -N -X 2>/dev/null | sed -e 's/ (.*)$//g' | sed -n -e '/^\/.*:$/s/:$//p' >libdirs.txt

  #for SteamOS, remove alternative link created
  DisString=`lsb_release -i`
  DID=`echo $DisString | awk '{ print $3 }'`

  if [ "$DID" = "SteamOS" ]
  then
    update-alternatives --remove glx /usr/lib/fglrx > /dev/null
  fi

  # remove all invalid paths to simplify the following code  
  # have a look for the XF86 lib dir at the same time
  found_xf86_libdir=0;
  echo -n >libdirs2.txt
  for libdir in `cat libdirs.txt`;
  do
    if [ -d $libdir ]
    then
      echo $libdir >>libdirs2.txt
    fi
  done

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
        rm -f $libdir/$libname
      else
        if [ -f $libdir/$libname ]
        then
          # remove regular files
          rm -f $libdir/$libname
        else
          echo "WARNING: lib file $libdir/$libname"
          echo "is of unknown type and therefore not handled."
        fi
      fi
    done
  done

  # Step 2: restore any "libGL.so*" from XFree86
  # - zero sized files will finally get deleted
  for libdir in `cat libdirs2.txt`;
  do
    for libfile in `ls -1 $libdir/FGL.renamed.libGL.so* 2>/dev/null`;
    do
      libname=`find $libfile -printf %f`
      origlibfile=`echo $libdir/$libname | sed -n -e 's/FGL\.renamed\.//p'`
      origlibname=`echo $libname | sed -n -e 's/FGL\.renamed\.//p'`
      mv $libdir/$libname $libdir/$origlibname
      if [ ! -s $libdir/$origlibname ]
      then
        rm -f $libdir/$origlibname
      fi
    done
  done

  # Step 3: rebuild any library symlinks
  /sbin/ldconfig

  # Ensures correct install of libGL.so symlink
  libdir=`cat /usr/share/ati/libGLdir.txt`
  ln -s $libdir/libGL.so.1 $libdir/libGL.so
  rm /usr/share/ati/libGLdir.txt

  # cleanup helper files
  rm -f libdirs.txt libdirs2.txt
#SLES 12 only we are copying the original xorg.conf for X
if [ -f /etc/ati/NoAMDXorg ] && [ "`cat /etc/*-release | grep -i sles`" ]
then 
	if ! [ -f /etc/X11/xorg.conf ]
	then
		cp /etc/X11/xorg.conf.install /etc/X11/xorg.conf
	fi
	rm -rf /etc/ati/NoAMDXorg
#on other distro when passed with NoAMDXorg, we are not creating xorg.conf file itself, 
#so else, section is not required. Here only delete NoAMDXorg which we have created during installation.
elif [ -f /etc/ati/NoAMDXorg ]; then 
	rm -rf /etc/ati/NoAMDXorg
else 
		  #Normal uninstallation flow
		  # Step X: backup current xconf & restore last .original backup
		  OLD_DIR=`pwd`
		  cd ${INSTALLPATH}/etc/X11/
		  xconf_list="XF86Config
		XF86Config-4
		xorg.conf"

		  for xconf in ${xconf_list}; do
		  if [ -f ${xconf} ]; then
		    count=0
		    #backup last xconf
		    #assume the current xconf has fglrx, backup to <xconf>.fglrx-<#>
		    while [ -f "${xconf}.fglrx-${count}" ]; do
			count=$(( ${count} + 1 ))
		    done
		    cp "${xconf}" "${xconf}.fglrx-${count}"

		    #now restore the last saved non-fglrx
		    count=0
		    while [ -f "${xconf}.original-${count}" ]; do
		       count=$(( ${count} + 1 ))
		    done
		    if [ ${count} -ne 0 ]; then
		      #check if xorg.conf was created by aticonfig because no xorg.conf existed
		      #do not restore the xorg.conf file it the file begins with # NOXORGCONFEXISTED
		      xorg_chk=`head -n 1 < "${xconf}.original-$(( ${count} - 1 ))" | grep '^# NOXORGCONFEXISTED'`
		      if [ -n "${xorg_chk}" ]; then
			 #delete the xorg.conf file
			 rm -f "${xconf}"
		      else
			 #restore the xorg.conf file
			 cp -f "${xconf}.original-$(( ${count} - 1 ))" "${xconf}"
		      fi

		    fi
		  fi
		  done

		  cd ${OLD_DIR}
fi

  # Remove ATI_PROFILE script (from post.sh)
  ATI_PROFILE_FNAME="ati-fglrx"
  PROFILE_COMMENT=" # Do not modify - set by ATI FGLRX"
  PROFILE_LINE="\. /etc/ati/${ATI_PROFILE_FNAME}\.sh ${PROFILE_COMMENT}"
  ATI_PROFILE_FILE1="/etc/profile.d/${ATI_PROFILE_FNAME}.sh"
  ATI_PROFILE_FILE2="/etc/ati/${ATI_PROFILE_FNAME}.sh"

  if [ -w "${ATI_PROFILE_FILE1}" ]; then
    rm -f "${ATI_PROFILE_FILE1}"

  elif [ -w "${ATI_PROFILE_FILE2}" ]; then
    rm -f "${ATI_PROFILE_FILE2}"

    PROFILE_TEMP=`mktemp -t profile_temp.XXXXXX`
    if [ $? -eq 0 ]; then
      # Match tempfile permissions with current profile
      chmod --reference=/etc/profile ${PROFILE_TEMP} 2>/dev/null
      grep -ve "${PROFILE_LINE}" /etc/profile 2>/dev/null > ${PROFILE_TEMP}
      if [ $? -eq 0 ]; then
        mv -f ${PROFILE_TEMP} /etc/profile 2>/dev/null
      fi
    fi

  fi

  #restore original libglx.so
  LIBGLX="libglx.so"

  if [ -f $ATI_XLIB_EXT_32/FGL.renamed.$LIBGLX ]; then
    rm $ATI_XLIB_EXT_32/$LIBGLX 2>/dev/null
    rm $ATI_XLIB_EXT_32/`echo $LIBGLX | sed -e s/libglx/libglx.fgl/g` 2>/dev/null
    mv $ATI_XLIB_EXT_32/FGL.renamed.$LIBGLX $ATI_XLIB_EXT_32/$LIBGLX 2>/dev/null
  fi

  if [ -f $ATI_XLIB_EXT_64/FGL.renamed.$LIBGLX ]; then
    rm $ATI_XLIB_EXT_64/$LIBGLX 2>/dev/null
    rm $ATI_XLIB_EXT_64/`echo $LIBGLX | sed -e s/libglx/libglx.fgl/g` 2>/dev/null
    mv $ATI_XLIB_EXT_64/FGL.renamed.$LIBGLX $ATI_XLIB_EXT_64/$LIBGLX 2>/dev/null
  fi

  # remove docs
  # make sure we're not doing "rm -rf /"; that would be bad
  if [ "${ATI_DOC}" = "/" ]
  then
    echo "Error: ATI_DOC is / in post_un.sh;" 1>&2
    echo "aborting rm operation to prevent unwanted data loss" 1>&2

    exit 1
  fi
  rm -rf ${ATI_DOC} 2>/dev/null

  #remove user applicaion profile if not doing an upgrade
  if [ -z "${ATI_PRESERVE}" -o "${ATI_PRESERVE}" != "Y" ]; then
    rm -f ${ATI_CONFIG}/atiapfuser.blb
  fi

  echo "restore of system environment completed"

###End: postun_drv ###
fi


### RPM-only usage below here ###

# ATI_LOG and license clean up
LIC_PATH=${ATI_LOG}
LIC_FILE=LICENSE.TXT
LOG_FILE=fglrx-install.log

# remove files, ignore nonexisting file, never prompt
if [ -z "${ATI_PRESERVE}" -o "${ATI_PRESERVE}" != "Y" ]; then
rm -f ${ATI_LOG}/${LOG_FILE} 2>/dev/null
fi

rm -f ${LIC_PATH}/${LIC_FILE} 2>/dev/null

#remove ${LOG_PATH}, ignore non-empty directory to avoid removing any non-driver files the user stores in there
rmdir --ignore-fail-on-non-empty ${ATI_LOG} 2>/dev/null

exit 0;

#############################################################################
# file list                                                                 #
# NOTE: Remove the grep -v "fireglcontrol" pipe step below when we no       #
#       longer build the old fireglcontrol panel.  This filter is a         #
#       temporary measure to prevent it from being inadvertently installed. #
#############################################################################
%files


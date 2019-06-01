#!/bin/sh
#
# Copyright (c) 2008-2010, 2011 Advanced Micro Devices, Inc.
#
# WARNING
#   Before editing this file, make sure you are familiar with the purpose of
#   POLICY_INTERFACE_VERSION, described in (TODO: add dev handbook link); if in
#   doubt, increment POLICY_INTERFACE_VERSION whenever you edit this file
#
# Policy layer information:
#  Completion date: August 2006
#  Authors:
#  - Dennis Ng - initial design and implementation
#  - Denver Gingerich - implementation completion, extensive bug fixing
#
# Purpose
#   Provides a default policy for the policy layer in case the distribution the
#   user is running does not yet have a policy designed for it
#
# Usage
#   Implements --iscurrentdistro and --printpolicy as described in
#   README.distro, except --iscurrentdistro is instead called --printversion
#   to differentiate this script from the other policy scripts and because the
#   name "--iscurrentdistro" does not make sense in this setting
#
# Known users:
#   - ati-installer.sh
#   - buildpkg.d/b30specfile.sh

alias echo=/bin/echo

checksh()
{
    . ./check.sh $@
}

###Begin: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###

# Version of the policy interface that this script supports; see WARNING in
#  default_policy.sh header for more details
DEFAULT_POLICY_INTERFACE_VERSION=2

###End: interfaceversion - DO NOT REMOVE; used in b30specfile.sh ###


#Starting point of this script, process the {action} argument

#Requested action
action=$1

case "${action}" in
--printversion)
    _XVER_USER_SPEC="none"

    if [ -n "${X_VERSION}" ]
    then
        _XVER_USER_SPEC=${X_VERSION}
    fi

    X_VERSION=""
    _ARCH=""
    checksh --noprint

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

    echo "distro query result: yes, version: ${POLICY_VERSION}"
    ;;
--printpolicy)

    ### Step 1: extract variables from version string ###

    version=$2

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


    ### Step 4: print detected variable values to standard out ###

printf \
"# X_VERSION and _ARCH set by check.sh
       X_VERSION=${XVER_DETECTED}
           _ARCH=${ARCH}
        X_LAYOUT=${X_LAYOUT}
"

    # determine if user overrode the X_VERSION and output a note if they did
    if [ "${XVER_USER_SPEC}" != "none" ]
    then
printf \
"# user overrode X_VERSION to the following:
       X_VERSION=${XVER_USER_SPEC}
"
    fi

printf "
     ATI_XLIB_32=${ATI_XLIB_32}
     ATI_XLIB_64=${ATI_XLIB_64}
     ATI_XLIB_EXT_32=${ATI_XLIB_EXT_32}
     ATI_XLIB_EXT_64=${ATI_XLIB_EXT_64}
   ATI_3D_DRV_32=${ATI_3D_DRV_32}
   ATI_3D_DRV_64=${ATI_3D_DRV_64}
        ATI_XLIB=${ATI_XLIB}
       ATI_X_BIN=${ATI_X_BIN}
        ATI_SBIN=${ATI_SBIN}
    ATI_KERN_MOD=${ATI_KERN_MOD}
      ATI_2D_DRV=${ATI_2D_DRV}
    ATI_X_MODULE=${ATI_X_MODULE}
     ATI_DRM_LIB=${ATI_DRM_LIB}
      ATI_CP_LNK=${ATI_CP_LNK}
 ATI_CP_KDE3_LNK=${ATI_CP_KDE3_LNK}
  ATI_GL_INCLUDE=${ATI_GL_INCLUDE}
  ATI_ATIGL_INCLUDE=${ATI_ATIGL_INCLUDE}
  ATI_CP_KDE_LNK=${ATI_CP_KDE_LNK}
         ATI_DOC=${ATI_DOC}
      ATI_CP_DOC=${ATI_CP_DOC}
ATI_CP_GNOME_LNK=${ATI_CP_GNOME_LNK}
        ATI_ICON=${ATI_ICON}
         ATI_MAN=${ATI_MAN}
         ATI_SRC=${ATI_SRC}
 ATI_X11_INCLUDE=${ATI_X11_INCLUDE}
      ATI_CP_BIN=${ATI_CP_BIN}
     ATI_CP_I18N=${ATI_CP_I18N}
         ATI_LIB=${ATI_LIB}     
         ATI_LOG=${ATI_LOG}
      ATI_CONFIG=${ATI_CONFIG}
   OPENCL_CONFIG=${OPENCL_CONFIG}
   OPENCL_LIB_32=${OPENCL_LIB_32}
   OPENCL_LIB_64=${OPENCL_LIB_64}
      OPENCL_BIN=${OPENCL_BIN}
ATI_SECURITY_CFG=${ATI_SECURITY_CFG}
  ATI_PX_SUPPORT=${ATI_PX_SUPPORT}
      ATI_UNINST=${ATI_UNINST}
"

    exit 0
    ;;
*|--*)
    echo ${action}: unsupported option passed by ati-installer.sh
    exit 0
    ;;
esac


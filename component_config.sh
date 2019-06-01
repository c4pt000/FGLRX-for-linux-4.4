#!/bin/sh
#
# Copyright (c) 2008-2009, 2010, 2011 Advanced Micro Devices, Inc.
#
# Purpose: 
#   Set variables describing driver components
# Input :  
#   $1      specifies the directory where files from the common and X specific
#           directories where merged prior to calling of this script
#   ATI_*   the ATI_* environment variables must be set before running this
#           script; see the section on the policy layer in README.distro for
#           further information
# Return: 
#   None
#
# Known users:
#   - copy_uninstall_files.sh
#   - lokixml.sh
#   - buildpkg.d/b45verifyfiles.sh

INSTALL_FILES=$1

###############################################################################
# List of components (listed in the order ther will appear in the installer window)

COMPONENTS="doc drv km cp"

###############################################################################
# DOCUMENTATION
# At the moment this includes only various license files.

desc_doc="Install Requirements"
req_doc=true

files_doc=`find                                              \
    ${INSTALL_FILES}${ATI_DOC}/*LICENSE*                    \
-type f | sed -e "s!${INSTALL_FILES}/!!"`

###############################################################################
# DISPLAY AND OPENGL DRIVERS

desc_drv="Display and OpenGL Drivers"
exe_drv="/sbin/\|/bin/\|\.sh$\|switchlib"
req_drv=true

if [ "$CALLED_BY_VERIFY_SCRIPT" = "1" ]
then

  # normal defaults
  LIB_PATHS="
    ${INSTALL_FILES}/usr/lib*/libatical*                         \
    ${INSTALL_FILES}/usr/lib*/libatiuki*                         \
    ${INSTALL_FILES}/usr/lib*/fglrx/switchlib*                   \
    ${INSTALL_FILES}/usr/lib*/libamdocl*                         \
    ${INSTALL_FILES}/usr/lib*/libOpenCL*                         \
    ${INSTALL_FILES}/usr/X11R6/lib*/lib*                         \
    ${INSTALL_FILES}/usr/X11R6/lib*/fglrx/fglrx-lib*             \
    ${INSTALL_FILES}/usr/X11R6/lib*/modules/glesx*               \
    ${INSTALL_FILES}/usr/X11R6/lib*/modules/amdxmm*              \
    ${INSTALL_FILES}/usr/X11R6/lib*/modules/dri/*                \
    ${INSTALL_FILES}/usr/X11R6/lib*/modules/linux/*              \
    ${INSTALL_FILES}/usr/X11R6/lib*/modules/extensions/fglrx/*   \
    ${INSTALL_FILES}/usr/X11R6/lib*/modules/drivers/*.*o         "
else
  
  LIB_PATHS="
    ${INSTALL_FILES}${ATI_DRM_LIB}/lib*                     \
    ${INSTALL_FILES}${ATI_2D_DRV}/*.*o                      \
    ${INSTALL_FILES}${ATI_X_MODULE}/glesx*                  \
    ${INSTALL_FILES}${ATI_X_MODULE}/amdxmm*                 \
    ${INSTALL_FILES}${ATI_XLIB_32}/lib*                     \
    ${INSTALL_FILES}${ATI_XLIB_32}/fglrx/fglrx-lib*         \
    ${INSTALL_FILES}${ATI_PX_SUPPORT}/switchlib*            \
    ${INSTALL_FILES}${ATI_3D_DRV_32}/*                      "
 
  LIBGLX="fglrx-libglx.so"
  if [ ${_ARCH} = "x86_64" ]; then
    LIB_PATHS="${LIB_PATHS}                                 \
      ${INSTALL_FILES}${ATI_XLIB_EXT_64}/fglrx/${LIBGLX}    "
  else
    LIB_PATHS="${LIB_PATHS}                                 \
      ${INSTALL_FILES}${ATI_XLIB_EXT_32}/fglrx/${LIBGLX}    "
  fi 
      
  if ! [ -z "${ATI_XLIB_64}" -a -z "${ATI_3D_DRV_64}" -a -z "${ATI_XLIB_EXT_64}" ]; then
  LIB_PATHS="${LIB_PATHS}                                   \
    ${INSTALL_FILES}${ATI_XLIB_64}/lib*                     \
    ${INSTALL_FILES}${ATI_XLIB_64}/fglrx/fglrx-lib*         \
    ${INSTALL_FILES}${ATI_3D_DRV_64}/*                      "
  fi

fi

files_drv=`find                                             \
    ${INSTALL_FILES}${ATI_DOC}/user-manual/*                \
    ${INSTALL_FILES}${ATI_DOC}/examples/*                   \
    ${INSTALL_FILES}${ATI_DOC}/articles/*                   \
    ${INSTALL_FILES}${ATI_DOC}/*.html                       \
    ${INSTALL_FILES}${ATI_MAN}/*                            \
    ${LIB_PATHS}                                            \
    ${INSTALL_FILES}${ATI_GL_INCLUDE}/*                     \
    ${INSTALL_FILES}${ATI_ATIGL_INCLUDE}/*                  \
    ${INSTALL_FILES}${ATI_X_BIN}/fgl*                       \
    ${INSTALL_FILES}${ATI_X_BIN}/aticonfig                  \
    ${INSTALL_FILES}${ATI_X_BIN}/atiodcli                   \
    ${INSTALL_FILES}${ATI_X_BIN}/atiode                     \
    ${INSTALL_FILES}${ATI_X_BIN}/amd-console-helper         \
    ${INSTALL_FILES}${OPENCL_BIN}/clinfo                    \
    ${INSTALL_FILES}${ATI_SRC}/fglrx_sample_source.tgz      \
    ${INSTALL_FILES}${ATI_SBIN}/*                           \
    ${INSTALL_FILES}/etc/ati/*                              \
    ${INSTALL_FILES}${OPENCL_CONFIG}/amdocl*                \
-type f | sed -e "s!${INSTALL_FILES}/!!"`

# this adds the symlinks created in ati-installer.sh (see "# for Xorg 7...")
if [ "${X_LAYOUT}" = "modular" -a "$CALLED_BY_VERIFY_SCRIPT" != "1" ]
then

    files_drv="${files_drv}                                 \
        `find ${INSTALL_FILES}/usr/X11R6/lib/modules/dri/*  \
        -type l | sed -e "s!${INSTALL_FILES}/!!"`           "

    if [ -n "${ATI_3D_DRV_64}" ]
    then
        files_drv="${files_drv}                                  \
            `find ${INSTALL_FILES}/usr/X11R6/lib64/modules/dri/* \
            -type l | sed -e "s!${INSTALL_FILES}/!!"`            "
    fi
fi

if [ "${X_LAYOUT}" = "monolithic" -a "$CALLED_BY_VERIFY_SCRIPT" != "1" ]
then


    files_drv="${files_drv}                                 \
        `find ${INSTALL_FILES}${OPENCL_LIB_32}/libamdocl*   \
              ${INSTALL_FILES}${OPENCL_LIB_32}/libOpenCL*   \
              ${INSTALL_FILES}${OPENCL_LIB_32}/libamdhsasc*   \
        -type f | sed -e "s!${INSTALL_FILES}/!!"`           "

    if [ -n "${OPENCL_LIB_64}" ]
    then
        files_drv="${files_drv}                             \
        `find ${INSTALL_FILES}${OPENCL_LIB_64}/libamdocl*   \
              ${INSTALL_FILES}${OPENCL_LIB_64}/libOpenCL*   \
              ${INSTALL_FILES}${OPENCL_LIB_64}/libamdhsasc*   \
            -type f | sed -e "s!${INSTALL_FILES}/!!"`       "
    fi

fi


# this adds the amdconfig symlink created in ati-installer.sh
files_drv="${files_drv}                                    \
    `find ${INSTALL_FILES}${ATI_X_BIN}/amdconfig           \
    -type l | sed -e "s!${INSTALL_FILES}/!!"`              "

####################################################################################
# KERNEL MODULE

desc_km="Kernel Module"
exe_km="\.sh"
req_km=true

files_km=`find                                              \
    ${INSTALL_FILES}${ATI_KERN_MOD}/*                       \
    ${INSTALL_FILES}/etc/modprobe.d/blacklist*              \
-type f | sed -e "s!${INSTALL_FILES}/!!"`

###############################################################################
# CONTROL PANEL

desc_cp="AMD Control Center"
exe_cp="/bin/"
req_cp=false

if [ "$CALLED_BY_VERIFY_SCRIPT" = "1" ]
then
  
  LIB_PATHS="${INSTALL_FILES}/usr/share/ati/lib*/libQt*.so* "

else
 
  LIB_PATHS="${INSTALL_FILES}${ATI_LIB}/libQt*.so*          "

fi

#amdcccle security file only for Ubuntu
if [ "`cat /etc/*-release | grep "Ubuntu"`" ]; then 
    AMDCCCLE_POLICY="${INSTALL_FILES}/usr/share/polkit-1/actions/com.ubuntu.amdcccle.pkexec.policy "
fi

files_cp=`find                                              \
    ${INSTALL_FILES}${ATI_CP_LNK}/*                         \
    ${INSTALL_FILES}${ATI_ICON}/*                           \
    ${INSTALL_FILES}${ATI_CP_I18N}/*.qm                     \
    ${INSTALL_FILES}${ATI_CP_BIN}/amdcccle                  \
    ${INSTALL_FILES}${ATI_CP_BIN}/amdxdg-su                 \
    ${INSTALL_FILES}${ATI_CP_BIN}/amdupdaterandrconfig      \
    ${INSTALL_FILES}${ATI_CP_DOC}/ccc_copyrights.txt        \
    ${INSTALL_FILES}${ATI_SECURITY_CFG}/amdcccle-su         \
    ${LIB_PATHS}                                            \
-type f | sed -e "s!${INSTALL_FILES}/!!"`

if [ "`cat /etc/*-release | grep "Ubuntu"`" ] 
then 
        files_cp="${files_cp}                                  \
            `find ${AMDCCCLE_POLICY} -type f | sed -e "s!${INSTALL_FILES}/!!"`            "
fi

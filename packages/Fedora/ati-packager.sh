#!/bin/sh

# Purpose
#   Create packages for Fedora Core and Red Hat Enterprise Linux distributions
#   - Original script provided by ATI Technologies Inc.
#   - Modified for use on Fedora Core and Red Hat Enterprise Linux for ATI
#     Technologies Inc. by Niko Mirthes <nmirthes AT gmail.com>
#   - Thanks to Mike Harris <mharris AT redhat.com> for providing ideas,
#     examples, and advice.
#   - Thanks to the other package maintainers whose ideas I may have borrowed.
#   - Thanks to Michael Larabel <Michael AT Phoronix.com> for testing package
#     builds and ensuring the acpi power management bits work.

# Usage
#   See README.distro document

# Locales
export LANG=C
export LC_ALL=C

# Function: get_supported_packages()
# Purpose: List supported distributions and associated X version
get_supported_packages()
{
  SUPPORTED_DISTROS="FC3 FC4 FC5 FC6 F7 F8 F9 F10 RHEL3 RHEL4"

  for distros in ${SUPPORTED_DISTROS}; do
    echo "${distros}"
  done
}

# Function: build_package()
# Purpose: Build the requested package if supported
build_package()
{
  # Distribution passed to the installer
  distro_name="$1"
  # Current architecture
  release_arch="$(uname -m)"
  # Currently running kernel
  kernel_variant="$(uname -r)"
  # Driver version
  drv_version="$(./ati-packager-helper.sh --version)"
  # Driver release
  drv_release="$(./ati-packager-helper.sh --release)"
  # Relative path to the distribution directory
  rel_distro_dir="$(dirname $0)"
  # Absolute path to the distribution directory
  abs_distro_dir="$(cd ${rel_distro_dir} 2>/dev/null && pwd)"

  # Absolute path of the <installer root> directory
  INSTALLER_ROOT_DIR="$(pwd)"
  # Temporary directory to merge files from the common, arch and x* directories
  TMP_DRV_FILES_DIR=/tmp/ATI-fglrx-${drv_version}-${drv_release}-"$$"-$(id -un)
  # Final spec file as a result of variable substitution
  TMP_PKG_SPEC=${TMP_DRV_FILES_DIR}/SPECS/ATI-fglrx.spec
  # Temporary file to output diagnostics of the package build utility
  TMP_PKG_BUILD_LOG=${TMP_DRV_FILES_DIR}/ATI-fglrx_build.log
  # Script exit code
  EXIT_CODE=0

  # Specify the X release
  case "${distro_name}" in
    RHEL3)         X11_RELEASE='x430';;
    FC3|FC4|RHEL4) X11_RELEASE='x680';;
    FC5)           X11_RELEASE='x700';;
    FC6)           X11_RELEASE='x710';;
    F7|F8)         X11_RELEASE='x710';;
    F9|F10)        X11_RELEASE='x740';;
  esac

  # Detect the target architecture
  if [ "${release_arch}" = 'x86_64' ]; then
    ARCH=x86_64
    ARCH_DIR=x86_64
    ARCH_LIB=lib64
    X11_RELEASE=${X11_RELEASE}_64a
  else
    ARCH=i386
    ARCH_DIR=x86
    ARCH_LIB=lib
  fi

  # Fail if the Linux kernel headers aren't found
  if [ ! -e /lib/modules/${kernel_variant}/build/include/linux/version.h ]; then
    echo "Please install an appropriate Linux kernel module build package."
    echo "The package(s) you need are likely kernel-devel and/or kernel-headers."
    echo "If you've compiled a custom kernel, make sure /usr/src/linux exists"
    echo "and the source tree matches the currently running kernel."
    exit 1
  fi

  # [Re]create the merging directory, or clean it up
  rm -rf ${TMP_DRV_FILES_DIR} &> /dev/null
  mkdir ${TMP_DRV_FILES_DIR}

  # Create an RPM build tree
  mkdir -p ${TMP_DRV_FILES_DIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS,tmp}

  # Package specification file for the requested package
  PKG_SPEC=${abs_distro_dir}/ATI-fglrx.spec

  # Merge files from different source directories
  TMP_RPM_BUILD_DIR=${TMP_DRV_FILES_DIR}/BUILD/ATI-fglrx-${drv_version}

  mkdir -p ${TMP_RPM_BUILD_DIR}
  cp -pR ${INSTALLER_ROOT_DIR}/common/* ${TMP_RPM_BUILD_DIR}
  cp -pR ${INSTALLER_ROOT_DIR}/arch/${ARCH_DIR}/* ${TMP_RPM_BUILD_DIR}
  cp -pR ${INSTALLER_ROOT_DIR}/${X11_RELEASE}/* ${TMP_RPM_BUILD_DIR}

  # Move files as required for X11R7-based distribution releases
  if echo "${X11_RELEASE}"|grep "x7.0" &> /dev/null ; then
    # get rid of libdri.so so we don't conflict with system package!
    rm -rf ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/modules/extensions
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/include/X11 \
       ${TMP_RPM_BUILD_DIR}/usr/include
    mkdir -p ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/dri
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/modules/dri/* \
       ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/dri
    mkdir -p ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/xorg/modules
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/modules/{drivers,linux} \
       ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/xorg/modules
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/modules/esut.a \
       ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/xorg/modules
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/modules/glesx.so \
       ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/xorg/modules
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/modules/amdxmm.so \
       ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/xorg/modules
      # ln -s ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/dri/fglrx_dri.so ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/lib/modules/dri/fglrx_dri.so
      ln -fs ../../../../${ARCH_LIB}/dri/fglrx_dri.so
    # Same work around for 32-on-64
    if [ "${release_arch}" = 'x86_64' ]; then
      mkdir -p ${TMP_RPM_BUILD_DIR}/usr/lib/dri
      mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/lib/modules/dri/* \
       ${TMP_RPM_BUILD_DIR}/usr/lib/dri
      ln -fs ../../../../lib/dri/fglrx_dri.so
      popd &> /dev/null
    fi
  fi

  # Create the directory for the OpenGL libraries on all releases
  mkdir -p ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/fglrx
  mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/${ARCH_LIB}/lib* \
     ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/fglrx

  # Create some symlinks so the package owns and will remove them on package removal
  pushd ${TMP_RPM_BUILD_DIR}/usr/${ARCH_LIB}/fglrx &> /dev/null
  ln -s libGL.so.1.2 libGL.so
  ln -s libGL.so.1.2 libGL.so.1
  ln -s libfglrx_dm.so.1.0 libfglrx_dm.so.1
  ln -s libfglrx_gamma.so.1.0 libfglrx_gamma.so.1
  ln -s libfglrx_pp.so.1.0 libfglrx_pp.so.1
  ln -s libfglrx_tvout.so.1.0 libfglrx_tvout.so.1
  popd &> /dev/null

  # Support 32 bit OpenGL apps on x86_64
  if [ "${release_arch}" = 'x86_64' ]; then
    mkdir -p ${TMP_RPM_BUILD_DIR}/usr/lib/fglrx
    mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/lib/*.so.* \
       ${TMP_RPM_BUILD_DIR}/usr/lib/fglrx
    pushd ${TMP_RPM_BUILD_DIR}/usr/lib/fglrx &> /dev/null
    ln -fs libGL.so.1.2 libGL.so.1
    popd &> /dev/null
  fi

  # Move the binaries to /usr/bin instead of /usr/X11R6/bin
  mkdir -p ${TMP_RPM_BUILD_DIR}/usr/bin
  mv ${TMP_RPM_BUILD_DIR}/usr/X11R6/bin/* \
     ${TMP_RPM_BUILD_DIR}/usr/bin

  # Rename the system information script
  mv ${TMP_RPM_BUILD_DIR}/usr/sbin/atigetsysteminfo.sh \
     ${TMP_RPM_BUILD_DIR}/usr/sbin/atigetsysteminfo

  # Move the icon to the pixmaps directory
  mv ${TMP_RPM_BUILD_DIR}/usr/share/icons \
     ${TMP_RPM_BUILD_DIR}/usr/share/pixmaps

  # Move source examples to docs
  mkdir -p ${TMP_RPM_BUILD_DIR}/usr/share/doc/fglrx/examples/source
  mv ${TMP_RPM_BUILD_DIR}/usr/src/ati/* \
     ${TMP_RPM_BUILD_DIR}/usr/share/doc/fglrx/examples/source

  # Move the docs to the expected location
  mv ${TMP_RPM_BUILD_DIR}/usr/share/doc/fglrx \
     ${TMP_RPM_BUILD_DIR}/usr/share/doc/ATI-fglrx-$(./ati-packager-helper.sh --version)

  # Copy atieventsd init script
  mkdir -p ${TMP_RPM_BUILD_DIR}/etc/rc.d/init.d
  cp ${abs_distro_dir}/atieventsd.init ${TMP_RPM_BUILD_DIR}/etc/rc.d/init.d/atieventsd

  # Change the path to gdm's Xauth file to suit Fedora Core
  sed -i 's|GDM_AUTH_FILE=/var/lib/gdm/$1.Xauth|GDM_AUTH_FILE=/var/gdm/$1.Xauth|' ${TMP_RPM_BUILD_DIR}/etc/ati/authatieventsd.sh

  # Copy ACPI PowerPlay script
  mkdir -p ${TMP_RPM_BUILD_DIR}/etc/acpi/{actions,events}
  cp ${abs_distro_dir}/ati-powermode.sh ${TMP_RPM_BUILD_DIR}/etc/acpi/actions/ati-powermode.sh
  cp ${abs_distro_dir}/a-ac-aticonfig ${TMP_RPM_BUILD_DIR}/etc/acpi/events/a-ac-aticonfig.conf
  cp ${abs_distro_dir}/a-lid-aticonfig ${TMP_RPM_BUILD_DIR}/etc/acpi/events/a-lid-aticonfig.conf

  # If this is X11R7, most of /usr/X11R6 is empty at this point
  if echo "${X11_RELEASE}"|grep "x7.0" &> /dev/null ; then
    rm -rf ${TMP_RPM_BUILD_DIR}/usr/X11R6/bin \
           ${TMP_RPM_BUILD_DIR}/usr/X11R6/include
  fi

  # Clean up a bit
  rm -rf ${TMP_RPM_BUILD_DIR}/usr/share/applnk \
         ${TMP_RPM_BUILD_DIR}/usr/share/gnome \
         ${TMP_RPM_BUILD_DIR}/usr/src \
         ${TMP_RPM_BUILD_DIR}/opt

  # Clean up any pre-existing spec file
  rm -f ${abs_distro_dir}/ATI-fglrx.spec

  # The spec file and it's template for the requested distribution
  SPECFILE=${abs_distro_dir}/ATI-fglrx.spec
  SPECTMPL=$SPECFILE-tmpl

  # Some variables based on the specified distribution release and it's X version
  case "${distro_name}" in
    FC3|FC4|RHEL3|RHEL4)
      X11_MODULE_DIR="%{_x11libdir}/modules"
      X11_INCLUDE_DIR="%{_x11includedir}"
      OGL_32_ON_64="%{_x11moddir32bit}"
      ICD_PATH_BUG=""
      ICD_PATH_BUG_32=""
    ;;
    FC5|FC6|F7|F8|F9|F10)
      DRI_MODULE_DIR="%{_libdir}/dri"
      X11_MODULE_DIR="%{_libdir}/xorg/modules"
      X11_INCLUDE_DIR="%{_includedir}"
      OGL_32_ON_64="%{_moddir32bit}"
      ICD_PATH_BUG_32="%{_x11moddir32bit}/*"
    ;;
  esac

  # Lower the case of the distribution release tag
  case "${distro_name}" in
    FC3|FC4|FC5|FC6|F7|F8|F9|F10) RH_RELEASE_TAG="$(echo ${distro_name}|tr A-Z a-z)";;
    RHEL3|RHEL4) RH_RELEASE_TAG="$(echo ${distro_name}|tr A-Z a-z|cut -c 3-)";;
  esac

  # Substitute the above variables in the spec file
  sed -f - ${SPECTMPL} > ${SPECFILE} <<END_SED_SCRIPT
s!@RH_RELEASE_TAG@!${RH_RELEASE_TAG}!g
s!@DRI_MODULE_DIR@!${DRI_MODULE_DIR}!g
s!@X11_MODULE_DIR@!${X11_MODULE_DIR}!g
s!@X11_INCLUDE_DIR@!${X11_INCLUDE_DIR}!g
s!@OGL_32_ON_64@!${OGL_32_ON_64}!g
s!@ICD_PATH_BUG@!${ICD_PATH_BUG}!g
s!@ICD_PATH_BUG_32@!${ICD_PATH_BUG_32}!g
END_SED_SCRIPT

  # Substitute ATI's variables in the spec file
  sed -f - ${PKG_SPEC} > ${TMP_PKG_SPEC} <<END_SED_SCRIPT
s!%ATI_DRIVER_VERSION!`./ati-packager-helper.sh --version`!g
s!%ATI_DRIVER_RELEASE!`./ati-packager-helper.sh --release`!g
s!%ATI_DRIVER_DESCRIPTION!`./ati-packager-helper.sh --description`!g
s!%ATI_DRIVER_URL!`./ati-packager-helper.sh --url`!g
s!%ATI_DRIVER_VENDOR!`./ati-packager-helper.sh --vendor`!g
s!%ATI_DRIVER_SUMMARY!`./ati-packager-helper.sh --summary`!g
END_SED_SCRIPT

  # Build the packages
  rpmbuild -bb --define "_topdir ${TMP_DRV_FILES_DIR}" \
               --define "_builddir ${TMP_DRV_FILES_DIR}/BUILD" \
               --define "_rpmdir ${TMP_DRV_FILES_DIR}/RPMS" \
               --define "_sourcedir ${TMP_DRV_FILES_DIR}/SOURCES" \
               --define "_specdir ${TMP_DRV_FILES_DIR}/SPECS" \
               --define "_srcrpmdir ${TMP_DRV_FILES_DIR}/SRPMS" \
               --define "_tmppath ${TMP_DRV_FILES_DIR}/tmp" \
               --define "_rpmfilename  %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" \
               --target ${ARCH} ${TMP_PKG_SPEC} > ${TMP_PKG_BUILD_LOG} 2>&1

  # Retrieve the absolute path to the resulting packages
  if [ $? -eq 0 ]; then
    # Remove the useless debuginfo packages
    rm -f ${TMP_DRV_FILES_DIR}/RPMS/*debuginfo*.rpm
    package_file=$(ls ${TMP_DRV_FILES_DIR}/RPMS/*rpm)
  else
    EXIT_CODE=1
  fi

  # Post build diagnostics and processing
  if [ ${EXIT_CODE} -eq 0 ]; then
    # Absolute path to the installer parent directory
    abs_installer_parent_dir=$(cd ${INSTALLER_ROOT_DIR}/.. 2>/dev/null && pwd)
    for pkg in ${package_file}; do
      # Copy the created package to the same directory as the installer
      cp ${pkg} ${abs_installer_parent_dir}
      echo "Package ${abs_installer_parent_dir}/$(basename ${pkg}) has been successfully generated"
    done
  else
    echo "Package build failed!"
    echo "Package build utility output:"
    cat ${TMP_PKG_BUILD_LOG}
    EXIT_CODE=1
  fi

  # Clean up
  rm -rf ${TMP_DRV_FILES_DIR} &> /dev/null
  rm -f ${abs_distro_dir}/ATI-fglrx.spec &> /dev/null

  exit ${EXIT_CODE}
}


# Starting point of this script, process the {action} argument

# Requested action
action=$1

case "${action}" in
--get-supported)
    get_supported_packages
    ;;
--buildpkg)
    package=$2
    if [ "${package}" != "" ]
    then
        support_flag=false
        for supported_list in `get_supported_packages`
        do
            if [ "${supported_list}" = "${package}" ]
            then
                support_flag=true
                break
            fi
        done
        if [ "${support_flag}" = "true" ]
        then
            build_package ${package}
        else
            echo "Requested package is not supported."
        fi
    else
            echo "Please provide package name"
    fi
    exit 0
    ;;
*|--*)
    echo ${action}: unsupported option passed by ati-installer.sh
    exit 0
    ;;
esac

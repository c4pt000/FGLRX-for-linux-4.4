#############################################################################
# spec file header                                                          #
#############################################################################

Name:           %PACKAGE_NAME
Summary:        %AMD_DRIVER_SUMMARY
Version:        %AMD_DRIVER_VERSION
Release:        %AMD_DRIVER_RELEASE
License:        %AMD_DRIVER_VENDOR
URL:            %AMD_DRIVER_URL
Group:          Servers
PreReq:         %insserv_prereq %fillup_prereq
Requires:       %PACKAGE_NAME_CORE = %{version}-%{release}
Requires:       %PACKAGE_NAME_GRAPHICS = %{version}-%{release}
Requires:       %PACKAGE_NAME_AMDCCCLE = %{version}-%{release}
Requires:       %PACKAGE_NAME_OPENCL = %{version}-%{release}
%if 0%{?suse_version} >= 1315
Requires(post):  update-alternatives
Requires(preun): update-alternatives
%endif
Provides:       fglrx km_fglrx
Obsoletes:      fglrx km_fglrx ati-fglrxG02 x11-video-fglrxG02
Obsoletes:      fglrx_6_9_0_SLE10 fglrx64_6_9_0_SLE10 fglrx_7_4_0_SLE11 fglrx64_7_4_0_SLE11
Obsoletes:      fglrx_7_4_0_SUSE111 fglrx64_7_4_0_SUSE111 fglrx_7_4_0_SUSE112 fglrx64_7_4_0_SUSE112 fglrx_7_5_0_SUSE113 fglrx64_7_5_0_SUSE113 fglrx_7_6_0_SUSE114 fglrx64_7_6_0_SUSE114
%if %suse_version > 1010
Obsoletes:      fglrx_core_SLE10 fglrx64_core_SLE10 fglrx_xpic_SLE10 fglrx64_xpic_SLE10
%if %suse_version > 1110
Obsoletes:      fglrx_core_SUSE111 fglrx64_core_SUSE111 fglrx_core_SLE11 fglrx64_core_SLE11 fglrx_xpic_SUSE111 fglrx64_xpic_SUSE111 fglrx_xpic_SLE11 fglrx64_xpic_SLE11
%if %suse_version > 1120
Obsoletes:      fglrx_core_SUSE112 fglrx64_core_SUSE112 fglrx_xpic_SUSE112 fglrx64_xpic_SUSE112
%if %suse_version > 1130
Obsoletes:      fglrx_core_SUSE113 fglrx64_core_SUSE113 fglrx_xpic_SUSE113 fglrx64_xpic_SUSE113
%if %suse_version > 1140
Obsoletes:      fglrx_core_SUSE114 fglrx64_core_SUSE114 fglrx_xpic_SUSE114 fglrx64_xpic_SUSE114
%if %suse_version > 1210
Obsoletes:      fglrx_core_SUSE121 fglrx64_core_SUSE121 fglrx_xpic_SUSE121 fglrx64_xpic_SUSE121
%if %suse_version > 1220
Obsoletes:      fglrx_core_SUSE122 fglrx64_core_SUSE122 fglrx_xpic_SUSE122 fglrx64_xpic_SUSE122
%if %suse_version > 1230
Obsoletes:      fglrx_core_SUSE123 fglrx64_core_SUSE123 fglrx_xpic_SUSE123 fglrx64_xpic_SUSE123
%if %suse_version > 1310
Obsoletes:      fglrx_core_SUSE131 fglrx64_core_SUSE131 fglrx_xpic_SUSE131 fglrx64_xpic_SUSE131
%if %suse_version > 1320
Obsoletes:      fglrx_core_SUSE132 fglrx64_core_SUSE132 fglrx_xpic_SUSE132 fglrx64_xpic_SUSE132
%endif
%endif
%endif
%endif
%endif
%endif
%endif
%endif
%endif
%endif
ExclusiveArch:  %ix86 x86_64
BuildRoot:      %AMD_DRIVER_BUILD_ROOT

%global _privatelibs libQtCore|libQtGui
%global __provides_exclude ^(%{_privatelibs})\\.so.*$
%global __requires_exclude ^(%{_privatelibs})\\.so.*$

%if %suse_version > 1010
%define MODULES_DIR       /usr/%{_lib}/xorg/modules
%define DRI_DRIVERS_DIR   /usr/%{_lib}/dri
%define DRI_DRIVERS32_DIR /usr/lib/dri
%else
%define MODULES_DIR       /usr/X11R6/%{_lib}/modules
%define DRI_DRIVERS_DIR   /usr/X11R6/%{_lib}/modules/dri
%define DRI_DRIVERS32_DIR /usr/X11R6/lib/modules/dri
%endif
%if 0%{?suse_version} >= 1315
%define MOD_UPDATES_DIR   .
%else
%define MOD_UPDATES_DIR   updates
%endif

# local rpm options
%define __check_files   %{nil}

#############################################################################
# spec file description                                                     #
#############################################################################
%description
This package is a meta package to installed fglrx-core,
fglrx-graphics, fglrx-amdcccle and fglrx-opencl.

%package -n %PACKAGE_NAME_CORE
Requires:       gcc make patch %AMD_DRIVER_KERNEL_DEVEL
Summary:        fglrx core package
Group:          Servers

%description -n %PACKAGE_NAME_CORE
The fglrx core package contains the fglrx kernel module and the
automatic kernel module rebuild script

%package -n %PACKAGE_NAME_GRAPHICS
Requires:       %PACKAGE_NAME_CORE = %{version}-%{release}
Summary:        fglrx graphics package
Group:          Servers

%description -n %PACKAGE_NAME_GRAPHICS
The fglrx graphics package contains X.Org Server related display driver
with the AMD OpenGL driver.

%package -n %PACKAGE_NAME_AMDCCCLE
Requires:       %PACKAGE_NAME_CORE = %{version}-%{release}
Requires:       %PACKAGE_NAME_GRAPHICS = %{version}-%{release}
Summary:        fglrx amdcccle package
Group:          Servers

%description -n %PACKAGE_NAME_AMDCCCLE
The fglrx amdcccle package contains the AMD Catalyst Control Center

%package -n %PACKAGE_NAME_OPENCL
Requires:       %PACKAGE_NAME_CORE = %{version}-%{release}
Summary:        fglrx opencl package
Group:          Servers

%description -n %PACKAGE_NAME_OPENCL
The fglrx opencl package contains the OpenCL driver

%install
%if %suse_version > 1110
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT
cp -a %AMD_DRIVER_BUILD_ROOT/* $RPM_BUILD_ROOT
%endif
tmpdir=$(mktemp -d /tmp/amd_fglrx.XXXXXX)
mkdir $tmpdir/fglrx
mv $RPM_BUILD_ROOT/* $tmpdir/fglrx
#
mkdir -p $RPM_BUILD_ROOT/etc/ati \
         $RPM_BUILD_ROOT/etc/init.d \
         $RPM_BUILD_ROOT/etc/modprobe.d \
         $RPM_BUILD_ROOT/etc/OpenCL/vendors \
         $RPM_BUILD_ROOT/etc/pam.d \
         $RPM_BUILD_ROOT/etc/security/console.apps \
         $RPM_BUILD_ROOT/usr/X11R6/%{_lib}/fglrx \
%ifarch x86_64
         $RPM_BUILD_ROOT/usr/X11R6/lib/fglrx \
%endif
         $RPM_BUILD_ROOT/usr/bin \
         $RPM_BUILD_ROOT/usr/include/ATI/GL \
         $RPM_BUILD_ROOT/usr/include/GL \
         $RPM_BUILD_ROOT%{DRI_DRIVERS_DIR} \
%ifarch x86_64
         $RPM_BUILD_ROOT%{DRI_DRIVERS32_DIR} \
         $RPM_BUILD_ROOT/usr/lib \
%endif
         $RPM_BUILD_ROOT/usr/%{_lib}/fglrx \
         $RPM_BUILD_ROOT%{MODULES_DIR}/{linux,drivers} \
         $RPM_BUILD_ROOT%{MODULES_DIR}/%{MOD_UPDATES_DIR}/extensions/fglrx \
         $RPM_BUILD_ROOT/usr/sbin \
         $RPM_BUILD_ROOT/usr/share/applications \
         $RPM_BUILD_ROOT/usr/share/ati/{amdcccle,%{_lib}} \
         $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-amdcccle \
         $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-core/patches \
         $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-graphics/{articles,user-manual} \
         $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-meta \
         $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-opencl \
         $RPM_BUILD_ROOT/usr/share/man/man8 \
         $RPM_BUILD_ROOT/usr/share/pixmaps \
         $RPM_BUILD_ROOT/usr/src/kernel-modules/fglrx/2.6.x \
         $RPM_BUILD_ROOT/var/adm/fillup-templates \
#         $RPM_BUILD_ROOT/usr/%{_lib}/fglrx/lib \
pushd $tmpdir/fglrx
    install -m 644 etc/ati/* \
                   $RPM_BUILD_ROOT/etc/ati
    install -m 755 etc/ati/authatieventsd.sh \
                   $RPM_BUILD_ROOT/etc/ati
    install -m 755 etc/init.d/* \
                   $RPM_BUILD_ROOT/etc/init.d
    ln -s /etc/init.d/atieventsd $RPM_BUILD_ROOT/usr/sbin/rcatieventsd
    install -m 644 etc/OpenCL/vendors/* \
                   $RPM_BUILD_ROOT/etc/OpenCL/vendors
    install -m 644 etc/modprobe.d/* \
                   $RPM_BUILD_ROOT/etc/modprobe.d
    ln -s su $RPM_BUILD_ROOT/etc/pam.d/amdcccle-su
    install -m 755 etc/security/console.apps/amdcccle-su \
                   $RPM_BUILD_ROOT/etc/security/console.apps
    install -m 755 usr/X11R6/%{_lib}/fglrx/* \
                   $RPM_BUILD_ROOT/usr/X11R6/%{_lib}/fglrx
    rm -rf usr/X11R6/%{_lib}/fglrx
    install -m 755 usr/X11R6/%{_lib}/* \
                   $RPM_BUILD_ROOT/usr/X11R6/%{_lib}
    ln -s libfglrx_dm.so.1.0 $RPM_BUILD_ROOT/usr/X11R6/%{_lib}/libfglrx_dm.so.1
    ln -s libfglrx_dm.so.1 $RPM_BUILD_ROOT/usr/X11R6/%{_lib}/libfglrx_dm.so
%ifarch x86_64
    install -m 755 usr/X11R6/lib/fglrx/* \
                   $RPM_BUILD_ROOT/usr/X11R6/lib/fglrx
    rm -rf usr/X11R6/lib/fglrx
    install -m 755 usr/X11R6/lib/* \
                   $RPM_BUILD_ROOT/usr/X11R6/lib
    ln -s libfglrx_dm.so.1.0 $RPM_BUILD_ROOT/usr/X11R6/lib/libfglrx_dm.so.1
    ln -s libfglrx_dm.so.1 $RPM_BUILD_ROOT/usr/X11R6/lib/libfglrx_dm.so
%endif
    install -m 755 usr/bin/* \
                   $RPM_BUILD_ROOT/usr/bin
    chmod ug+s $RPM_BUILD_ROOT/usr/bin/amd-console-helper
    ln -s aticonfig $RPM_BUILD_ROOT/usr/bin/amdconfig
    install -m 644 usr/include/ATI/GL/* \
                   $RPM_BUILD_ROOT/usr/include/ATI/GL
    install -m 644 usr/include/GL/* \
                   $RPM_BUILD_ROOT/usr/include/GL
    install -m 755 usr/%{_lib}/dri/* \
                   $RPM_BUILD_ROOT%{DRI_DRIVERS_DIR}
    rm -rf usr/%{_lib}/dri
    install -m 755 usr/%{_lib}/fglrx/* \
                   $RPM_BUILD_ROOT/usr/%{_lib}/fglrx
    rm -rf usr/%{_lib}/fglrx
    install -m 755 usr/%{_lib}/xorg/modules/drivers/* \
                   $RPM_BUILD_ROOT%{MODULES_DIR}/drivers
    install -m 755 usr/%{_lib}/xorg/modules/linux/* \
                   $RPM_BUILD_ROOT%{MODULES_DIR}/linux
    install -m 755 usr/%{_lib}/xorg/modules/updates/extensions/fglrx/* \
                   $RPM_BUILD_ROOT%{MODULES_DIR}/%{MOD_UPDATES_DIR}/extensions/fglrx
    rm -rf usr/%{_lib}/xorg/modules/{drivers,linux,updates}
    install -m 755 usr/%{_lib}/xorg/modules/* \
                   $RPM_BUILD_ROOT%{MODULES_DIR}
    rm -rf usr/%{_lib}/xorg
    install -m 755 usr/%{_lib}/* \
                   $RPM_BUILD_ROOT/usr/%{_lib}
    ln -s libAMDXvBA.so.1.0 $RPM_BUILD_ROOT/usr/%{_lib}/libAMDXvBA.so.1
    ln -s libAMDXvBA.so.1 $RPM_BUILD_ROOT/usr/%{_lib}/libAMDXvBA.so
    ln -s libXvBAW.so.1.0 $RPM_BUILD_ROOT/usr/%{_lib}/libXvBAW.so.1
    ln -s libXvBAW.so.1 $RPM_BUILD_ROOT/usr/%{_lib}/libXvBAW.so
    ln -s libatiuki.so.1.0 $RPM_BUILD_ROOT/usr/%{_lib}/libatiuki.so.1
    ln -s libatiuki.so.1 $RPM_BUILD_ROOT/usr/%{_lib}/libatiuki.so
    ln -s libOpenCL.so.1 $RPM_BUILD_ROOT/usr/%{_lib}/libOpenCL.so
%ifarch x86_64
    install -m 755 usr/lib/dri/* \
                   $RPM_BUILD_ROOT%{DRI_DRIVERS32_DIR}
    rm -rf usr/lib/dri
    install -m 755 usr/lib/* \
                   $RPM_BUILD_ROOT/usr/lib
    ln -s libAMDXvBA.so.1.0 $RPM_BUILD_ROOT/usr/lib/libAMDXvBA.so.1
    ln -s libAMDXvBA.so.1 $RPM_BUILD_ROOT/usr/lib/libAMDXvBA.so
    ln -s libXvBAW.so.1.0 $RPM_BUILD_ROOT/usr/lib/libXvBAW.so.1
    ln -s libXvBAW.so.1 $RPM_BUILD_ROOT/usr/lib/libXvBAW.so
    ln -s libatiuki.so.1.0 $RPM_BUILD_ROOT/usr/lib/libatiuki.so.1
    ln -s libatiuki.so.1 $RPM_BUILD_ROOT/usr/lib/libatiuki.so
    ln -s libOpenCL.so.1 $RPM_BUILD_ROOT/usr/lib/libOpenCL.so
%endif
    install -m 755 usr/sbin/* \
                   $RPM_BUILD_ROOT/usr/sbin
    install -m 644 usr/share/applications/* \
                   $RPM_BUILD_ROOT/usr/share/applications
    echo "GenericName=AMD Catalyst Control Center" >> $RPM_BUILD_ROOT/usr/share/applications/amdcccle.desktop
    echo "X-SuSE-translate=false" >> $RPM_BUILD_ROOT/usr/share/applications/amdcccle.desktop
    echo "GenericName=AMD Catalyst Control Center (Administrative)" >> $RPM_BUILD_ROOT/usr/share/applications/amdccclesu.desktop
    echo "X-SuSE-translate=false" >> $RPM_BUILD_ROOT/usr/share/applications/amdccclesu.desktop
    install -m 755 usr/share/ati/amd-uninstall.sh \
                   $RPM_BUILD_ROOT/usr/share/ati
    install -m 755 usr/share/ati/amdcccle/* \
                   $RPM_BUILD_ROOT/usr/share/ati/amdcccle
    install -m 755 usr/share/ati/%{_lib}/* \
                   $RPM_BUILD_ROOT/usr/share/ati/%{_lib}
    install -m 644 usr/share/doc/packages/fglrx-amdcccle/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-amdcccle
    install -m 644 usr/share/doc/packages/fglrx-core/patches/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-core/patches
    rm -rf usr/share/doc/packages/fglrx-core/patches
    install -m 644 usr/share/doc/packages/fglrx-core/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-core
    install -m 644 usr/share/doc/packages/fglrx-graphics/articles/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-graphics/articles
    install -m 644 usr/share/doc/packages/fglrx-graphics/user-manual/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-graphics/user-manual
    rm -rf usr/share/doc/packages/fglrx-graphics/{articles,user-manual}
    install -m 644 usr/share/doc/packages/fglrx-graphics/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-graphics
    install -m 644 usr/share/doc/packages/fglrx-meta/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-meta
    install -m 644 usr/share/doc/packages/fglrx-opencl/* \
                   $RPM_BUILD_ROOT/usr/share/doc/packages/fglrx-opencl
    test -f usr/share/man/man8/atieventsd.8 && \
        gzip usr/share/man/man8/atieventsd.8 && \
        test -f usr/share/man/man8/atieventsd.8.gz && \
        install -m 644 usr/share/man/man8/atieventsd.8.gz \
                       $RPM_BUILD_ROOT/usr/share/man/man8
    install -m 644 usr/share/pixmaps/* \
                   $RPM_BUILD_ROOT/usr/share/pixmaps
    install -m 644 usr/src/kernel-modules/fglrx/2.6.x/* \
                   $RPM_BUILD_ROOT/usr/src/kernel-modules/fglrx/2.6.x
    rm -rf usr/src/kernel-modules/fglrx/2.6.x
    install -m 644 usr/src/kernel-modules/fglrx/* \
                   $RPM_BUILD_ROOT/usr/src/kernel-modules/fglrx
    install -m 644 var/adm/fillup-templates/sysconfig.fglrxconfig \
                   $RPM_BUILD_ROOT/var/adm/fillup-templates/sysconfig.fglrxconfig
popd
rm -rf $tmpdir
export NO_BRP_CHECK_RPATH=true

%post -n %PACKAGE_NAME_CORE
%run_ldconfig
if [ -f etc/sysconfig/fglrxconfig-oldconfig ]; then
    mv -f etc/sysconfig/fglrxconfig-oldconfig etc/sysconfig/fglrxconfig
fi
%{fillup_only -n fglrxconfig}
CURRENT_PATH=`pwd`
pushd /usr/src/kernel-modules/fglrx
# add kernel patches here
echo "Apply some patches ..."
%if %suse_version > 1030
    patch -p0 -s < /usr/share/doc/packages/fglrx-core/patches/ati-CONFIG_SMP.patch
    if [ $? -eq 0 ]; then
        echo "ati-CONFIG_SMP.patch applied successfully."
    else
        echo "ati-CONFIG_SMP.patch could not applied! Please report this bug to Sebastian Siebert <freespacer@gmx.de>. Thank you."
    fi
%endif
%if %suse_version > 1100
    patch -p0 -s < /usr/share/doc/packages/fglrx-core/patches/ati-2.6.27-build-fix-1.patch
    if [ $? -eq 0 ]; then
        echo "ati-2.6.27-build-fix-1.patch applied successfully."
    else
        echo "ati-2.6.27-build-fix-1.patch could not applied! Please report this bug to Sebastian Siebert <freespacer@gmx.de>. Thank you."
    fi
%endif
%if %suse_version > 1100
    patch -p0 -s < /usr/share/doc/packages/fglrx-core/patches/ati-2.6.36-compat_alloc_user_space.patch
    if [ $? -eq 0 ]; then
        echo "ati-2.6.36-compat_alloc_user_space.patch applied successfully."
    else
        echo "ati-2.6.36-compat_alloc_user_space.patch could not applied! Please report this bug to Sebastian Siebert <freespacer@gmx.de>. Thank you."
    fi
%endif
# placeholder_for_additional_patches_for_fglrx_sources
rm -f *.orig
popd
if [ -x etc/init.d/boot.fglrxrebuild ]; then
    # Create symbolic run level links for boot.fglrxrebuild start script:
    %{fillup_and_insserv -Y boot.fglrxrebuild}
fi
usr/bin/fglrx-kernel-build.sh -f -a
if [ $? -ne 0 ]; then
    echo 
    echo "**************************************************************"
    echo "Building/installation of fglrx kernel module failed! Try again"
    echo "by calling \"/usr/bin/fglrx-kernel-build.sh\" manually."
    echo "**************************************************************"
    echo 
fi
echo
echo "*************************************************************"
echo "Please read \"/usr/share/doc/packages/fglrx-core/README.SuSE\" for"
echo "configuration details when using SaX2."
echo "*************************************************************"
echo
# recreate initrd without KMS, if the use of KMS is enabled in initrd
# The developer of openSUSE 12.1 changed the name of KMS configuration.
# In the future we should add a switch for openSUSE 12.1. Currently
# both variable are used.
if grep -q '^NO_KMS_IN_INITRD=\"no\"' /etc/sysconfig/kernel; then
    echo "Disable KMS to prevent driver issue:"
    sed -i 's/^NO_KMS_IN_INITRD.*/NO_KMS_IN_INITRD="yes"/g' /etc/sysconfig/kernel
    mkinitrd
fi
if grep -q '^KMS_IN_INITRD=\"yes\"' /etc/sysconfig/kernel; then
    echo "Disable KMS to prevent driver issue:"
    sed -i 's/^KMS_IN_INITRD.*/KMS_IN_INITRD="no"/g' /etc/sysconfig/kernel
    mkinitrd
fi
# no *KMS_IN_INITRD in /etc/sysconfig/kernel any longer on sle12 and openSUSE 13.2
%if 0%{?suse_version} >= 1315
    mkinitrd
%endif
if [ ! -f "etc/ati/atiapfuser.blb" ]; then
    touch etc/ati/atiapfuser.blb
fi
exit 0

%post -n %PACKAGE_NAME_GRAPHICS
INSTALL_PARAM=$1
%run_ldconfig
if [ -x etc/init.d/atieventsd ]; then
    # Create symbolic run level links for atieventsd start script:
    %{fillup_and_insserv -y atieventsd}
fi
%if %suse_version < 1110
    if [ -r /etc/powersave/events ]; then
        grep -q "EVENT_DAEMON_SCHEME_CHANGE=.*ati-powermode.sh" /etc/powersave/events || \
            sed -e 's/\(EVENT_DAEMON_SCHEME_CHANGE="\)\(.*\)/\1ati-powermode.sh \2/g' -i /etc/powersave/events
    fi
%endif
# For openSUSE 12.1 and higher: we should add a dynamic library search path
%if %suse_version > 1140
%ifarch x86_64
    echo "/usr/X11R6/lib64" >/etc/ld.so.conf.d/fglrx.conf
    echo "/usr/X11R6/lib" >>/etc/ld.so.conf.d/fglrx.conf
%else
    echo "/usr/X11R6/lib" >/etc/ld.so.conf.d/fglrx.conf
%endif
%run_ldconfig
%endif
test -f %{MODULES_DIR}/drivers/fglrx_drv.so && \
    touch %{MODULES_DIR}/drivers/fglrx_drv.so
%if %suse_version > 1010
# ATI libGL still uses the old X11R6 path :-(
mkdir -p usr/X11R6/%{_lib}/modules
test -d usr/X11R6/%{_lib}/modules/dri && \
    mv usr/X11R6/%{_lib}/modules/dri usr/X11R6/%{_lib}/modules/dri.old
ln -snf %{DRI_DRIVERS_DIR} usr/X11R6/%{_lib}/modules/dri
%ifarch x86_64
mkdir -p usr/X11R6/lib/modules
test -d usr/X11R6/lib/modules/dri && \
    mv usr/X11R6/lib/modules/dri usr/X11R6/lib/modules/dri.old
ln -snf %{DRI_DRIVERS32_DIR} usr/X11R6/lib/modules/dri
%endif
%endif
AMDCONFIG_BIN="`which aticonfig 2>/dev/null`"
if [ -n "${AMDCONFIG_BIN}" -a -x "${AMDCONFIG_BIN}" ]; then
    if [ -f etc/X11/xorg.conf.fglrx-oldconfig ]; then
        mv -f etc/X11/xorg.conf.fglrx-oldconfig etc/X11/xorg.conf
    elif [ -f etc/X11/xorg.conf.fglrx-post ]; then
        # Fallback for older fglrx versions.
        # The condition will be removed later.
        mv -f etc/X11/xorg.conf.fglrx-post etc/X11/xorg.conf
    fi
    # Don't run aticonfig on build machines
    if /sbin/lspci -n | grep 0300 | cut -d : -f3 | sed 's/ //g' | grep -q 1002; then
        ${AMDCONFIG_BIN} --initial=check >/dev/null
        if [ $? -eq 1 ]; then
           ${AMDCONFIG_BIN} --initial >/dev/null
        fi
        ${AMDCONFIG_BIN} --del-pcs-key=LDC,ReleaseVersion >/dev/null 2>&1
        ${AMDCONFIG_BIN} --del-pcs-key=LDC,Catalyst_Version >/dev/null 2>&1
    fi
fi
if [ "${INSTALL_PARAM}" -eq 1 ]; then
%if 0%{?suse_version} >= 1315
    /usr/sbin/update-alternatives \
        --force --install \
        %{_libdir}/xorg/modules/extensions/libglx.so libglx.so \
        %{_libdir}/xorg/modules/extensions/fglrx/fglrx-libglx.so 100
%endif
    %{_libdir}/fglrx/switchlibglx amd
    %{_libdir}/fglrx/switchlibGL amd
else
    if [ "$(%{_libdir}/fglrx/switchlibglx query)" = "intel" ]; then
%if 0%{?suse_version} >= 1315
        /usr/sbin/update-alternatives \
            --force --install \
            %{_libdir}/xorg/modules/extensions/libglx.so libglx.so \
            %{_libdir}/xorg/modules/extensions/fglrx/fglrx-libglx.so 100
%endif
        %{_libdir}/fglrx/switchlibglx intel
    else
%if 0%{?suse_version} >= 1315
        /usr/sbin/update-alternatives \
            --force --install \
            %{_libdir}/xorg/modules/extensions/libglx.so libglx.so \
            %{_libdir}/xorg/modules/extensions/fglrx/fglrx-libglx.so 100
%endif
        %{_libdir}/fglrx/switchlibglx amd
    fi
    if [ "$(%{_libdir}/fglrx/switchlibGL query)" = "intel" ]; then
        %{_libdir}/fglrx/switchlibGL intel
    else
        %{_libdir}/fglrx/switchlibGL amd
    fi
fi
exit 0

%preun -n %PACKAGE_NAME_CORE
if [ -x etc/init.d/boot.fglrxrebuild ]; then
    %stop_on_removal boot.fglrxrebuild
fi
# remove symlinks during uninstall (not during update)
if [ "$1" -eq 0 ]; then
    if [ -f "etc/ati/atiapfuser.blb" ]; then
        rm -f etc/ati/atiapfuser.blb
    fi
    %run_ldconfig
fi
exit 0

%preun -n %PACKAGE_NAME_GRAPHICS
if [ -x etc/init.d/atieventsd ]; then
    %stop_on_removal atieventsd
fi
# remove symlinks during uninstall (not during update)
if [ "$1" -eq 0 ]; then
    rm -f /usr/X11R6/lib*/libGL.so*
%if 0%{?suse_version} >= 1315
    %_sbindir/update-alternatives --remove libglx.so %{_libdir}/xorg/modules/extensions/fglrx/fglrx-libglx.so
%else
    rm -f %{_libdir}/xorg/modules/%{MOD_UPDATES_DIR}/extensions/libglx.so
%endif
    if [ -f /etc/ld.so.conf.d/fglrx.conf ]; then
        rm -f /etc/ld.so.conf.d/fglrx.conf
    fi
    %run_ldconfig
fi
exit 0

%postun -n %PACKAGE_NAME_CORE
%{insserv_cleanup}
if [ "$1" -eq 0 ]; then
    if [ -f etc/sysconfig/fglrxconfig ]; then
        mv -f etc/sysconfig/fglrxconfig etc/sysconfig/fglrxconfig-oldconfig
    fi
    # cleanup
    rm -rf usr/src/kernel-modules/fglrx/
    rm -rf etc/ati/
    # try to unload the kernel module, which fails if it is still in use
    rmmod fglrx &> /dev/null
    # now remove all available fglrx kernel modules
    find /lib/modules -iname "fglrx.ko" -print0 | xargs -r -0 rm
    # remove radeon blacklist from initrd
    mkinitrd
fi
exit 0

%postun -n %PACKAGE_NAME_GRAPHICS
#if [ -x etc/init.d/atieventsd ]; then
    # Rearrange run level symlinks after removing the atieventsd init script
    %{insserv_cleanup}
#fi
if [ "$1" -eq 0 ]; then
    if [ -f etc/X11/xorg.conf ]; then
        cp -f etc/X11/xorg.conf etc/X11/xorg.conf.fglrx-oldconfig
    fi
    ITERATION=0
    while [ -f etc/X11/xorg.conf.original-${ITERATION} ];
    do
        ITERATION=$((${ITERATION} + 1))
    done
    ITERATION=$((${ITERATION} - 1))
    if [ ${ITERATION} -ge 0 ]; then
        if [ -n "`grep NOXORGCONFEXISTED etc/X11/xorg.conf.original-${ITERATION}`" ]; then
            # if xorg.conf does not exist, the files can safely removed
            rm -f etc/X11/xorg.conf etc/X11/xorg.conf.original-${ITERATION}
        else
            mv -f etc/X11/xorg.conf.original-${ITERATION} etc/X11/xorg.conf
        fi
    else
        rm -f etc/X11/xorg.conf
    fi
fi
exit 0

%files
%defattr(-, root, root)
/usr/share/doc/packages/fglrx-meta/*

%files -n %PACKAGE_NAME_CORE
%defattr(-, root, root)
/etc/ati/amdpcsdb*
/etc/ati/atiapfxx*
/etc/ati/control
/etc/ati/logo*
/etc/ati/signature
/etc/init.d/boot.fglrxrebuild
/etc/modprobe.d/*
/usr/bin/fglrx-kernel-build.sh
/usr/%{_lib}/libatiadlxx*
/usr/%{_lib}/libatiuki*
%ifarch x86_64
/usr/lib/libatiadlxx*
/usr/lib/libatiuki*
%endif
/usr/sbin/atigetsysteminfo.sh
%dir /usr/share/ati/
/usr/share/ati/amd-uninstall.sh
/usr/share/doc/packages/fglrx-core/*
/usr/share/doc/packages/fglrx-core/patches/*
%verify(not md5 size mtime) /usr/src/kernel-modules/fglrx/*
/usr/src/kernel-modules/fglrx/2.6.x/*
/var/adm/fillup-templates/*

%files -n %PACKAGE_NAME_GRAPHICS
%defattr(-, root, root)
/etc/ati/authatieventsd.sh
/etc/init.d/atieventsd
/usr/X11R6/%{_lib}/*
%ifarch x86_64
/usr/X11R6/lib/*
%endif
/usr/bin/amdconfig
/usr/bin/amdupdaterandrconfig
/usr/bin/aticonfig
/usr/bin/atiodcli
/usr/bin/atiode
/usr/bin/fgl_glxgears
/usr/bin/fglrxinfo
/usr/include/ATI/GL/*
/usr/include/GL/*
/usr/%{_lib}/fglrx/*
/usr/%{_lib}/libAMDXvBA*
/usr/%{_lib}/libXvBAW*
%ifarch x86_64
/usr/lib/libAMDXvBA*
/usr/lib/libXvBAW*
%endif
%{DRI_DRIVERS_DIR}/*
%ifarch x86_64
%{DRI_DRIVERS32_DIR}/*
%endif
%{MODULES_DIR}/*
%{MODULES_DIR}/drivers/*
%{MODULES_DIR}/linux/*
%{MODULES_DIR}/%{MOD_UPDATES_DIR}/extensions/*
%{MODULES_DIR}/%{MOD_UPDATES_DIR}/extensions/fglrx/*
/usr/sbin/amdnotifyui
/usr/sbin/atieventsd
/usr/sbin/rcatieventsd
/usr/share/doc/packages/fglrx-graphics/*
/usr/share/doc/packages/fglrx-graphics/articles/*
/usr/share/doc/packages/fglrx-graphics/user-manual/*
/usr/share/man/man8/*
%verify(not mtime) %{MODULES_DIR}/drivers/fglrx_drv.*

%files -n %PACKAGE_NAME_AMDCCCLE
%defattr(-, root, root)
/etc/pam.d/*
/etc/security/console.apps/*
/usr/bin/amdcccle
/usr/bin/amdxdg-su
/usr/share/applications/*
%dir /usr/share/ati/amdcccle/
/usr/share/ati/amdcccle/*
%dir /usr/share/ati/%{_lib}/
/usr/share/ati/%{_lib}/*
/usr/share/doc/packages/fglrx-amdcccle/*
/usr/share/pixmaps/*

%files -n %PACKAGE_NAME_OPENCL
%defattr(-, root, root)
/etc/OpenCL/vendors/*
/usr/bin/amd-console-helper
/usr/bin/clinfo
/usr/%{_lib}/libOpenCL*
/usr/%{_lib}/libamdocl*
# /usr/%{_lib}/libamdhsasc*
/usr/%{_lib}/libatical*
%ifarch x86_64
/usr/lib/libOpenCL*
/usr/lib/libamdocl*
# /usr/lib/libamdhsasc*
/usr/lib/libatical*
%endif
/usr/share/doc/packages/fglrx-opencl/*

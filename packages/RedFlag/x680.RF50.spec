%define         _kmodver        %(echo `uname -r`)
%define         _kmoddir        /%{_lib}/modules

%define         _x11dir         %{_prefix}/X11R6
%define         _x11bindir      %{_x11dir}/bin
%define         _x11libdir      %{_x11dir}/%{_lib}
%define         _x11includedir  %{_x11dir}/include

Name:           fglrx_6_8_2_RF50
Version:        %ATI_DRIVER_VERSION
Release:        %ATI_DRIVER_RELEASE
Summary:        %ATI_DRIVER_SUMMARY

Group:          User Interface/X Hardware Support
License:        MIT
URL:            %ATI_DRIVER_URL

# Requires:       %{name}-module = %{version}-%{release}
Requires:       %{name}-module-%{_kmodver} = %{version}-%{release}

Requires(post):   /sbin/ldconfig /sbin/chkconfig
Requires(postun): /sbin/ldconfig /sbin/service
Requires(preun):  /sbin/chkconfig /sbin/service

Conflicts:      fglrx-glc22
Conflicts:      fglrx
Conflicts:      fglrx_6_8_0
Conflicts:      fglrx_4_3_0

Conflicts:      kernel-module-fglrx
Conflicts:      ati-fglrx
Conflicts:      ati-fglrx-devel

Conflicts:      fglrx_6_8_2_FC3
Conflicts:      fglrx_6_8_2_FC4
Conflicts:      fglrx_7_0_0_FC5

ExclusiveArch:  %{ix86}

%description
%ATI_DRIVER_DESCRIPTION


%package control-panel
Summary:        The control panel for the ATI proprietary graphics driver
Group:          User Interface/X Hardware Support
License:        Other License(s), see package

Requires:       %{name} = %{version}-%{release}


%description control-panel
This package provides the control panel used by the ATI proprietary
graphics driver for ATI Radeon graphic cards. This includes ATI RADEON
(8500 and later), MOBILITY RADEON (M9 and later), RADEON XPRESS IGP,
and FireGL series of graphics graphics accelerators.


%package devel
Summary:        Development Files for the ATI proprietary graphics driver
Group:          Development/Libraries
License:        Other License(s), see package

Requires:       %{name} = %{version}-%{release}

%description devel
This package provides development files and examples required for the
ATI proprietary graphics driver for ATI Radeon graphic cards. This
includes ATI RADEON (8500 and later), MOBILITY RADEON (M9 and later),
RADEON XPRESS IGP, and FireGL series of graphics graphics accelerators.


# %package -n kernel-module-%{name}-%{_kmodver}
%package -n %{name}-module-%{_kmodver}
Summary:        The Linux kernel module for the ATI proprietary graphics driver
Group:          System Environment/Kernel
License:        Other License(s), see package

# %description -n kernel-module-%{name}-%{_kmodver}
%description -n %{name}-module-%{_kmodver}
This package provides the Linux kernel module required by the ATI proprietary
driver for ATI Radeon graphic cards. This includes ATI RADEON (8500 and
later), MOBILITY RADEON (M9 and later), RADEON XPRESS IGP, and FireGL
series of graphics graphics accelerators.

BuildRequires:    kernel-devel-%{_kmodver}

Requires(post):   /sbin/depmod
Requires(postun): /sbin/depmod


%install
export RPM_BUILD_ROOT=%ATI_DRIVER_BUILD_ROOT

# Create the required directories
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/ld.so.conf.d \
         $RPM_BUILD_ROOT%{_libdir}/fglrx \
         $RPM_BUILD_ROOT%{_datadir}/applications

# Move files around for Fedora Core 4's Xorg 6.8.x
mv $RPM_BUILD_ROOT%{_x11libdir}/*.so.1.* \
   $RPM_BUILD_ROOT%{_libdir}/fglrx
mv $RPM_BUILD_ROOT%{_x11libdir}/*.a \
   $RPM_BUILD_ROOT%{_libdir}/fglrx
mv $RPM_BUILD_ROOT%{_datadir}/icons \
   $RPM_BUILD_ROOT%{_datadir}/pixmaps

# Move source examples to docs
mkdir -p $RPM_BUILD_ROOT%{_docdir}/fglrx/examples/source
mv $RPM_BUILD_ROOT%{_usrsrc}/ATI/* \
   $RPM_BUILD_ROOT%{_docdir}/fglrx/examples/source
mv $RPM_BUILD_ROOT%{_docdir}/fglrx \
   $RPM_BUILD_ROOT%{_docdir}/%{name}-%{version}

# Create some symlinks
pushd $RPM_BUILD_ROOT%{_libdir}/fglrx
ln -fs libfglrx_gamma.so.1.0 libfglrx_gamma.so.1
ln -fs libfglrx_dm.so.1.0 libfglrx_dm.so.1
ln -fs libfglrx_pp.so.1.0 libfglrx_pp.so.1
ln -fs libGL.so.1.2.ati libGL.so.1.2
ln -fs libGL.so.1.2 libGL.so.1
popd

# Avoid disturbing FC/RH Xorg/Mesa packages
pushd $RPM_BUILD_ROOT%{_sysconfdir}/ld.so.conf.d
cat <<EOF > fglrx-x86.conf
%{_libdir}/fglrx/
EOF
popd

# Create a proper desktop file in the right location for Fedora Core
pushd $RPM_BUILD_ROOT%{_datadir}/applications
cat <<EOF > ati-fireglcontrolpanel.desktop
[Desktop Entry]
Encoding=UTF-8
Name=ATI Control Panel
GenericName=ATI Control Panel
Comment=ATI graphics adapter settings
Exec=fireglcontrolpanel
Icon=ati.xpm
Terminal=false
Type=Application
#Categories=Qt;Application;System;
Version=%{version}
EOF
popd

# Build the kernel module and install it
export AS_USER=y
pushd $RPM_BUILD_ROOT%{_kmoddir}/fglrx/build_mod
sh make.sh verbose
mkdir -p $RPM_BUILD_ROOT%{_kmoddir}/%{_kmodver}/extra
install -D -m 0644 fglrx.ko $RPM_BUILD_ROOT%{_kmoddir}/%{_kmodver}/extra/fglrx/fglrx.ko
rm -rf $RPM_BUILD_ROOT%{_kmoddir}/fglrx
popd

# Strip binaries and objects since rpmbuild refuses to do so in
# this circumstance for reasons that are not yet clear to me
find $RPM_BUILD_ROOT -type f -perm 0755 -exec strip -g --strip-unneeded '{}' \;

# Fix perms for rpmlint
find $RPM_BUILD_ROOT%{_docdir} -type f -perm 0555 -exec chmod 0644 '{}' \;
find $RPM_BUILD_ROOT -type f -perm 0555 -exec chmod 0755 '{}' \;

%preun
if [ $1 = 0 ]; then
    /sbin/service atieventsd stop >/dev/null 2>&1
    /sbin/chkconfig --del atieventsd
fi

%post
/sbin/chkconfig --add atieventsd
/sbin/ldconfig

%postun
if [ "$1" -ge "1" ]; then
    /sbin/service atieventsd condrestart >/dev/null 2>&1
fi
/sbin/ldconfig

# %post -n kernel-module-%{name}-%{_kmodver}
%post -n %{name}-module-%{_kmodver}
if [ -r /boot/System.map-%{_kmodver} ] ; then
    /sbin/depmod -e -F /boot/System.map-%{_kmodver} %{_kmodver} > /dev/null || :
fi

# %postun -n kernel-module-%{name}-%{_kmodver}
%postun -n %{name}-module-%{_kmodver}
if [ -r /boot/System.map-%{_kmodver} ] ; then
    /sbin/depmod -e -F /boot/System.map-%{_kmodver} %{_kmodver} > /dev/null || :
fi


%files
%defattr(-,root,root,-)
%dir %{_sysconfdir}/ati
%dir %{_libdir}/fglrx
%doc %{_docdir}/%{name}-%{version}
%config %{_sysconfdir}/fglrxrc
%config %{_sysconfdir}/fglrxprofiles.csv
%config %{_sysconfdir}/ld.so.conf.d/fglrx-x86.conf
%{_sysconfdir}/ati/*
%{_initrddir}/atieventsd
%{_sbindir}/atieventsd
%{_x11bindir}/aticonfig
%{_x11bindir}/fgl_glxgears
%{_x11bindir}/fglrxinfo
%{_x11bindir}/fglrx_xgamma
%{_x11libdir}/modules/drivers/fglrx_drv.o
%{_x11libdir}/modules/linux/libfglrxdrm.a
%{_x11libdir}/modules/dri/fglrx_dri.so
%{_x11libdir}/modules/dri/atiogl_a_dri.so
%{_libdir}/fglrx/*.so.1*
%{_mandir}/man[1-9]/atieventsd.*

%files control-panel
%defattr(-,root,root,-)
%{_x11bindir}/fireglcontrolpanel
%{_datadir}/applications/ati-fireglcontrolpanel.desktop
%{_datadir}/pixmaps/ati.xpm

%files devel
%defattr(-,root,root,-)
%{_libdir}/fglrx/*.a
%{_includedir}/GL/*ATI.h
%{_x11includedir}/X11/extensions/fglrx*.h

# %files -n kernel-module-%{name}-%{_kmodver}
%files -n %{name}-module-%{_kmodver}
%defattr(-,root,root,-)
%dir %{_kmoddir}/%{_kmodver}/extra/fglrx
%{_kmoddir}/%{_kmodver}/extra/fglrx/*


%changelog
* Wed Jun 28 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- began work on Fedora Core 4 spec
- renamed kernel module package as per Livna repo naming practices
- minor tweaks for inclusion with the installer

* Tue Jun 27 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- tweak authatieventsd.sh for Fedora Core (/var/gdm not /var/lib/gdm)

* Mon Jun 26 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- created an init script and necessary spec scriptlets for
  the ATI External Events Daemon

* Sun Jun 25 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- stopped putting authatieventsd.sh in init until its purpose is clear
- modified ati-packager.sh - everything is now self-contained. no more
  use of /tmp, and creating the packages as a user *should* work fine
- made the symlinks for the work around relative
- make sure binaries and objects are getting stripped

* Thu Jun 22 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- need to conditionalize things based on Fedora Core Extras guidelines
- minor tweaks to Fedora Core 5 spec
- began work on Fedora Core 3 spec

* Sun Jun 18 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- made some changes as advised by mharris@redhat.com
- added a fourth package (control panel package)
- create a desktop file in a non-deprecated location

* Wed Jun 14 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- split into three packages (kernel module/devel/the rest)
- include source examples
- move the dri modules to the prescribed location on Fedora Core 5
- create symlinks so direct rendering works on Fedora Core 5

* Mon Jun 12 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- started adding build/install requirements

* Sun Jun 11 2006 Niko Mirthes <nmirthes AT gmail DOT com>
- basic Fedora Core 5 monolithic package generated
- need to further organize layout and scripts

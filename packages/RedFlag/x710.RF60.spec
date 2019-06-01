%define         _kmodver        %(echo `uname -r`)
%define         _kmoddir        /%{_lib}/modules

%define         _x11dir         %{_prefix}/X11R6
%define         _x11bindir      %{_x11dir}/bin
%define         _x11libdir      %{_x11dir}/%{_lib}
%define         _x11libdir2     %{_prefix}/%{_lib}/xorg
%define         _x11includedir  %{_x11dir}/include

Name:           fglrx_1_3_0_RF60
Version:        %ATI_DRIVER_VERSION
Release:        %ATI_DRIVER_RELEASE
Summary:        %ATI_DRIVER_SUMMARY

Group:          User Interface/X Hardware Support
License:        MIT 
URL:            %ATI_DRIVER_URL

Requires(post):   /sbin/ldconfig /sbin/chkconfig
Requires(postun): /sbin/ldconfig /sbin/service
Requires(preun):  /sbin/chkconfig /sbin/service

Conflicts:      fglrx-glc22
Conflicts:      fglrx
Conflicts:      fglrx_4_3_0
Conflicts:      fglrx_6_8_0
Conflicts:      fglrx_6_9_0
Conflicts:      kernel-module-fglrx
Conflicts:      ati-fglrx
Conflicts:      ati-fglrx-devel

ExclusiveArch:  %{ix86}

%description
%ATI_DRIVER_DESCRIPTION

%install
export RPM_BUILD_ROOT=%ATI_DRIVER_BUILD_ROOT
# Create the required directories
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/ld.so.conf.d \
         $RPM_BUILD_ROOT%{_libdir}/xorg

# Move files around
mv $RPM_BUILD_ROOT%{_x11libdir}/*.so.1.* \
   $RPM_BUILD_ROOT%{_libdir}/xorg
mv $RPM_BUILD_ROOT%{_x11libdir}/*.a \
   $RPM_BUILD_ROOT%{_libdir}/xorg
mv $RPM_BUILD_ROOT%{_x11libdir}/modules \
   $RPM_BUILD_ROOT%{_libdir}/xorg
mv $RPM_BUILD_ROOT%{_datadir}/icons \
   $RPM_BUILD_ROOT%{_datadir}/pixmaps

# Move OpenGL ICD
if [ -f $RPM_BUILD_ROOT%{_libdir}/xorg/modules/dri/fglrx_dri.so ]; then
    mv $RPM_BUILD_ROOT%{_libdir}/xorg/modules/dri \
       $RPM_BUILD_ROOT%{_libdir}
fi

# Move source examples to docs
mkdir -p $RPM_BUILD_ROOT%{_docdir}/fglrx/examples/source
mv $RPM_BUILD_ROOT%{_usrsrc}/ati/* \
   $RPM_BUILD_ROOT%{_docdir}/fglrx/examples/source
mv $RPM_BUILD_ROOT%{_docdir}/fglrx \
   $RPM_BUILD_ROOT%{_docdir}/%{name}-%{version}

# Create some symlinks
pushd $RPM_BUILD_ROOT%{_libdir}/xorg
ln -fs libfglrx_gamma.so.1.0 libfglrx_gamma.so.1
ln -fs libfglrx_dm.so.1.0 libfglrx_dm.so.1
ln -fs libfglrx_pp.so.1.0 libfglrx_pp.so.1
ln -fs libfglrx_tvout.so.1.0 libfglrx_tvout.so.1
ln -fs libGL.so.1.2.ati libGL.so.1.2
ln -fs libGL.so.1.2 libGL.so.1
popd

# Avoid disturbing FC/RH Xorg/Mesa packages
pushd $RPM_BUILD_ROOT%{_sysconfdir}/ld.so.conf.d
cat <<EOF > fglrx-x86.conf
%{_libdir}/xorg/
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
# remove link for fglrx_dri.so
if [ -e /usr/X11R6/lib/modules/dri/fglrx_dri.so ]; then
    rm -f /usr/X11R6/lib/modules/dri/fglrx_dri.so
fi

if [ $1 = 0 ]; then
    /sbin/service atieventsd stop >/dev/null 2>&1
    /sbin/chkconfig --del atieventsd
fi

%post
# Backup libGL.so.1.2, and create new links
if [ -f /usr/lib/libGL.so.1.2 ]; then
    mv /usr/lib/libGL.so.1.2 /usr/lib/xorg/FGL.renamed.libGL.so.1.2
    rm -f /usr/lib/libGL.so
    rm -f /usr/lib/libGL.so.1
    ln -s /usr/lib/xorg/libGL.so.1.2 /usr/lib/libGL.so.1
    ln -s /usr/lib/libGL.so.1 /usr/lib/libGL.so
fi

# create link for fglrx_dri.so
if [ -f /usr/lib/dri/fglrx_dri.so ]; then
    mkdir -p /usr/X11R6/lib/modules/dri
    ln -s /usr/lib/dri/fglrx_dri.so /usr/X11R6/lib/modules/dri/fglrx_dri.so
fi

/sbin/chkconfig --add atieventsd
/sbin/ldconfig

if [ -r /boot/System.map-%{_kmodver} ]; then
    /sbin/depmod -e -F /boot/System.map-%{_kmodver} %{_kmodver} > /dev/null || :
fi

%postun
# restore libGL.so.1.2 and related links
if [ -f /usr/lib/xorg/FGL.renamed.libGL.so.1.2 ]; then
    mv /usr/lib/xorg/FGL.renamed.libGL.so.1.2 /usr/lib/libGL.so.1.2
    rm -f /usr/lib/libGL.so
    rm -f /usr/lib/libGL.so.1
    ln -s /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
    ln -s /usr/lib/libGL.so.1 /usr/lib/libGL.so
fi
  
if [ "$1" -ge "1" ]; then
    /sbin/service atieventsd condrestart >/dev/null 2>&1
fi
/sbin/ldconfig

if [ -r /boot/System.map-%{_kmodver} ] ; then
    /sbin/depmod -e -F /boot/System.map-%{_kmodver} %{_kmodver} > /dev/null || :
fi

# backup current xconf and restore last .original backup
pushd /etc/X11 > /dev/null
if [ -f xorg.conf ] ; then
    count=0
    # backup last xconf
    # assume the current xconf has fglrx, backup to <xconf>.fglrx-<#>
    while [ -f xorg.conf.fglrx-${count} ] ; do
        count=$(( ${count} + 1 ))
    done
    cp xorg.conf xorg.conf.fglrx-${count}

    # now restore the last saved non-fglrx
    count=0
    while [ -f xorg.conf.original-${count} ] ; do
       count=$(( ${count} + 1 ))
    done
    if [ ${count} -ne 0 ] ; then
        cp -f xorg.conf.original-$(( ${count} - 1 )) xorg.conf
    fi
fi
popd > /dev/null

%files
%defattr(-,root,root,-)
%dir %{_sysconfdir}/ati
%dir %{_libdir}/xorg
%doc %{_docdir}/%{name}-%{version}
%config %{_sysconfdir}/ati/control
%config %{_sysconfdir}/ld.so.conf.d/fglrx-x86.conf
%{_sysconfdir}/ati/*
%{_initrddir}/atieventsd
%{_sbindir}/atieventsd
%{_x11bindir}/aticonfig
%{_x11bindir}/fgl_glxgears
%{_x11bindir}/fglrxinfo
%{_x11bindir}/fglrx_xgamma
%{_x11libdir2}/modules/drivers/fglrx_drv.so
%{_x11libdir2}/modules/linux/libfglrxdrm.so
%{_libdir}/dri/fglrx_dri.so
%{_x11libdir2}/modules/glesx.so
%{_x11libdir2}/modules/esut.a
%{_x11libdir2}/*.so.*
%{_mandir}/man[1-9]/atieventsd.*

# Catalyst Control Center Linux Edition
%{_x11bindir}/amdcccle
%{_datadir}/gnome/apps/amdcccle.desktop
%{_datadir}/applnk/amdcccle.kdelnk
%{_datadir}/pixmaps/ccc*
%{_datadir}/ati/amdcccle/amdcccle_*.qm

# Development Files
%{_libdir}/xorg/*.a
%{_includedir}/GL/*ATI.h
%{_x11includedir}/X11/extensions/fglrx*.h

# Kernel Module
%dir %{_kmoddir}/%{_kmodver}/extra/fglrx
%{_kmoddir}/%{_kmodver}/extra/fglrx/*

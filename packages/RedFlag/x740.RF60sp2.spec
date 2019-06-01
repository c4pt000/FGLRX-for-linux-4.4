%define         _kmodver        %(echo `uname -r`)
%define         _kmoddir        /%{_lib}/modules

%define         _x11dir         %{_prefix}/X11R6
%define         _x11bindir      %{_x11dir}/bin
%define         _x11libdir      %{_x11dir}/%{_lib}
%define         _x11libdir2     %{_prefix}/%{_lib}/xorg
%define         _x11includedir  %{_x11dir}/include

Name:           fglrx_1_3_0_RF60sp2
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
mv $RPM_BUILD_ROOT%{_x11libdir}/* \
   $RPM_BUILD_ROOT%{_libdir}/xorg

mv $RPM_BUILD_ROOT%{_datadir}/icons \
   $RPM_BUILD_ROOT%{_datadir}/pixmaps

mv $RPM_BUILD_ROOT%{_libdir}/libatical* $RPM_BUILD_ROOT%{_libdir}/xorg

mkdir -p $RPM_BUILD_ROOT/usr/share/applications/
cp -ar $RPM_BUILD_ROOT/opt/kde3/share/applnk/amdccclesu_kde3.desktop $RPM_BUILD_ROOT/usr/share/applications/amdccclesu_kde3.desktop


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
sh make.sh --uname_r* `uname -r`
mkdir -p $RPM_BUILD_ROOT%{_kmoddir}/%{_kmodver}/extra
install -D -m 0644 fglrx.ko $RPM_BUILD_ROOT/lib/modules/extra-kmod-%{_kmodver}/fglrx.ko
rm -rf $RPM_BUILD_ROOT%{_kmoddir}/fglrx
popd

# Strip binaries and objects since rpmbuild refuses to do so in
# this circumstance for reasons that are not yet clear to me
find $RPM_BUILD_ROOT -type f -perm 0755 -exec strip -g --strip-unneeded '{}' \;

# Fix perms for rpmlint
find $RPM_BUILD_ROOT%{_docdir} -type f -perm 0555 -exec chmod 0644 '{}' \;
find $RPM_BUILD_ROOT -type f -perm 0555 -exec chmod 0755 '{}' \;


# workaround for confliction with xorg-x11-server-Xorg
mkdir $RPM_BUILD_ROOT%{_libdir}/xorg/modules/extensions/fglrx
mv $RPM_BUILD_ROOT%{_libdir}/xorg/modules/extensions/libdri.so $RPM_BUILD_ROOT%{_libdir}/xorg/modules/extensions/fglrx/
mv $RPM_BUILD_ROOT%{_libdir}/xorg/modules/extensions/libglx.so $RPM_BUILD_ROOT%{_libdir}/xorg/modules/extensions/fglrx/


mkdir -p $RPM_BUILD_ROOT/usr/share/hwdata/videoaliases/
# Build the kernel module and install it
for kvariant in %{kvariants}
do
#    install -D -m 0644 _kmod_build_$kvariant/lib/modules/fglrx/build_mod/2.6.x/fglrx.ko $RPM_BUILD_ROOT/lib/modules/%{kverrel}/extra/%{kmod_name}/fglrx.ko

    # generate fglrx.xinf
    /sbin/modinfo $RPM_BUILD_ROOT/lib/modules/extra-kmod-%{_kmodver}/fglrx.ko| \
    grep "alias:"| \
    grep "pci:"|sort|uniq | \
    sed -e 's/bc03sc/bc*sc/g' | \
    sed -e 's/.*pci:/alias pcivideo:/g' | \
    sed -e 's/$/ fglrx/g' \
    > $RPM_BUILD_ROOT/usr/share/hwdata/videoaliases/fglrx.xinf
done


#%clean 
#rm -rf  $RPM_BUILD_ROOT

%pre
if ! lspci -n | grep 0300 |grep 1002; then
    echo "AMD/Ati graphics card NOT found. Skip installation."
    exit 1
fi

%post
# check whether to do
#grep -i $gfxid /usr/share/hwdata/videoaliases/fglrx.xinf || exit 0

# only first install
if [ "$1" = "1" ]; then
#####################Backup Xserver libdri.so libglx.so###########################
    if [ -f /usr/lib/xorg/modules/extensions/libdri.so ];then
        mv /usr/lib/xorg/modules/extensions/libdri.so /usr/lib/xorg/modules/extensions/libdri.so.XserverBackup
    fi
    if [ -f /usr/lib/xorg/modules/extensions/libglx.so ];then
        mv /usr/lib/xorg/modules/extensions/libglx.so /usr/lib/xorg/modules/extensions/libglx.so.XserverBackup
    fi
    # Backup libGL.so.1.2, and create new links
    if [ -f /usr/lib/libGL.so.1.2 ]; then
        mv /usr/lib/libGL.so.1.2 /usr/lib/xorg/FGL.renamed.libGL.so.1.2
        rm -f /usr/lib/libGL.so
        rm -f /usr/lib/libGL.so.1
        ln -s /usr/lib/xorg/libGL.so.1.2 /usr/lib/libGL.so.1
        ln -s /usr/lib/libGL.so.1 /usr/lib/libGL.so
    fi
fi

cp /usr/lib/xorg/modules/extensions/fglrx/* /usr/lib/xorg/modules/extensions/

######################## ResartX List#####################
#for KillX in %{RestartX} ;
#do
#    if  lspci -n |grep -i $KillX   ;then
#        sed  -i -e 's/TerminateServer=true/TerminateServer=false/g' /usr/share/config/kdm/kdmrc
#    fi
#done



if [ -d /usr/lib/xorg ]; then
    ln -s /usr/lib/xorg/ /usr/lib/fglrx
fi

# create link for fglrx_dri.so
# useless for xorg-server-1.5.x
if [ -f /usr/lib/dri/fglrx_dri.so ]; then
    mkdir -p /usr/X11R6/lib/modules/dri
    ln -sf /usr/lib/dri/fglrx_dri.so /usr/X11R6/lib/modules/dri/fglrx_dri.so
fi

/sbin/chkconfig --add atieventsd
/sbin/ldconfig
/sbin/depmod -a

if [ -r /boot/System.map-%{kversion} ]; then
    /sbin/depmod -e -F /boot/System.map-%{kversion} %{kversion} > /dev/null || :
fi


%ifarch x86_64
%post libs-32bit
/sbin/ldconfig
%endif  #x86_64

%preun
# remove link for fglrx_dri.so
#if [ -e /usr/X11R6/lib/modules/dri/fglrx_dri.so ]; then
#    rm -f /usr/X11R6/lib/modules/dri/fglrx_dri.so
#fi

if [ $1 = 0 ]; then
    /sbin/service atieventsd stop >/dev/null 2>&1
    /sbin/chkconfig --del atieventsd
fi





%postun

##############Xserver so######################
if [ $1 = 0 ]; then
    if [ -f /usr/lib/xorg/modules/extensions/libdri.so.XserverBackup ];then
        rm -f /usr/lib/xorg/modules/extensions/libdri.so
        mv /usr/lib/xorg/modules/extensions/libdri.so.XserverBackup /usr/lib/xorg/modules/extensions/libdri.so
    fi
    if [ -f /usr/lib/xorg/modules/extensions/libglx.so.XserverBackup ];then
        rm -f /usr/lib/xorg/modules/extensions/libglx.so
        mv /usr/lib/xorg/modules/extensions/libglx.so.XserverBackup /usr/lib/xorg/modules/extensions/libglx.so
    fi

# restore libGL.so.1.2 and related links
    if [ -f /usr/lib/xorg/FGL.renamed.libGL.so.1.2 ]; then
        mv /usr/lib/xorg/FGL.renamed.libGL.so.1.2 /usr/lib/libGL.so.1.2
        rm -f /usr/lib/libGL.so
        rm -f /usr/lib/libGL.so.1
        ln -s /usr/lib/libGL.so.1.2 /usr/lib/libGL.so.1
        ln -s /usr/lib/libGL.so.1 /usr/lib/libGL.so
    fi

    unlink /usr/lib/fglrx
        sed -i '/insmod/d' /etc/rc.local > /dev/null 2>&1
fi

if [ "$1" -ge "1" ]; then
        /sbin/service atieventsd condrestart >/dev/null 2>&1
fi
/sbin/ldconfig

if [ -r /boot/System.map-%{kversion} ] ; then
    /sbin/depmod -e -F /boot/System.map-%{kversion} %{kversion} > /dev/null || :
fi


/sbin/zerohwconf >/dev/null 2>&1

%ifarch x86_64
%postun libs-32bit
/sbin/ldconfig
%endif #x86_64

%files
%defattr(-,root,root,-)
%dir %{_sysconfdir}/ati
%dir %{_libdir}/xorg
%doc %{_docdir}/%{name}-%{version}
#%config %{_sysconfdir}/ati/control
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
%{_x11libdir2}/modules/amdxmm.so
%{_x11libdir2}/modules/glesx.so
%{_x11libdir2}/modules/esut.a
%{_x11libdir2}/modules/extensions/fglrx/libdri.so
%{_x11libdir2}/modules/extensions/fglrx/libglx.so
%{_x11libdir2}/*.so.*
%{_mandir}/man[1-9]/atieventsd.*
# Catalyst Control Center Linux Edition
%{_x11bindir}/amdcccle
%{_x11bindir}/atiodcli
%{_x11bindir}/atiode
%{_x11bindir}/amdxdg-su
%{_datadir}/pixmaps/ccc*
%{_datadir}/ati/amdcccle/amdcccle_*.qm
#%{_datadir}/applications/*.desktop
# Development Files
%{_libdir}/xorg/*.a
%{_includedir}/GL/*ATI.h
%{_x11includedir}/X11/extensions/fglrx*.h
#added source
#/usr/share/doc/%{name}-%{version}/examples/etc/acpi/ati-powermode.sh
#/usr/share/doc/%{name}-%{version}/examples/source/fglrx_sample_source.tgz
/usr/share/hwdata/videoaliases/*
/usr/X11R6/bin/amdupdaterandrconfig
/usr/lib/xorg/libatical*
/usr/lib/xorg/libatiadlxx.so
/usr/share/applications/amdccclesu_kde3.desktop
/lib/modules/extra-kmod-%{_kmodver}/fglrx.ko
/opt/kde3/share/applnk/amdcccle_kde3.desktop
/opt/kde3/share/applnk/amdccclesu_kde3.desktop
/usr/lib/xorg/libAMDXvBA.cap
/usr/sbin/amdnotifyui
/usr/sbin/atigetsysteminfo.sh
/usr/share/applnk/amdcccle.kdelnk
/usr/share/applnk/amdccclesu.kdelnk
/usr/share/gnome/apps/amdcccle.desktop
/usr/share/gnome/apps/amdccclesu.desktop
/usr/share/doc/amdcccle/ccc_copyrights.txt

%exclude /fglrx.spec
%exclude /fglrx-pkgbuild.log

%changelog

* Thu May 21 2009 Huang Wenlong <huangwenlong@redflag-linux.com> 8.62-2
-fix setup twice files add a file in file list ccc_copyrights.txt


* Thu Feb 19 2009 Huang Wenlong <huangwenlong@redflag-linux.com> 8.573-1
-edit spec file make rpm package with *.run


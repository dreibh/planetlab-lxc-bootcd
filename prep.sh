#!/bin/bash
#
# Builds the BootCD reference image, the first of two
# initramfs cpio archives that are concatenated together by
# isolinux/syslinux to form a custom BootCD.
#
# Aaron Klingaman <alk@absarokasoft.com>
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2004-2006 The Trustees of Princeton University
#
# $Id$
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# In both a normal CVS environment and a PlanetLab RPM
# build environment, all of our dependencies are checked out into
# directories at the same level as us.
if [ -d ../build ] ; then
    PATH=$PATH:../build
    srcdir=..
else
    echo "Error: Could not find sources in either . or .."
    exit 1
fi

export PATH

. build.common

pldistro=$1 ; shift
nodefamily=$1; shift

# Packages to install, junk and precious : see build/<pldistro>/bootcd.pkgs

# Do not tolerate errors
set -e

# Root of the initramfs reference image
bootcd=$PWD/build/bootcd
install -d -m 755 $bootcd

# Write version number
rpmquery --specfile bootcd.spec --queryformat '%{VERSION}\n' | head -1 > build/version.txt
echo $nodefamily > build/nodefamily

# Install base system
pl_root_makedevs $bootcd
pkgsfile=$(pl_locateDistroFile ../build/ $pldistro bootcd.pkgs) 
pl_root_mkfedora $bootcd $pldistro $pkgsfile
pl_root_tune_image $bootcd

# Install ipnmac (for SuperMicro machines with IPMI)
echo "* Installing IPMI utilities"
install -D -m 755 ipnmac/ipnmac.x86 $bootcd/usr/sbin/ipnmac

# Install configuration files
echo "* Installing configuration files"
for file in fstab mtab modprobe.conf inittab hosts sysctl.conf ; do
    install -D -m 644 etc/$file $bootcd/etc/$file
done

# Install initscripts
echo "* Installing initscripts"
for file in pl_sysinit pl_hwinit pl_netinit pl_validateconf pl_boot ; do
    sed -i -e "s,@PLDISTRO@,$pldistro,g" -e "s,@FCDISTRO@,$fcdistro,g" initscripts/$file
    install -D -m 755 initscripts/$file $bootcd/etc/init.d/$file
done

# connect the scripts for upstart
# fedora 9 comes with /sbin/init from upstart, that uses /etc/event.d instead of inittab
# (in fact inittab is read for determining the default runlevel)
if [ -d $bootcd/etc/event.d ] ; then
    echo "* Tuning /etc/event.d /for upstart"
    pushd $bootcd/etc/event.d
    sed -i -e 's,/etc/rc.d/rc.sysinit[a-z\.]*,/etc/init.d/pl_sysinit,g' *
    popd    
fi

# Write nodefamily stamp, to help bootmanager do the right thing
mkdir -p $bootcd/etc/planetlab
echo $nodefamily > $bootcd/etc/planetlab/nodefamily

# Install fallback node configuration file
echo "* Installing fallback node configuration file"
install -D -m 644 usr-boot/default-node.txt $bootcd/usr/boot/default-node.txt

# Copy /etc/passwd out
install -D -m 644 $bootcd/etc/passwd build/passwd

# Root of the isofs
isofs=$PWD/build/isofs
install -d -m 755 $isofs

# Copy the kernel out
for kernel in $bootcd/boot/vmlinuz-* ; do
    if [ -f $kernel ] ; then
	install -D -m 644 $kernel $isofs/kernel
    fi
done

# Don't need /boot anymore
rm -rf $bootcd/boot

# initramfs requires that /init be present
ln -sf /sbin/init $bootcd/init

# Pack the rest into a compressed archive
echo "* Compressing reference image"
(cd $bootcd && find . | cpio --quiet -c -o) | gzip -9 > $isofs/bootcd.img

exit 0

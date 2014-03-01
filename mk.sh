#!/bin/sh
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export INITRAMFS_SOURCE=`readlink -f ..`/initramfs
#export CONFIG_AOSP_BUILD=y
export PACKAGEDIR=$PARENT_DIR/Packages
#Enable FIPS mode
export USE_SEC_FIPS_MODE=true
export ARCH=arm
export CROSS_COMPILE=/home/none/android/toolchains/arm-eabi-4.7/bin/arm-eabi-

echo "Remove old Package Files"
rm -rf $PACKAGEDIR/*

echo "Setup Package Directory"
mkdir -p $PACKAGEDIR/system/app
mkdir -p $PACKAGEDIR/system/lib/modules
mkdir -p $PACKAGEDIR/system/etc/init.d

echo "Create initramfs dir"
mkdir -p $INITRAMFS_DEST

echo "Remove old initramfs dir"
rm -rf $INITRAMFS_DEST/*

echo "Copy new initramfs dir"
cp -R $INITRAMFS_SOURCE/* $INITRAMFS_DEST

echo "chmod initramfs dir"
chmod -R g-w $INITRAMFS_DEST/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print)
rm -rf $(find $INITRAMFS_DEST -name .git -print)

#echo "Remove old zImage"
#rm $PACKAGEDIR/zImage
rm arch/arm/boot/zImage

echo "Clean old build"
make clean

echo "Make the kernel"
make VARIANT_DEFCONFIG=jf_eur_defconfig jf_defconfig SELINUX_DEFCONFIG=selinux_defconfig

make -j16

echo "Copy modules to Package"
cp -a $(find . -name *.ko -print |grep -v initramfs) $PACKAGEDIR/system/lib/modules/

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo "Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "Make boot.img"
	./mkbootfs $INITRAMFS_DEST | gzip > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline 'console=null androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3' --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $PACKAGEDIR/boot.img
	export curdate=`date "+%b%d_%H%M"`
#	echo "Executing loki"
#	./loki_patch-linux-x86_64 boot aboot.img $PACKAGEDIR/boot.img $PACKAGEDIR/boot.lok
#	rm $PACKAGEDIR/boot.img
	#cp loki_flash $PACKAGEDIR/loki_flash
	cd $PACKAGEDIR
	cp -R ../META-INF-SEC ./META-INF
	rm ramdisk.gz
	rm zImage
	zip -r ../Jeboo_Kernel_i9505_$curdate.zip .
	cd $KERNELDIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

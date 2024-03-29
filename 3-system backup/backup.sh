#!/bin/bash

#install tools
sudo apt-get -y install rsync dosfstools parted kpartx exfat-fuse

# create log file
curent_path=`pwd`/log
mkdir -p $curent_path
log_file=${curent_path}/backup_log-`date +%Y%m%d-%H%M%S`.log
touch $log_file

echo_log(){
	echo [`date +%Y/%m/%d-%H:%M:%S`]: $* >> $log_file
}

echo_log "Create log at" $log_file

#mount USB device
usbmount=/mnt/backup_flash
mkdir -p $usbmount
if [ -z $1 ]; then
	echo "no argument, assume the mount device is /dev/sda1 ? Y/N"
	read key
	if [ "$key" = "y" -o "$key" = "Y" ]; then
		# sudo mount -o uid=1000 /dev/sda1 $usbmount
		sudo mount /dev/sda1 $usbmount
		echo_log "Mounted /dev/sda1 at" $usbmount "."
	else
		echo "$0 [backup dest device name], e.g. $0 /dev/sda1"
		exit 0
	fi
else
	# sudo mount -o uid=1000 $1 $usbmount
	sudo mount $1 $usbmount
	echo_log "Mounted" $1 "at" $usbmount "."
fi
if [ -z "`grep $usbmount /etc/mtab`" ]; then
	echo "mount fail, exit now"
	echo_log "Mount fail."
	exit 0
fi 

img=$usbmount/rpi-`date +%Y%m%d-%H%M`.img
#img=$usbmount/rpi.img


echo ===================== part 1, create a new blank img ===============================
# New img file
#sudo rm $img
bootsz=`df -P | grep /boot | awk '{print $2}'`
echo_log "boot section size: " $bootsz "Byte(s)"
rootsz=`df -P | grep /dev/root | awk '{print $3}'`
echo_log "root section size: " $rootsz "Byte(s)"
totalsz=`echo $bootsz $rootsz | awk '{print int(($1+$2)*1.3)}'`
echo_log "total size: " $totalsz "Byte(s)"
sudo dd if=/dev/zero of=$img bs=1K count=$totalsz
echo_log "Create image file at" $img

# format virtual disk
bootstart=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p1 | awk '{print $2}'`
bootend=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p1 | awk '{print $3}'`
rootstart=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $2}'`
echo "boot: $bootstart >>> $bootend, root: $rootstart >>> end"
echo_log "boot: $bootstart >>> $bootend, root: $rootstart >>> end"
#rootend=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}'`
sudo parted $img --script -- mklabel msdos
sudo parted $img --script -- mkpart primary fat32 ${bootstart}s ${bootend}s
sudo parted $img --script -- mkpart primary ext4 ${rootstart}s -1s
echo_log "Image file parted done."
loopdevice=`sudo losetup -f --show $img`
device=/dev/mapper/`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
sleep 15
echo_log `sudo mkfs.vfat ${device}p1 -n BOOT`
echo_log `sudo mkfs.ext4 ${device}p2`


echo ===================== part 2, fill the data to img =========================
# mount partitions
virmount=/media/vir_mount
#sudo mkdir -p $virmount
mountb=${virmount}/backup_boot
mountr=${virmount}/backup_root
sudo mkdir -p $mountb $mountr
echo_log "Make directories: " $mountb $mountr
# backup /boot
echo_log "Mount" ${device}p1 "at" $mountb
sudo mount -t vfat ${device}p1 $mountb >> $log_file
echo_log "mount done"
sudo cp -rfp /boot/* $mountb
sync
echo "...Boot partition done"
echo_log "Boot partition done"
# backup /root
echo_log "Mount" ${device}p2 "at" $mountr
sudo mount -t ext4 ${device}p2 $mountr >> $log_file
echo_log "mount done"
if [ -f /etc/dphys-swapfile ]; then
        SWAPFILE=`cat /etc/dphys-swapfile | grep ^CONF_SWAPFILE | cut -f 2 -d=`
	if [ "$SWAPFILE" = "" ]; then
		SWAPFILE=/var/swap
	fi
	EXCLUDE_SWAPFILE="--exclude=$SWAPFILE"
fi
sudo rsync --force -rltWDEgop --delete --stats --progress \
	$EXCLUDE_SWAPFILE \
	--exclude='.gvfs' \
	--exclude='/dev' \
	--exclude='/media' \
	--exclude='/mnt' \
	--exclude='/proc' \
	--exclude='/run' \
	--exclude='/sys' \
	--exclude='/tmp' \
	--exclude='lost\+found' \
	--exclude='$usbmount' \
	--exclude='$virmount' \
	--exclude='$log_file' \
	// $mountr >> $log_file
# special dirs 
for i in dev media mnt proc run sys boot; do
	if [ ! -d $mountr/$i ]; then
		sudo mkdir $mountr/$i
	fi
done
if [ ! -d $mountr/tmp ]; then
	sudo mkdir $mountr/tmp
	sudo chmod a+w $mountr/tmp
fi
sudo rm -f $mountr/etc/udev/rules.d/70-persistent-net.rules

sync
echo ${mountr}/home/pi
ls -lia $mountr/home/pi/
echo "...Root partition done"
# if using the dump/restore 
# tmp=$usbmount/root.ext4
# sudo chattr +d $img $mountb $mountr $tmp
# sudo mount -t ext4 ${device}p2 $mountr
# cd $mountr
# sudo dump -0uaf - / | sudo restore -rf -
# cd


# replace PARTUUID
opartuuidb=`blkid -o export /dev/mmcblk0p1 | grep PARTUUID`
opartuuidr=`blkid -o export /dev/mmcblk0p2 | grep PARTUUID`
npartuuidb=`blkid -o export ${device}p1 | grep PARTUUID`
npartuuidr=`blkid -o export ${device}p2 | grep PARTUUID`
sudo sed -i "s/$opartuuidr/$npartuuidr/g" $mountb/cmdline.txt
sudo sed -i "s/$opartuuidb/$npartuuidb/g" $mountr/etc/fstab
sudo sed -i "s/$opartuuidr/$npartuuidr/g" $mountr/etc/fstab

sudo umount $mountb
sudo umount $mountr

# umount loop device
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice
sudo umount $usbmount
sudo rm -rf $mountb $mountr
echo "==== All done. You can un-plug the backup device"
echo_log "done"

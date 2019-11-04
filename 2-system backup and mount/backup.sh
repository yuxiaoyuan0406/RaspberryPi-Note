#!/bin/bash
#===============================================================================
#
#          FILE: backup.sh
# 
#         USAGE: ./backup.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: dosfstools dump parted kpartx
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: yuxiaoyuan, yuxiaoyuan0406@qq.com
#  ORGANIZATION: ---
#       CREATED: 2019-11-3 16:19:33
#      REVISION:  ---
#===============================================================================

# 时间
now=`date +%Y-%m-%d-%H%M%S`
exho "time:%t $now"

# 备份文件写入位置
target_file_dir=/home/pi/Documents/backup_test
sudo mkdir -p $target_file_dir
img=${target_file_dir}/backup-${now}.img
echo "target file" $img

# 虚拟磁盘挂载位置
vir_dir=/mnt/vir_img

# 目标文件文件系统和目录
bootfs=/dev/mmcblk0p1
rootfs=/dev/root
bootdir=`df -P | grep ${bootfs} | awk '{print $6}'`
rootdir=`df -P | grep ${rootfs} | awk '{print $6}'`
echo $bootfs "mounted on" $bootdir
echo $rootfs "mounted on" $rootdir

# 计算目标空间尺寸
bootsz=`df -P | grep $bootfs | awk '{print $2}'`
rootsz=`df -P | grep $rootfs | awk '{print $3}'`
totalsz=`echo $rootsz $bootsz | awk '{print int(($1+$2)*1.5)}'`
echo "total size" ${totalsz}KB

# 获取分区始末位置
bootstart=`sudo fdisk -l | grep $bootfs | awk '{print $2}'`
bootend=`sudo fdisk -l | grep $bootfs | awk '{print $3}'`
# rootstart=`sudo fdisk -l | grep $rootfs | awk '{print $2}'`
((rootstart=$bootend+1))
echo "boot: $bootstart -> $bootend, root: $rootstart -> end"

# 申请镜像空间
echo "Creating image file..."
sudo dd if=/dev/zero of=$img bs=1k count=$totalsz
echo "Image file is created at $img"

# 目标镜像分区
echo "Seperating image..."
sudo parted $img --script -- mklabel msdos
sudo parted $img --script -- mkpart primary fat32 ${bootstart}s ${bootend}s
sudo parted $img --script -- mkpart primary ext4 ${rootstart}s -1

# 创建虚拟磁盘
echo "Creating virtual device..."
loopdevice=`sudo losetup -f --show $img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
sleep 5     # 暂停来避开bug
device="/dev/mapper/${device}"
echo "Done. $device"

# 格式化
echo "Format..."
sudo mkfs.vfat ${device}p1 -n BOOT
sudo mkfs.ext4 ${device}p2

# 挂载虚拟磁盘
vir_boot=${vir_dir}/boot
vir_root=${vir_dir}/root
sudo mkdir -p $vir_boot $vir_root
echo "Loading boot section..."
sudo mount -t vfat ${device}p1 $vir_boot
echo "Loading root section..."
sudo mount -t ext4 ${device}p2 $vir_root

# 备份boot分区
echo "Copying boot section..."
sudo cp -rfp ${bootdir}/* ${vir_boot}/

# 备份root分区
echo "Copying root section"
cd $vir_root
sudo chattr +d $img
sudo dump -0uaf - $rootdir | sudo restore -rf - 
cd
sudo sync

# 卸载虚拟磁盘
echo "All done"
sudo umount ${vir_dir}/*
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice

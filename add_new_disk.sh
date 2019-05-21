#!/usr/bin/env bash

# https://n40lab.wordpress.com/2016/07/28/project-atomic-installing-vm-with-vagrant-libvirt-and-get-more-space-for-the-varlibdocker-directory/
set -e
set -x

VAGRANT_FLAG="/etc/vagrant_disk_added_date"

if [ -f $VAGRANT_FLAG ]
then
   echo "disk already added so exiting."
   cat $VAGRANT_FLAG
   exit 0
fi

echo "deltarpm=true
fastestmirror=true
timeout=15
retries=3
metadata_expire=172800" >> /etc/dnf/dnf.conf

dnf install -y lvm2 # provide LVM commands https://access.redhat.com/solutions/543593

df -h
lsblk # check physical volumes present
fdisk -u /dev/sda <<EOF
n
p
1


t
8e
w
EOF

pvs
pvcreate /dev/sda1
pvdisplay
pvs

vgs
vgcreate vg_docker /dev/sda1
#vgcreate vg00 /dev/sda1
#vgextend VolGroup /dev/sdb1
vgdisplay
vgs

lvs
#lvcreate -n lv00-docker -L 40G vg00
#lvcreate -n lv00-root -l 100%FREE vg00
lvs
# lvextend -l 100%FREE /dev/name-of-volume-group/root
# https://computingforgeeks.com/install-arch-linux-with-lvm-on-uefi-system/
# https://www.linuxtrainingacademy.com/wp-content/uploads/2018/04/lvm-diagram-linux-training-academy.png
# http://www.brainupdaters.net/en/brief-introduction-logical-volumes-lv-concept-example-application-3/
# lvcreate -n arch-root -L 20G arch-lvm
# lvcreate -n arch-swap -L 2G arch-lvm
# lvcreate -n arch-home -l 100%FREE arch-lvm
#resize2fs /dev/name-of-volume-group/root

#https://docs.docker.com/storage/storagedriver/device-mapper-driver/
lvcreate --wipesignatures y -n thinpool vg_docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta vg_docker -l 1%VG
lvconvert -y --zero n -c 512K --thinpool vg_docker/thinpool --poolmetadata vg_docker/thinpoolmeta

echo "activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}" >> /etc/lvm/profile/docker-thinpool.profile

lvchange --metadataprofile docker-thinpool vg_docker/thinpool

lvdisplay -m

#mkfs.ext4 /dev/vg00/lv00-docker # 54Mo format approx.
#mkfs.xfs -n ftype=1 /dev/mapper/vg00-lv00--docker #94Mo format approx.

# /dev/vg00/lv00-docker  /dev/mapper/vg00-lv00--docker
#echo "/dev/vg00/lv00-docker /var/lib/docker ext4 defaults 0 0" >> /etc/fstab
#mount -a

date > $VAGRANT_FLAG

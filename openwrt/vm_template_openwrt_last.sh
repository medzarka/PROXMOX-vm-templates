
#################################################
# this script creates an openwrt image template



#----------------------------------------------------
# template configuration
TEMPLATE_NAME=template-openwrt
VMID=9002
RAM=512
CORES=1
BRIDGE1=vmbr0
BRIDGE2=vmbr1
COMPRESSED_IMAGE=/tmp/openwrt.img.gz
DISKIMAGE=/tmp/openwrt.img
DISKIMAGE_SIZE=1G
STORAGE=local-zfs

#----------------------------------------------------
# create the template
VER=$(curl --silent "https://api.github.com/repos/openwrt/openwrt/releases/latest"|grep '"tag_name"'|sed -E 's/.*"([^"]+)".*/\1/'|sed 's/v//')
TAGS=_template,openwrt,v.$VER
TEMPLATE_NAME=template-openwrt-$VER


wget -O $COMPRESSED_IMAGE https://downloads.openwrt.org/releases/$VER/targets/x86/64/openwrt-$VER-x86-64-generic-ext4-combined.img.gz
du -sh $COMPRESSED_IMAGE
gunzip $COMPRESSED_IMAGE
qemu-img resize -f raw $DISKIMAGE $DISKIMAGE_SIZE

qm destroy $VMID --destroy-unreferenced-disks 1 --purge 1

qm create $VMID --name $TEMPLATE_NAME 
qm set $VMID --ostype l26
qm set $VMID --machine q35
qm set $VMID --net0 virtio,bridge=$BRIDGE1 
qm set $VMID --net1 virtio,bridge=$BRIDGE2
qm set $VMID --memory $RAM
qm set $VMID --cores $CORES --cpu cputype=host,flags=+aes
qm importdisk $VMID $DISKIMAGE $STORAGE
qm set $VMID --scsihw virtio-scsi-single --scsi0 $STORAGE:vm-$VMID-disk-0,cache=unsafe,discard=on,iothread=1,size=$DISKIMAGE_SIZE
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --tablet 0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1 # optional but recommened
qm set $VMID --tags $TAGS

rm -rf $COMPRESSED_IMAGE
rm -rf $DISKIMAGE

qm start $VMID
qm terminal $VMID

#qm guest passwd <vmid> 


##

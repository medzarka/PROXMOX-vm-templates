echo ' 1 - Network configurations:'

echo '' > /etc/config/network
uci set network.loopback=interface
uci set network.loopback.proto='static'
uci set network.loopback.ipaddr='127.0.0.1'
uci set network.loopback.netmask='255.0.0.0'
uci set network.loopback.device='lo'
#uci set network.wan6=interface
#uci set network.wan6.proto='dhcpv6'
#uci set network.wan6.device='eth0'
uci set network.wan=interface
uci set network.wan.ipaddr='xx.xx.xx.xx'
uci set network.wan.gateway='xx.xx.xx.xx'
uci set network.wan.netmask='255.255.255.0'
uci set network.wan.dns='193.110.81.0'
uci set network.wan.proto='static'
uci set network.wan.device='eth0'
#uci set network.@device[0]=device
uci add network device
uci set network.@device[-1].type='8021q'
uci set network.@device[-1].ifname='eth1'
uci set network.@device[-1].vid='10'
uci set network.@device[-1].name='eth1.10'
uci set network.@device[-1].ipv6='0'
#uci set network.@device[0]=device
uci add network device
uci set network.@device[-1].type='8021q'
uci set network.@device[-1].ifname='eth1'
uci set network.@device[-1].vid='20'
uci set network.@device[-1].name='eth1.20'
uci set network.@device[-1].ipv6='0'
#uci set network.@device[0]=device
uci add network device
uci set network.@device[-1].type='8021q'
uci set network.@device[-1].ifname='eth1'
uci set network.@device[-1].vid='30'
uci set network.@device[-1].name='eth1.30'
uci set network.@device[-1].ipv6='0'
#uci set network.@device[0]=device
uci add network device
uci set network.@device[-1].type='8021q'
uci set network.@device[-1].ifname='eth1'
uci set network.@device[-1].vid='40'
uci set network.@device[-1].name='eth1.40'
uci set network.@device[-1].ipv6='0'
uci set network.LAN_HOST=interface
uci set network.LAN_HOST.proto='static'
uci set network.LAN_HOST.device='eth1.10'
uci set network.LAN_HOST.ipaddr='192.168.10.1'
uci set network.LAN_HOST.netmask='255.255.255.0'
uci set network.DMZ=interface
uci set network.DMZ.proto='static'
uci set network.DMZ.device='eth1.20'
uci set network.DMZ.ipaddr='192.168.20.1'
uci set network.DMZ.netmask='255.255.255.0'
uci set network.LAN_VMs=interface
uci set network.LAN_VMs.proto='static'
uci set network.LAN_VMs.device='eth1.30'
uci set network.LAN_VMs.ipaddr='192.168.30.1'
uci set network.LAN_VMs.netmask='255.255.255.0'
uci set network.LAN_LXCs=interface
uci set network.LAN_LXCs.proto='static'
uci set network.LAN_LXCs.device='eth1.40'
uci set network.LAN_LXCs.ipaddr='192.168.40.1'
uci set network.LAN_LXCs.netmask='255.255.255.0'
uci commit 
reload_config


################################################################
echo ' 2 - Firewall configurations:'
echo '' > /etc/config/firewall
echo '      Configuring default firewall'

uci add firewall defaults > /dev/null
uci set firewall.@defaults[-1]=defaults
uci set firewall.@defaults[-1].input='REJECT'
uci set firewall.@defaults[-1].output='ACCEPT'
uci set firewall.@defaults[-1].forward='REJECT'
uci set firewall.@defaults[-1].synflood_protect='1'

#echo '      Cleaning firewall'
#while uci delete firewall.@zone[-1] > /dev/null 2>&1; do
#echo ''  > /dev/null 2>&1
#done
#while uci delete firewall.@forwarding[-1] > /dev/null 2>&1; do
#echo '' > /dev/null 2>&1
#done
#while uci delete firewall.@rule[-1] > /dev/null 2>&1; do
#echo '' > /dev/null 2>&1
#done

#echo '      Configuring firewall zones'
#uci set firewall.@zone[-1]=zone

uci add firewall zone > /dev/null
uci set firewall.@zone[-1].name='lan'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
uci delete firewall.@zone[-1].network > /dev/null 2>&1
uci add_list firewall.@zone[-1].network='LAN_HOST'
uci add_list firewall.@zone[-1].network='LAN_LXCs'
uci add_list firewall.@zone[-1].network='LAN_VMs'
#uci set firewall.@zone[0].network='LAN_HOST' 'LAN_LXCs' 'LAN_VMs'
#uci set firewall.@zone[1]=zone
uci add firewall zone > /dev/null
uci set firewall.@zone[-1].name='wan'
uci set firewall.@zone[-1].input='DROP'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='DROP'
uci set firewall.@zone[-1].masq='1'
uci set firewall.@zone[-1].mtu_fix='1'
uci delete firewall.@zone[-1].network > /dev/null 2>&1
uci add_list firewall.@zone[-1].network='wan'
#uci add_list firewall.@zone[1].network='wan6'
#uci set firewall.@zone[1].network='wan' 'wan6'
#uci set firewall.@zone[2]=zone
uci add firewall zone > /dev/null
uci set firewall.@zone[-1].name='dmz'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='REJECT'
uci set firewall.@zone[-1].device='eth1.20'
uci set firewall.@zone[-1].family='ipv4'
uci set firewall.@zone[-1].network='DMZ'
echo '      Configuring firewall zones forwarding'
uci add firewall forwarding > /dev/null
#uci set firewall.@forwarding[0]=forwarding
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='wan'
uci add firewall forwarding > /dev/null
#uci set firewall.@forwarding[1]=forwarding
uci set firewall.@forwarding[-1].src='dmz'
uci set firewall.@forwarding[-1].dest='wan'
uci add firewall forwarding > /dev/null
#uci set firewall.@forwarding[2]=forwarding
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='dmz'
echo '      Configuring firewall rules'
uci add firewall rule > /dev/null
#uci set firewall.@rule[-1]=rule
uci set firewall.@rule[-1].name='Allow-Admin'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='443'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit 
reload_config

################################################################
echo ' 3 - Install required softwares:'
uci set system.@system[0].ttylogin="1"
uci commit system
service system restart

opkg update
opkg install qemu-ga nano-full htop parted losetup resize2fs
/etc/init.d/qemu-ga enable
/etc/init.d/qemu-ga start
echo "qemu-ga --daemonize -m virtio-serial -p /dev/vport1p1" > /etc/rc.local

# Configure startup scripts
cat << "EOF" > /etc/uci-defaults/70-rootpt-resize
if [ ! -e /etc/rootpt-resize ] \
&& type parted > /dev/null \
&& lock -n /var/lock/root-resize
then
ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e \
'$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
ROOT_DISK="/dev/$(basename "${ROOT_BLK%/*}")"
ROOT_PART="${ROOT_BLK##*[^0-9]}"
parted -f -s "${ROOT_DISK}" \
resizepart "${ROOT_PART}" 100%
mount_root done
touch /etc/rootpt-resize
reboot
fi
exit 1
EOF
cat << "EOF" > /etc/uci-defaults/80-rootfs-resize
if [ ! -e /etc/rootfs-resize ] \
&& [ -e /etc/rootpt-resize ] \
&& type losetup > /dev/null \
&& type resize2fs > /dev/null \
&& lock -n /var/lock/root-resize
then
ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e \
'$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
ROOT_DEV="/dev/${ROOT_BLK##*/}"
LOOP_DEV="$(awk -e '$5=="/overlay"{print $9}' \
/proc/self/mountinfo)"
if [ -z "${LOOP_DEV}" ]
then
LOOP_DEV="$(losetup -f)"
losetup "${LOOP_DEV}" "${ROOT_DEV}"
fi
resize2fs -f "${LOOP_DEV}"
mount_root done
touch /etc/rootfs-resize
reboot
fi
exit 1
EOF
cat << "EOF" >> /etc/sysupgrade.conf
/etc/uci-defaults/70-rootpt-resize
/etc/uci-defaults/80-rootfs-resize
EOF


sh /etc/uci-defaults/70-rootpt-resize
sh /etc/uci-defaults/80-rootfs-resize

    
cat <<EOF > /etc/sysctl.conf
# Defaults are configured in /etc/sysctl.d/* and can be customized in this file
## Better networking, edit /etc/sysctl.conf
#-# Force gc to clean-up quickly
net.ipv4.neigh.default.gc_interval = 3600
#-# Set ARP cache entry timeout
net.ipv4.neigh.default.gc_stale_time = 3600
#-# Setup DNS threshold for arp 
net.ipv4.neigh.default.gc_thresh3 = 4096
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh1 = 1024
EOF






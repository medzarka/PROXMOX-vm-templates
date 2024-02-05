#!/bin/sh
######################### Alpine template setup script #############################

# [x] F1 Update the system ..
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "Configure the alpine repositories and update the system ..."
sed -i 's/#http/http/g' /etc/apk/repositories # enable community repository
apk update
apk upgrade --no-cache --available

# [x] F2 Install required softwares
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "Install required softwares ..."
apk --no-cache add neofetch htop chrony doas tzdata nano parted bash parted
apk --no-cache add python3 py3-pip py3-pyserial py3-netifaces # required for cloud init

# [x] F3 Setup NTP to Asia/Riyadh
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "setup time zone and NTP ..."
setup-timezone -z Asia/Riyadh
rc-update add chronyd default

# [x] F4 Install KVM guest agent (QEMU)
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "install KVM guest agent (QEMU) ..."
apk --no-cache add qemu-guest-agent
rc-update add qemu-guest-agent
rc-service qemu-guest-agent start

# [x] F5 install and configure cloud-init
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "install and configure cloud-init ..."
## install and configurecloud-init
apk --no-cache add cloud-init cloud-utils-growpart e2fsprogs e2fsprogs-extra
echo 'isofs' > /etc/modules-load.d/isofs.conf
chmod -x /etc/modules-load.d/isofs.conf
setup-cloud-init
echo 'datasource_list: [ NoCloud, ConfigDrive, None ]' > /etc/cloud/cloud.cfg.d/99_pve.cfg
chmod 644 /etc/cloud/cloud.cfg.d/99_pve.cfg

# [x] F6 configure sudo/doas
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "configure sudo and doas (no password required when using doas) ..."
## configure sudo and doas
#  !!!! Please to consider only one option
# ------------ no password required ------------
# for sudo --> echo '%wheel ALL=(ALL) NOPASSWD: ALL' > "/etc/sudoers.d/wheel"
echo 'permit nopass :wheel' > "/etc/doas.d/wheel.conf"
echo 'permit nopass keepenv root as root' >> "/etc/doas.d/wheel.conf"
# ------------ with required user password ------------
# for sudo --> echo '%wheel ALL=(ALL) ALL' > "/etc/sudoers.d/wheel"
#echo 'permit persist :wheel' > "/etc/doas.d/wheel.conf"
#echo 'permit nopass keepenv root as root' >> "/etc/doas.d/wheel.conf"

# [x] F7 Configure the firewall
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "Configure the firewall and hardening the access (22 only is accessible) ..."
# Hardening Alpine
apk --no-cache add ufw
ufw default deny incoming
ufw default allow outgoing
ufw limit SSH  # open SSH port and protect against brute-force login attacks
#ufw allow out 123/udp # allow outgoing NTP (Network Time Protocol)

# The following instructions will allow apk to work:
#ufw allow out DNS     # allow outgoing DNS
#ufw allow out 80/tcp  # allow outgoing HTTP traffic
#ufw allow out 443/tcp  # allow pcloud webdav access

#  enabling ufw
ufw enable
rc-service ufw restart
rc-update add ufw default

# [x] F8 Hardening SSH
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "Hardening SSH ..."
sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config # By setting this to no, connection speed can increase.
sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sed -r -i 's/^#?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
sed -r -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config 
sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
rc-service sshd restart

# [x] F9 Delete the root password
# NOTE The code is working and tested on alpine linux 3.19 
passwd -d root  # to delete the password.
#passwd -l root  # to lock the user.
#echo "Update root password ..."
#sudo pass generate system/root 50
#sudo bash -c 'ROOT_PASS=`pass system/root` && echo "root:$ROOT_PASS" | chpasswd'

# [x] F10 - OK - Disable IPV6
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "Disable IPV6 ..."
cat << EOF > /etc/sysctl.d/99-disable-ipv6.conf
# Diable IPV6 (Comment the three following lines to get IPV6 back)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF
#sysctl -p # to apply all the kernel parameters
sysctl -p /etc/sysctl.d/99-disable-ipv6.conf # to apply the modifications for the given file only

# [x] F11 System Tweak
# NOTE The code is working and tested on alpine linux 3.19 
echo "------------------------------------------------------------------------"
echo "System Tweak ..."

echo "Update the kernel options (concerning the console ttyS0 terminal) ..."
sed -Ei \
  -e "s|^[# ]*(default_kernel_opts)=.*|\1=\"console=ttyS0,115200n8 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory\"|" \
  -e "s|^[# ]*(serial_port)=.*|\1=ttyS0|" \
  -e "s|^[# ]*(modules)=.*|\1=sd-mod,usb-storage,ext4|" \
  -e "s|^[# ]*(default)=.*|\1=virt|" \
  -e "s|^[# ]*(timeout)=.*|\1=1|" \
  "/etc/update-extlinux.conf"
/sbin/extlinux --install /boot
/sbin/update-extlinux --warn-only

# Disable getty for physical ttys, enable getty for serial ttyS0.
# but we could not connect to terminal after it ????
#sed -Ei -e '/^tty[0-9]/s/^/#/' -e '/^#ttyS0:/s/^#//' "/etc/inittab"

## ------------------------------------------------------------------------
# [ ] F12 - configure update sceript and backup's folders list
# INCOMPLETE 
# The main idea behind this step is to allow the PVE01 system to update and backup the VM.
# Thus, we create an update script in /root/update.sh to update the VM system.
# Then, we create a backup's folders list to make a backup for specific folders.

echo "------------------------------------------------------------------------"
echo "configure update sceript and backup's folders list ..."

cat << EOF > /root/update.sh
#!/bin/sh
# --- Configs
log_file=/var/log/system-update.log

# --- Update
update_date_start=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "------------------------------------" >> \$log_file 2>&1
echo "Start system update at \${update_date_start}" >> \$log_file 2>&1
/sbin/apk update >> \$log_file 2>&1
/sbin/apk upgrade --no-cache --available >> \$log_file 2>&1
/sbin/apk -v cache clean
/sbin/apk -v cache purge
update_date_end=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "Update ended at \${update_date_end}" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1

# --- Done
EOF
chmod a+x /root/update.sh


cat << EOF > /root/backup.list
CONFIGS /etc
ROOT    /root
LOGS    /var/log
EOF

## ------------------------------------------------------------------------
# [x] Last step - Cleaning the system
# NOTE The code is working and tested on alpine linux 3.19 

echo "Cleaning the package system ..."
apk -v cache clean
apk -v cache purge
rm /var/cache/apk/*

# clean shell history
unset HISTFILE; rm -rf /root/.*history     # remove command history
find /home -type f  -name '.ash_history' -delete

# clean ssh data
shred -u /etc/ssh/*_key /etc/ssh/*_key.pub   # remove host keys
rm -f /root/.ssh/authorized_keys
find /home -type f  -name 'authorized_keys' -delete
rc-service sshd restart

# clean cloud init data
cloud-init clean

# stop the system
poweroff
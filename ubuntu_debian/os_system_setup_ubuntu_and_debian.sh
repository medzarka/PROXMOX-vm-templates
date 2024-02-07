#!/bin/bash
######################### Ubuntu 24.04/22.04 and Debian 11/12 templates setup script #############################



# https://docs.cloudstack.apache.org/en/4.18.1.0/adminguide/templates/_create_linux.html


# [x] F1 - Update the system ..
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "------------------------------------------------------------------------"
echo "Update the system ..."
sudo apt update
sudo apt upgrade -y

## ------------------------------------------------------------------------
# [x] F2 - Install required softwares
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "------------------------------------------------------------------------"
echo "Install required softwares..."
sudo apt install --no-install-recommends neofetch htop chrony tzdata nano parted -y

## ------------------------------------------------------------------------
# [x] F3 - F3 Setup NTP to Asia/Riyadh
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "Setup NTP to Asia/Riyadh ..."
sudo timedatectl set-timezone Asia/Riyadh
sudo timedatectl # to check

## ------------------------------------------------------------------------
# [x] F4 Install KVM guest agent (QEMU)
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "Install KVM guest agent (QEMU) ..."
sudo apt install --no-install-recommends qemu-guest-agent -y
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# [x] F5 install and configure cloud-init
# NOTE The ubuntu cloud image has already cloud-init installed
echo "------------------------------------------------------------------------"
echo "install and configure cloud-init ..."

# [x] F6 configure sudo/doas
# NOTE The ubuntu cloud image has already sudo without password configured
echo "------------------------------------------------------------------------"
echo "configure sudo and doas (no password required when using doas) ..."

# [x] F7 Configure the firewall
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "------------------------------------------------------------------------"
echo "Configure the firewall (22 only is accessible) ..."
sudo apt install --no-install-recommends ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit ssh         # open SSH port and protect against brute-force login attacks
#sudo ufw allow out 123/udp # allow outgoing NTP (Network Time Protocol)

# The following instructions will allow apk to work:
#sudo ufw allow out DNS     # allow outgoing DNS
#sudo ufw allow out 80/tcp  # allow outgoing HTTP traffic
#sudo ufw allow out 443/tcp  # allow outgoing HTTPS traffic

#  enabling ufw
sudo ufw enable
sudo systemctl enable ufw 
sudo systemctl restart ufw 

# [x] F8 Hardening SSH
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "------------------------------------------------------------------------"
echo "Hardening SSH ..."
sudo sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config # By setting this to no, connection speed can increase.
sudo sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config 
sudo sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config # Do not allow password authentication.
sudo systemctl restart ssh

# [x] F9 Delete the root password
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
sudo passwd -d root  # to delete the password.
sudo passwd -l root  # to lock the user.
#To update a user password from variable:
#sudo bash -c 'ROOT_PASS=`pass system/root` && echo "root:$ROOT_PASS" | chpasswd'

## ------------------------------------------------------------------------
# [x] F10 - OK - Disable IPV6
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "------------------------------------------------------------------------"
echo "Diable IPV6 ..."
# Only for Ubuntu and debian 12 ---------
sudo sed -r -i 's/dhcp6:.*/link-local: [ ipv4 ]/g' /etc/netplan/50-cloud-init.yaml
# it will be reset after cloud-init clean
# -------------------------

sudo bash -c 'cat << EOF > /etc/sysctl.d/99-disable-ipv6.conf
# Diable IPV6 (Comment the three following lines to get IPV6 back)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF'
#sysctl -p # to apply all the kernel parameters
sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf # to apply the modifications for the given file only
# reboot to apply modifications
# COMMENT The system will reload again the IPv6 after each reboot.
# COMMENT Then, We can solve the IPV6 issue by calling the following script hourly
sudo bash -c 'cat <<EOF > /etc/cron.hourly/disable-ipv6
#!/bin/bash
sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
EOF'
sudo chmod +x /etc/cron.hourly/disable-ipv6
sudo run-parts --test /etc/cron.hourly # to check

# [x] F11 System Tweak
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04
echo "------------------------------------------------------------------------"
echo "System Tweak ..."

echo "Avoid Network wait ..."
# Only for Ubuntu ---------
sudo systemctl disable lxd-agent
# -------------------------
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service

## ------------------------------------------------------------------------
# [ ] F12 - configure update sceript and backup's folders list
# INCOMPLETE 
# The main idea behind this step is to allow the PVE01 system to update and backup the VM.
# Thus, we create an update script in /root/update.sh to update the VM system.
# Then, we create a backup's folders list to make a backup for specific folders.

echo "------------------------------------------------------------------------"
echo "configure update sceript and backup's folders list ..."

sudo bash -c 'cat << EOF > /root/update.sh
#!/bin/bash
log_file=/var/log/system-update.log
update_date_start=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "------------------------------------" >> \$log_file 2>&1
echo "Start system update at \${update_date_start}" >> \$log_file 2>&1
sudo apt update >> \$log_file 2>&1
sudo apt upgrade -y >> \$log_file 2>&1
sudo apt-get -y clean  >> \$log_file 2>&1
sudo apt-get -y autoclean  >> \$log_file 2>&1
sudo apt-get -y autoremove  >> \$log_file 2>&1 
update_date_end=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "Update ended at \${update_date_end}" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
# --- Done
EOF'
sudo chmod a+x /root/update.sh


sudo bash -c 'cat << EOF > /root/backup.list
CONFIGS /etc
ROOT    /root
LOGS    /var/log
EOF'

# [x] Last step - Cleaning the system
# NOTE The code is working and tested on ubuntu linux 24.04 /22.04

########################################
echo "Cleaning the package system ..."
sudo apt-get -y clean 
sudo apt-get -y autoclean 
sudo apt-get -y autoremove --purge 
sudo rm -rf /var/lib/apt/lists/*

########################################
echo "Remove netplan file(s)"
sudo rm /etc/netplan/50-cloud-init.yaml

########################################
echo "Cleanup persistent udev rules"
rm -f /etc/udev/rules.d/70*
rm -f /var/lib/dhcp/dhclient.* # for redhat based system
rm -f /var/lib/dhclient/* # for ubuntu based system

########################################
echo "Clear the machine-id"
sudo truncate -s0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

########################################
echo "Run cloud-init clean"
sudo cloud-init clean

########################################
echo "Clear Shell History"
sudo truncate -s0 ~/.bash_history
sudo history -c
truncate -s0 ~/.bash_history
history -c

########################################
echo "Cleanup /tmp directories"
rm -rf /tmp/*
rm -rf /var/tmp/*

########################################
echo "Cleanup current ssh keys"
sudo shred -u /etc/ssh/*_key /etc/ssh/*_key.pub /etc/ssh/ssh_host_*   # remove host keys
sudo rm -f /root/.ssh/authorized_keys
sudo find /home -type f  -name 'authorized_keys' -delete
sudo systemctl restart ssh

########################################
echo "Reset hostname"
cat /dev/null > /etc/hostname

########################################
echo "Cleanup shell history"
unset HISTFILE; 
history -w
history -c
sudo history -w
sudo history -c
sudo rm -rf /root/.*history
sudo find /home -type f  -name '.ash_history' -delete 

########################################
echo "Cleaning log files"
cat /dev/null > /var/log/audit/audit.log 2>/dev/null
cat /dev/null > /var/log/wtmp 2>/dev/null
logrotate -f /etc/logrotate.conf 2>/dev/null
rm -f /var/log/*-* /var/log/*.gz 2>/dev/null


########################################
echo "Shutdown the VM"
sudo shutdown -h now

#-------------------------------------------------------------
# Extra

#sudo fallocate -l 2G /swapfile
#ls -lh /swapfile
#sudo chmod 600 /swapfile
#ls -lh /swapfile
#sudo mkswap /swapfile
#sudo swapon /swapfile
#sudo swapon --show
#sudo cp /etc/fstab /etc/fstab.bak
#echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab



#sudo bash -c 'cat <<EOF >> /etc/sysctl.d/99-swappiness.conf
#vm.swappiness=10
#vm.vfs_cache_pressure=50
#EOF'

#sudo reboot

# TODO 
# 1 - recreate the templates
# 2 - adjust the cleaning for each ubuntu distribution
# 3 - write a tutorial to be printed after each template creation. This tutorial enumerate steps to update the size of the disk.
# 4 - write a tutorial to create a swap file and update the swapiness and the cache pressure.
# 5 - execute this script directly from the vm creation script.



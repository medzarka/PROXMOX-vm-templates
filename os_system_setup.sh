#!/bin/sh

#LINUX_DISTRIBUTION=$(cat /etc/*-release | grep ID | head -n1 | cut -d '=' -f2)
LINUX_DISTRIBUTION=$(cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/["]//g' | awk '{print $1}')
LINUX_DISTRIBUTION_VERSION=$(cat /etc/*-release | grep VERSION_ID | head -n1 | cut -d '=' -f2 | cut -d '"' -f2)

# SEE NOTES -----------------------------------------------------------------------
# POST Check of the templates
# [x] Check Ubuntu 24.04 [disk size: 3584M | sda1 / (last) - 2.4G | sda16 /boot 881M | sda15 /boot/efi 105M | FREE SPACE AFTER UPDATE 984M | RAM: 166M]
# [x] Check Ubuntu 22.04 [disk size: 2252M | sda1 / (last) - 2G   | sda15 /boot/efi 105M | FREE SPACE AFTER UPDATE 50M WITH ERROR | RAM: 169M]
# [ ] Check Debian 12 [disk size: 2G | sda1 / (last) - 1.9G | sda15 /boot/efi 130M | FREE SPACE AFTER UPDATE 540M | RAM: 110M]
# [ ] Check Ubuntu 11 [disk size: 2G | sda1 / (last) - 1.9G | sda15 /boot/efi 130M | FREE SPACE AFTER UPDATE 651M | RAM: 65M]
# [x] Check Alpine 3.19 [disk size: 1G | sda3 / (last) - 427M | sda1 /boot 271M | FREE SPACE AFTER UPDATE 248M | RAM: 45M]
# [ ] Check Rocky 9
# [ ] Check Rocky 8

# SEE NOTES -----------------------------------------------------------------------


# [x] F0 - System identification ..
echo ""
echo "------------------------------------------------------------------------"
echo "System identification ..."
echo "Detected Linux distribution --> $LINUX_DISTRIBUTION"
echo "Linux distribution version  --> $LINUX_DISTRIBUTION_VERSION"

# [x] F1 - Update the system ...
echo ""
echo "------------------------------------------------------------------------"
echo "Update the system ..."
if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections
sudo apt-get update
sudo apt-get upgrade -y --no-install-recommends
sudo apt-get autoremove -y --purge
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas sed -i 's/#http/http/g' /etc/apk/repositories # enable community repository
doas apk update
doas apk upgrade --no-cache --available
fi

if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo dnf update -y
fi

## ------------------------------------------------------------------------
# [x] F2 - Install required softwares
echo ""
echo "------------------------------------------------------------------------"
echo "Install required softwares..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections
sudo apt-get install --no-install-recommends neofetch htop chrony tzdata nano parted wget -y
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas apk --no-cache add neofetch htop chrony doas tzdata nano parted bash parted wget
doas apk --no-cache add python3 py3-pip py3-pyserial py3-netifaces # required for cloud init
fi

if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo dnf -y install bash-completion chrony tzdata nano parted wget yum-utils
fi

## ------------------------------------------------------------------------
# [x] F3 - F3 Setup NTP to Asia/Riyadh
echo ""
echo "------------------------------------------------------------------------"
echo "Setup NTP to Asia/Riyadh ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo timedatectl set-timezone Asia/Riyadh
sudo timedatectl # to check
fi
if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas setup-timezone -z Asia/Riyadh
doas rc-update add chronyd default
fi

## ------------------------------------------------------------------------
# [x] F4 Install KVM guest agent (QEMU)
echo ""
echo "------------------------------------------------------------------------"
echo "Install KVM guest agent (QEMU) ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections
sudo apt-get install --no-install-recommends qemu-guest-agent -y
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
fi
if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas apk --no-cache add qemu-guest-agent
doas rc-update add qemu-guest-agent
doas rc-service qemu-guest-agent start
fi
if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo dnf -y install qemu-guest-agent 
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
fi

# [x] F5 install and configure cloud-init
echo ""
echo "------------------------------------------------------------------------"
echo "install and configure cloud-init ..."
# Here, we will install cloud-init only on Alpine. 
# The other distributions have cloud-init already installed.

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas apk --no-cache add cloud-init cloud-utils-growpart e2fsprogs e2fsprogs-extra
doas sh -c 'echo 'isofs' > /etc/modules-load.d/isofs.conf'
doas chmod -x /etc/modules-load.d/isofs.conf
doas setup-cloud-init
doas sh -c "echo 'datasource_list: [ NoCloud, ConfigDrive, None ]' > /etc/cloud/cloud.cfg.d/99_pve.cfg"
doas chmod 644 /etc/cloud/cloud.cfg.d/99_pve.cfg
else
echo "  --- Cloud-init is already installed and configured for Ubuntu/Debian/Rocky distributions"
fi

# [x] F6 configure sudo/doas
echo ""
echo "------------------------------------------------------------------------"
echo "configure sudo and doas (no password required when using doas) ..."
# Here, we will configure doas only on Alpine. 
# The other distributions have sudo permit already configured.

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
## configure sudo and doas
#  !!!! Please to consider only one option
# ------------ no password required ------------
# for sudo --> echo '%wheel ALL=(ALL) NOPASSWD: ALL' > "/etc/sudoers.d/wheel"
doas sh -c "echo 'permit nopass :wheel' > /etc/doas.d/wheel.conf"
doas sh -c "echo 'permit nopass keepenv root as root' >> /etc/doas.d/wheel.conf"
# ------------ with required user password ------------
# for sudo --> echo '%wheel ALL=(ALL) ALL' > "/etc/sudoers.d/wheel"
#echo 'permit persist :wheel' > "/etc/doas.d/wheel.conf"
#echo 'permit nopass keepenv root as root' >> "/etc/doas.d/wheel.conf"
echo "  --- doas permit is installed and configured for Alpine distribution"
else
echo "  --- sudo permit is already installed and configured for Ubuntu/Debian/Rocky distributions"
fi

# [x] F7 Configure the firewall
echo ""
echo "------------------------------------------------------------------------"
echo "Configure the firewall (only ssh port is accessible) ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections
sudo apt-get install --no-install-recommends ufw -y  # BUG install and config issue with debian 11
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit ssh  # open SSH port and protect against brute-force login attacks
#sudo ufw allow out 123/udp # allow outgoing NTP (Network Time Protocol)
# The following instructions will allow apk to work:
#sudo ufw allow out DNS     # allow outgoing DNS
#sudo ufw allow out 80/tcp  # allow outgoing HTTP traffic
#sudo ufw allow out 443/tcp  # allow outgoing HTTPS traffic

#  enabling ufw
sudo ufw --force enable
sudo systemctl enable ufw 
sudo systemctl restart ufw 
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas apk --no-cache add ufw
doas ufw default deny incoming
doas ufw default allow outgoing
doas ufw limit SSH  
doas ufw --force enable
doas rc-service ufw restart
doas rc-update add ufw default
fi

if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then # BUG ERROR:dbus.proxies:Introspect error on :1.47:/org/fedoraproject/FirewallD1: dbus.exceptions.DBusException: org.freedesktop.DBus.Error.NoReply: Did not receive a reply. Possible causes include: the remote application did not send a reply, the message bus security policy blocked the reply, the reply timeout expired, or the network connection was broken.
sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld
# to list the services that are already allowed
sudo firewall-cmd --permanent --list-all
# to get the list of the known services
sudo firewall-cmd --get-services    
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
fi

# [x] F8 Hardening SSH
echo ""
echo "------------------------------------------------------------------------"
echo "Hardening SSH ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
sudo sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config # By setting this to no, connection speed can increase.
sudo sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config 
sudo sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config # Do not allow password authentication.
sudo systemctl restart ssh
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config # By setting this to no, connection speed can increase.
doas sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
doas sed -r -i 's/^#?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
doas sed -r -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
doas sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config 
doas sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
doas rc-service sshd restart
fi

if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config # By setting this to no, connection speed can increase.
sudo sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config 
sudo sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config # Do not allow password authentication.
sudo systemctl restart sshd
fi
echo " --- /etc/ssh/sshd_config file is updated"

# [x] F9 Delete the root password
echo ""
echo "------------------------------------------------------------------------"
echo "Lock the root user ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo passwd -d root  # to delete the password.
sudo passwd -l root  # to lock the user.
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas passwd -d root  # to delete the password.
doas passwd -l root  # to lock the user.
fi

#To update a user password from variable:
#sudo bash -c 'ROOT_PASS=`pass system/root` && echo "root:$ROOT_PASS" | chpasswd'

## ------------------------------------------------------------------------
# [x] F10 - Disable IPV6
echo ""
echo "------------------------------------------------------------------------"
echo "Diable IPV6 ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
#sudo bash -c 'cat << EOF > /etc/sysctl.d/99-disable-ipv6.conf
sudo tee /etc/sysctl.d/99-disable-ipv6.conf <<EOF
# Diable IPV6 (Comment the three following lines to get IPV6 back)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF
sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf # to apply the modifications for the given file only
echo " --- /etc/sysctl.d/99-disable-ipv6.conf file is created and applied"
# reboot to apply modifications
# COMMENT The system will reload again the IPv6 after each reboot.
# COMMENT Then, We can solve the IPV6 issue by calling the following script hourly
sudo mkdir -p /etc/cron.hourly
#sudo bash -c 'cat <<EOF > /etc/cron.hourly/disable-ipv6
sudo tee /etc/cron.hourly/disable-ipv6 <<EOF
#!/bin/bash
sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
EOF
sudo chmod +x /etc/cron.hourly/disable-ipv6
sudo run-parts --test /etc/cron.hourly # to check
echo " --- /etc/cron.hourly/disable-ipv6 hourly file is created"
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas tee /etc/sysctl.d/99-disable-ipv6.conf <<EOF
# Diable IPV6 (Comment the three following lines to get IPV6 back)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF
doas sysctl -p /etc/sysctl.d/99-disable-ipv6.conf # to apply the modifications for the given file only
echo " --- /etc/sysctl.d/99-disable-ipv6.conf file is created and applied"
fi

# Only for Ubuntu and debian 12 ---------
#sudo sed -r -i 's/dhcp6:.*/link-local: [ ipv4 ]/g' /etc/netplan/50-cloud-init.yaml
# it will be reset after cloud-init clean
# -------------------------

# [x] F11 System Tweak
echo ""
echo "------------------------------------------------------------------------"
echo "System Tweak ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
echo " --- disabling lxd-agent service ..."
if [ "$LINUX_DISTRIBUTION" = "Debian" ]; then 
sudo systemctl disable lxd-agent
fi
echo " --- disabling systemd-networkd-wait-online.service ..."
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
echo " --- Update the kernel options (concerning the console ttyS0 terminal) ..."
doas sed -Ei \
-e "s|^[# ]*(default_kernel_opts)=.*|\1=\"console=ttyS0,115200n8 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory\"|" \
-e "s|^[# ]*(serial_port)=.*|\1=ttyS0|" \
-e "s|^[# ]*(modules)=.*|\1=sd-mod,usb-storage,ext4|" \
-e "s|^[# ]*(default)=.*|\1=virt|" \
-e "s|^[# ]*(timeout)=.*|\1=1|" \
"/etc/update-extlinux.conf"
doas /sbin/extlinux --install /boot
doas /sbin/update-extlinux --warn-only
# Disable getty for physical ttys, enable getty for serial ttyS0.
# but we could not connect to terminal after it ????
#sed -Ei -e '/^tty[0-9]/s/^/#/' -e '/^#ttyS0:/s/^#//' "/etc/inittab"
fi
if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
echo " "
fi

# [ ] F12 - configure update script and backup's folders list
echo ""
echo "------------------------------------------------------------------------"
echo "Configure an update script and backup's folders list ..."
# The main idea behind this step is to allow the PVE01 system to update and backup the VM.
# Thus, we create an update script in /root/update.sh to update the VM system.
# Then, we create a backup's folders list to make a backup for specific folders.

echo " --- configure a system update script (that will be executed by proxmox) ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then 
#sudo bash -c 'cat << EOF > /root/update.sh   # RECHECK do not work on debian 11 and 12
sudo tee /root/update.sh <<EOF
#!/bin/bash
log_file=/var/log/system-update.log
update_date_start=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "------------------------------------" >> \$log_file 2>&1
echo "Start system update at \${update_date_start}" >> \$log_file 2>&1
sudo bash -c "echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections"
echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections
sudo apt-get update >> \$log_file 2>&1
sudo apt-get -y upgrade --no-install-recommends >> \$log_file 2>&1
sudo apt-get -y autoremove --purge >> \$log_file 2>&1
sudo apt-get -y clean >> \$log_file 2>&1
sudo apt-get -y autoclean  >> \$log_file 2>&1
sudo apt-get -y autoremove --purge >> \$log_file 2>&1 
update_date_end=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "Update ended at \${update_date_end}" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
EOF
sudo chmod a+x /root/update.sh
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas tee /root/update.sh <<EOF # RECHECK do not work on Alpine, inexistant file
#!/bin/sh
log_file=/var/log/system-update.log
update_date_start=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "------------------------------------" >> \$log_file 2>&1
echo "Start system update at \${update_date_start}" >> \$log_file 2>&1
doas /sbin/apk update >> \$log_file 2>&1
doas /sbin/apk upgrade --no-cache --available >> \$log_file 2>&1
doas /sbin/apk -v cache clean >> \$log_file 2>&1
doas /sbin/apk -v cache purge >> \$log_file 2>&1
update_date_end=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "Update ended at \${update_date_end}" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
EOF
doas chmod a+x /root/update.sh
fi

if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo tee /root/update.sh <<EOF
#!/bin/sh
log_file=/var/log/system-update.log
update_date_start=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "------------------------------------" >> \$log_file 2>&1
echo "Start system update at \${update_date_start}" >> \$log_file 2>&1
sudo dnf update -y >> \$log_file 2>&1
sudo dnf clean dbcache >> \$log_file 2>&1
sudo dnf clean all >> \$log_file 2>&1 
update_date_end=\$(date +'%m-%d-%Y--%H:%M:%S')
echo "Update ended at \${update_date_end}" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
echo "" >> \$log_file 2>&1
EOF
sudo chmod a+x /root/update.sh
fi

echo " --- configure a backup list (that will be backuped by proxmox) ..."

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
#sudo bash -c 'cat << EOF > /root/backup.list # RECHECK do not work on debian 11
sudo tee /root/backup.list <<EOF
CONFIGS /etc
ROOT    /root
LOGS    /var/log
EOF
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
#doas sh -c 'cat << EOF > /root/backup.list # RECHECK do not work on Alpine, inexistant file
doas tee /root/backup.list <<EOF
CONFIGS /etc 
ROOT    /root
LOGS    /var/log
EOF
fi

# [x] Last step - Cleaning the system
echo ""
echo "------------------------------------------------------------------------"
echo "Cleaning the system ..."

########################################
echo " --- Cleaning the package system ..."
if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
echo "debconf debconf/frontend select noninteractive" | sudo debconf-set-selections
sudo apt-get -y clean 
sudo apt-get -y autoclean 
sudo apt-get -y autoremove --purge 
sudo rm -rf /var/lib/apt/lists/*
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas apk -v cache clean
doas apk -v cache purge
doas rm /var/cache/apk/*
fi

if [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo dnf -y autoremove
sudo dnf -y clean all  --enablerepo=\*;
fi

########################################
#echo " --- Remove netplan file(s)"
#if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ]; then
#sudo rm -f /etc/netplan/50-cloud-init.yaml
#fi

########################################
#echo " --- Cleanup persistent udev rules"
#if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
#sudo rm -rf /etc/udev/rules.d/70*
#sudo rm -rf /var/lib/dhclient/* # for ubuntu based system
#sudo rm -rf /var/lib/dhcp/dhclient.* # for redhat based system
#fi

#if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
#doas rm -rf /etc/udev/rules.d/70*
#doas rm -rf /var/lib/dhcp/dhclient.* # for redhat based system
#doas rm -rf /var/lib/dhclient/* # for ubuntu based system
#fi

########################################
echo " --- Clear the machine-id"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo truncate -s0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas truncate -s0 /etc/machine-id
doas rm -f /var/lib/dbus/machine-id
fi

########################################
echo " --- Run cloud-init clean"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo cloud-init clean
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas cloud-init clean >> /dev/null 2>&1
fi


########################################
echo " --- Clear Shell History"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo rm -rf /root/.*history     # remove command history
sudo find /home -type f  -name '.*_history' -delete
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas rm -rf /root/.*history     # remove command history
doas find /home -type f  -name '.*_history' -delete
fi

########################################
echo " --- Cleanup /tmp directories"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas rm -rf /tmp/*
doas rm -rf /var/tmp/*
fi

########################################
echo " --- Cleanup current ssh keys"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo rm -f /etc/ssh/*_key /etc/ssh/*_key.pub /etc/ssh/ssh_host_*   # remove host keys
sudo rm -f /root/.ssh/authorized_keys
sudo find /home -type f  -name 'authorized_keys' -delete
#sudo systemctl restart ssh
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas rm -f  /etc/ssh/*_key /etc/ssh/*_key.pub /etc/ssh/ssh_host_*   # remove host keys
doas rm -f /root/.ssh/authorized_keys
doas find /home -type f  -name 'authorized_keys' -delete
fi


########################################
echo " --- Reset hostname"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo bash -c "echo /dev/null >> /etc/hostname"
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas sh -c "echo /dev/null >> /etc/hostname"
fi


########################################
echo " --- Cleaning log files"

if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
sudo rm -rf /var/log/**
fi

if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
doas rm -rf /var/log/**
fi

########################################
#echo " --- Shutdown the VM"

#if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ] || [ "$LINUX_DISTRIBUTION" = "Debian" ] || [ "$LINUX_DISTRIBUTION" = "Rocky" ]; then
#sudo shutdown -h now
#fi

#if [ "$LINUX_DISTRIBUTION" = "Alpine" ]; then
#doas poweroff
#fi

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
# [ ] - write a tutorial to be printed after each template creation. This tutorial enumerate steps to update the size of the disk.
# [ ] - write a tutorial to create a swap file and update the swapiness and the cache pressure.





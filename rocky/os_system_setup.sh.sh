#!/bin/sh

######################### Debian 12 template setup script #############################

# version 0.1
# ------------------------------------------------------------------------------------------------------------------
# 1 - Update the system
# 2 - Install required softwares (neofetch htop chrony tzdata nano)
# 3 - Setup NTP to Asia/Riyadh
# 4 - Install KVM guest agent (QEMU)
# 5 - Configure CRON for daily system update
# 6 - Configure the firewall (22 only is accessible. ROOT user is locked.)
# 7 - system cleaning
# ------------------------------------------------------------------------------------------------------------------

## ------------------------------------------------------------------------
echo "Update the system and install some required packages ..."
sudo apt update
sudo apt upgrade -y

## ------------------------------------------------------------------------
echo "Install required softwares ..."
sudo apt install --no-install-recommends neofetch htop chrony tzdata nano cloud-guest-utils -y

## ------------------------------------------------------------------------
echo "setup time zone and NTP ..."
sudo timedatectl set-timezone Asia/Riyadh
sudo timedatectl # to check

## ------------------------------------------------------------------------
echo "Install and enable QEMU guest agent ..."
sudo apt install --no-install-recommends qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

## ------------------------------------------------------------------------
echo "CRON daily system update ..."
sudo apt install --no-install-recommends cron -y
sudo systemctl enable cron
sudo systemctl start cron
sudo cat <<EOF > /etc/cron.daily/package-update
#!/bin/bash
sudo apt update 
sudo apt upgrade -y
EOF
sudo chmod a+x /etc/cron.daily/package-update
sudo run-parts --test /etc/cron.daily # to check

## ------------------------------------------------------------------------
echo "onfigure the firewall (22 only is accessible. ROOT user is locked.) ..."
sudo apt install --no-install-recommends ufw
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


## ------------------------------------------------------------------------
# Hardening SSH

sudo sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config # By setting this to no, connection speed can increase.
sudo sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config 
sudo sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config # Do not allow password authentication.
sudo systemctl restart sshd ssh

## ------------------------------------------------------------------------
#  clean up
sudo rm -rf /config/* /tmp/* /var/lib/apt/lists/* /var/tmp/* 
sudo apt-get -y clean 
sudo apt-get -y autoclean 
sudo apt-get -y autoremove 
sudo rm -rf /var/lib/apt/lists/*


sudo su -
cat /dev/null > /etc/machine-id
cat /dev/null > /var/lib/dbus/machine-id
cat /dev/null > /var/lib/dbus/machine-id
cloud-init clean
shutdown -h now





# PROXMOX-vm-templates


### Alpine Linux Machine Templates

#### Alpine Linux Version 3.19
- Execute the script **vm_template_setup.sh**. It creates the VM template and prints some usefull information on how to finilize installing Alpine Linux.

- After starting the new created VM template, start a Terminal and execute the script **os_system_setup.sh**. This script handles these steps:
  - F1 - Configure the alpine repositories and update the system,
  - F2 - Install required softwares (neofetch htop chrony doas tzdata nano parted bash) and some other softwares required for CloudInit (python3 py3-pip py3-pyserial py3-netifaces),
  - F3 - Setup NTP time zone,
  - F4 - Install KVM guest agent (QEMU),
  - F5 - Install and configure cloud-init,
  - F6 - Configure doas (doas reboot and doas halt are working). Here we choose to get doas access without password prompt,
  - F7 - Configure the ufw firewall (opening only the SSH port),
  - F8 - Hardening SSH access,
  - F9 - Disable IPV6, 
  - F10 - Update the kernel options (concerning the console ttyS0 terminal),
  - F11 - Configure a script to update, backup and synchronize the system,
  

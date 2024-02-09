# PROXMOX-vm-templates

The repository provide a set of shell scripts to create **Proxmox** virtual machines templates.

We are focusing on Ubuntu 22.0/24.04, Debian 11/12, Alpine Linux 3.19 and Rocky Linux 8/9.

All the templates are created from the cloud raw images (see vm_template_<**distribution_name**>__<**version**>.sh files for images urls). 

As an exeception, Alpine linux template is created based on a hand created raw image through creating a simple vm, install alpine linux from iso file on it, then create a backup of the vm and finally convert the dump file to a raw image:
- we decompress the backup to have the .vma using the command `zstd -d vzdump-qemu-$VMID....vma.zst`. 
- we cxtract the vma through the command `vma extract vzdump-qemu-$VMID....vma ./export`. The latter will give a .raw file (disk image ) and a .conf file (VM Config).

Once the virtual machines, that we will use as templates, are created, we execute a script to prepare a template. This script intend to:

0 - Identify the linux distribution and version. In this step, we expand the virtual disk if we want to have more disk space.
1 - Update the system.
2 - Install required softwares (neofetch htop chrony doas tzdata nano parted bash) and some other softwares required for Cloud-Init (python3 py3-pip py3-pyserial py3-netifaces),
3 - Setup NTP time zone. In this step, it is configured on Asia/Riyadh. but it could be updated.
4 - Install KVM guest agent (QEMU).
5 - Install and configure cloud-init (in particular for Alpine Linux).
6 - Configure doas in particular for Alpine Linux). Here we choose to get doas access without password prompt.
7 - Configure the **ufw** firewall (for ubuntu, alpine and debian distributions). For rocky linux, we configure **firewalld**.
8 - Hardening SSH access through some tweaks on the */etc/ssh/sshd_config* file.
9 - Disable IPV6.
10 - Upply some specific tweaks:
  - for ubuntu/debian based templates, we desactivate the *lxd-agent* and *systemd-networkd-wait-online* services.
  - for alpine based template, we add some extra options to the boot loader in order to work well with ttyS0 console.
11 - we write two scripts:
  - /root/update.sh : that will contain instructions to update the system. This script will be called periodically by the **Proxmox** system (through ssh call).
  - /root/backup.list : is a file that contains pairs of names and pathes. This data will be used periodically by the **Proxmox** system to backup the virtual machine according the pathes provides.
12 - Clean the system through:
  - Cleaning the package system,
  - Clearing the machine-id,
  - Running cloud-init clean,
  - Clearing Shell History,
  - Cleaning /tmp directories,
  - Cleaning ssh keys,
  - Reset the hostname,
  - and finally cleaning log files.

  

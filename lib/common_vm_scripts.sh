

# NOTE - Template scripts

convert_vm_to_template(){

    echo " --- shutdown the template"
    sudo qm shutdown $TEMPLATE_VM_ID --forceStop 1 --timeout 60

    echo " --- dump the vm $TEMPLATE_VM_ID"
    sudo vzdump $TEMPLATE_VM_ID --mode stop --mailto root 

    echo " --- convert the vm $TEMPLATE_VM_ID to a template"
    sudo qm template $TEMPLATE_VM_ID
}

template_os_setup(){
    echo "-----------------------------------------------------------------"
    echo "Configuring the template OS system ..."

    echo "   start the template"
    sudo qm start $TEMPLATE_VM_ID

    echo "  waiting the system to be fully loaded and the port 22 is open."
    IPP=$(echo $IP | cut -d '/' -f1)
    while true; do
        nc -z -v -w60 $IPP 22 >> /dev/null 2>&1
        result=$?
        if [  "$result" != 0 ]; then
            echo "     still waiting"
            sleep 3
        else
            break
        fi
    done

    echo "   execute the script on the template"
    ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $DEFAULT_USER@$IPP 'sh -s' < os_system_setup.sh
    echo "   the execution of the script on the template is done."

    
    
    
}

create_new_template(){
    echo "-----------------------------------------------------------------"
    echo "Create the new VM Template ..."
    sudo qm create $TEMPLATE_VM_ID --name $TEMPLATE_NAME 
    sudo qm set $TEMPLATE_VM_ID --net0 virtio,bridge=$BRIDGE,tag=$VLAN  
    sudo qm set $TEMPLATE_VM_ID --memory $RAM 
    sudo qm set $TEMPLATE_VM_ID --machine q35 
    sudo qm set $TEMPLATE_VM_ID --ostype l26 
    #sudo qm set $TEMPLATE_VM_ID --numa 1 
    sudo qm set $TEMPLATE_VM_ID --cores $CORES --cpu cputype=host 
    sudo qm set $TEMPLATE_VM_ID --scsihw virtio-scsi-single
    sudo qm importdisk $TEMPLATE_VM_ID $IMAGE_PATH $STORAGE
    sudo qm set $TEMPLATE_VM_ID --scsi0 $STORAGE:vm-$TEMPLATE_VM_ID-disk-0,aio=io_uring,cache=unsafe,discard=on,iothread=1,ssd=1
    sudo qm set $TEMPLATE_VM_ID --boot c --bootdisk scsi0
    #sudo qm set $TEMPLATE_VM_ID --scsi0 $STORAGE:$DISKIMAGE_SIZE,aio=io_uring,cache=unsafe,discard=on,iothread=1,ssd=1 
    #sudo qm set $TEMPLATE_VM_ID --boot c --bootdisk scsi0 
    sudo qm set $TEMPLATE_VM_ID --tablet 0 
    sudo qm set $TEMPLATE_VM_ID --serial0 socket --vga serial0 
    sudo qm set $TEMPLATE_VM_ID --agent enabled=1 
    sudo qm set $TEMPLATE_VM_ID --tags $TAGS 
    sudo qm set $TEMPLATE_VM_ID --ide2 $STORAGE:cloudinit 
    sudo qm set $TEMPLATE_VM_ID --ciuser $DEFAULT_USER 
    sudo qm set $TEMPLATE_VM_ID --cipassword $(openssl passwd -6 $USER_PASSWORD) 
    sudo qm set $TEMPLATE_VM_ID --sshkeys /root/.ssh/authorized_keys 
    sudo qm set $TEMPLATE_VM_ID --ipconfig0 ip=$IP,gw=$GW,ip6=auto
    #sudo qm set $TEMPLATE_VM_ID --ipconfig0 ip=dhcp,ip6=auto 
    sudo qm set $TEMPLATE_VM_ID --nameserver $DNS 
    sudo qm set $TEMPLATE_VM_ID --searchdomain $MAIN_DOMAIN 
    sudo qm set $TEMPLATE_VM_ID --ciupgrade 0

    if [ $DISKIMAGE_SIZE != "0G" ]
    then
        echo "Update the disk image size to $DISKIMAGE_SIZE ..."
        sudo qm disk resize $TEMPLATE_VM_ID scsi0 $DISKIMAGE_SIZE
    else
        echo "Disk image resize ignored"
    fi

    sudo sync

    
}


# [ ] Download a VM disk image from a given URL
download_vm_disk_image(){
    IMAGE_URL=$1
    IMAGE_PATH=$2

    echo ""
    echo "-----------------------------------------------------------------"
    if [ -n "$IMAGE_URL" ] && [ -n "$IMAGE_PATH" ] && [ -n "$DISKIMAGE_SIZE" ]; then
    
        if [ -e $IMAGE_PATH ]
        then
            echo "The VM disk image is already downloaded."
        else
            echo "Download the VM disk image ..."
            wget -O $IMAGE_PATH  $IMAGE_URL
            du -sh $IMAGE_PATH
        fi

    else
        echo "ERROR: IMAGE_URL/IMAGE_PATH/DISKIMAGE_SIZE are not well provided for the download_vm_disk_image function."
        echo "Exiting."
        exit -1
    fi
}

# [ ] Destroy a VM for a givem VM ID
destroy_old_vm(){

    VM_ID=$1
    echo ""
    echo "-----------------------------------------------------------------"
    if [ -n "$VM_ID" ] ; then
        echo "Destroying the old VM wit ID $VM_ID ..."
        sudo qm stop $VM_ID 
        sudo qm destroy $VM_ID --destroy-unreferenced-disks 1 --purge 1 
    else
        echo "ERROR: VM_ID is not well provided for the destroy_old_vm function."
        echo "Exiting."
        exit -1
    fi
}



# [ ] Create a new VM



# [x] Setp 1 - Write a function to create or retrieve a common variable from PASS
create_retrive_common_variable_from_pass()
{
    RETURN_VALUE=""
    DATA_NAME=$1

    if [ -n "$DATA_NAME" ]; then 

        DATA_PATH="pve01/templates/common/$DATA_NAME"
        DATA_VALUE=$(pass $DATA_PATH)  
        if [[ -z "$DATA_VALUE" ]]; then 
            echo "The $DATA_NAME variable is not defined, please type it twice (like a password):"
            pass insert $DATA_PATH
            DATA_VALUE=$(pass $DATA_PATH)  
            echo "The $DATA_NAME is defined to $DATA_VALUE"
        else
            echo "The $DATA_NAME is already defined to $DATA_VALUE"
        fi

        RETURN_VALUE=$DATA_VALUE

    else
        echo "ERROR: The DATA_NAME is not defined for the create_retrive_common_variable_from_pass function. Exiting" 
        exit -1
    fi
        
}

# [x] Setp 2 - Write a function to create or retrieve a VM specific variable from PASS
create_retrive_specific_vm_variable_from_pass()
{
    RETURN_VALUE=""
    VM_ID=$1
    DATA_NAME=$2

    if [ -n "$VM_ID" ] && [ -n "$DATA_NAME" ]; then

        DATA_PATH="pve01/templates/$VM_ID/$DATA_NAME"
        DATA_VALUE=$(pass $DATA_PATH)  
        if [[ -z "$DATA_VALUE" ]]; then 
            echo "The $DATA_NAME variable for the VM $VM_ID is not defined, please type it twice (like a password):"
            pass insert $DATA_PATH
            DATA_VALUE=$(pass $DATA_PATH)  
            echo "The $DATA_NAME for the VM $VM_ID is defined to $DATA_VALUE"
        else
            echo "The $DATA_NAME for the VM $VM_ID is already defined to $DATA_VALUE"
        fi

        RETURN_VALUE=$DATA_VALUE
        
    else
        echo "ERROR: The DATA_NAME/VM_ID are not well defined for the create_retrive_specific_vm_variable_from_pass function. Exiting" 
        exit -1
    fi
}

# [x] Setp 2 - Write a function to create or retrieve a VM specific USER_PASSWORD from PASS
create_retrive_specific_template_user_password_from_pass()
{
    RETURN_VALUE=""
    VM_ID=$1
    DEFAULT_PASSWORD_LENGTH=$2
    DATA_NAME="default_user_password"

    if [ -n "$VM_ID" ] && [ -n "$DEFAULT_PASSWORD_LENGTH" ]; then

        DATA_PATH="pve01/templates/$VM_ID/$DATA_NAME"
        DATA_VALUE=$(pass $DATA_PATH)  
        if [[ -z "$DATA_VALUE" ]]; then 
            echo "The $DATA_NAME variable for the VM $VM_ID is not defined, we will generate a new one."
            pass generate $DATA_PATH $DEFAULT_PASSWORD_LENGTH -n 
            DATA_VALUE=$(pass $DATA_PATH)  
            echo "The $DATA_NAME for the VM $VM_ID is defined to $DATA_VALUE"
        else
            echo "The $DATA_NAME for the VM $VM_ID is already defined to $DATA_VALUE"
        fi

        RETURN_VALUE=$DATA_VALUE
        
    else
        echo "ERROR: The DEFAULT_PASSWORD_LENGTH/VM_ID are not well defined for the create_retrive_specific_template_user_password_from_pass function. Exiting" 
        exit -1
    fi
}

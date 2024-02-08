

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

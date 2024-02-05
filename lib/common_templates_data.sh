#!/bin/bash


echo "--------------------------------------------------------"
PASS_DATA_PATH=pve01/templates/common/domain > /dev/null 2>&1
MAIN_DOMAIN=$(pass $PASS_DATA_PATH)  
if [[ -z "$MAIN_DOMAIN" ]]; then 
    #pass generate pve01/vms/"$TEMPLATE_VM_ID" $PASSWORD_LENGTH -n 
    echo "The main domain is not defined, please type it twice:"
    pass insert $PASS_DATA_PATH
    MAIN_DOMAIN=$(pass $PASS_DATA_PATH)  
    echo "The main domain is defined to $MAIN_DOMAIN ."
else
    echo "The main domain is defined to $MAIN_DOMAIN ."
fi

echo "--------------------------------------------------------"
PASS_DATA_PATH=pve01/templates/common/default_user > /dev/null 2>&1
DEFAULT_USER=$(pass $PASS_DATA_PATH)  
if [[ -z "$DEFAULT_USER" ]]; then 
    #pass generate pve01/vms/"$TEMPLATE_VM_ID" $PASSWORD_LENGTH -n 
    echo "The default username is not defined, please type it twice:"
    pass insert $PASS_DATA_PATH
    DEFAULT_USER=$(pass $PASS_DATA_PATH)  
    echo "The default username is defined to $DEFAULT_USER ."
else
    echo "default username is defined to $DEFAULT_USER ."
fi
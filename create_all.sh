mkdir -p log/
rm -rf log/**

echo "Create the ubuntu_24.04 template"
bash vm_template_ubuntu_24.04.sh >> log/ubuntu_24.04.log 2>&1

echo "Create the ubuntu_22.04 template"
bash vm_template_ubuntu_22.04.sh >> log/ubuntu_22.04.log 2>&1

echo "Create the debian 12 template"
bash vm_template_debian_12.sh >> log/debian_12.log 2>&1 

echo "Create the Debian 11 template"
bash vm_template_debian_11.sh >> log/debian_11.log 2>&1  

echo "Create the alpine 3.19 template"
bash vm_template_alpine_3.19.sh  >> log/alpine_3.19.log 2>&1 

#echo "Create the Rocky 9 template"
#bash vm_template_rocky_9.sh >> log/rocky_9.log 2>&1

#echo "Create the Rocky 8 template"
#bash vm_template_rocky_8.sh >> log/rocky_8.log 2>&1
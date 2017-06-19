#Devstack services can be acccessed using Screen
#Test your connection to screen by using screen -r stack
#This will return an error but on /dev/pts/<number>
#Change mod using sudo chmod 777 /dev/pts/**
#There is an error when uploading large images (like windows)
#To avoid this pitfall, upgrade webob and then restart all services in screen
#sudo pip install webob --upgrade
cd /home/stack
mkdir images
cd /home/stack/images
#Download Images from URLs
#wget https://pubmirror2.math.uh.edu/fedora-buffet/fedora/linux//releases/25/CloudImages/x86_64/images/Fedora-Cloud-Base-25-1.3.x86_64.qcow2
#wget https://pubmirror2.math.uh.edu/fedora-buffet/fedora/linux//releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-22-20150521.x86_64.qcow2
#wget https://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img
#wget http://cloud.centos.org/centos/6/images/CentOS-6-x86_64-GenericCloud-1508.qcow2
###wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1705.qcow2
###wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
###wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img

#Source Chameleon Cloud Credentials
cat <<'EOF' >> chameleon-openrc
#!/bin/bash
export OS_AUTH_URL=https://chi.tacc.chameleoncloud.org:5000/v2.0
export OS_TENANT_ID=fe290d303ec049e6824a89820ab123b8
export OS_TENANT_NAME="CH-818983"
export OS_PROJECT_NAME="CH-818983"
export OS_USERNAME="gonzalo"
echo "Please enter your Chameleon Password: "
read -sr OS_PASSWORD_INPUT
export OS_PASSWORD=$OS_PASSWORD_INPUT
export OS_REGION_NAME="regionOne"
if [ -z "$OS_REGION_NAME" ]; then unset OS_REGION_NAME; fi
EOF

source /home/stack/devstack/openrc admin admin
OS_TENANT_ID_BU=$(openstack project list | grep -w "admin" | awk '{print $2}')
source /home/stack/images/chameleon-openrc

#Download Images from Swift
swift download cisco-images CentOS-6-x86_64-GenericCloud-1508.qcow2
swift download cisco-images Fedora-Cloud-Base-22-20150521.x86_64.qcow2
swift download cisco-images Fedora-Cloud-Base-25-1.3.x86_64.qcow2
swift download cisco-images windows_server_2012_r2_standard_eval_kvm_20170321.qcow2.gz

#Decompress Windows Image
gunzip -d windows_server_2012_r2_standard_eval_kvm_20170321.qcow2.gz

OS_TENANT_ID=$OS_TENANT_ID_BU
source /home/stack/devstack/openrc admin admin
#Create Glance Images
openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file CentOS-6-x86_64-GenericCloud-1508.qcow2 CentOS-6
#openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file CentOS-7-x86_64-GenericCloud-1705.qcow2 CentOS-7
glance --os-image-api-version 1 image-create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --is-public True --location https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2 --name "CentOS-7"
openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file Fedora-Cloud-Base-22-20150521.x86_64.qcow2 Fedora-22
openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file Fedora-Cloud-Base-25-1.3.x86_64.qcow2 Fedora-25
openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file precise-server-cloudimg-amd64-disk1.img Ubuntu-12.04
#openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file trusty-server-cloudimg-amd64-disk1.img Ubuntu-14.04
glance --os-image-api-version 1 image-create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --is-public True --location https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img --name "Ubuntu-14.04"
#openstack image create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --public --file xenial-server-cloudimg-amd64-disk1.img Ubuntu-16.04
glance --os-image-api-version 1 image-create --container-format bare --disk-format qcow2 --min-disk 8 --min-ram 1024 --is-public True --location https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img --name "Ubuntu-16.04"
openstack image create --container-format bare --disk-format qcow2 --min-disk 15 --min-ram 2048 --public --file precise-server-cloudimg-amd64-disk1.img Ubuntu-12.04
openstack image create --property hypervisor_type=qemu --container-format bare --disk-format qcow2 --property os_type=windows --min-disk 40 --min-ram 4096 --public --file windows_server_2012_r2_standard_eval_kvm_20170321.qcow2 Windows-Server-2012-R2-V2API
glance --os-image-api-version 1 image-create --property hypervisor_type=qemu --container-format bare --disk-format qcow2 --property os_type=windows --min-disk 40 --min-ram 4096 --is-public True --file windows_server_2012_r2_standard_eval_kvm_20170321.qcow2 --name "Windows-Server-2012-R2-V1API"


OS_PRIVATE_NET=$(openstack network list | grep -w "private" | awk '{print $2}')
ssh-keygen -b 2048 -t rsa -f /home/stack/.ssh/id_rsa -q -N ""
openstack keypair create --public-key ~/.ssh/id_rsa.pub my-pub-key
openstack server create --flavor 2 --image CentOS-6 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key centos6-instance
openstack server create --flavor 2 --image CentOS-7 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key centos7-instance
openstack server create --flavor 2 --image Fedora-22 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key fedora22-instance
openstack server create --flavor 2 --image Fedora-25 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key fedora25-instance
openstack server create --flavor 2 --image Ubuntu-12.04 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key ubuntu1204-instance
openstack server create --flavor 2 --image Ubuntu-14.04 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key ubuntu1404-instance
openstack server create --flavor 2 --image Ubuntu-16.04 --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key ubuntu1604-instance
openstack server create --flavor 3 --image Windows-Server-2012-R2-V2API --nic net-id=$OS_PRIVATE_NET --key-name my-pub-key windows-server-2012
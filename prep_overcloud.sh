#!/usr/bin/env bash

NETWORK=public
PASSWORD=Redhat01
DNS1=192.168.1.249

source /home/stack/overcloudrc 
# Create public network
neutron net-create public --router:external --provider:physical_network datacentre --provider:network_type vlan --provider:segmentation_id 5
neutron subnet-create --name public --enable_dhcp=False --allocation-pool=start=192.168.1.50,end=192.168.1.99 --gateway=192.168.0.1 public 192.168.0.0/23


# create shiftstack tenant
source ~/overcloudrc
openstack project create shiftstack
openstack user create --password $PASSWORD shiftstack_user
openstack role add --user shiftstack_user --project shiftstack _member_
openstack image create --public --disk-format qcow2 --container-format bare --property hw_disk_bus=scsi --property hw_scsi_model=virtio-scsi --property hw_qemu_guest_agent=yes --file ~/images/rhel76.qcow2 rhel76
openstack image create --public --disk-format qcow2 --container-format bare --property hw_disk_bus=scsi --property hw_scsi_model=virtio-scsi --property hw_qemu_guest_agent=yes --file ~/images/rhel76ocp.qcow2 rhel76ocp
openstack image create --public --disk-format qcow2 --container-format bare --property hw_disk_bus=scsi --property hw_scsi_model=virtio-scsi --property hw_qemu_guest_agent=yes --file ~/images/centos7.qcow2 centos
openstack flavor create --ram 2048 --disk 10 --vcpus 1 m1.small
openstack flavor create --ram 4096 --disk 20 --vcpus 2 m1.medium
openstack flavor create --ram 12288 --disk 45 --vcpus 4 m1.master
openstack flavor create --ram 12288 --disk 45 --vcpus 4 m1.large
openstack flavor create --ram 8192 --disk 20 --vcpus 2 m1.node
openstack quota set --secgroups 20 shiftstack
openstack quota set --ram 128000  shiftstack
openstack image list
openstack flavor list
openstack network list
openstack subnet list

# prepare shiftstack tenant
sed -e 's/OS_USERNAME=.*/OS_USERNAME=shiftstack_user/' -e 's/OS_PROJECT_NAME=.*/OS_PROJECT_NAME=shiftstack/' -e 's/OS_CLOUDNAME=.*/OS_CLOUDNAME=shiftstack/' -e 's/OS_PASSWORD=.*/OS_PASSWORD=Redhat01/' ~/overcloudrc > ~/shiftstackrc
source ~/shiftstackrc
openstack keypair create --public-key ~/.ssh/id_rsa.pub undercloud_key
openstack network create bastion
openstack subnet create --network bastion --subnet-range 172.16.0.0/24 --dns-nameserver $DNS1 bastion
openstack router create bastion
openstack router set --external-gateway $NETWORK bastion
openstack router add subnet bastion bastion
openstack security group create bastion --description "Security group for the Bastion instance"
openstack security group rule create bastion --protocol tcp --dst-port 22
openstack security group rule create bastion --protocol icmp
openstack server create --flavor m1.small --network bastion --image rhel76 --key-name undercloud_key --security-group bastion bastion
openstack floating ip create $NETWORK
export floating_ip=$(openstack floating ip list -f value -c "Floating IP Address")
openstack server add floating ip bastion $floating_ip
openstack server list | grep $floating_ip
sleep 60
ping -c 3 $floating_ip
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ~/shiftstackrc cloud-user@$floating_ip:
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  ~/prep_bastion.sh cloud-user@$floating_ip:
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ~/certs/ca.crt.pem cloud-user@$floating_ip:
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cloud-user@$floating_ip -C 'sudo mv /home/cloud-user/ca.crt.pem /etc/pki/ca-trust/source/anchors/'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cloud-user@$floating_ip -C 'sudo update-ca-trust extract'
ssh -l cloud-user -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $floating_ip ls 

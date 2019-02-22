#!/usr/bin/env bash
sudo curl -o /etc/yum.repos.d/local.repo http://192.168.1.100/local.repo 
sudo yum-config-manager --enable rhel-7-server-ansible-2.5-rpms
sudo yum-config-manager --disable rhel-7-server-ansible-2.6-rpms
source ~/shiftstackrc
sudo yum clean all
sudo rm -rf /var/cache/yum
sudo yum install -y python2-shade python-dns python2-heatclient python-openstackclient python2-octaviaclient git vim-enhanced bash-completion bind-utils ansible
ssh-keygen -P '' -f ~/.ssh/id_rsa
openstack keypair create --public-key ~/.ssh/id_rsa.pub openshift
git clone https://github.com/tomassedovic/devns.git
cd devns/
cat << EOF > ~/devns/vars.yaml
---
dns_domain: openshift.lab.lan
external_network: public
key_name: openshift
image: centos
flavor: m1.small
server_name: openshift-dns
dns_forwarders: ["192.168.1.249"]
additional_repo_files: []
EOF
ansible-playbook --private-key ~/.ssh/id_rsa --user centos deploy.yaml -e @vars.yaml | tee ~/devns/ansible_devns.out
export dns_ip=$(openstack server show openshift-dns -f value -c addresses | awk ' { print $2 } ')
ssh -l centos $dns_ip sudo grep secret /var/named/public-openshift.lab.lan.key | tee ~/secret.txt
ssh -l centos $dns_ip sudo grep -A 2 forwarders /etc/named/named.conf.view
#sudo yum update -y

# clone openshift-ansible
git clone https://github.com/openshift/openshift-ansible
cp -r openshift-ansible/playbooks/openstack/sample-inventory/ inventory

#!/bin/bash
# name: deploy_ocp.sh
#-----------------------------------------------------------------------------------------------------------------------------
#   Copyright 2018 Ken Holden <kholden@redhat.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#-----------------------------------------------------------------------------------------------------------------------------
# ensure script run as cloud-user user and in stack’s home directory
if [ "$USER" != "cloud-user" ]; then
  echo "MUST BE RUN AS stack USER"
  exit 1
fi
if [ "$PWD" != "/home/cloud-user" ]; then
  echo "MUST BE IN THE CLOUD-USER's USER'S HOME DIRECTORY!!!"
  exit 1
fi


source ~/shiftstackrc
time ansible-playbook --user openshift -i openshift-ansible/playbooks/openstack/inventory.py -i inventory openshift-ansible/playbooks/openstack/openshift-cluster/provision_install.yml


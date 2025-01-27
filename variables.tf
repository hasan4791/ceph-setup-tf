################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2020
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################

################################################################
# Configure the OpenStack Provider
################################################################
variable "user_name" {
  description = "The user name used to connect to OpenStack/PowerVC"
  default     = "my_user_name"
}

variable "password" {
  description = "The password for the user"
  default     = "my_password"
}

variable "tenant_name" {
  description = "The name of the project (a.k.a. tenant) used"
  default     = "ibm-default"
}

variable "domain_name" {
  description = "The domain to be used"
  default     = "Default"
}

variable "auth_url" {
  description = "The endpoint URL used to connect to OpenStack/PowerVC"
  default     = "https://<HOSTNAME>:5000/v3/"
}

variable "insecure" {
  default = "true" # OS_INSECURE
}

variable "openstack_availability_zone" {
  description = "The name of Availability Zone for deploy operation"
  default     = ""
}


################################################################
# Configure the Instance details
################################################################

variable "ceph" {
  default = {
    count         = 1
    instance_type = "m1.xlarge"
    image_id      = "daa5d3f4-ab66-4b2d-9f3d-77bd61774419"
    # optional availability_zone
    # availability_zone = ""
    # optional fixed IP address
    # fixed_ip_v4   = "123.45.67.89"
    # fixed_ips = []
    # data_volume_size = 100 #Default volume size (in GB) to be attached to the ceph
    # data_volume_count = 0 #Number of volumes to be attached to each master node.
  }
}


variable "network_name" {
  description = "The name of the network to be used for deploy operations"
  default     = "my_network_name"
}

variable "network_type" {
  #Eg: SEA or SRIOV
  default     = "SEA"
  description = "Specify the name of the network adapter type to use for creating hosts"
}

variable "sriov_vnic_failover_vfs" {
  # Eg: 1 = VNIC without failover; 2 = VNIC failover with 2 SR-IOV VFs
  default     = 1
  description = "Specifies the amount of VNIC failover virtual functions (max. is 6)"
  validation {
    condition     = var.sriov_vnic_failover_vfs > 0 && var.sriov_vnic_failover_vfs < 7
    error_message = "The number of virtual functions for the parameter sriov_vnic_failover_vfs must be min. 1 and cannot exceed 6."
  }
}

variable "sriov_capacity" {
  # Eg: 0.02 = 2%; 0.20 = 20%; 1.00 = 100%
  default     = 0.02
  description = "Specifies the SR-IOV LP capacity"
}

variable "scg_id" {
  description = "The id of PowerVC Storage Connectivity Group to use for all nodes"
  default     = ""
}

variable "scg_flavor_is_public" {
  description = "Newly created compute template will be private by default. User can set this to true to make it visible in UI"
  default     = false
}

variable "rhel_username" {
  default = "root"
}

variable "keypair_name" {
  # Set this variable to the name of an already generated
  # keypair to use it instead of creating a new one.
  default = ""
}

variable "public_key_file" {
  description = "Path to public key file"
  # if empty, will default to ${path.cwd}/data/id_rsa.pub
  default = ""
}

variable "private_key_file" {
  description = "Path to private key file"
  # if empty, will default to ${path.cwd}/data/id_rsa
  default = ""
}

variable "private_key" {
  description = "content of private ssh key"
  # if empty string will read contents of file at var.private_key_file
  default = ""
}

variable "public_key" {
  description = "Public key"
  # if empty string will read contents of file at var.public_key_file
  default = ""
}

variable "rhel_subscription_username" {
  default = ""
}

variable "rhel_subscription_password" {
  default = ""
}

variable "rhel_subscription_org" {
  default = ""
}

variable "rhel_subscription_activationkey" {
  default = ""
}

variable "rhcos_pre_kernel_options" {
  description = "List of kernel arguments for the cluster nodes for pre-installation"
  default     = []
}

variable "rhcos_kernel_options" {
  description = "List of kernel arguments for the cluster nodes"
  default     = []
}

variable "sysctl_tuned_options" {
  description = "Set to true to apply sysctl options via tuned operator. Default: false"
  default     = false
}

variable "sysctl_options" {
  description = "List of sysctl options to apply."
  default     = []
}

variable "match_array" {
  description = "Criteria for node/pod selection."
  default     = <<EOF
EOF
}

variable "chrony_config" {
  description = "Set to true to setup time synchronization and setup chrony. Default: false"
  default     = true
}

variable "chrony_config_servers" {
  description = "List of ntp servers and options to apply"
  default     = []
  # example: chrony_config_servers = [ {server = "10.3.21.254", options = "iburst"}, {server = "10.5.21.254", options = "iburst"} ]
}

################################################################
### Instrumentation
################################################################
variable "ssh_agent" {
  description = "Enable or disable SSH Agent. Can correct some connectivity issues. Default: false"
  default     = false
}

variable "connection_timeout" {
  description = "Timeout in minutes for SSH connections"
  default     = 45
}

variable "private_network_mtu" {
  type        = number
  description = "MTU value for the private network interface on RHEL and RHCOS nodes"
  default     = 1450
}

variable "installer_log_level" {
  description = "Set the log level required for openshift-install commands"
  default     = "info"
}

variable "ansible_repo_name" {
  default = "ansible-2.9-for-rhel-8-ppc64le-rpms"
}

variable "baseos_repo" {
  default = "rhel-9-for-ppc64le-baseos-rpms"
}
variable "supplementary_repo" {
  default = "rhel-9-for-ppc64le-supplementary-rpms"
}
variable "appstream_repo" {
  default = "rhel-9-for-ppc64le-appstream-rpms"
}
variable "highavailability_repo" {
  default = "rhel-9-for-ppc64le-highavailability-rpms"
}
variable "codeready_builder_repo" {
  description = "Set the repo URL for using ceph"
  default = "codeready-builder-for-rhel-9-ppc64le-rpms"
}

variable "ceph_repo" {
  description = "Set the repo URL for using ceph"
  # Repo for running ceph helpernode setup steps.
  default = "http://9.114.181.66/ceph-6/"
}

locals {
  private_key_file = var.private_key_file == "" ? "${path.cwd}/data/id_rsa" : var.private_key_file
  public_key_file  = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : var.public_key_file
  private_key      = var.private_key == "" ? file(coalesce(local.private_key_file, "/dev/null")) : var.private_key
  public_key       = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
  create_keypair   = var.keypair_name == "" ? "1" : "0"
}


# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
variable "cluster_domain" {
  default = "nip.io"
}
# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
# Should not be more than 14 characters
variable "cluster_id_prefix" {
  default = "ceph"
}
# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
# Length cannot exceed 14 characters when combined with cluster_id_prefix
variable "cluster_id" {
  default = ""
}

variable "fips_compliant" {
  type        = bool
  description = "Set to true to enable usage of FIPS for OCP deployment."
  default     = false
}

variable "dns_forwarders" {
  default = "8.8.8.8; 8.8.4.4"
}

variable "lb_ipaddr" {
  description = "Define the preconfigured external Load Balancer"
  default     = ""
}

variable "ext_dns" {
  description = "Define the preconfigured external DNS and Load Balancer"
  default     = ""
}

variable "mount_etcd_ramdisk" {
  description = "Whether mount etcd directory in the ramdisk (Only for dev/test) on low performance disk"
  default     = false
}


variable "storage_type" {
  #Supported values: nfs (other value won't setup a storageclass)
  default = "nfs"
}

variable "volume_storage_template" {
  # Storage template name or ID for creating the volume.
  default = ""
}

# ceph-setup-tf

Terraform automation for deploying a Ceph cluster on IBM PowerVC / OpenStack.

## Overview

This repository provisions:
- Ceph nodes on IBM Power platform through PowerVC
- Network ports for the Ceph nodes
- Optional Ceph VIP when deploying more than one node
- Optional block storage volumes for Ceph OSD data disks
- Initial Ceph bootstrap and service configuration on the deployed nodes

The current implementation supports single-node and multi-node Ceph deployments. For production-like multi-node setups, configure one or more data volumes per node so OSDs can be prepared on attached block storage.

## Prerequisites

- A working PowerVC / OpenStack environment
- Terraform `>= 1.2.0`
- Access to an image that can run the Ceph setup flow
- A valid network in PowerVC for the deployed nodes
- SSH key pair available locally, or an existing key pair name
- Access to Ceph package repositories:
  - `ceph_repo`
  - `rhceph_repo`
- If using subscribed RHEL images, valid Red Hat subscription credentials or activation key details
- Storage connectivity group ID if you want to use a custom SCG-backed flavor
- Attached data volumes configured through `ceph.data_volume_count` and `ceph.data_volume_size` for OSD provisioning

## Files

- `var.tfvars.template` - sample variable file
- `variables.tf` - root input variables
- `ceph.tf` - root module composition
- `outputs.tf` - deployment outputs
- `modules/1_ceph` - Ceph instance and bootstrap logic
- `modules/2_network` - network port and VIP creation logic

## Configuration

Copy the template and update it for your environment:

```bash
cp var.tfvars.template var.tfvars
```

Important values to review in `var.tfvars`:

### PowerVC access
- `auth_url`
- `user_name`
- `password`
- `tenant_name`
- `domain_name`
- `openstack_availability_zone`

### Instance and cluster settings
- `network_name`
- `nick_name`
- `cluster_id_prefix`
- `cluster_id`
- `cluster_domain`
- `ceph.instance_type`
- `ceph.image_id`
- `ceph.count`

### Ceph storage settings
- `ceph.data_volume_count`
- `ceph.data_volume_size`
- `ceph.fixed_ip_v4`
- `ceph.fixed_ips`

### Repository settings
- `ceph_repo`
- `rhceph_repo`
- `baseos_repo`
- `appstream_repo`
- `supplementary_repo`
- `highavailability_repo`
- `codeready_builder_repo`

### Access and subscription settings
- `rhel_username`
- `public_key_file`
- `private_key_file`
- `keypair_name`
- `rhel_subscription_username`
- `rhel_subscription_password`
- `rhel_subscription_org`
- `rhel_subscription_activationkey`
- `connection_timeout`
- `ssh_agent`

### Optional network and storage customization
- `network_type` (`SEA` or `SRIOV`)
- `sriov_vnic_failover_vfs`
- `sriov_capacity`
- `scg_id`
- `scg_flavor_is_public`
- `volume_storage_template`

## Example `ceph` object

```hcl
ceph = {
  instance_type     = "<ceph-compute-template>"
  image_id          = "<image-uuid-rhel>"
  count             = 3
  data_volume_count = 1
  data_volume_size  = 500
}
```

Optional attributes:

```hcl
ceph = {
  instance_type     = "<ceph-compute-template>"
  image_id          = "<image-uuid-rhel>"
  availability_zone = "<availability-zone>"
  count             = 3
  fixed_ip_v4       = "<ipv4-address>"
  fixed_ips         = ["<node1-ip>", "<node2-ip>", "<node3-ip>"]
  data_volume_count = 1
  data_volume_size  = 500
}
```

## Deployment

Use the provided `Makefile` targets:

Initialize the workspace:

```bash
make init
```

Review the execution plan:

```bash
make plan
```

Apply the configuration:

```bash
make apply
```

After a successful apply, the current Terraform state is backed up automatically as:

```bash
terraform.tfstate.<cluster_id>
```

## Outputs

After a successful deployment, Terraform returns useful values including:
- `cluster_id`
- `ceph_ip`
- `ceph_vip`
- `ceph_ssh_command`
- `storageclass_name`

Use the generated SSH command output to connect to the primary Ceph node.

## Manually attach disk and custom pool setup

After the cluster is deployed, you can add a local disk manually and create a dedicated crush rule and CephFS pools for that device class.

Helper scripts are available at:

```bash
scripts/create_new_osd.sh
scripts/create_cephfs.sh
scripts/create_rbd.sh
```

Make them executable before use:

```bash
chmod +x scripts/create_new_osd.sh scripts/create_cephfs.sh scripts/create_rbd.sh
```

### Run on all Ceph nodes

Steps 1 to 4 must be executed on all Ceph nodes.

1. Rescan the SCSI bus:

```bash
rescan-scsi-bus.sh -a -m -r
```

2. Zap the target device before preparing it:

```bash
ceph-volume lvm zap --destroy <device_path>
```

Example:

```bash
ceph-volume lvm zap --destroy /dev/sda
```

3. Prepare the OSD with a device class:

```bash
ceph-volume raw prepare --objectstore bluestore --data <device_path> --crush-device-class <device_class>
```

4. Start the OSD service:

```bash
ceph osd tree down
systemctl start ceph@osd.<id>
```

### Run on any one Ceph node

The remaining steps must be executed on any one Ceph node after all nodes have completed steps 1 to 4.

#### Create CephFS pools with a dynamic crush rule

A crush rule is generated automatically as:

```bash
rule-<device_class>
```

If the rule already exists in `ceph osd crush rule ls`, it is reused. Otherwise it is created automatically.

1. Create the metadata pool:

```bash
ceph osd pool create <metadata_pool_name> 32 replicated rule-<device_class>
```

2. Create the data pool:

```bash
ceph osd pool create <data_pool_name> 32 replicated rule-<device_class>
```

3. Enable the CephFS application on the metadata pool:

```bash
ceph osd pool application enable <metadata_pool_name> cephfs
```

4. Enable the CephFS application on the data pool:

```bash
ceph osd pool application enable <data_pool_name> cephfs
```

5. Create the CephFS filesystem:

```bash
ceph fs new <fs_name> <metadata_pool_name> <data_pool_name>
```

#### Create an RBD pool

A crush rule is generated automatically as `rule-<device_class>` and created only if it does not already exist.

1. Create the RBD pool:

```bash
ceph osd pool create <rbd_pool_name> 32 <device_class>
```

2. Enable PG autoscaling:

```bash
ceph osd pool set <rbd_pool_name> pg_autoscale_mode on
```

3. Initialize the RBD pool:

```bash
rbd pool init <rbd_pool_name>
```

4. Create an RBD image:

```bash
rbd create --size 100G --pool <rbd_pool_name> <rbd_name>
```

5. List RBD images:

```bash
rbd ls -l
```

### Use the helper scripts

Run the per-node OSD steps on every Ceph node:

```bash
./scripts/create_new_osd.sh \
  --device /dev/sda \
  --device-class ssd \
  --osd-id 3
```

Run the CephFS setup on any one Ceph node:

```bash
./scripts/create_cephfs.sh \
  --device-class ssd \
  --metadata-pool cephfs_metadata_ssd \
  --data-pool cephfs_data_ssd \
  --fs-name cephfs-ssd
```

Run the RBD setup on any one Ceph node:

```bash
./scripts/create_rbd.sh \
  --device-class ssd \
  --rbd-pool rbd_ssd \
  --rbd-name rbd01 \
  --rbd-size 100G
```

## Notes

- If `ceph.count > 1`, a VIP port is created by the network module.
- If `cluster_id` is not set, a random ID is generated using `cluster_id_prefix`.
- If `scg_id` is provided, a derived flavor is created with the PowerVC storage connectivity group.
- If subscription details are not provided, package installation falls back to direct repo configuration.
- OSD preparation depends on attached block storage volumes.
- The default provider version constraint for OpenStack is `~> 3.3.2`.

## Destroy

To remove the deployed infrastructure:

```bash
make destroy
```

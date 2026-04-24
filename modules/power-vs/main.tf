# ==============================================================================
# Power VS Workspace
# ==============================================================================

resource "ibm_resource_instance" "power_vs_workspace" {
  name              = "${var.name_prefix}-power-workspace"
  service           = "power-iaas"
  plan              = "power-virtual-server-group"
  location          = var.zone
  resource_group_id = var.resource_group_id
  tags              = var.tags

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ==============================================================================
# Power VS Private Network
# ==============================================================================

resource "ibm_pi_network" "private_network" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_network_name      = "${var.name_prefix}-power-network"
  pi_network_type      = "vlan"
  pi_cidr              = var.network_cidr
  pi_dns               = var.dns_servers

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# ==============================================================================
# SSH Key for Power VS Instances
# ==============================================================================

resource "ibm_pi_key" "ssh_key" {
  count = var.ssh_public_key != "" ? 1 : 0

  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_key_name          = "${var.name_prefix}-power-key"
  pi_ssh_key           = var.ssh_public_key

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# ==============================================================================
# Get Available Images
# ==============================================================================

data "ibm_pi_images" "available_images" {
  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
}

# Find the specified image
locals {
  image_id = [
    for image in data.ibm_pi_images.available_images.image_info :
    image.id if image.name == var.image_name
  ][0]
}

# ==============================================================================
# Power VS Instances
# ==============================================================================

resource "ibm_pi_instance" "instance" {
  count = var.instance_count

  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_instance_name     = "${var.name_prefix}-power-vm-${count.index + 1}"
  pi_image_id          = local.image_id
  pi_memory            = var.memory
  pi_processors        = var.cores
  pi_proc_type         = var.processor_type
  pi_sys_type          = var.system_type
  pi_storage_type      = var.storage_type
  
  pi_network {
    network_id = ibm_pi_network.private_network.network_id
  }

  pi_key_pair_name = var.ssh_public_key != "" ? ibm_pi_key.ssh_key[0].pi_key_name : null
  
  pi_health_status = "WARNING"

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  depends_on = [ibm_pi_network.private_network]
}

# ==============================================================================
# Additional Storage Volumes (Optional)
# ==============================================================================

resource "ibm_pi_volume" "storage" {
  count = var.instance_count

  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_volume_name       = "${var.name_prefix}-power-vol-${count.index + 1}"
  pi_volume_size       = var.storage_size
  pi_volume_type       = var.storage_type
  pi_volume_shareable  = false

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# Attach volumes to instances
resource "ibm_pi_volume_attach" "volume_attach" {
  count = var.instance_count

  pi_cloud_instance_id = ibm_resource_instance.power_vs_workspace.guid
  pi_volume_id         = ibm_pi_volume.storage[count.index].volume_id
  pi_instance_id       = ibm_pi_instance.instance[count.index].instance_id

  timeouts {
    create = "30m"
    delete = "30m"
  }
}
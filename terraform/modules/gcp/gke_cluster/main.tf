provider "google-beta" {
  version = "2.9"
  region  = var.region
  zone    = var.zone
  project = var.project_id
}

provider "aws" {
  region                  = var.region_aws
  shared_credentials_file = var.aws_credentials_file
  profile                 = var.aws_profile
}

data "http" "external_ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  allowed_subnets = concat(list("${chomp(data.http.external_ip.body)}/32"), var.allowed_ips)
}

########################################################
# GKE Cluster
########################################################

resource "google_container_cluster" "cluster" {
  provider           = google-beta
  project            = var.project_id
  name               = var.cluster_name
  location           = var.location
  network            = var.network
  subnetwork         = var.subnetwork
  min_master_version = var.k8s_version
  node_locations     = var.node_locations

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  lifecycle {
    ignore_changes = [
      "node_pool",
      "network",
      "network_policy",
    ]
  }

  vertical_pod_autoscaling {
    enabled = true
  }

  # cluster_autoscaling {
  #   enabled = true

  #   resource_limits {
  #     resource_type = "cpu"
  #     maximum       = "${var.cluster_autoscaling_cpu_max_limit}"
  #     minimum       = "${var.cluster_autoscaling_cpu_min_limit}"
  #   }

  #   resource_limits {
  #     resource_type = "memory"
  #     maximum       = "${var.cluster_autoscaling_memory_max_limit}"
  #     minimum       = "${var.cluster_autoscaling_memory_min_limit}"
  #   }
  # }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"
    }
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # workaround #2231 issue with master access
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      iterator = cidr_block
      for_each = local.allowed_subnets
      content {
        cidr_block   = cidr_block.value
      }
    }
  }
  
  ip_allocation_policy {
    use_ip_aliases = true
    cluster_ipv4_cidr_block = var.pods_cidr
  }

  # network_policy {
  #   enabled  = false
  #   provider = "CALICO"
  # }

  addons_config {
    http_load_balancing {
      disabled = true
    }
    kubernetes_dashboard {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = true
    }
    network_policy_config {
      disabled = true
    }
  }

  resource_labels = {
    "project"      = "legion"
    "cluster_name" = var.cluster_name
  }
}

########################################################
# Node Pool
########################################################

resource "google_container_node_pool" "cluster_nodes" {
  provider           = google-beta
  project            = var.project_id
  name               = "${var.cluster_name}-node-pool"
  location           = var.location
  cluster            = var.cluster_name
  initial_node_count = 1
  depends_on         = [google_container_cluster.cluster]
  version            = var.node_version

  autoscaling {
    min_node_count = var.gke_num_nodes_min
    max_node_count = var.gke_num_nodes_max
  }

  management {
    auto_repair  = false
    auto_upgrade = false
  }

  node_config {
    preemptible     = false
    machine_type    = var.gke_node_machine_type
    disk_size_gb    = var.node_disk_size_gb
    service_account = var.nodes_sa
    image_type      = "COS"
    tags            = [var.gke_node_tag]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      "project" = "legion"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

########################################################
# Node Pool High CPU
########################################################

resource "google_container_node_pool" "cluster_nodes_highcpu" {
  provider           = google-beta
  project            = var.project_id
  name               = "${var.cluster_name}-highcpu-node-pool"
  location           = var.location
  cluster            = var.cluster_name
  initial_node_count = 0
  depends_on         = [google_container_cluster.cluster]
  version            = var.node_version

  autoscaling {
    min_node_count = "0"
    max_node_count = var.gke_highcpu_num_nodes_max
  }

  management {
    auto_repair  = false
    auto_upgrade = false
  }

  node_config {
    preemptible     = false
    machine_type    = var.gke_node_machine_type_highcpu
    disk_size_gb    = var.node_disk_size_gb
    service_account = var.nodes_sa
    image_type      = "COS"
    tags            = [var.gke_node_tag]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      "project" = "legion"
    }

    taint {
      key    = "dedicated"
      value  = "jenkins-slave"
      effect = "NO_SCHEDULE"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

########################################################
# Node Pool GPU
########################################################

resource "google_container_node_pool" "cluster_nodes_gpu" {
  provider           = google-beta
  project            = var.project_id
  name               = "${var.cluster_name}-gpu-node-pool"
  location           = var.location
  cluster            = var.cluster_name
  initial_node_count = 0
  depends_on         = [google_container_cluster.cluster]
  version            = var.node_version

  autoscaling {
    min_node_count = "0"
    max_node_count = var.gke_gpu_num_nodes_max
  }

  management {
    auto_repair  = false
    auto_upgrade = false
  }

  node_config {
    preemptible     = false
    machine_type    = var.gke_node_machine_type_gpu
    disk_size_gb    = var.node_disk_size_gb
    service_account = var.nodes_sa
    image_type      = "COS"
    tags            = [var.gke_node_tag]

    guest_accelerator {
      type  = var.gke_gpu_accelerator
      count = var.gpu_accelerators_count
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      "project" = "legion"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

########################################################
# SSH keys
########################################################

data "aws_s3_bucket_object" "ssh_public_key" {
  bucket = var.secrets_storage
  key    = "${var.cluster_name}/ssh/${var.cluster_name}.pub"
}

resource "google_compute_project_metadata_item" "ssh_public_keys" {
  provider = google-beta
  project  = var.project_id
  key      = "ssh-keys"
  value    = "${var.ssh_user}:${data.aws_s3_bucket_object.ssh_public_key.body}"
}

########################################################
# Bastion Host
########################################################
resource "google_compute_instance" "gke_bastion" {
  name                      = "${var.bastion_hostname}-${var.cluster_name}"
  machine_type              = var.bastion_machine_type
  zone                      = var.zone
  project                   = var.project_id
  allow_stopping_for_update = true
  depends_on                = [google_container_cluster.cluster]

  // Specify the Operating System Family and version.
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  tags = [var.bastion_tag]

  // Define a network interface in the correct subnet.
  network_interface {
    subnetwork         = var.subnetwork
    subnetwork_project = var.project_id
    access_config {
      // Implicit ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${data.aws_s3_bucket_object.ssh_public_key.body}"
  }

  metadata_startup_script = "sed -i '/AllowAgentForwarding/s/^#//g' /etc/ssh/sshd_config && service sshd restart"

  // Necessary scopes for administering kubernetes.
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

########################################################
#  DNS records
########################################################

resource "google_dns_record_set" "gke_bastion" {
  project      = var.project_id
  name         = "bastion.${var.cluster_name}.${var.root_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  rrdatas      = [google_compute_instance.gke_bastion.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "gke_api" {
  project      = var.project_id
  name         = "api.${var.cluster_name}.${var.root_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  rrdatas      = [google_container_cluster.cluster.endpoint]
}

# Wait for cluster startup
resource "null_resource" "kubectl_config" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "local-exec" {
    command = "timeout 1200 bash -c 'until curl -sk https://${google_container_cluster.cluster.endpoint}; do sleep 20; done'"
  }
  depends_on = [
    google_container_node_pool.cluster_nodes,
    google_container_node_pool.cluster_nodes_highcpu,
  ]
}


# Specify the GCP Provider
provider "google-beta" {
  project = var.project_id
  region  = var.region
  version = "~> 3.30"
  alias   = "gb3"
}

resource "google_container_cluster" "primary" {
  provider           = google-beta.gb3
  name               = var.cluster_name
  location           = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  cluster_autoscaling {
    enabled = true
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    istio_config {
      disabled = true
    }
  }

  logging_service = "logging.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "np" {
  name       = "my-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.num_nodes

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
  }

  version = latest

  management {
    auto_repair = true
    auto_upgrade = false
  }

  autoscaling {
    max_node_count = max_num_nodes
    min_node_count = min_num_nodes
  }
}
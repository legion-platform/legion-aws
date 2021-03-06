data "google_compute_network" "gcp_network_1" {
  project = var.project_id
  name    = var.gcp_network_1_name
}

data "google_compute_network" "gcp_network_2" {
  project = var.project_id
  name    = var.gcp_network_2_name
}

resource "google_compute_network_peering" "peering1" {
  name         = "${var.gcp_network_2_name}-${var.gcp_network_1_name}-peering"
  network      = data.google_compute_network.gcp_network_1.self_link
  peer_network = data.google_compute_network.gcp_network_2.self_link
}

resource "google_compute_network_peering" "peering2" {
  name         = "${var.gcp_network_1_name}-${var.gcp_network_2_name}-peering"
  network      = data.google_compute_network.gcp_network_2.self_link
  peer_network = data.google_compute_network.gcp_network_1.self_link
  depends_on   = [google_compute_network_peering.peering1]
}

resource "google_compute_firewall" "to_network_1" {
  project       = var.project_id
  name          = "${var.gcp_network_2_name}-${var.gcp_network_1_name}"
  network       = var.gcp_network_2_name
  source_ranges = var.gcp_network_1_range

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_firewall" "to_network_2" {
  project       = var.project_id
  name          = "${var.gcp_network_1_name}-${var.gcp_network_2_name}"
  network       = var.gcp_network_1_name
  source_ranges = var.gcp_network_2_range

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = var.project
}

# create network
resource "google_compute_network" "devnet" {
  name                    = "development-network"
  auto_create_subnetworks = false
}

# create subnet for nat vms
resource "google_compute_subnetwork" "devnetsubnat" {
  name          = "development-network-subnet-nat"
  ip_cidr_range = "10.0.1.0/24"
  region  = var.region
  network = google_compute_network.devnet.name
}

# create subnet for bastion vms
resource "google_compute_subnetwork" "devnetsubbas" {
  name          = "development-network-subnet-bastion"
  ip_cidr_range = "10.0.2.0/24"
  region  = var.region
  network = google_compute_network.devnet.name
}

# create firewall to allow SSH from console
resource "google_compute_firewall" "rule1" {
  name    = "dev-allow-ssh-to-console"
  network = google_compute_network.devnet.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

# create firewall to allow SSH from bastion
resource "google_compute_firewall" "rule2" {
  name    = "dev-allow-ssh-from-bastion"
  network = google_compute_network.devnet.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_tags = ["bastion"]
}

# create firewall to allow SSH to ext ip
resource "google_compute_firewall" "rule3" {
  name    = "dev-allow-ssh-to-extip"
  network = google_compute_network.devnet.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}

# Create Cloud Router
resource "google_compute_router" "router" {
  name    = "cloudnat-router"
  network = google_compute_network.devnet.name
  region = var.region
}

# Create Nat gateway
resource "google_compute_router_nat" "natrouter" {
  name   = "cloudnat-natrouter"
  router = google_compute_router.router.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"

  # for all subnets in network
  # source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # for specific subnets from network
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.devnetsubnat.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# create vm in bastion subnet
resource "google_compute_instance" "bastion-instance" {
  name = "bastion-vm"
  zone         = var.zone
  machine_type = "e2-small"

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20240430"
    }
  }

  network_interface {
    network    = google_compute_network.devnet.name
    subnetwork = google_compute_subnetwork.devnetsubbas.name
    access_config {}
  }
  metadata_startup_script = file("/path/to/file/bastionKey.sh")
}

# Create a VM in a nat subnet

resource "google_compute_instance" "nat-instance" {
  name = "nat-vm"
  zone         = var.zone
  machine_type = "e2-small"

  tags = ["app"]

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240415"
    }
  }

  network_interface {
    network    = google_compute_network.devnet.name
    subnetwork = google_compute_subnetwork.devnetsubnat.name
  }
}


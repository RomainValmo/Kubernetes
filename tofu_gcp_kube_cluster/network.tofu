resource "google_compute_network" "kube_gcp" {
  name                    = "kube-network"        
  auto_create_subnetworks = true                    
}

resource "google_compute_subnetwork" "kube_gcp_subnet" {
  name          = "kube-gcp-subnet"                   
  region        = var.gcp_region                      
  network       = google_compute_network.kube_gcp.self_link 
  ip_cidr_range = "10.0.0.0/24"                       
}

resource "google_compute_firewall" "kube_gcp_firewall" {
  name    = "kube-gcp-firewall"                       
  network = google_compute_network.kube_gcp.self_link 

  allow {
    protocol = "tcp"
    ports    = ["30000-32767", "80", "443", "22" ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = [ "kube-node-port" ]
}

resource "google_compute_address" "kube_gcp_address" {
  name   = "kube-gcp-address"
  region = var.gcp_region
}

resource "google_compute_firewall" "default_allow_icmp" {
  name    = "default-allow-icmp-2"
  network = google_compute_network.kube_gcp.self_link

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "default_allow_internal" {
  name    = "default-allow-internal-2"
  network = google_compute_network.kube_gcp.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.128.0.0/9"]
}

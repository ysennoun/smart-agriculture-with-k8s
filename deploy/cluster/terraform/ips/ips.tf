resource "google_compute_network" "vernemq" {
  name = "vernemq-ip2"
  region = var.region
}

resource "google_compute_network" "api" {
  name = "api-ip2"
  region = var.region
}

resource "google_compute_network" "front_end" {
  name = "front-end-ip2"
  region = var.region
}

output "vernemq_ip" {
  value = google_compute_address.vernemq.address
}
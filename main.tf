# main.tf

 provider "google" {
   credentials =  jsondecode(base64decode(var.gcp_service_account_key))
   project     = "emea-tac-cloud-and-compute"
   region      = "us-central1"
 }

resource "google_compute_instance" "harbor" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = "us-central1-a"

  boot_disk {
    auto_delete = true
    device_name = var.instance_name

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20231101"
      size  = var.disk_size
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }
    network_interface {
      subnetwork = var.subnet
      access_config {
        network_tier = "PREMIUM"
      }
  }
  metadata = {
    ssh-keys = "${var.ssh-user}:${var.ssh-key}"
  }
  tags = ["http-server", "https-server", "emea-tac-lab"]

  metadata_startup_script = file("${path.module}/harbor_install_gcp.sh")
  
}

output "habor_instance" {
  value = "https://${google_compute_instance.harbor.network_interface.0.access_config.0.nat_ip}.sslip.io"
}



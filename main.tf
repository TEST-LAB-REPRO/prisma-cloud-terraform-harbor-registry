# main.tf

 provider "google" {
   credentials = file("./credentials.json")
   project     = var.project_id
   region      = var.region
 }

resource "google_compute_instance" "harbor" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    auto_delete = true
    device_name = var.instance_name

    initialize_params {
      image = var.image
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

  provisioner "remote-exec" {
  inline = ["echo 'Wait until SSH is ready'"]

  connection {
    type        = "ssh"
    user        = var.ssh-user
    host        =  google_compute_instance.harbor.network_interface.0.access_config.0.nat_ip
    private_key =  file("./id_rsa")
  }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${google_compute_instance.harbor.network_interface.0.access_config.0.nat_ip},  --private-key ${var.private_key_path} harbor_deploy.yaml"
  }

}

output "habor_instance" {
  value = "https://${google_compute_instance.harbor.network_interface.0.access_config.0.nat_ip}.sslip.io"
}



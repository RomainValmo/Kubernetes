resource "google_compute_instance" "control_plan" {
  name         = var.instance
  machine_type = var.instance_type
  zone         = var.zone
  allow_stopping_for_update = true
    tags         = [ "kube-node-port" ]
  boot_disk {
    initialize_params {
      image = var.image
      size =  var.size_disk
       type  = var.disk_type
    }
  }
  network_interface {
      network = google_compute_network.kube_gcp.self_link
      #network = "default"
      #subnetwork = "default"
      subnetwork = google_compute_subnetwork.kube_gcp_subnet.self_link
      access_config {     

       }
 }
  service_account {
    scopes = ["cloud-platform"]
  }
metadata = {
  ssh-keys = "romain:${file("./ssh.pub")}"
}
}



output "instance_external_ip" {
  value = google_compute_instance.control_plan.network_interface[0].access_config[0].nat_ip
}

resource "null_resource" "remote_script_execution" {
  depends_on = [google_compute_instance.control_plan]  # Cela garantit que l'instance est créée avant d'exécuter ce bloc

  # Provisioner 'file' pour copier le script sur la VM
  provisioner "file" {
    source      = "../Install_kube_cilium_helm/master.sh"
    destination = "/tmp/remote-script.sh"

    connection {
      type        = "ssh"
      user        = "romain"
      private_key = file("./ssh")
      host        = google_compute_instance.control_plan.network_interface[0].access_config[0].nat_ip
    }
  }

  # Provisioner 'remote-exec' pour exécuter le script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/remote-script.sh",  # Rendre le script exécutable
      "sudo /tmp/remote-script.sh"       # Exécuter le script avec sudo
    ]

    connection {
      type        = "ssh"
      user        = "romain"
      private_key = file("./ssh")
      host        = google_compute_instance.control_plan.network_interface[0].access_config[0].nat_ip
    }
  }
}


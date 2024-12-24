resource "google_compute_instance" "worker_node" {
  for_each = var.worker
  name         = each.key
  machine_type = var.instance_type
  zone         = var.zone
  allow_stopping_for_update = true
    tags         = [ "kube-node-port" ]
  boot_disk {
    initialize_params {
      image = var.image
      size =  each.value.size_disk
      type  = each.value.disk_type
    }
  }
  network_interface {
      network = google_compute_network.kube_gcp.self_link
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

output "instance_external_ip_worker" {
  value = { for instance_name, instance in google_compute_instance.worker_node : 
    instance_name => instance.network_interface[0].access_config[0].nat_ip
  }
}


resource "null_resource" "remote_script_execution_worker" {
  for_each = google_compute_instance.worker_node
  depends_on = [google_compute_instance.worker_node]

  provisioner "file" {
    source      = "../Install_kube_cilium_helm/worker.sh"
    destination = "/tmp/remote-script.sh"

    connection {
      type        = "ssh"
      user        = "romain"
      private_key = file("./ssh")
      host        = each.value.network_interface[0].access_config[0].nat_ip 
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/remote-script.sh",  
      "sudo /tmp/remote-script.sh"       
    ]

    connection {
      type        = "ssh"
      user        = "romain"
      private_key = file("./ssh")
      host        = each.value.network_interface[0].access_config[0].nat_ip
    }
  }
}


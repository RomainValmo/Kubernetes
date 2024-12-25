variable "gcp_credentials_file" {
    description = "path to your Json file"
    type        = string
    default = "./gcp.json"
}

variable "gcp_project_id" {
    description = "Google Cloud Project ID"
    type        = string
}

variable "gcp_region" {
    description = "Google Cloud Region"
    type        = string
}

variable "instance" {
    description = "Instance name"
    type        = string
  
}

variable "instance_type" {
    description = "Instance type"
    type        = string    
  
}

variable "zone" {
    description = "Zone"
    type        = string    
  
}

variable "image" {
    description = "Image"
    type        = string
    default = "ubuntu-2004-focal-v20241219"
  
}

variable "size_disk" {
    description = "Disk size"
    type        = number
    default = 20
  
}

variable "disk_type" {
    description = "Disk type"
    type        = string
    default = "pd-standard"
  
}

variable "path_master" {
    description = "Path to the startup script"
    type        = string
    default = "../Install_kube_cilium_helm/master.sh"
  
}

variable "worker" {
  type = map(object({
    size_disk    = number
    disk_type    = string
  }))

}

variable "tag_masternote"{
    type = list(string)
    description = "value of the tag for the master node"
    default = ["kube-node-port-masternode"]
}


variable "masternode" {
  type = map(object({
    instance_type    = string
    zone    = string
    allow_stopping_for_update    = bool
    image    = string
    size_disk    = number
    disk_type    = string
    ssh-host    = string
    ssh-file    = string
  }))
  default = {
    "masternode1" = {
        instance_type = "e2-medium"
        zone = "europe-west1-b"
        allow_stopping_for_update = true
        image = "ubuntu-2004-focal-v20241219"
        size_disk = 20
        disk_type = "pd-standard"
        ssh-host = "romain"
        ssh-file = "./ssh.pub"
    }
  }

}

variable "private_key_ssh" {
    description = "Path to the private key"
    type        = string
    default = "./ssh"
  
}

variable "network_ip_range" {
    description = "Network IP range"
    type        = string
    default = "10.132.0.0/20"
  
}
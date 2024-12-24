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

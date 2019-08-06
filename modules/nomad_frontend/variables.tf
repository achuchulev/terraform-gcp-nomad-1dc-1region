variable "gcp_credentials_file_path" {
  description = "Locate the GCP credentials .json file"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "gcp_region" {
  description = "Default to N.Virginia region"
  default     = "us-east4"
}

variable "gcp-vpc-network" {
  
}


variable "gcp-subnet1-name" {
}

variable "gcp_instance_type" {
  description = "Machine Type. Correlates to an network egress cap."
  default     = "n1-standard-1"
}

variable "gcp_disk_image" {
  description = "Boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nginx-v001"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "cloudflare_email" {
}

variable "cloudflare_token" {
}

variable "cloudflare_zone" {
}

variable "subdomain_name" {
}

variable "backend_private_ips" {
}

variable "dc" {
  type    = string
  default = "dc1"
}

variable "nomad_region" {
  default = "global"
}


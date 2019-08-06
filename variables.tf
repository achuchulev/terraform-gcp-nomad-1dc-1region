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

variable "servers_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "clients_count" {
  description = "The number of clients to provision."
  default     = "3"
}

variable "datacenter" {
  description = "The name of Nomad datacenter."
  type        = string
  default     = "dc1"
}

variable "nomad_region" {
  description = "The name of Nomad region."
  type        = string
  default     = "global"
}

variable "authoritative_region" {
  description = "Points the Nomad's authoritative region."
  type        = string
  default     = "global"
}

variable "gcp_instance_type" {
  description = "Machine Type. Correlates to an network egress cap."
  default     = "n1-standard-1"
}

variable "gcp_disk_image" {
  description = "Boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nomad-server-v093"
}

variable "gcp_client_disk_image" {
  description = "Client boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nomad-client-v093"
}

variable "gcp_frontend_disk_image" {
  description = "Frontend boot disk for gcp_instance_type."
  default     = "nomad-multiregion/ubuntu-1604-xenial-nginx-v001"
}

variable "instance_role" {
}

variable "cloudflare_email" {
}

variable "cloudflare_token" {
}

variable "cloudflare_zone" {
}

variable "subdomain_name" {
}


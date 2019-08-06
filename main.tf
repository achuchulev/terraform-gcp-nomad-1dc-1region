resource "null_resource" "generate_self_ca" {
  provisioner "local-exec" {
    # script called with private_ips of nomad backend servers
    command = "${path.root}/scripts/gen_self_ca.sh ${var.nomad_region}"
  }
}

resource "random_id" "server_gossip" {
  byte_length = 16
}

# Module that creates Nomad server instances
module "nomad_server" {
  source = "./modules/nomad_instance"

  gcp_project_id            = var.gcp_project_id
  gcp_credentials_file_path = var.gcp_credentials_file_path
  gcp_region                = var.gcp_region
  nomad_instance_count      = var.servers_count
  gcp_disk_image            = var.gcp_disk_image
  dc                        = var.datacenter
  nomad_region              = var.nomad_region
  authoritative_region      = var.authoritative_region
  gcp_instance_type         = var.gcp_instance_type
  gcp-vpc-network           = var.gcp-vpc-network
  gcp-subnet1-name          = var.gcp-subnet1-name
  domain_name               = var.subdomain_name
  zone_name                 = var.cloudflare_zone
  secure_gossip             = random_id.server_gossip.b64_std
}

# Module that creates Nomad client instances
module "nomad_client" {
  source = "./modules/nomad_instance"

  gcp_project_id            = var.gcp_project_id
  gcp_credentials_file_path = var.gcp_credentials_file_path
  gcp_region                = var.gcp_region
  dc                        = var.datacenter
  nomad_region              = var.nomad_region
  instance_role             = var.instance_role
  nomad_instance_count      = var.clients_count
  gcp_disk_image            = var.gcp_client_disk_image
  gcp_instance_type         = var.gcp_instance_type
  gcp-vpc-network           = var.gcp-vpc-network
  gcp-subnet1-name          = var.gcp-subnet1-name
  domain_name               = var.subdomain_name
  zone_name                 = var.cloudflare_zone
}

# Module that creates Nomad frontend instance
module "nomad_frontend" {
  source = "./modules/nomad_frontend"

  gcp_project_id            = var.gcp_project_id
  gcp_credentials_file_path = var.gcp_credentials_file_path
  gcp_region                = var.gcp_region
  gcp_disk_image            = var.gcp_frontend_disk_image
  dc                        = var.datacenter
  gcp_instance_type         = var.gcp_instance_type
  gcp-vpc-network           = var.gcp-vpc-network
  gcp-subnet1-name          = var.gcp-subnet1-name
  backend_private_ips       = module.nomad_server.instance_private_ip
  cloudflare_token          = var.cloudflare_token
  cloudflare_zone           = var.cloudflare_zone
  subdomain_name            = var.subdomain_name
  cloudflare_email          = var.cloudflare_email
  nomad_region              = var.nomad_region
}


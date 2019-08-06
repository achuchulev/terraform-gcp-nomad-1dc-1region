// Generates random name for instances
module "random_name" {
  source = "../random_pet"
}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

resource "google_compute_instance" "nginx_instance" {
  name         = "${var.gcp_region}-${var.dc}-${module.random_name.name}-frontend"
  machine_type = var.gcp_instance_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image
    }
  }

  network_interface {
    subnetwork = var.gcp-subnet1-name

    access_config {
      # Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")} }"
  }

  tags = ["nomad-frontend"]

  connection {
      host        = google_compute_instance.nginx_instance.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file("~/.ssh/id_rsa")
    }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/nomad/ssl",
    ]
  }
  provisioner "file" {
    source      = "${path.root}/ssl/nomad/${var.nomad_region}/"
    destination = "nomad/ssl"
  }

  provisioner "remote-exec" {
    script      = "${path.root}/scripts/cron_create.sh"
  }
}

# This makes the nginx configuration 
resource "null_resource" "nginx_config" {
  # changes to any server instance of the nomad cluster requires re-provisioning
  triggers = {
    backend_instance_ips   = jsonencode(var.backend_private_ips)
    cloudflare_record_ip   = cloudflare_record.nomad_frontend.value
    cloudflare_record_name = cloudflare_record.nomad_frontend.name
  }

  depends_on = [google_compute_instance.nginx_instance]

  # script can run on every nomad server instance change
  # script can run on every nomad server instance change
  connection {
    type        = "ssh"
    host        = google_compute_instance.nginx_instance.network_interface[0].access_config[0].nat_ip
    user        = var.ssh_user
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    # script called with private_ips of nomad backend servers
    source      = "${path.root}/scripts/nginx.sh"
    destination = "/tmp/nginx.sh"
  }

  provisioner "remote-exec" {
    # script called with private_ips of nomad backend servers
    inline = [
      "sudo echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -profile=client - | cfssljson -bare nomad/ssl/cli",
      "chmod +x /tmp/nginx.sh",
      "sudo /tmp/nginx.sh ${var.nomad_region}",
      "export IN=${replace(jsonencode(var.backend_private_ips), ",", "")}", # here we search for and remove commas
      "OUT=$(echo $IN | tr -d '[]')",                                       # here we remove square brackets
      "export OUT",
      "sudo -E bash -c 'echo upstream nomad_backend { $OUT } >> /etc/nginx/sites-available/default'",
      "sudo systemctl start nginx.service",
      "sudo rm -rf /tmp/*",
    ]
  }
}

# Creates a DNS record with Cloudflare
resource "cloudflare_record" "nomad_frontend" {
  domain = var.cloudflare_zone
  name   = var.subdomain_name
  value  = google_compute_instance.nginx_instance.network_interface[0].access_config[0].nat_ip
  type   = "A"
  ttl    = 3600
}

# Generates a trusted certificate issued by Let's Encrypt
resource "null_resource" "certbot" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cloudflare_record = cloudflare_record.nomad_frontend.value
    nginx_config      = null_resource.nginx_config.id
  }

  depends_on = [
    cloudflare_record.nomad_frontend,
    null_resource.nginx_config,
  ]

  # certbot script can run on every instance ip change
  connection {
    type        = "ssh"
    host        = google_compute_instance.nginx_instance.network_interface[0].access_config[0].nat_ip
    user        = var.ssh_user
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    # certbot script called with public_ip of frontend server
    inline = [
      "sudo certbot --nginx --non-interactive --agree-tos -m ${var.cloudflare_email} -d ${var.subdomain_name}.${var.cloudflare_zone} --redirect",
    ]
  }
}

resource "google_compute_firewall" "gcp-allow-http-https-traffic" {
  name    = "${var.gcp-vpc-network}-gcp-allow-http-https-traffic"
  network = var.gcp-vpc-network

  allow {
    protocol = "tcp"
    ports    = ["80", "433"]
  }

  source_ranges = [
    "0.0.0.0/0",
  ]

  source_tags = ["nomad-frontend"]

}

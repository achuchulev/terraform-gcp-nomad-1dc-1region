// Generates random name for instances
module "random_name" {
  source = "../random_pet"
}

// Provides access to available Google Compute zones in a region for a given project
data "google_compute_zones" "available" {
  region = var.gcp_region
}

// Creates Nomad instances
resource "google_compute_instance" "nomad_instance" {
  count        = var.nomad_instance_count
  name         = "${module.random_name.name}-${var.instance_role}-0${count.index + 1}"
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
      # ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")} }"
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  allow_stopping_for_update = true

  tags = [var.instance_role]

  connection {
    type     = "ssh"
    host     = self.network_interface[0].access_config[0].nat_ip
    user     = var.ssh_user
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

  provisioner "file" {
    source      = "${path.root}/config/cfssl.json"
    destination = "/tmp/cfssl.json"
  }

  provisioner "file" {
    source      = "${path.root}/config/nomad.service"
    destination = "/tmp/nomad.service"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/provision-${var.instance_role}.sh"
    destination = "/tmp/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -config=/tmp/cfssl.json -hostname='${var.instance_role}.${var.nomad_region}.nomad,localhost,127.0.0.1' - | cfssljson -bare nomad/ssl/${var.instance_role}",
      "sudo echo '{}' | cfssl gencert -ca=nomad/ssl/nomad-ca.pem -ca-key=nomad/ssl/nomad-ca-key.pem -profile=client - | cfssljson -bare nomad/ssl/cli",
      "sudo chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh ${var.nomad_region} ${var.dc} ${var.authoritative_region} ${var.gcp_project_id} ${var.secure_gossip}",
      "sudo cp /tmp/nomad.service /etc/systemd/system",
      "sudo systemctl enable nomad.service",
      "sudo systemctl start nomad.service",
      "sudo rm -rf /tmp/*",
      "echo 'export NOMAD_ADDR=https://${var.domain_name}.${var.zone_name}' >> ~/.profile",
    ]
  }
}

# Allow SSH
resource "google_compute_firewall" "gcp-allow-nomad-traffic" {
  count   = var.instance_role == "server" ? 1 : 0
  name    = "${var.gcp-vpc-network}-gcp-allow-nomad-traffic"
  network = var.gcp-vpc-network

  allow {
    protocol = "tcp"
    ports    = var.tcp_ports_nomad
  }

  allow {
    protocol = "udp"
    ports    = var.udp_ports_nomad
  }

  source_ranges = [
    "0.0.0.0/0",
  ]

  source_tags = ["server", "client"]
}
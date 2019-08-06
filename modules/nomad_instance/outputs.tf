output "instance_public_ip" {
  value = [google_compute_instance.nomad_instance.*.network_interface.0.access_config.0.nat_ip]
}

output "instance_private_ip" {
  value = [formatlist(
    "%s %s:%s;",
    "server",
    google_compute_instance.nomad_instance.*.network_interface.0.network_ip,
    "4646",
  )]
}


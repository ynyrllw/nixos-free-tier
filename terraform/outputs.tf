output "instance_ip" {
  description = "Public IP address of the deployed instance"
  value       = oci_core_instance.nixos.public_ip
}

output "instance_id" {
  description = "OCID of the deployed instance"
  value       = oci_core_instance.nixos.id
}

output "image_id" {
  description = "OCID of the imported custom image"
  value       = oci_core_image.nixos.id
}

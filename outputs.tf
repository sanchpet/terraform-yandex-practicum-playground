output "boot_disk_id" {
  description = "The ID of the boot disk created for the instance."
  value       = yandex_compute_disk.boot_disk.id
}

output "instance_id" {
  description = "The ID of the Yandex Compute instance."
  value       = yandex_compute_instance.first-vm.id
}

output "subnet_id" {
  description = "The ID of the VPC subnet used by the Yandex Compute instance."
  value       = yandex_vpc_subnet.subnet-d.id
}

output "ydb_id" {
  description = "The ID of the Yandex Managed Service for YDB instance."
  value       = yandex_ydb_database_serverless.first-ydb.id
}

output "service_account_id" {
  description = "The ID of the Yandex IAM service account."
  value       = yandex_iam_service_account.bucket.id
}

output "bucket_name" {
  description = "The name of the Yandex Object Storage bucket."
  value       = yandex_storage_bucket.first-bucket.bucket
}

output "bucket_access_key" {
  description = "The access key for the Yandex Object Storage bucket."
  value       = yandex_iam_service_account_static_access_key.bucket.access_key
  sensitive = true
}

output "instance_public_ip_address" {
  description = "The external IP address of the instance."
  value       = yandex_compute_instance.first-vm.network_interface[0].nat_ip_address
}

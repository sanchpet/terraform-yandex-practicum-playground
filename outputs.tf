output "boot_disk_ids" {
  description = "The IDs of the boot disks created for the instances."
  value = {
    for disk in yandex_compute_disk.boot_disk :
    disk.name => disk.id...
  }
}

output "instance_ids" {
  description = "The IDs of the Yandex Compute instances."
  value = {
    for instance in yandex_compute_instance.first-vm :
    instance.name => instance.id...
  }
}

output "subnet_ids" {
  description = "The IDs of the VPC subnets used by the Yandex Compute instances."
  value = {
    for subnet in yandex_vpc_subnet.private :
    subnet.name => subnet.id...
  }
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

output "instance_public_ip_addresses" {
  description = "The external IP addresses of the instances."
  value = {
    for address in yandex_vpc_address.public :
    address.name => address.external_ipv4_address[0].address...
  }
}

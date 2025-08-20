locals {
  boot_disk_name      = "${var.name_prefix}-boot-disk"
  linux_vm_name       = "${var.name_prefix}-first-vm"
  vpc_network_name    = "${var.name_prefix}-private"
  ydb_serverless_name = "${var.name_prefix}-ydb-serverless"
  bucket_sa_name      = "${var.name_prefix}-bucket-sa"
  bucket_name         = "${var.name_prefix}-terraform-bucket-sanchpet-${random_string.bucket_name.result}"
}

resource "yandex_vpc_network" "private" {
    name = local.vpc_network_name
}

resource "yandex_vpc_subnet" "subnet-d" {
    name           = keys(var.subnets)[0] # use the first key from the subnets map
    zone           = var.zone
    network_id     = yandex_vpc_network.private.id
    v4_cidr_blocks = var.subnets[keys(var.subnets)[0]]
}

data "yandex_compute_image" "ubuntu-2204-latest" { # image for new machine
    family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "boot_disk" {
    name     = local.boot_disk_name
    zone     = var.zone
    image_id = data.yandex_compute_image.ubuntu-2204-latest.id
    size     = 15
}

resource "yandex_compute_instance" "first-vm" {
    name                      = local.linux_vm_name
    allow_stopping_for_update = true
    platform_id               = var.instance_resources.platform_id
    zone                      = var.zone

    resources {
        cores  = var.instance_resources.cores
        memory = var.instance_resources.memory
    }

    boot_disk {
        disk_id = yandex_compute_disk.boot_disk.id
    }

    network_interface {
        subnet_id = yandex_vpc_subnet.subnet-d.id
    }
}

resource "yandex_ydb_database_serverless" "first-ydb" {
  name        = local.ydb_serverless_name
  location_id = "ru-central1"
}

resource "yandex_iam_service_account" "bucket" {
  name = local.bucket_sa_name
}

resource "yandex_resourcemanager_folder_iam_member" "storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.bucket.id}"
}

resource "yandex_iam_service_account_static_access_key" "bucket" {
  service_account_id = yandex_iam_service_account.bucket.id
  description        = "static access key for object storage"
}

resource "random_string" "bucket_name" {
  length  = 8
  special = false
  upper   = false
}

resource "yandex_storage_bucket" "first-bucket" {
  bucket     = local.bucket_name
  access_key = yandex_iam_service_account_static_access_key.bucket.access_key
  secret_key = yandex_iam_service_account_static_access_key.bucket.secret_key
  
  depends_on = [ yandex_resourcemanager_folder_iam_member.storage_editor ]
} 

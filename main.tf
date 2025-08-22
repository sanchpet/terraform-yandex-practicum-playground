locals {
  boot_disk_name      = var.boot_disk_name != null ? var.boot_disk_name : "${var.name_prefix}-boot-disk" 
  linux_vm_name       = var.linux_vm_name != null ? var.linux_vm_name : "${var.name_prefix}-linux-vm"
  vpc_network_name    = var.vpc_network_name != null ? var.vpc_network_name : "${var.name_prefix}-private"
  ydb_serverless_name = var.ydb_serverless_name != null ? var.ydb_serverless_name : "${var.name_prefix}-ydb-serverless"
  bucket_sa_name      = var.bucket_sa_name != null ? var.bucket_sa_name : "${var.name_prefix}-bucket-sa"
  bucket_name         = var.bucket_name != null ? var.bucket_name : "${var.name_prefix}-terraform-bucket-${random_string.bucket_name.result}"
} 

resource "yandex_vpc_network" "private" {
  name = local.vpc_network_name
}

resource "yandex_vpc_subnet" "private" {
  for_each = var.zones

  name           = keys(var.subnets)[index(tolist(var.zones), each.value)]
  zone           = each.value
  network_id     = yandex_vpc_network.private.id
  v4_cidr_blocks = var.subnets[each.value]
}

resource "yandex_vpc_address" "public" {
  for_each = var.zones

  name = length(var.zones) > 1 ? "${local.linux_vm_name}-address-${substr(each.value, -1, 0)}" : "${local.linux_vm_name}-address"
  external_ipv4_address {
    zone_id = each.value
  }
}

data "yandex_compute_image" "ubuntu-2204-latest" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "boot_disk" {
  for_each = var.zones

  name     = length(var.zones) > 1 ? "${local.boot_disk_name}-${substr(each.value, -1, 0)}" : local.boot_disk_name
  zone     = each.value
  image_id = data.yandex_compute_image.ubuntu-2204-latest.id
  
  type = var.instance_resources.disk.disk_type
  size = var.instance_resources.disk.disk_size
}

resource "yandex_compute_instance" "first-vm" {
  for_each = var.zones

  name                      = length(var.zones) > 1 ? "${local.linux_vm_name}-${substr(each.value, -1, 0)}" : local.linux_vm_name
  allow_stopping_for_update = true
  platform_id               = var.instance_resources.platform_id
  zone                      = each.value
  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
      ydb_connect_string = yandex_ydb_database_serverless.first-ydb.ydb_full_endpoint,
      bucket_domain_name = yandex_storage_bucket.first-bucket.bucket_domain_name
    })
  }

  resources {
    cores  = var.instance_resources.cores
    memory = var.instance_resources.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk[each.value].id
  }

  dynamic "secondary_disk" {
    for_each = each.value == "ru-central1-a" ? yandex_compute_disk.secondary_disk_a : each.value == "ru-central1-b" ? yandex_compute_disk.secondary_disk_b : each.value == "ru-central1-d" ? yandex_compute_disk.secondary_disk_d : []
    content {
      disk_id = try(secondary_disk.value.id, null)
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.private[each.value].id
    nat             = true
    nat_ip_address  = yandex_vpc_address.public[each.value].external_ipv4_address[0].address
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

resource "yandex_compute_disk" "secondary_disk_a" {
  count = contains(var.zones, "ru-central1-a") ? var.secondary_disks.count : 0

  name = "${var.secondary_disks.name}-a-${count.index}"
  zone = "ru-central1-a"

  type = var.secondary_disks.type
  size = var.secondary_disks.size
}

resource "yandex_compute_disk" "secondary_disk_b" {
  count = contains(var.zones, "ru-central1-b") ? var.secondary_disks.count : 0

  name = "${var.secondary_disks.name}-b-${count.index}"
  zone = "ru-central1-b"

  type = var.secondary_disks.type
  size = var.secondary_disks.size
}

resource "yandex_compute_disk" "secondary_disk_d" {
  count = contains(var.zones, "ru-central1-d") ? var.secondary_disks.count : 0

  name = "${var.secondary_disks.name}-d-${count.index}"
  zone = "ru-central1-d"

  type = var.secondary_disks.type
  size = var.secondary_disks.size
} 

resource "time_sleep" "wait_120_seconds" {
  create_duration = "120s"

  depends_on = [yandex_compute_instance.first-vm]
} 

resource "yandex_compute_snapshot" "initial" {
  for_each = yandex_compute_disk.boot_disk

  name           = "${each.value.name}-initial"
  source_disk_id = each.value.id

  depends_on = [time_sleep.wait_120_seconds]
} 

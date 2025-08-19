resource "yandex_vpc_network" "private" {
    name = "private"
}

resource "yandex_vpc_subnet" "subnet-d" {
    name           = "private"
    zone           = "ru-central1-d"
    network_id     = "${yandex_vpc_network.private.id}"
    v4_cidr_blocks = ["192.168.10.0/24"]
}

data "yandex_compute_image" "ubuntu-2204-latest" { # image for new machine
    family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "boot_disk" {
    name     = "boot-disk"
    zone     = "ru-central1-d"
    image_id = data.yandex_compute_image.ubuntu-2204-latest.id
    size     = 15
}

resource "yandex_compute_instance" "first-vm" {
    name                      = "first-vm"
    allow_stopping_for_update = true
    platform_id               = "standard-v3"
    zone                      = "ru-central1-d"

    resources {
        cores  = "4"
        memory = "8"
    }

    boot_disk {
        disk_id = yandex_compute_disk.boot_disk.id
    }

    network_interface {
        subnet_id = yandex_vpc_subnet.subnet-d.id
    }
}

resource "yandex_ydb_database_serverless" "first-ydb" {
  name        = "test-ydb-serverless"
  location_id = "ru-central1"
}

resource "yandex_iam_service_account" "bucket" {
  name = "bucket-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "storage_editor" {
  folder_id = "b1ge6p6tq19q17eip1ok"
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
  bucket     = "terraform-bucket-sanchpet-${random_string.bucket_name.result}"
  access_key = yandex_iam_service_account_static_access_key.bucket.access_key
  secret_key = yandex_iam_service_account_static_access_key.bucket.secret_key
  
  depends_on = [ yandex_resourcemanager_folder_iam_member.storage_editor ]
} 

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1.00"
}

provider "yandex" {
  zone                     = "ru-central1-d"
  folder_id                = "b1ge6p6tq19q17eip1ok"
}

provider "random" {}

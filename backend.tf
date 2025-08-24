terraform {
  backend "s3" {
    region         = "ru-central1"
    bucket         = "sanchpet-backend"
    key            = "terraform.tfstate"

    dynamodb_table = "state-lock-table"

    endpoints = {
      s3       = "https://storage.yandexcloud.net",
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1gr5nrg10c4rnr8gehu/etnlefq54kuisph4cgcu"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

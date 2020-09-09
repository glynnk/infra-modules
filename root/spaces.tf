resource "digitalocean_spaces_bucket" "bucket" {
  name   = format("%S-bucket", var.root.name)
  region = var.root.bucket_region
}

resource "digitalocean_spaces_bucket" "bucket" {
  name   = format("%S-tfstate-bucket", var.root.name)
  region = var.root.bucket_region
}

# state.tf
# Remote state
terraform {
  backend "s3" {
    endpoint                    = format("%s.digitaloceanspaces.com/", digitalocean_spaces_bucket.bucket.region) # specify the correct DO region
    region                      = "eu-west-1"                                                                    # not used since it's a DigitalOcean spaces bucket
    key                         = format("%s-root.tfstate", var.root.name)
    bucket                      = digitalocean_spaces_bucket.bucket.name

    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

terraform {
  backend "s3" {
    bucket       = "emmy-github-webdev-observastack"
    key          = "observastack/production/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
terraform {
  backend "s3" {
    bucket       = "jeevan-cloudops-terraform-state"
    key          = "cloudops/dev/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
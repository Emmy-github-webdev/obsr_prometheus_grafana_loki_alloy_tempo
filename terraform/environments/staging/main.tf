module "vpc" {
  source = "../../modules/vpc"

  project_name = "observastack"
  environment  = "staging"

  vpc_cidr = "10.20.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  tags = {
    Project     = "observastack"
    Environment = "staging"
    ManagedBy   = "Terraform"
    Owner       = "ObservaStack"
    Criticality = "medium"
  }
}
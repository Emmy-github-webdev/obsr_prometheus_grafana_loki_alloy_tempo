module "vpc" {
  source = "../../modules/vpc"

  project_name = "observastack"
  environment  = "dev"

  vpc_cidr = "10.10.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  tags = {
    Project     = "observastack"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "ObservaStack"
    Criticality = "low"
  }
}
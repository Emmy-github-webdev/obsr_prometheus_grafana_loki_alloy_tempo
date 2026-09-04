module "vpc" {
  source = "../../modules/vpc"

  project_name = "observastack"
  environment  = "production"

  vpc_cidr = "10.30.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  tags = {
    Project     = "observastack"
    Environment = "production"
    ManagedBy   = "Terraform"
    Owner       = "ObservaStack"
    Criticality = "high"
  }
}
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "observastack"
      Environment = "production"
      ManagedBy   = "Terraform"
      Owner       = "ObservaStack"
      Criticality = "high"
    }
  }
}
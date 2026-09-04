provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "observastack"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "ObservaStack"
      Criticality = "low"
    }
  }
}
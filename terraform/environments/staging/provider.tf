provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "observastack"
      Environment = "staging"
      ManagedBy   = "Terraform"
      Owner       = "ObservaStack"
      Criticality = "medium"
    }
  }
}
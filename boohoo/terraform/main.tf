terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "boohoo-terraform-state-332779204498"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2"
  
  default_tags {
    tags = {
      Project     = "BoohooDataPipeline"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

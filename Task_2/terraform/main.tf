terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "vignesh"
}

locals {
  project_name = "my-vpc"
  environment  = "production"
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "vignesh"
  }
}

module "vpc" {
  source = "./modules/vpc"
  project_name              = local.project_name
  environment              = local.environment
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.availability_zones
  public_subnets           = var.public_subnet_cidrs
  private_subnets          = var.private_subnet_cidrs
  tags                     = local.common_tags
  enable_flow_logs         = true
  flow_logs_retention_days = 30
} 
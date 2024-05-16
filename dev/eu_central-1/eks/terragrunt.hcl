# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If any environment
# needs to deploy a different module version, it should redefine this block with a different ref to override the
# deployed version.
terraform {
  source = "${local.base_source_url}"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    public_subnet_ids  = ["subnet-1", "subnet-2"]
    private_subnet_ids = ["psubnet-1", "psubnet-2"]
    vpc_id             = "temp-id"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the terraform block in the child terragrunt configurations.
  base_source_url = "git::git@github.com:Tomczi18/terragruntModules.git//eks"
}

# Inputs are the values demanded by specific module. In this case we providing data in order to create vpc.
inputs = {
  cluster_name                         = "eks"
  cluster_service_ipv4_cidr            = "172.20.0.0/16"
  cluster_version                      = "1.28"
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  env                                  = local.env
  instance_type                        = "t2.micro"
  eks_keypair                          = "terraform-key"
  ami_type                             = "AL2_x86_64"
  public_subnet_ids                    = dependency.vpc.outputs.public_subnet_ids
  private_subnet_ids                   = dependency.vpc.outputs.private_subnet_ids
}

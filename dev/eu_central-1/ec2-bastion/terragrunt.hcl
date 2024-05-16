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
    public_subnet_ids = ["subnet-1", "subnet-2"]
    vpc_id            = "temp-id"
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
  base_source_url = "git::git@github.com:Tomczi18/terragruntModules.git//ec2-bastion"
}

# Inputs are the values demanded by specific module. In this case we providing data in order to create vpc.
inputs = {
  env                   = local.env
  instance_type         = "t2.micro"
  ec2_bastion_subnet_id = dependency.vpc.outputs.public_subnet_ids[0]
  vpc_id                = dependency.vpc.outputs.vpc_id
  instance_keypair      = "terraform-key"
}

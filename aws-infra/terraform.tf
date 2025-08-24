terraform {
  # Define required providers and their version constraints
  required_providers {
    # AWS provider for managing AWS resources
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use latest 5.x version
    }

    # Random provider for generating unique identifiers
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"  # Specific version for reproducibility
    }
  }

  # Require specific Terraform version for consistency
  required_version = "~> 1.12.1"
}

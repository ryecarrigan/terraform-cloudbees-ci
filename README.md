# tf-core-modern
 Terraform plan for CloudBees Core for Modern platforms in AWS EKS

## Cluster Setup
This plan uses default AWS credentials. 
1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Edit `terraform.tfvars` and provide your desired values.
3. Run `terraform plan` and verify the output.
4. Run `terraform apply` to create resources.

Run `kubectl get nodes -w` to verify that nodes are now connecting.

Your EKS cluster is now ready to install CloudBees Core.

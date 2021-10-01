# terraform-cloudbees-ci
Terraform plan for CloudBees CI for modern cloud platforms.

Includes roots for creating a Kubernetes cluster in EKS (other providers TBD) and Helmfile configuration for installing CloudBees SDA.

## Prerequisites
This plan uses default AWS credentials and region available for the terraform AWS provider.

You _must_ set (at minimum) `AWS_PROFILE` and `AWS_REGION`. 

### Tools
The following tools must be installed and available in your PATH:
* `aws` CLI with configured profile(s)
* `helm` v3.0+
* `terraform` v1.0+
* `kubectl` v1.18+

### Configuration
1. Set up your local configuration 
    * Copy `.env.example` to `.env`
    * Edit `.env` and provide your desired values.
    * If needed, reload the configuration with `source .env`

2. (Optional) Bootstrap the S3 bucket to be configured as the Terraform backend.
    ```shell
    make bucket ACTION=apply
    ```

   If you want to reuse an existing bucket, set the value of `BUCKET_NAME` to the existing bucket's name.

   You can also import the existing bucket.
   ```shell
   make bucket-import
   ```

    NOTE: Because this manages the location of remote state storage, state for this plan
    is not itself stored remotely. However, the S3 bucket is the only resource that is managed.

## Installation
The Makefile wraps Terraform with a default action of "plan". When you run the following `make` targets, you can set the value of `ACTION` to change this behavior.

### EKS 
1. Prepare the EKS cluster.
    * Initialize the terraform plan. 
        ```shell
        make eks-init
        ```
    * (Optional) View the terraform plan. Without a provided `ACTION`, this will run `terraform plan`.
        ```shell
        make eks
        ```
    * Create the EKS cluster.
        ```shell
        make eks ACTION=apply
        ```

# terraform-cloudbees-ci
Terraform plan for CloudBees SDA for modern cloud platforms.

Includes roots for creating a Kubernetes cluster in EKS (other providers TBD) and configuration for installing CloudBees SDA.

## Prerequisites
### Tools
The following tools should be installed and available in your PATH:

* Required
  * `terraform` v1.0+
* Recommended
  * `aws` CLI with configured profile(s)
  * `kubectl` at a version matching the target Kubernetes cluster

### Configuration
1. Set up your local configuration 
   1. Use `.env` to configure variables across all plans
      * Copy `.env.example` to `.env`
      * Edit `.env` and provide your desired values.
      * If needed, reload the configuration with `source .env`
   2. Use `.auto.tfvars` to configure each plan
      * Copy `.auto.tfvars.example` to `.auto.tfvars` in each Terraform root
      * Edit `.auto.tfvars` and provide your desired values.
2. Set up the Terraform backend.
   * It is recommended to configure a remote Terraform backend for each of the root plans.
   * Each Terraform plan contains a `backend.tf.example` that you can copy to `backend.tf` (ignored by Git) and modify as needed.
   * Otherwise, Terraform will use the default local store.

## Installation
The Makefile wraps Terraform with a default action of "plan". When you run the following `make` targets, you can set the value of `ACTION` to change this behavior.

### EKS 
1. Prepare the EKS cluster.
    * Initialize the terraform plan. 
        ```shell
        $ terraform init
        ```
    * (Optional) View the terraform plan. Without a provided `ACTION`, this will run `terraform plan`.
        ```shell
        $ terraform plan
        ```
    * Create the EKS cluster.
        ```shell
        $ terraform apply
        ```

2. Install CloudBees SDA.
   * Initialize the terraform plan.
       ```shell
       $ terraform init
       ```
   * (Optional) View the terraform plan. Without a provided `ACTION`, this will run `terraform plan`.
       ```shell
       $ terraform plan
       ```
   * Create the EKS cluster.
       ```shell
       $ terraform apply
       ```

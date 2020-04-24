#!/usr/bin/env bash
# From the AWS docs: https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html#enable-windows-support

if [[ -z "$AWS_REGION" ]]; then
  echo "AWS_REGION must be set"
  exit
fi

if [[ -z "$CLUSTER_NAME" ]]; then
  echo "CLUSTER_NAME must be set"
  exit
fi

if ! aws eks update-kubeconfig --name "${CLUSTER_NAME}"; then
  exit
fi

# 1. Deploy the VPC resource controller to your cluster.
kubectl apply \
  -f https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/${AWS_REGION}/vpc-resource-controller/latest/vpc-resource-controller.yaml

# 2. Create the VPC admission controller webhook manifest for your cluster.

# 2.a. Download the required scripts and deployment files.
curl -sSo webhook-create-signed-cert.sh https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/${AWS_REGION}/vpc-admission-webhook/latest/webhook-create-signed-cert.sh
curl -sSo webhook-patch-ca-bundle.sh https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/${AWS_REGION}/vpc-admission-webhook/latest/webhook-patch-ca-bundle.sh
curl -sSo vpc-admission-webhook-deployment.yaml https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/${AWS_REGION}/vpc-admission-webhook/latest/vpc-admission-webhook-deployment.yaml

# 2.b. Add permissions to the shell scripts so that they can be executed.
chmod +x webhook-create-signed-cert.sh webhook-patch-ca-bundle.sh
# 2.c. Create a secret for secure communication.
./webhook-create-signed-cert.sh

# 2.d. Verify the secret.
kubectl get secret -n kube-system vpc-admission-webhook-certs

# 2.e. Configure the webhook and create a deployment file.
cat ./vpc-admission-webhook-deployment.yaml | ./webhook-patch-ca-bundle.sh > vpc-admission-webhook.yaml

# 3. Deploy the VPC admission webhook.
kubectl apply -f vpc-admission-webhook.yaml

# 4. Determine if your cluster has the required cluster role binding.
if ! kubectl get clusterrolebinding eks:kube-proxy-windows
then
  # Apply the configuration to the cluster.
  kubectl apply -f eks-kube-proxy-windows-crb.yaml
fi

# Clean temporary files
rm webhook-create-signed-cert.sh
rm webhook-patch-ca-bundle.sh
rm vpc-admission-webhook-deployment.yaml

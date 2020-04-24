#!/usr/bin/env bash
# Like the install script but in reverse.

if [[ -z "$AWS_REGION" ]]; then
  echo "AWS_REGION must be set"
  exit
fi

if [[ -z "$CLUSTER_NAME" ]]; then
  echo "CLUSTER_NAME must be set"
  exit
fi

# Check that AWS CLI is available, then use it to update kubeconfig
if command -v aws; then
  if ! aws eks update-kubeconfig --name "${CLUSTER_NAME}"; then exit; fi
else
  echo "AWS CLI not found"; exit
fi

# 4. Determine if your cluster has the required cluster role binding.
if kubectl get clusterrolebinding eks:kube-proxy-windows
then
  # Delete the configuration to the cluster.
  kubectl delete -f eks-kube-proxy-windows-crb.yaml
fi

# 3. Delete the VPC admission webhook.
if [[ -f ./vpc-admission-webhook.yaml ]]; then
  kubectl delete -f vpc-admission-webhook.yaml
  rm vpc-admission-webhook.yaml
else
  kubectl delete deployment -n kube-system vpc-admission-webhook-deployment
  kubectl delete mutatingwebhookconfigurations vpc-admission-webhook-cfg
  kubectl delete service -n kube-system vpc-admission-webhook-svc
fi

# 2.d. Verify the secret.
kubectl delete secret -n kube-system vpc-admission-webhook-certs

kubectl delete \
  -f https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/${AWS_REGION}/vpc-resource-controller/latest/vpc-resource-controller.yaml

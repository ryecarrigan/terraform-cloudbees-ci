#!/usr/bin/env bash
# Like the install script but in reverse.

if [[ -z "$AWS_REGION" ]]; then
  echo "AWS_REGION must be set"
  exit
fi

# 4. Determine if your cluster has the required cluster role binding.
if kubectl get clusterrolebinding eks:kube-proxy-windows
then
  # Delete the configuration to the cluster.
  kubectl delete -f eks-kube-proxy-windows-crb.yaml
fi

# 3. Delete the VPC admission webhook.
kubectl delete -f vpc-admission-webhook.yaml

# 2.d. Verify the secret.
kubectl delete secret -n kube-system vpc-admission-webhook-certs

kubectl delete \
  -f https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/${AWS_REGION}/vpc-resource-controller/latest/vpc-resource-controller.yaml

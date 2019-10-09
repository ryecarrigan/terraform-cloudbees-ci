#!/usr/bin/env bash
CLUSTER_NAME=$(terraform output cluster_name)
if [[ -z ${CLUSTER_NAME} ]]; then
  exit 1
fi

INSTANCE_ROLE_ARN=$(terraform output instance_role_arn)
if [[ -z ${INSTANCE_ROLE_ARN} ]]; then
  exit 1
fi

aws eks --region us-east-1 update-kubeconfig --name "${CLUSTER_NAME}"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${INSTANCE_ROLE_ARN}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

ACTION ?= plan


.ONESHELL:

eks:
	terraform -chdir=roots/eks $(ACTION)


sda:
	terraform -chdir=roots/sda $(ACTION)


post-eks:
	aws eks update-kubeconfig --name `terraform -chdir=roots/eks output -raw cluster_name`
	kubectl annotate --overwrite storageclass `kubectl get storageclass -o json | jq -r '.items[].metadata | select(.annotations."storageclass.kubernetes.io/is-default-class"=="true") | .name'` storageclass.kubernetes.io/is-default-class=false
	kubectl annotate --overwrite storageclass `terraform -chdir=roots/eks output -raw storage_class_name` storageclass.kubernetes.io/is-default-class=true


post-sda:
	kubectl config set-context --current --namespace=`terraform -chdir=roots/sda output -raw ci_namespace`

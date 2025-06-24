ACTION ?= plan


eks:
	terraform -chdir=roots/eks $(ACTION)


sda:
	terraform -chdir=roots/sda $(ACTION)


replication:
	terraform -chdir=roots/replication $(ACTION)


replication-timestamp:
	aws efs describe-replication-configurations --file-system-id `terraform -chdir=roots/replication output -raw primary_file_system`| jq -r ".Replications[].Destinations[] | select(.FileSystemId==\"`terraform -chdir=roots/replication output -raw secondary_file_system`\") | .LastReplicatedTimestamp"


post-eks:
	aws eks update-kubeconfig --name `terraform -chdir=roots/eks output -raw cluster_name`
	for name in `kubectl get storageclass -o json | jq -r '.items[].metadata | select(.annotations."storageclass.kubernetes.io/is-default-class"=="true") | .name'`; do kubectl annotate --overwrite storageclass $$name storageclass.kubernetes.io/is-default-class=false; done
	kubectl annotate --overwrite storageclass `terraform -chdir=roots/eks output -raw storage_class_name` storageclass.kubernetes.io/is-default-class=true


post-sda:
	kubectl config set-context --current --namespace=`terraform -chdir=roots/sda output -raw ci_namespace`


up:
	make eks ACTION="apply -auto-approve"
	make post-eks
	make sda ACTION="apply -auto-approve"
	make post-sda


down:
	make sda ACTION="destroy -auto-approve"
	make eks ACTION="destroy -auto-approve"


in:
	for name in `terraform -chdir=roots/eks output -json autoscaling_group_names | jq -r '. | flatten[]'`; do aws autoscaling update-auto-scaling-group --auto-scaling-group-name $$name --min-size 0 --desired-capacity 0; done


out:
	for name in `terraform -chdir=roots/eks output -json autoscaling_group_names | jq -r '. | flatten[]'`; do aws autoscaling update-auto-scaling-group --auto-scaling-group-name $$name --min-size 1 --desired-capacity 1; done

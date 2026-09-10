SHELL := /usr/bin/env bash
ACTION ?= plan

.PHONY: all help eks eks-resources ci sda replication replication-timestamp post-eks post-sda up down in out fmt validate

help:
	@echo "Usage: make <target> [ACTION=<action>]"
	@echo ""
	@echo "Workflow targets:"
	@echo "  up                    Apply full stack (eks -> eks-resources -> post-eks -> sda -> post-sda)"
	@echo "  down                  Destroy full stack in reverse order"
	@echo "  in / out              Scale worker node groups to 0 or 1"
	@echo "  fmt / validate        Format and validate all root modules"
	@echo ""
	@echo "Component targets (runs: terraform -chdir=roots/<dir> \$$(ACTION)):"
	@echo "  eks                   roots/eks-core"
	@echo "  eks-resources         roots/eks-resources"
	@echo "  sda / ci              roots/sda"
	@echo "  replication           roots/replication"
	@echo "  replication-timestamp Query AWS EFS replication status"


eks:
	terraform -chdir=roots/eks-core $(ACTION)


eks-resources:
	terraform -chdir=roots/eks-resources $(ACTION)


ci sda:
	terraform -chdir=roots/sda $(ACTION)


replication:
	terraform -chdir=roots/replication $(ACTION)


replication-timestamp:
	@PRIMARY=$$(terraform -chdir=roots/replication output -raw primary_file_system); \
	SECONDARY=$$(terraform -chdir=roots/replication output -raw secondary_file_system); \
	aws efs describe-replication-configurations --file-system-id "$$PRIMARY" | \
		jq -r --arg sec "$$SECONDARY" '.Replications[].Destinations[] | select(.FileSystemId == $$sec) | .LastReplicatedTimestamp'


post-eks:
	aws eks update-kubeconfig --name $$(terraform -chdir=roots/eks-core output -raw cluster_name)
	@CONTEXT=$$(terraform -chdir=roots/eks-core output -raw cluster_arn); \
	for name in $$(kubectl get storageclass --context "$$CONTEXT" -o json | jq -r '.items[].metadata | select(.annotations."storageclass.kubernetes.io/is-default-class"=="true") | .name'); do \
		kubectl annotate --context "$$CONTEXT" --overwrite storageclass "$$name" storageclass.kubernetes.io/is-default-class=false; \
	done; \
	SC_NAME=$$(terraform -chdir=roots/eks-resources output -raw storage_class_name); \
	if [ -n "$$SC_NAME" ]; then \
		kubectl annotate --context "$$CONTEXT" --overwrite storageclass "$$SC_NAME" storageclass.kubernetes.io/is-default-class=true; \
	fi


post-sda:
	kubectl config set-context --current --namespace=$$(terraform -chdir=roots/sda output -raw ci_namespace)


up:
	$(MAKE) eks ACTION="apply -auto-approve"
	$(MAKE) eks-resources ACTION="apply -auto-approve"
	$(MAKE) post-eks
	$(MAKE) sda ACTION="apply -auto-approve"
	$(MAKE) post-sda


down:
	$(MAKE) sda ACTION="destroy -auto-approve"
	$(MAKE) eks-resources ACTION="destroy -auto-approve"
	$(MAKE) eks ACTION="destroy -auto-approve"


in:
	@for name in $$(terraform -chdir=roots/eks-core output -json autoscaling_group_names | jq -r '. | flatten[]'); do \
		aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$$name" --min-size 0 --desired-capacity 0; \
		echo "Scaled in: $$name"; \
	done


out:
	@for name in $$(terraform -chdir=roots/eks-core output -json autoscaling_group_names | jq -r '. | flatten[]'); do \
		aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$$name" --min-size 0 --desired-capacity 1; \
		echo "Scaled out: $$name"; \
	done


fmt:
	terraform fmt -recursive


validate:
	@for dir in roots/*; do \
		if [ -d "$$dir" ]; then \
			echo "==> Validating $$dir"; \
			terraform -chdir=$$dir validate || exit 1; \
		fi; \
	done


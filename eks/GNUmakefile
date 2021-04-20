ACTION ?= plan


.PHONY: bucket
0 bucket:
	$(call check_defined, TF_VAR_bucket_name, name of the backend state bucket)
	@cd roots/00_state_bucket && \
		terraform $(ACTION)

bucket-init roots/state_bucket/.terraform/terraform.tfstate:
	$(call check_defined, TF_VAR_bucket_name, name of the backend state bucket)
	@cd roots/00_state_bucket && \
		terraform init \
			-reconfigure


.PHONY: cluster
1 cluster: roots/01_cluster
	$(call check_defined, TF_VAR_cluster_name, name of the EKS cluster)
	@cd roots/01_cluster && \
		terraform $(ACTION)

cluster-init roots/01_cluster/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/01_cluster && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)"


.PHONY: nodes
2 nodes: roots/02_nodes
	$(call check_defined, TF_VAR_bucket_name, name for the backend state bucket)
	$(call check_defined, TF_VAR_cluster_name, name of the EKS cluster)
	@cd roots/02_nodes && \
		terraform $(ACTION)

nodes-init roots/02_nodes/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name for the backend state bucket)
	@cd roots/02_nodes && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)"


.PHONY: helm
3 resources: roots/03_helm
	$(call check_defined, TF_VAR_bucket_name, name for the backend state bucket)
	$(call check_defined, TF_VAR_cluster_name, name of the EKS cluster)
	@cd roots/03_helm && \
		terraform $(ACTION)

helm-init roots/03_helm/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name for the backend state bucket)
	@cd roots/03_helm && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)"


.PHONY: cname
4 cname: roots/04_cname
	@cd roots/04_cname && \
		terraform $(ACTION)

.PHONY: init
init: cluster-init nodes-init helm-init


windows-add:
	@cd windows-support && \
		./install-windows-support.sh

windows-remove:
	@cd windows-support && \
		./uninstall-windows-support.sh


check_defined = \
		$(strip $(foreach 1,$1, \
			$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
		$(if $(value $1),, \
			$(error Undefined $1$(if $2, ($2))))

ACTION ?= plan


.PHONY: bucket
bucket:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/state_bucket && \
		terraform $(ACTION) \
			-var "bucket_name=$(BUCKET_NAME)"


.PHONY: cluster
cluster: roots/cluster_setup/.terraform/terraform.tfstate
	$(call check_defined, CLUSTER_NAME, name of the EKS cluster)
	@cd roots/cluster_setup && \
		terraform $(ACTION) \
			-var "cluster_name=$(CLUSTER_NAME)"

cluster-init roots/cluster_setup/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/cluster_setup && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)"


.PHONE: nodes
nodes: roots/cluster_nodes
	$(call check_defined, BUCKET_NAME, name for the backend state bucket)
	$(call check_defined, CLUSTER_NAME, name of the EKS cluster)
	@cd roots/cluster_nodes && \
		terraform $(ACTION) \
			-var "bucket_name=$(BUCKET_NAME)" \
			-var "cluster_name=$(CLUSTER_NAME)"

nodes-init roots/cluster_nodes/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name for the backend state bucket)
	@cd roots/cluster_nodes && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)"


.PHONY: resources
resources: roots/cluster_resources
	$(call check_defined, BUCKET_NAME, name for the backend state bucket)
	$(call check_defined, CLUSTER_NAME, name of the EKS cluster)
	@cd roots/cluster_resources && \
		terraform $(ACTION) \
			-var "bucket_name=$(BUCKET_NAME)" \
			-var "cluster_name=$(CLUSTER_NAME)"

resources-init roots/cluster_resources/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name for the backend state bucket)
	@cd roots/cluster_resources && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)"

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

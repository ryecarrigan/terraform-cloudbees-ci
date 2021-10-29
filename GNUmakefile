ACTION ?= plan
STATE_KEY ?= cloudbees_sda


.PHONY: bucket
bucket:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/backend_s3 && \
		terraform $(ACTION) \
			-var bucket_name=$(BUCKET_NAME)

bucket-import:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/backend_s3 && \
		terraform import \
			-var 'bucket_name=$(BUCKET_NAME)' \
			aws_s3_bucket.this $(BUCKET_NAME)

bucket-init roots/backend_s3/.terraform/terraform.tfstate:
	@cd roots/backend_s3 && \
		terraform init \
			-reconfigure


.PHONY: eks
eks: roots/eks
	$(call check_defined, TF_VAR_cluster_name, name of the EKS cluster)
	@cd roots/eks && \
		terraform $(ACTION)

eks-init roots/eks/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/eks && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)" \
			-backend-config="key=$(STATE_KEY)/cluster/terraform.tfstate"


.PHONY: eks-context
eks-context:
	$(call check_defined, CLUSTER_NAME, name of the EKS cluster)
	$(call check_defined, CI_NAMESPACE, namespace for CloudBees CI)
	aws eks update-kubeconfig --name $(CLUSTER_NAME)
	@cd roots/eks && \
		kubectl config set-context `terraform output -raw cluster_arn` --namespace=$(CI_NAMESPACE)
	@cd roots/eks && \
		kubectl config use-context `terraform output -raw cluster_arn`


.PHONY: sda
sda: roots/sda
	$(call check_defined, TF_VAR_cluster_name, name of the EKS cluster)
	@cd roots/sda && \
		terraform $(ACTION)

sda-init roots/sda/.terraform/terraform.tfstate:
	$(call check_defined, BUCKET_NAME, name of the backend state bucket)
	@cd roots/sda && \
		terraform init \
			-reconfigure \
			-backend-config="bucket=$(BUCKET_NAME)" \
			-backend-config="key=$(STATE_KEY)/eks_sda/terraform.tfstate"


check_defined = \
		$(strip $(foreach 1,$1, \
			$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
		$(if $(value $1),, \
			$(error Undefined $1$(if $2, ($2))))

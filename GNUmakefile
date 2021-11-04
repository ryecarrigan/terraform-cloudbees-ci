ACTION ?= plan


.PHONY: eks
eks: roots/eks
	@cd roots/eks && \
		terraform $(ACTION)


.PHONY: eks-context
eks-context:
	@cd roots/eks && \
		aws eks update-kubeconfig --name  `terraform output -raw cluster_id` && \
		kubectl config use-context `terraform output -raw cluster_arn`
ifdef CI_NAMESPACE
	@cd roots/eks && \
		kubectl config set-context `terraform output -raw cluster_arn` --namespace=$(CI_NAMESPACE)
endif


eks-create:
	make eks ACTION="apply -auto-approve"
	make eks-context
	make sda ACTION="apply -auto-approve"


eks-destroy:
	make sda ACTION="destroy -auto-approve"
	make eks ACTION="destroy -auto-approve"


.PHONY: sda
sda: roots/sda
	@cd roots/sda && \
		terraform $(ACTION)

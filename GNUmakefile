ACTION ?= plan


.PHONY: eks
eks: roots/eks
	@cd roots/eks && \
		terraform $(ACTION)


.PHONY: eks-context
eks-context:
	@cd roots/eks && \
		eval `terraform output -raw update_kubeconfig_command` && \
		eval `terraform output -raw update_kubectl_context_command` && \
		kubectl annotate --overwrite storageclass gp2 storageclass.kubernetes.io/is-default-class=false


.PHONY: sda
sda: roots/sda
	@cd roots/sda && \
		terraform $(ACTION)


.PHONY: sda-context
sda-context: roots/sda
	@cd roots/sda && \
		eval `terraform output -raw update_kubectl_namespace_command`

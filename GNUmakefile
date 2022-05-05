ACTION ?= plan


.PHONY: eks
eks: roots/eks
	@cd roots/eks && \
		terraform $(ACTION)


.PHONY: sda
sda: roots/sda
	@cd roots/sda && \
		terraform $(ACTION)


.PHONY: sda-context
sda-context: roots/sda
	@cd roots/sda && \
		eval `terraform output -raw update_kubectl_namespace_command`

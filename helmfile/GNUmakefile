casc:
	kubectl -n ${CI_NAMESPACE} create configmap oc-casc-bundle --from-file=oc-casc-bundle/ -o yaml --dry-run=client | kubectl apply -f -
	kubectl -n ${CI_NAMESPACE} create configmap mc-casc-bundle --from-file=mc-casc-bundle/ -o yaml --dry-run=client | kubectl apply -f -

casc-delete:
	kubectl -n ${CI_NAMESPACE} delete configmap oc-casc-bundle
	kubectl -n ${CI_NAMESPACE} delete configmap mc-casc-bundle

config:
	kubectl -n ${CI_NAMESPACE} create configmap oc-configmap --from-file=oc-configmap/ -o yaml --dry-run=client | kubectl apply -f -

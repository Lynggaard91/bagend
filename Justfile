deploy_talos:
  terraform -chdir=./terraform apply
  kustomize build --enable-helm ./kubernetes/cilium | kubectl --kubeconfig=./terraform/talos/kubeconfig apply -f -

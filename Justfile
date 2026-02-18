deploy: tf kapply
tf:
    terraform -chdir=./terraform/homelab apply
tfd:
    terraform -chdir=./terraform/homelab destroy
tfiu:
    terraform -chdir=./terraform/homelab init -upgrade
kust:
    kustomize build --enable-helm
kustdiff:
    git stash
    git switch master
    kustomize build --enable-helm > /tmp/master.yaml
    git switch "$GITBRANCH"
    git stash pop
    kustomize build --enable-helm > /tmp/branch.yaml
    git diff --no-index --color=always /tmp/master.yaml /tmp/branch.yaml | less -R
kapply:
    kustomize build --enable-helm ./kubernetes/cilium | kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig apply -f -

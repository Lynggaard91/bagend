deploy: tf k8s-bootstrap
tf:
    terraform -chdir=./terraform/homelab apply
tfd:
    terraform -chdir=./terraform/homelab destroy
tfiu:
    terraform -chdir=./terraform/homelab init -upgrade
tfc-plan:
    terraform -chdir=./terraform/cloudflare plan
tfc-apply:
    terraform -chdir=./terraform/cloudflare apply
tfc-init:
    terraform -chdir=./terraform/cloudflare init
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
k8s-bootstrap: kapply
    kustomize build --enable-helm ./kubernetes/cilium | kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig apply -f -
    kustomize build --enable-helm ./kubernetes/argocd | kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig apply -f -
    kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig create namespace eso --dry-run=client -o yaml | kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig apply -f -
    kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig create secret generic eso-credentials --namespace eso --from-literal=access-key-id=$(aws ssm get-parameter --name /bagend/eso/access_key_id --profile bagend --region eu-west-1 --query Parameter.Value --output text) --from-literal=secret-access-key=$(aws ssm get-parameter --name /bagend/eso/secret_access_key --with-decryption --profile bagend --region eu-west-1 --query Parameter.Value --output text) --dry-run=client -o yaml | kubectl --kubeconfig=./terraform/homelab/talos/kubeconfig apply -f -

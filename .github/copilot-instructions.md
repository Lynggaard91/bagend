# Project Instructions

## Global Instructions
Do not make changes to this file. If any changes or suggestions are to be made around instructions these must be provided in \<project\>/.github/instructions/. This does not count for index, plan or improvements out of scope of agent-instructions.

Apply the Global instructions directed in '/Users/clj/git/global-agent-instructions/global-instructions.md'.

## Project Specific Instructions

- '/Users/clj/git/global-agent-instructions/awesome-copilot/instructions/kubernetes-manifests.instructions.md'

- '/Users/clj/git/global-agent-instructions/awesome-copilot/instructions/terraform.instructions.md'

--

# The Project - Bagend, Homelab

I'm building a homelab which will inhabit various services to help me learn and experiment with different technologies. But also to serve Networking (Unifi), Home Media Server (Jellyfin), Home Automation (Home Assistant) and more. The project will use AWS Route53 for DNS Management. Everything will be run on Proxmox.

## Project Expectations

### Infrastructure as Code
The main language for IaC will be HCL. Eventually a switch will be made to OpenTofu from Terraform and possible Terragrunt on top as an orchestrator abstraction.

### Kubernetes
The operating system for Kubernetes will be Talos.

I expect the Kubernetes Cluster to use these components:
- Cilium for networking
- Longhorn for storage
- External-DNS for DNS management
- Cert-Manager for certificate management
- kgateway for API Gateway (superseding ) management
- Groundcover as observability stack
- ArgoCD for GitOps

## References

These references must be used first and foremost whenever intel needs to be gathered around one of the mentioned languages, tools, frameworks or components.

*Proxmox*
- https://pve.proxmox.com/pve-docs/

*Talos*
- https://docs.siderolabs.com/talos/v1.12/overview/what-is-talos


*Longhorn*
- https://longhorn.io/docs/1.10.1/


*Cilium*
- https://github.com/cilium/cilium
- https://cilium.io/

*ArgoCD*
- https://argo-cd.readthedocs.io/en/stable/

*External-DNS*
- https://github.com/kubernetes-sigs/external-dns

*Cert-manager*
- https://cert-manager.io/docs/

*kgateway*
- https://github.com/kgateway-dev/kgateway

*groundcover*
- https://docs.groundcover.com/

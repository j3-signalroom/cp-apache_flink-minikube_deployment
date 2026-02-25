# ==============================================================================
# Confluent Platform on Minikube - Quickstart Makefile
# Deploys CP Core Components using Confluent for Kubernetes (CFK) in KRaft mode
# ==============================================================================

TUTORIAL_HOME ?= https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart
NAMESPACE      ?= confluent
MINIKUBE_CPUS  ?= 6
MINIKUBE_MEM   ?= 20480
MINIKUBE_DISK  ?= 50g
C3_PORT        ?= 9021

.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "  Confluent Platform on Minikube — Quickstart"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ------------------------------------------------------------------------------
# Phase 1: Prerequisites (macOS)
# ------------------------------------------------------------------------------
.PHONY: install-prereqs
install-prereqs: ## Install Docker Desktop, kubectl, and Minikube via Homebrew
	@echo "→ Installing Docker Desktop..."
	brew install --cask docker
	@echo "→ Installing kubectl..."
	brew install kubectl
	@echo "→ Installing Minikube..."
	brew install minikube || brew link --overwrite minikube
	@echo "✔ Prerequisites installed. Launch Docker Desktop before running 'make minikube-start'."

.PHONY: check-prereqs
check-prereqs: ## Verify required tools are available
	@echo "→ Checking prerequisites..."
	@command -v docker    >/dev/null 2>&1 || (echo "✘ docker not found"    && exit 1)
	@command -v kubectl   >/dev/null 2>&1 || (echo "✘ kubectl not found"   && exit 1)
	@command -v minikube  >/dev/null 2>&1 || (echo "✘ minikube not found"  && exit 1)
	@command -v helm      >/dev/null 2>&1 || (echo "✘ helm not found"      && exit 1)
	@echo "✔ All prerequisites found."

# ------------------------------------------------------------------------------
# Phase 2: Minikube cluster
# ------------------------------------------------------------------------------
.PHONY: minikube-start
minikube-start: ## Start Minikube with resources required for Confluent Platform
	@echo "→ Starting Minikube (cpus=$(MINIKUBE_CPUS), memory=$(MINIKUBE_MEM), disk=$(MINIKUBE_DISK))..."
	minikube start \
		--driver=docker \
		--cpus=$(MINIKUBE_CPUS) \
		--memory=$(MINIKUBE_MEM) \
		--disk-size=$(MINIKUBE_DISK)

.PHONY: minikube-status
minikube-status: ## Check Minikube and cluster node status
	minikube status
	kubectl get nodes

.PHONY: minikube-stop
minikube-stop: ## Stop the Minikube cluster
	minikube stop

.PHONY: minikube-delete
minikube-delete: ## Completely delete the Minikube cluster
	minikube delete

# ------------------------------------------------------------------------------
# Phase 3: Confluent Operator (CFK)
# ------------------------------------------------------------------------------
.PHONY: namespace
namespace: ## Create the 'confluent' namespace and set it as the default context
	@echo "→ Creating namespace '$(NAMESPACE)'..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl config set-context --current --namespace=$(NAMESPACE)
	@echo "✔ Namespace '$(NAMESPACE)' is active."

.PHONY: operator-install
operator-install: namespace ## Add the Confluent Helm repo and install the CFK Operator
	@echo "→ Adding Confluent Helm repo..."
	helm repo add confluentinc https://packages.confluent.io/helm
	helm repo update
	@echo "→ Installing Confluent Operator..."
	helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes \
		--namespace $(NAMESPACE)
	@echo "✔ Confluent Operator installed."

.PHONY: operator-status
operator-status: ## Verify the Confluent Operator pod is running
	kubectl get pods -n $(NAMESPACE)

.PHONY: operator-uninstall
operator-uninstall: ## Uninstall the Confluent Operator Helm release
	helm uninstall confluent-operator -n $(NAMESPACE)

# ------------------------------------------------------------------------------
# Phase 4: Deploy Confluent Platform (KRaft mode)
# ------------------------------------------------------------------------------
.PHONY: platform-deploy
platform-deploy: ## Deploy all CP components (Kafka KRaft, Schema Registry, Connect, ksqlDB, REST Proxy, C3)
	@echo "→ Applying Confluent Platform manifest from:"
	@echo "    $(TUTORIAL_HOME)/confluent-platform-c3++.yaml"
	kubectl apply -f $(TUTORIAL_HOME)/confluent-platform-c3++.yaml
	@echo "✔ Manifest applied. Run 'make platform-watch' to follow pod startup."

.PHONY: platform-watch
platform-watch: ## Watch pods come up in the confluent namespace (Ctrl+C to exit)
	kubectl get pods -n $(NAMESPACE) -w

.PHONY: platform-status
platform-status: ## Show current pod status for all CP components
	kubectl get pods -n $(NAMESPACE)

.PHONY: platform-delete
platform-delete: ## Remove all CP components deployed via the manifest
	kubectl delete -f $(TUTORIAL_HOME)/confluent-platform-c3++.yaml

# ------------------------------------------------------------------------------
# Phase 5: Control Center access
# ------------------------------------------------------------------------------
.PHONY: c3-open
c3-open: ## Port-forward Control Center and open it in your browser
	@echo "→ Forwarding Control Center to http://localhost:$(C3_PORT)"
	@echo "   Press Ctrl+C to stop."
	@(sleep 2 && open http://localhost:$(C3_PORT)) &
	kubectl port-forward -n $(NAMESPACE) controlcenter-0 $(C3_PORT):$(C3_PORT)

# ------------------------------------------------------------------------------
# Composite workflows
# ------------------------------------------------------------------------------
.PHONY: up
up: check-prereqs minikube-start operator-install platform-deploy ## Full stack: start Minikube → install Operator → deploy CP
	@echo ""
	@echo "✔ Confluent Platform is deploying."
	@echo "  Run 'make platform-watch' to monitor pod startup."
	@echo "  Once all pods are Running, run 'make c3-open' to access Control Center."

.PHONY: down
down: platform-delete operator-uninstall ## Tear down CP and Operator (keeps Minikube running)
	@echo "✔ Confluent Platform and Operator removed."

.PHONY: teardown
teardown: down ## Full teardown: remove CP, Operator, namespace, and stop Minikube
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	$(MAKE) minikube-stop
	@echo "✔ Full teardown complete."
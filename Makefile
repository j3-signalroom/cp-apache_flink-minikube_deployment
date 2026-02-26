# ==============================================================================
# Confluent Platform on Minikube - Quickstart Makefile
# Deploys CP Core Components using Confluent for Kubernetes (CFK) in KRaft mode
# + Apache Flink 2.2 via Flink Kubernetes Operator 1.14
# + Kafka UI via Provectus Helm chart
# ==============================================================================

TUTORIAL_HOME        ?= https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart
NAMESPACE             ?= confluent
MINIKUBE_CPUS         ?= 6
MINIKUBE_MEM          ?= 20480
MINIKUBE_DISK         ?= 50g
C3_PORT               ?= 9021
FLINK_OPERATOR_VER    ?= 1.14.0
FLINK_IMAGE           ?= flink:2.2
FLINK_VERSION         ?= v2_2
FLINK_CLUSTER_NAME    ?= flink-basic
FLINK_UI_PORT         ?= 8081
KAFKA_UI_PORT         ?= 8080
FLINK_MANIFEST        ?= k8s/base/flink-basic-deployment.yaml

.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "  Confluent Platform + Apache Flink on Minikube — Quickstart"
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
minikube-start: ## Start Minikube with resources required for Confluent Platform + Flink
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
operator-uninstall: ## Uninstall the Confluent Operator Helm release (safe to run even if not installed)
	@helm uninstall confluent-operator -n $(NAMESPACE) 2>/dev/null || echo "→ confluent-operator not installed, skipping."

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
platform-delete: ## Remove all CP components deployed via the manifest (safe to run even if not deployed)
	@kubectl delete -f $(TUTORIAL_HOME)/confluent-platform-c3++.yaml 2>/dev/null || echo "→ CP components not found, skipping."

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
# Phase 6: Apache Flink
# ------------------------------------------------------------------------------
.PHONY: flink-cert-manager
flink-cert-manager: ## Install cert-manager (required by Flink Kubernetes Operator)
	@echo "→ Installing cert-manager..."
	kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml
	@echo "→ Waiting for cert-manager pods to be ready..."
	kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=120s
	kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=120s
	kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=120s
	@echo "✔ cert-manager is ready."

.PHONY: flink-operator-install
flink-operator-install: ## Install the Flink Kubernetes Operator $(FLINK_OPERATOR_VER)
	@echo "→ Adding Flink Operator Helm repo (v$(FLINK_OPERATOR_VER))..."
	helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-$(FLINK_OPERATOR_VER)/
	helm repo update
	@echo "→ Installing Flink Kubernetes Operator..."
	helm upgrade --install flink-kubernetes-operator flink-operator-repo/flink-kubernetes-operator \
		--namespace $(NAMESPACE) \
		--set webhook.create=false
	@echo "✔ Flink Kubernetes Operator $(FLINK_OPERATOR_VER) installed."

.PHONY: flink-operator-status
flink-operator-status: ## Check Flink operator pod status
	kubectl get pods -n $(NAMESPACE) | grep flink

.PHONY: flink-operator-uninstall
flink-operator-uninstall: ## Uninstall the Flink Kubernetes Operator (safe to run even if not installed)
	@helm uninstall flink-kubernetes-operator -n $(NAMESPACE) 2>/dev/null || echo "→ flink-kubernetes-operator not installed, skipping."

.PHONY: flink-deploy
flink-deploy: ## Deploy a Flink session cluster using $(FLINK_MANIFEST) (image=$(FLINK_IMAGE), version=$(FLINK_VERSION))
	@echo "→ Deploying Flink session cluster from $(FLINK_MANIFEST) (image=$(FLINK_IMAGE), flinkVersion=$(FLINK_VERSION))..."
	@test -f $(FLINK_MANIFEST) || (echo "✘ $(FLINK_MANIFEST) not found. Is it alongside the Makefile?" && exit 1)
	@command -v envsubst >/dev/null 2>&1 || (echo "✘ envsubst not found. Install gettext: brew install gettext" && exit 1)
	FLINK_IMAGE=$(FLINK_IMAGE) FLINK_VERSION=$(FLINK_VERSION) \
		envsubst '$$FLINK_IMAGE $$FLINK_VERSION' < $(FLINK_MANIFEST) | kubectl apply -f -
	@echo "✔ Flink cluster deployed (image=$(FLINK_IMAGE), flinkVersion=$(FLINK_VERSION))."

.PHONY: flink-status
flink-status: ## Show status of all Flink pods and FlinkDeployment CRs
	@echo "--- Pods ---"
	kubectl get pods -n $(NAMESPACE) | grep flink
	@echo ""
	@echo "--- FlinkDeployments ---"
	kubectl get flinkdeployment -n $(NAMESPACE)

.PHONY: flink-ui
flink-ui: ## Port-forward the Flink UI and open it in your browser
	@echo "→ Forwarding Flink UI to http://localhost:$(FLINK_UI_PORT)"
	@echo "   Press Ctrl+C to stop."
	@FLINK_POD=$$(kubectl get pods -n $(NAMESPACE) -l component=jobmanager --no-headers -o custom-columns=":metadata.name" | head -1); \
	if [ -z "$$FLINK_POD" ]; then \
		echo "✘ No Flink JobManager pod found. Is the cluster deployed?"; exit 1; \
	fi; \
	echo "   Forwarding from pod: $$FLINK_POD"; \
	(sleep 2 && open http://localhost:$(FLINK_UI_PORT)) & \
	kubectl port-forward -n $(NAMESPACE) $$FLINK_POD $(FLINK_UI_PORT):$(FLINK_UI_PORT)

.PHONY: flink-delete
flink-delete: ## Delete the Flink session cluster (safe to run even if not deployed)
	@kubectl delete flinkdeployment $(FLINK_CLUSTER_NAME) -n $(NAMESPACE) --ignore-not-found=true
	@echo "✔ Flink cluster '$(FLINK_CLUSTER_NAME)' deleted."

# ------------------------------------------------------------------------------
# Phase 7: Kafka UI (Provectus)
# ------------------------------------------------------------------------------
.PHONY: kafka-ui-install
kafka-ui-install: ## Install Kafka UI and connect it to the Confluent Kafka cluster
	@echo "→ Adding Kafka UI Helm repo..."
	helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts
	helm repo update
	@echo "→ Installing Kafka UI..."
	helm upgrade --install kafka-ui kafka-ui/kafka-ui \
		--namespace $(NAMESPACE) \
		--set yamlApplicationConfig.kafka.clusters[0].name="confluent" \
		--set yamlApplicationConfig.kafka.clusters[0].bootstrapServers="kafka:9092" \
		--set yamlApplicationConfig.kafka.clusters[0].schemaRegistry="http://schemaregistry:8081" \
		--set yamlApplicationConfig.kafka.clusters[0].kafkaConnect[0].name="connect" \
		--set yamlApplicationConfig.kafka.clusters[0].kafkaConnect[0].address="http://connect:8083" \
		--set yamlApplicationConfig.auth.type="DISABLED" \
		--set yamlApplicationConfig.management.health.ldap.enabled="false"
	@echo "✔ Kafka UI installed."

.PHONY: kafka-ui-status
kafka-ui-status: ## Check Kafka UI pod status
	kubectl get pods -n $(NAMESPACE) | grep kafka-ui

.PHONY: kafka-ui-open
kafka-ui-open: ## Port-forward Kafka UI and open it in your browser
	@echo "→ Forwarding Kafka UI to http://localhost:$(KAFKA_UI_PORT)"
	@echo "   Press Ctrl+C to stop."
	@(sleep 2 && open http://localhost:$(KAFKA_UI_PORT)) &
	kubectl port-forward -n $(NAMESPACE) svc/kafka-ui $(KAFKA_UI_PORT):80

.PHONY: kafka-ui-uninstall
kafka-ui-uninstall: ## Uninstall Kafka UI (safe to run even if not installed)
	@helm uninstall kafka-ui -n $(NAMESPACE) 2>/dev/null || echo "→ kafka-ui not installed, skipping."
	@echo "✔ Kafka UI removed."

# ------------------------------------------------------------------------------
# Composite workflows
# ------------------------------------------------------------------------------
.PHONY: up
up: check-prereqs minikube-start cp-core-up kafka-ui-install ## Full stack: Minikube → cp-core-up → kafka-ui (run 'make flink-up' separately for Flink)
	@echo ""
	@echo "✔ Confluent Platform and Kafka UI are deploying."
	@echo "  Run 'make platform-watch' to monitor pod startup."
	@echo "  Run 'make flink-up' to also deploy Apache Flink."

.PHONY: cp-core-up
cp-core-up: operator-install platform-deploy ## Phases 3-5: install CFK Operator → deploy CP → access Control Center
	@echo ""
	@echo "✔ Confluent Platform is deploying."
	@echo "  Run 'make platform-watch' to monitor pod startup."
	@echo "  Once all pods are Running, run 'make c3-open' to access Control Center."

.PHONY: flink-up
flink-up: flink-cert-manager flink-operator-install flink-deploy ## Install cert-manager → Flink Operator → deploy Flink cluster
	@echo ""
	@echo "✔ Flink is deploying."
	@echo "  Run 'make flink-status' to check pod status."
	@echo "  Once running, open the Flink UI with 'make flink-ui'."

.PHONY: down
down: kafka-ui-uninstall platform-delete operator-uninstall ## Tear down Kafka UI, CP and Operator (keeps Minikube running)
	@echo "✔ Confluent Platform, Kafka UI and Operator removed."

.PHONY: flink-down
flink-down: flink-delete flink-operator-uninstall ## Tear down Flink cluster and operator
	@echo "✔ Flink cluster and operator removed."

.PHONY: teardown
teardown: flink-down down ## Full teardown: remove Flink, Kafka UI, CP, Operator, namespace, and stop Minikube
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	$(MAKE) minikube-stop
	@echo "✔ Full teardown complete."
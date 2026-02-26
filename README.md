# Confluent Platform and Apache Flink on Minikube

A Makefile-driven quickstart that deploys a full local streaming stack on Minikube:

- **Confluent Platform** (KRaft mode) via Confluent for Kubernetes (CFK)
- **Apache Flink 2.2** via the Flink Kubernetes Operator
- **Kafka UI** (Provectus) for cluster inspection

---

**Table of Contents**
<!-- toc -->
+ [**1.0 Prerequisites**](#10-prerequisites)
+ [**2.0 Resource Requirements**](#20-resource-requirements)
+ [**3.0 Quickstart**](#30-quickstart)
    - [**3.1 Full stack (CP + Kafka UI)**](#31-full-stack-cp--kafka-ui)
    - [**3.2 Add Apache Flink (run separately after `make up`)**](#32-add-apache-flink-run-separately-after-make-up)
+ [**4.0 Composite Workflow Reference**](#40-composite-workflow-reference)
+ [**5.0 Individual Target Reference**](#50-individual-target-reference)
    - [**5.1 Phase 1 — Prerequisites**](#51-phase-1--prerequisites)
    - [**5.2 Phase 2 — Minikube**](#52-phase-2—-minikube)
    - [**5.3 Phase 3 — Confluent Operator**](#53-phase-3--confluent-operator)
    - [**5.4 Phase 4 — Confluent Platform**](#54-phase-4--confluent-platform)
    - [**5.5 Phase 5 — Control Center**](#55-phase-5--control-center)
    - [**5.6 Phase 6 — Apache Flink**](#56-phase-6-—apache-flink)
    - [**5.7 Phase 7 — Kafka UI**](#57-phase-7--kafka-ui)
+ [**6.0 Configuration**](#60-configuration)
+ [**7.0 Repository Layout**](#70-repository-layout)
+ [**8.0 Teardown**](#80-teardown)
+ [**9.0 Manual Deployment Instructions**](#90-manual-deployment-instructions)
<!-- tocstop -->

---

## **1.0 Prerequisites**

macOS with Homebrew. To install all required tools in one step:

```bash
make install-prereqs
```

This installs Docker Desktop, `kubectl`, and Minikube via Homebrew. Once complete, **launch Docker Desktop** before proceeding.

To verify all tools are present without installing:

```bash
make check-prereqs
```

Required: `docker`, `kubectl`, `minikube`, `helm`, `envsubst` (`brew install gettext`).

---

## **2.0 Resource Requirements**

Minikube is configured with the following defaults, which are required to run the full stack:

| Resource | Default |
|----------|---------|
| CPUs | 6 |
| Memory | 20 GB |
| Disk | 50 GB |

Override any of these at the command line:

```bash
make up MINIKUBE_CPUS=8 MINIKUBE_MEM=24576
```

---

## **3.0 Quickstart**

### **3.1 Full stack (CP + Kafka UI)**

```bash
make up
```

This runs: `check-prereqs` → `minikube-start` → `namespace` → `operator-install` → `platform-deploy` → `kafka-ui-install`.

Once pods are up, open Control Center:

```bash
make c3-open        # http://localhost:9021
```

### **3.2 Add Apache Flink (run separately after `make up`)**

```bash
make flink-up
```

This runs: `namespace` → `flink-cert-manager` → `flink-operator-install` → `flink-deploy`. `flink-up` is self-contained and can also be run standalone on a fresh cluster.

Once the Flink JobManager pod is running:

```bash
make flink-ui       # http://localhost:8081
```

---

## **4.0 Composite Workflow Reference**

| Target | What it does |
|--------|-------------|
| `make up` | Full stack: Minikube + CP + Kafka UI |
| `make flink-up` | cert-manager + Flink Operator + Flink cluster |
| `make down` | Remove CP, Kafka UI, and Operator (Minikube keeps running) |
| `make flink-down` | Remove Flink cluster, Operator, and cert-manager |
| `make teardown` | Full teardown: everything + stop Minikube |

---

## **5.0 Individual Target Reference**

### **5.1 Phase 1 — Prerequisites**

| Target | Description |
|--------|-------------|
| `install-prereqs` | Install Docker Desktop, kubectl, Minikube via Homebrew |
| `check-prereqs` | Verify all required tools are available |

### **5.2 Phase 2 — Minikube**

| Target | Description |
|--------|-------------|
| `minikube-start` | Start Minikube with configured resources |
| `minikube-status` | Show Minikube and node status |
| `minikube-stop` | Stop the Minikube cluster |
| `minikube-delete` | Permanently delete the Minikube cluster |

### **5.3 Phase 3 — Confluent Operator**

| Target | Description |
|--------|-------------|
| `namespace` | Create the `confluent` namespace and set it as default context |
| `operator-install` | Add Confluent Helm repo and install CFK Operator |
| `operator-status` | Show CFK Operator pod status |
| `operator-uninstall` | Remove the CFK Operator Helm release |

### **5.4 Phase 4 — Confluent Platform**

| Target | Description |
|--------|-------------|
| `platform-deploy` | Deploy Kafka (KRaft), Schema Registry, Connect, ksqlDB, REST Proxy, Control Center |
| `platform-watch` | Watch pod startup live (Ctrl+C to exit) |
| `platform-status` | Show current pod status |
| `platform-delete` | Remove all CP components |

### **5.5 Phase 5 — Control Center**

| Target | Description |
|--------|-------------|
| `c3-open` | Port-forward Control Center and open `http://localhost:9021` |

### **5.6 Phase 6 — Apache Flink**

| Target | Description |
|--------|-------------|
| `flink-cert-manager` | Install cert-manager (Flink Operator dependency) |
| `flink-operator-install` | Install the Flink Kubernetes Operator |
| `flink-operator-status` | Show Flink Operator pod status |
| `flink-operator-uninstall` | Remove the Flink Operator Helm release |
| `flink-deploy` | Deploy the Flink session cluster |
| `flink-status` | Show Flink pods and FlinkDeployment CRs |
| `flink-ui` | Port-forward Flink UI and open `http://localhost:8081` |
| `flink-delete` | Delete the Flink session cluster |
| `cert-manager-uninstall` | Remove cert-manager |

### **5.7 Phase 7 — Kafka UI**

| Target | Description |
|--------|-------------|
| `kafka-ui-install` | Install Kafka UI connected to the local CP cluster |
| `kafka-ui-status` | Show Kafka UI pod status |
| `kafka-ui-open` | Port-forward Kafka UI and open `http://localhost:8080` |
| `kafka-ui-uninstall` | Remove Kafka UI |

---

## **6.0 Configuration**

All variables are overridable at the command line. Defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `NAMESPACE` | `confluent` | Kubernetes namespace |
| `MINIKUBE_CPUS` | `6` | vCPUs allocated to Minikube |
| `MINIKUBE_MEM` | `20480` | Memory in MB |
| `MINIKUBE_DISK` | `50g` | Disk size |
| `FLINK_OPERATOR_VER` | `1.14.0` | Flink Kubernetes Operator version |
| `FLINK_IMAGE` | `flink:2.2` | Flink container image |
| `FLINK_VERSION` | `v2_2` | Flink API version string for the FlinkDeployment CR |
| `FLINK_CLUSTER_NAME` | `flink-basic` | Name of the FlinkDeployment resource |
| `FLINK_MANIFEST` | `k8s/base/flink-basic-deployment.yaml` | Path to FlinkDeployment template |
| `CERT_MANAGER_VER` | `v1.17.1` | cert-manager version |
| `C3_PORT` | `9021` | Control Center local port |
| `FLINK_UI_PORT` | `8081` | Flink UI local port |
| `KAFKA_UI_PORT` | `8080` | Kafka UI local port |

Example — deploy Flink 2.1 instead of 2.2:

```bash
make flink-deploy FLINK_IMAGE=flink:2.1 FLINK_VERSION=v2_1
```

---

## **7.0 Repository Layout**

```
.
├── Makefile
├── README.md
├── README.pdf
├── CHANGELOG.md
├── CHANGELOG.pdf
├── KNOWN_ISSUES.md
├── KNOWN_ISSUES.pdf
├── .gitignore
└── docs
    └── manual_deployment.md   # Step-by-step manual deployment instructions (without Makefile)
    └── manual_deployment.pdf  # Step-by-step manual deployment instructions (without Makefile)
└── k8s/
    └── base/
        └── flink-basic-deployment.yaml   # FlinkDeployment CR template
```

The `flink-basic-deployment.yaml` is a template — `FLINK_IMAGE` and `FLINK_VERSION` are substituted at deploy time via `envsubst`. Do not apply it directly with `kubectl apply`.

---

## **8.0 Teardown**

Remove everything and stop Minikube:

```bash
make teardown
```

To keep Minikube running but remove all deployed components:

```bash
make flink-down   # Flink cluster + operator + cert-manager
make down         # CP + Kafka UI + CFK Operator
```

## **9.0 Manual Deployment Instructions**
For users who want to understand the underlying steps without using the Makefile, see [docs/manual_deployment.md](docs/manual_deployment.md).
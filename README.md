# Minikube Confluent Platform Local Deployment
This repo provides a Makefile-driven workflow to deploy Confluent Platform on a local Minikube cluster. It includes commands for setting up prerequisites, managing the Minikube cluster, installing the Confluent Kubernetes Operator, deploying CP components, and optionally deploying a Flink session cluster with the Flink Kubernetes Operator.

### Commands

| Command | Phase | Description |
|---|---|---|
| `make help` | — | Show all available commands |
| `make install-prereqs` | 1 | Install Docker Desktop, kubectl, and Minikube via Homebrew |
| `make check-prereqs` | 1 | Verify docker, kubectl, minikube, and helm are available |
| `make minikube-start` | 2 | Start Minikube with configured CPUs, memory, and disk |
| `make minikube-status` | 2 | Check Minikube and cluster node status |
| `make minikube-stop` | 2 | Stop the Minikube cluster |
| `make minikube-delete` | 2 | Completely delete the Minikube cluster |
| `make namespace` | 3 | Create the `confluent` namespace and set as default context |
| `make operator-install` | 3 | Add Confluent Helm repo and install the CFK operator |
| `make operator-status` | 3 | Verify the CFK operator pod is running |
| `make operator-uninstall` | 3 | Uninstall the CFK operator Helm release |
| `make platform-deploy` | 4 | Deploy all CP components via KRaft quickstart manifest |
| `make platform-watch` | 4 | Watch pods come up in the confluent namespace |
| `make platform-status` | 4 | Show current pod status for all CP components |
| `make platform-delete` | 4 | Remove all CP components |
| `make c3-open` | 5 | Port-forward Control Center and open in browser |
| `make flink-cert-manager` | 6 | Install cert-manager (Flink prerequisite) |
| `make flink-operator-install` | 6 | Install the Flink Kubernetes Operator |
| `make flink-operator-status` | 6 | Check Flink operator pod status |
| `make flink-operator-uninstall` | 6 | Uninstall the Flink Kubernetes Operator |
| `make flink-deploy` | 6 | Deploy a Flink session cluster |
| `make flink-status` | 6 | Show Flink pods and FlinkDeployment CRs |
| `make flink-ui` | 6 | Port-forward Flink UI and open in browser |
| `make flink-delete` | 6 | Delete the Flink session cluster |
| `make kafka-ui-install` | 7 | Add Provectus Helm repo and install Kafka UI pre-wired to Confluent |
| `make kafka-ui-status` | 7 | Check Kafka UI pod status |
| `make kafka-ui-open` | 7 | Port-forward Kafka UI and open in browser |
| `make kafka-ui-uninstall` | 7 | Uninstall Kafka UI |
| `make up` | Composite | check-prereqs → minikube-start → cp-core-up |
| `make cp-core-up` | Composite | Phases 3–5: CFK operator → CP deploy |
| `make flink-up` | Composite | cert-manager → Flink operator → Flink cluster |
| `make down` | Composite | Tear down Kafka UI, CP, and operator (keeps Minikube running) |
| `make flink-down` | Composite | Tear down Flink cluster and operator |
| `make teardown` | Composite | Full teardown: Flink + Kafka UI + CP + namespace + stop Minikube |

---

### Variables

| Variable | Default | Description |
|---|---|---|
| `TUTORIAL_HOME` | Confluent GitHub raw URL | Base URL for CP quickstart manifest files |
| `NAMESPACE` | `confluent` | Kubernetes namespace for all components |
| `MINIKUBE_CPUS` | `6` | CPUs allocated to Minikube |
| `MINIKUBE_MEM` | `20480` | Memory (MB) allocated to Minikube |
| `MINIKUBE_DISK` | `50g` | Disk size allocated to Minikube |
| `C3_PORT` | `9021` | Local port for Control Center port-forward |
| `FLINK_OPERATOR_VER` | `1.14.0` | Flink Kubernetes Operator version |
| `FLINK_IMAGE` | `flink:2.2` | Flink Docker image for the session cluster |
| `FLINK_VERSION` | `v2_2` | Flink version string used in the FlinkDeployment CR |
| `FLINK_CLUSTER_NAME` | `flink-basic` | Name of the deployed FlinkDeployment CR |
| `FLINK_UI_PORT` | `8081` | Local port for Flink UI port-forward |
| `KAFKA_UI_PORT` | `8080` | Local port for Kafka UI port-forward |

Variables can be overridden at runtime, e.g. `make kafka-ui-open KAFKA_UI_PORT=9090`.
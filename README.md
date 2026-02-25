# Minikube for Confluent Platform Core Components Makefile

The Makefile maps every section of the [tutorial](manual_deployment.md) to a clean, composable target. Here's a quick overview of the key workflows:

**All-in-one commands:**
- `make up` — full stack: checks prereqs → starts Minikube → installs CFK Operator → deploys all CP components
- `make down` — removes CP and the Operator (leaves Minikube running)
- `make teardown` — full teardown including namespace deletion and Minikube stop

**Granular targets** (for when your dev is stepping through manually):
- `make install-prereqs` / `make check-prereqs`
- `make minikube-start` / `make minikube-status`
- `make operator-install` / `make operator-status`
- `make platform-deploy` / `make platform-watch` / `make platform-status`
- `make c3-open` — port-forwards Control Center and opens it in the browser automatically

`make help` prints the full target list with descriptions at any time. The key variables (`NAMESPACE`, `MINIKUBE_CPUS`, `MINIKUBE_MEM`, etc.) are all overridable at the command line if a dev needs different resource allocations:

| Variable         | Description           |
| ---------------- | --------------------- |
| `NAMESPACE`      | Kubernetes namespace  |
| `MINIKUBE_CPUS`  | CPU allocation        |
| `MINIKUBE_MEM`   | Memory allocation     |
| `KAFKA_REPLICAS` | Kafka broker replicas |
| `STORAGE_CLASS`  | Storage class         |

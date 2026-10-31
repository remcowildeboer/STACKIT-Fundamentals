# Prometheus Operator CRDs

Docs: https://prometheus-operator.dev/docs/getting-started/introduction/
Github Repo: https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm upgrade \
  --install \
  prometheus-operator-crds prometheus-community/prometheus-operator-crds \
  --namespace o11y \
  --create-namespace \
  --version 26.0.0 \
  --values values.yaml
```

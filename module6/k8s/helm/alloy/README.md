# Grafana Alloy

Docs: https://grafana.com/docs/alloy/latest/
Github Repo: https://github.com/grafana/alloy

```shell
cp values.yaml.example values.yaml
helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm upgrade \
  --install \
  alloy grafana/alloy \
  --namespace o11y \
  --create-namespace \
  --version 1.5.2 \
  --values values.yaml
```

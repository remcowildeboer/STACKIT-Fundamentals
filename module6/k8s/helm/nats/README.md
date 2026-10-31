# NATS

Docs: https://docs.nats.io/
Github Repo: https://github.com/nats-io/k8s

```sh
helm repo add nats https://nats-io.github.io/k8s/helm/charts/ --force-update
helm upgrade \
  --install \
  nats nats/nats \
  --namespace nats \
  --create-namespace \
  --version 2.12.3 \
  --values values.yaml
```

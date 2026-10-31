# cert-manager

Docs: https://cert-manager.io/docs/
Github Repo: https://github.com/cert-manager/cert-manager

```sh
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade \
  --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.2 \
  --values values.yaml
```

Install [ClusterIssuer](https://cert-manager.io/docs/concepts/issuer/) for [Let's Encrypt](https://letsencrypt.org/)

```sh
kubectl apply -f clusterissuer-letsencrypt-production.yaml
```

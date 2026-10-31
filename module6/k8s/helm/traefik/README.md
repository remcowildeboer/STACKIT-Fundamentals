# traefik

Docs: https://doc.traefik.io/traefik/setup/kubernetes/
Github Repo: https://github.com/traefik/traefik/

```sh
helm repo add traefik https://traefik.github.io/charts/ --force-update
helm upgrade \
  traefik traefik/traefik \
  --install \
  --namespace traefik \
  --create-namespace \
  --version 38.0.2 \
  --values values.yaml
```

# Hands-on Practice: STACKIT Git, Pipelines & Container Registry

Notes and instructions for the STACKIT University hands-on exercise (Parts 1–4).

- **Repository:** `handson-developer-tool`
- **Go module name:** `my-app` (independent of the repository name; changing it is optional)
- **Image name:** `my-app` (independent of the repository name)

STACKIT Git is based on **Forgejo** (a fork of Gitea). STACKIT Pipelines use **Forgejo Actions**, which are largely compatible with GitHub Actions but not identical.

---

## Part 1: Set Up STACKIT Git Repository

### Create the Git instance
1. In the STACKIT Portal, open your project and go to **Developer Platform → Git**.
2. Create a new instance, choose a name, and pick the smallest flavor (enough for this exercise).
3. Wait until the status is **Running/Active** (takes a few minutes).

### Access the web interface
Open the instance details and click its URL. Sign in or set up the initial admin account.

### Create the repository
- Click **+** → **New Repository**, name it (here: `handson-developer-tool`), set it to **Private**.
- Tick **Initialize repository** (add a README) so the `main` branch exists immediately.

### Branch protection
**Repository → Settings → Branches → Add new rule**, branch pattern `main`:
- Disable/restrict direct pushes
- Require approvals and/or status checks (optional for this exercise)

> Branch protection blocks direct pushes to `main`. Work through feature branches and Pull Requests, or do the initial push before enabling protection.

```bash
git checkout -b feature/initial-code
git push -u origin feature/initial-code
# then open a Pull Request to main in the web UI and merge it
```

### Authentication

**SSH (recommended)**
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub
```
Add the public key under **avatar → Settings → SSH / GPG Keys → Add Key**, then test:
```bash
ssh -T git@<your-instance-host>
```

**HTTPS**
Use an access token instead of your password: **Settings → Applications → Generate New Token** (repository read/write).

### Verify
```bash
git clone git@<your-instance-host>:<username>/handson-developer-tool.git
```

---

## Part 2: Push Your Application Code

```bash
git clone git@<your-instance-host>:<username>/handson-developer-tool.git
cd handson-developer-tool
git checkout -b feature/initial-app
```

### `main.go`
```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello World from STACKIT!")
	})
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	log.Printf("Listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
```

### `go.mod`
```
module my-app

go 1.22
```

**What does `module my-app` mean?** It declares the module path: the name of the Go module. It serves as the import prefix for your own subpackages (e.g. `import "my-app/handlers"`) and marks the project root. It is just a chosen name: it does not need to match the repository name, the image name, or the binary name (which comes from `-o /app` in the Dockerfile). The `go 1.22` line sets the minimum Go version and should match or be lower than the version in the Dockerfile.

### `Dockerfile` (multi-stage)
```dockerfile
# Stage 1: build
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app

# Stage 2: minimal runtime
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /app /app
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

Why this setup:
- Only the compiled binary ends up in the final image (no Go toolchain, no source code).
- Distroless has no shell or package manager, so the attack surface is small.
- Runs as a non-root user.
- `CGO_ENABLED=0` produces a static binary that needs no system libraries.

### `.dockerignore`
```
.git
*.md
Dockerfile
```

### Test locally (optional)
```bash
docker build -t my-app:local .
docker run --rm -p 8080:8080 my-app:local
curl http://localhost:8080          # Hello World from STACKIT!
curl http://localhost:8080/healthz  # ok
docker images my-app                # ~5–10 MB
```

### Commit and push
```bash
git add main.go go.mod Dockerfile .dockerignore
git commit -m "Add Go hello-world web server with multi-stage Dockerfile"
git push -u origin feature/initial-app
```
Open a Pull Request to `main` and merge it. Verify the files appear in the web UI and the Dockerfile has two `FROM` lines.

---

## Part 3: Configure CI/CD Workflow

### Workflow location
Workflows live in `.forgejo/workflows/`. Make sure **Enable Repository Actions** is checked in the repository settings.

### Runners
Pipelines need a runner. Options:

**A. STACKIT managed runners (fee-based)**
According to the STACKIT docs: Portal → Project → **Developer Platform → Git** → select your instance → **Continuous integration & Runners** → **Edit** → set **Enable Runners** to **On** → save and click **Order fee-based**.

Available labels include:

| Label | Base | Notes |
|---|---|---|
| `stackit-docker` | Ubuntu 22.04 (ACT) | Docker, Node.js, Python, Git, build-essential: **use this for image builds** |
| `stackit-ubuntu-20` | Ubuntu 20.04 | Broad GitHub Actions compatibility |
| `stackit-ubuntu-22` | Ubuntu 22.04 | Standard Ubuntu |
| `stackit-alpine` / `stackit-alpine-bash` | Alpine | Lightweight |
| `stackit-busybox` | BusyBox | Minimal |
| `stackit-coretto-21` | Amazon Corretto 21 | Java |

Managed runners are ephemeral and scale with queued jobs, so they may show as "offline" when idle.

Reference: https://docs.stackit.cloud/products/developer-platform/git/getting-started/pipeline-runners/

**B. Custom runner on your own machine (workaround)**
1. Download the `forgejo-runner` binary from the Forgejo releases.
2. In the repository: **Settings → Actions → Runners → Create new Runner** to get a registration token.
3. Register and start:
```bash
./forgejo-runner register \
  --instance https://<your-git-instance-url> \
  --token <YOUR_TOKEN> \
  --name my-laptop-runner \
  --labels local-docker:host

./forgejo-runner daemon
```
4. Use `runs-on: local-docker` in the workflow. With `:host` mode, jobs run directly on your machine, so Docker must be installed and running, and jobs only run while the daemon is active.

Reference: https://docs.stackit.cloud/products/developer-platform/git/how-tos/pipelines-custom-runner

### `.forgejo/workflows/build.yaml` (build only)
```yaml
name: Build container image

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    name: Build Docker image
    runs-on: stackit-docker   # or your custom runner label
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Show Docker version
        run: docker version

      - name: Build image
        run: |
          docker build -t my-app:${{ github.sha }} .

      - name: List image
        run: docker images my-app
```

Push it through a feature branch and PR; then watch the **Actions** tab.

---

## Part 4: Publish to Container Registry

STACKIT Container Registry is Harbor-based. A "namespace" corresponds to a Harbor **project**.

### Namespace and credentials
1. In the Portal, open **Container Registry** and create a namespace (e.g. `my-app-training`). Note the registry host (usually `registry.onstackit.cloud`).
2. In the registry UI, select the project → **Robot Accounts → New Robot Account** with **Push** and **Pull** permissions. Copy the name (`robot$<namespace>+<name>`) and secret immediately; the secret is shown only once.

### Repository secrets
**Repository → Settings → Actions → Secrets**:

| Name | Value |
|---|---|
| `REGISTRY_URL` | `registry.onstackit.cloud` |
| `REGISTRY_USERNAME` | `robot$my-app-training+ci-pipeline` |
| `REGISTRY_PASSWORD` | robot account secret |

Secret names may not start with `GITHUB_`, `GITEA_`, or `FORGEJO_`. **Never put credentials in the workflow file.**

### `.forgejo/workflows/build.yaml` (build and push)
```yaml
name: Build and publish container image

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

env:
  NAMESPACE: my-app-training
  IMAGE_NAME: my-app

jobs:
  build:
    name: Build and push
    runs-on: stackit-docker   # or your custom runner label
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set image reference
        run: |
          echo "IMAGE=${{ secrets.REGISTRY_URL }}/${NAMESPACE}/${IMAGE_NAME}" >> "$GITHUB_ENV"
          echo "SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-8)" >> "$GITHUB_ENV"

      - name: Build image
        run: |
          docker build \
            -t "${IMAGE}:${SHORT_SHA}" \
            -t "${IMAGE}:latest" \
            .

      - name: Log in to STACKIT Container Registry
        if: github.event_name == 'push'
        env:
          REGISTRY_URL: ${{ secrets.REGISTRY_URL }}
          REGISTRY_USERNAME: ${{ secrets.REGISTRY_USERNAME }}
          REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
        run: |
          echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" \
            -u "$REGISTRY_USERNAME" --password-stdin

      - name: Push image
        if: github.event_name == 'push'
        run: |
          docker push "${IMAGE}:${SHORT_SHA}"
          docker push "${IMAGE}:latest"

      - name: Log out
        if: always() && github.event_name == 'push'
        run: docker logout "${{ secrets.REGISTRY_URL }}"
```

Design choices:
- Login and push run only on `push` to `main`; PR runs only test the build.
- `--password-stdin` keeps the password out of the command line.
- Secrets are passed via `env` so the `$` in the robot account name is not expanded by the shell.
- Images are tagged with the short commit SHA (traceability) and `latest` (convenience).

### Trigger and verify
1. Make a small change (e.g. update the text in `main.go`), commit on a feature branch, open a PR, and merge.
2. In the registry UI, open the namespace → `my-app` and check the SHA and `latest` tags.
3. Open the artifact to view the **vulnerability scan** (Trivy). If it says "Not scanned", enable **Automatically scan images on push** in the project's Configuration tab or click **Scan**. The distroless base should give very few findings.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Push rejected: "protected branch" | Push to a feature branch and merge via PR |
| No Actions tab / workflow not shown | Enable Repository Actions; check path `.forgejo/workflows/`; check YAML indentation (spaces, no tabs) |
| "Waiting for runner with label stackit-docker" | No runner with that label is registered. Enable managed runners in the Portal, check **Settings → Actions → Runners** for available labels, or use a custom runner |
| "Continuous integration & Runners" not visible in Portal | Open the instance detail page (not the list); check your project role; in a training project ask the trainer; otherwise use a custom runner or contact STACKIT support |
| `docker: command not found` / no Docker daemon | Use the `stackit-docker` label, or a custom runner with Docker installed |
| Registry login `unauthorized` | Use the full robot name `robot$...+...`; check expiry and Push permission |
| Push `denied` | Namespace in the image path must match the robot account's project |
| YAML parse error | `python -c "import yaml; yaml.safe_load(open('.forgejo/workflows/build.yaml'))"` |

## References
- STACKIT Git docs: https://docs.stackit.cloud/products/developer-platform/git/
- STACKIT Runners: https://docs.stackit.cloud/products/developer-platform/git/getting-started/pipeline-runners/
- Custom Runners: https://docs.stackit.cloud/products/developer-platform/git/how-tos/pipelines-custom-runner
- Forgejo Actions: https://forgejo.org/docs/latest/user/actions/

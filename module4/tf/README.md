# Terraform

## Create service account

* Install CLI tool: https://github.com/stackitcloud/stackit-cli/blob/main/INSTALLATION.md
* `stackit auth login`
* `stackit project list`
* `stackit config set --project-id PROJECTx-IDyy-zzzz-aaaa-DUMMYbbbbbbb`
* `stackit service-account create --name terraform`
* `stackit service-account list`

* `stackit service-account key create --email terraform-vsPzcS7@sa.stackit.cloud > sa_key.json`
* `stackit service-account key list --email terraform-vsPzcS7@sa.stackit.cloud`

* `stackit project member add terraform-vsPzcS7@sa.stackit.cloud --role editor`

## S3 Backend for tfstate

`stackit object-storage enable`

Note: The name must be globally unique. Use only lowercase letters, numbers or hyphens. The name should be at least 3 and at most 63 characters long.

Lets use something kinda random, to have a higher chance of catching an free bucket name:

* `stackit object-storage bucket create tfstate-bucket-g5el`
* `stackit object-storage credentials-group create --name terraform-state`
* `stackit object-storage credentials create --credentials-group-id CREDGROU-Pxxx-IDzz-aaaa-DUMMYbbbbbbb`

* `terraform init --backend-config=./config.s3.tfbackend`

Now we can start using Terraform.

## Connect to created SKE cluster

* `stackit ske cluster list`
* `stackit ske kubeconfig create scrumlr --login`
* `--login` ensures that authentication is performed with the stackit CLI and very short-lived credentials are used in the background, without this flag the credentials are static and and usually have a longer lifetime. If the credentials are obtained without the `--login` flag, they must be renewed manually.

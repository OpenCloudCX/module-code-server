# OpenCloudCX Code-Server Module

Using this module within OpenCloudCX will provision a code-server instance. This module can be used in multiple environments depending on the providers and DNS zones being defined. It is a good idea to have all modules, providers, and namespace creation in the same file.

# Setup

Add the following module definition to the bootstrap project

```
module "code-server" {
  <source block>

  dns_zone  = "<dns zone>"
  namespace = "<namespace>"

  providers = {
    kubernetes = <kubernetes provider reference>,
    helm       = <helm provider reference>
  }

  depends_on = [
    <eks module reference>,
  ]
}
```

# Source block

The source block will be in either of these formats

## Local filesystem

```
source = "<path to module>"
```

## Git repository

```
source = "git::ssh://git@github.com/<account or organization>/<repository>?ref=<branch>"
```

Note: If pulling from `main` branch, `?ref=<branch>` is not necessary.

## Terraform module

```
source  = "<url to terraform module>"
version = "<version>"
```

Verion formatting of the terraform source block [explained](https://www.terraform.io/docs/language/expressions/version-constraints.html)

# Providers

Provider references should be supplied through the `providers` configuration of the module. The main OpenCloudCX module will return all of the necessary information

```
provider "kubernetes" {
  host                   = module.<opencloudcx-module>.aws_eks_cluster_endpoint
  token                  = module.<opencloudcx-module>.aws_eks_cluster_auth_token
  cluster_ca_certificate = module.<opencloudcx-module>.aws_eks_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.<opencloudcx-module>.aws_eks_cluster_endpoint
    token                  = module.<opencloudcx-module>.aws_eks_cluster_auth_token
    cluster_ca_certificate = module.<opencloudcx-module>.aws_eks_cluster_ca_certificate
  }
}
```

Note: When multiple environments or cloud-providers are in use, the named module reference will need to be changed per environment.

## Module example with Git repository reference

This example also adds a `kubernetes_namespace` definition to create the namespace if one does not already exist.

```terraform
provider "kubernetes" {
  host                   = module.opencloudcx-aws-dev.aws_eks_cluster_endpoint
  token                  = module.opencloudcx-aws-dev.aws_eks_cluster_auth_token
  cluster_ca_certificate = module.opencloudcx-aws-dev.aws_eks_cluster_ca_certificate
}

resource "kubernetes_namespace" "develop" {
  metadata {
    name = "develop"
  }

  depends_on = [
    module.opencloudcx-aws-dev
  ]
}

provider "helm" {
  kubernetes {
    host                   = module.opencloudcx-aws-dev.aws_eks_cluster_endpoint
    token                  = module.opencloudcx-aws-dev.aws_eks_cluster_auth_token
    cluster_ca_certificate = module.opencloudcx-aws-dev.aws_eks_cluster_ca_certificate
  }
}

module "code-server" {
  source = "git::ssh://git@github.com/OpenCloudCX/module-code-server?ref=develop"

  dns_zone  = var.dns_zone
  namespace = "develop"

  providers = {
    kubernetes = kubernetes,
    helm       = helm
  }

  depends_on = [
    module.opencloudcx-aws-dev,
  ]
}

```

# Credentials

|Name|URL|Username|Password Location|
|---|---|---|---|
|Code Server| ```https://code-server.[DNS ZONE]```|None|AWS Secrets Manager [```code_server```]|

# Code-Server configuration

The OpenCloudCX enclave include an out-of-the-box Code Server instance allowing for a browser-based VSCode instance. Once the password has been retrieved from AWS Secrets Manager and used to authenticate to the server, some generic configuration will be necessary.

## Create SSH Key
Each instance will need to create their own SSH key for use within the github repository. To bring up the console within Code-Server, press ```CTRL-~``` and a terminal window will display at the bottom of the browser page. 

```
$ ssh-keygen

Generating public/private rsa key pair.
Enter file in which to save the key (/home/kodelib/.ssh/id_rsa): <enter>
Created directory '/home/kodelib/.ssh'.
Enter passphrase (empty for no passphrase): <enter>
Enter same passphrase again: <enter>
Your identification has been saved in /home/kodelib/.ssh/id_rsa
Your public key has been saved in /home/kodelib/.ssh/id_rsa.pub
```
The following configuration must also be set to do commit and push

```
git config --global user.email "<email>"
git config --global user.name "<name>"
```
Use [these instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) to copy the public key from ```id_rsa.pub``` to github.

NOTE: If a 403 error message occurs when attempting to push changes to the repository after keys have been exchanged, check the ```url``` in ```.git/config``` file. If it begins with ```https://github.com```, change it to ```ssh://git@github.com/```. Further reference is in [stack**overflow**](https://stackoverflow.com/questions/7438313/pushing-to-git-returning-error-code-403-fatal-http-request-failed/)
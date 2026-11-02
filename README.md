# Lab 3 — Infrastructure as Code

## Overview

This project demonstrates how to develop, test, release, and reuse an Ansible role. The role installs and configures Nginx and deploys a customizable webpage.

The project also includes an example AWS infrastructure setup that uses Terraform to provision an EC2 instance and Ansible to configure it using the released role.

## Architecture

```text
Role development
      |
      v
Yamllint + Ansible Lint
      |
      v
Molecule tests (Docker)
      |
      v
GitHub Actions CI
      |
      v
Versioned GitHub release
      |
      v
Example infrastructure
      |
      +-- Terraform -> AWS EC2
      |
      +-- Ansible -> Install released role
                          |
                          v
                     Nginx webpage
```

## 1. Develop and test the role

The role is named `birchjuice.nginx`.

Its main tasks are to install Nginx, create the website document root, deploy an HTML template, and ensure the service is running.

The template uses variables so the webpage can be customized without changing the role itself.

### Run the checks locally

From the repository root:

```bash
source .venv/bin/activate

yamllint .
ansible-lint
molecule test
```

- **Yamllint** checks YAML formatting.
- **Ansible Lint** checks Ansible practices.
- **Molecule** tests the role in a temporary Docker container, including idempotence and verification.

GitHub Actions runs the checks automatically through `.github/workflows/ci.yml`.

## 2. Release the role

Releases are created by pushing version tags. GitHub Actions packages the role files and publishes a GitHub release.

```bash
git tag v1.0.0
git push origin v1.0.0
```

The project has three releases:

- `v1.0.0` — Initial role.
- `v1.1.0` — Configurable document root.
- `v1.2.0` — Cleaner release packaging, excluding development and testing files.

The release workflow is `.github/workflows/release.yml`.

## 3. Deploy the example infrastructure

The `example/` directory demonstrates consuming a released version of the role in a separate Ansible project.

### Terraform — create the infrastructure

```bash
cd example/terraform

terraform init
terraform plan
terraform apply
```

Terraform creates an Ubuntu EC2 instance, an SSH key pair, and a security group allowing SSH and HTTP traffic.

Record the public IP address from Terraform's output.

### Ansible — install and run the released role

Navigate to the Ansible directory:

```bash
cd ../ansible
```

Update `hosts` with the EC2 public IP address.

Install the role specified in `requirements.yml`:

```bash
ansible-galaxy role install -r requirements.yml
```

The requirements file points to the `v1.2.0` GitHub release archive rather than the development repository.

Run the playbook:

```bash
ansible-playbook playbook.yml
```

Open `http://PUBLIC_IP` in a browser. The page should display **Hello from Lab 3!**

This demonstrates the full chain: Terraform provisions the server, Ansible consumes the published role, and the role configures Nginx and deploys the webpage.

## 4. Clean up

When finished, destroy the infrastructure:

```bash
cd ../terraform
terraform destroy
```

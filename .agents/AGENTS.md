# Project Rules & Guidelines (`vrm-cloud`)

This document outlines coding practices, conventions, and guidelines for Antigravity when working on the `vrm-cloud` repository.

## Overview
`vrm-cloud` manages cloud infrastructure and server automation (Oracle Cloud Infrastructure / OCI, Terraform, Ansible, Docker Compose, and Bash utility scripts).

## Guidelines & Best Practices

### 1. Security & Secrets Management
- **Never commit secrets, credentials, or private SSH keys** to Git. Double-check `.gitignore` before adding new file types.
- Keep sensitive variables in `.env` (git-ignored) or encrypted via Ansible Vault / OCI Vault where applicable.
- Ensure proper file permissions on sensitive files (e.g., `chmod 600` for keys).

### 2. Infrastructure as Code (Terraform)
- Ensure Terraform files (`alwaysfree.tf` and `terraform/`) are cleanly formatted using `terraform fmt`.
- Parameterize regions, OCIDs, and resource names using variables rather than hardcoding.
- Prefer explicit dependencies (`depends_on`) only when necessary; rely on implicit dependencies via variable references.

### 3. Configuration Management (Ansible & Docker Compose)
- Keep Ansible playbooks modular using roles (`ansible/roles/`).
- Document role variables clearly, and store default values in `defaults/main.yml`.
- Use standard 2-space YAML indentation and follow `ansible-lint` conventions where possible (e.g., using Fully Qualified Collection Names / FQCNs).
- **Docker Compose:** Avoid using the `latest` image tag. Pin container images to specific versions for reproducibility. Ensure persistent data uses bound volumes appropriately.

### 4. Scripts & Automation (Bash)
- Write portable Bash scripts in `scripts/` with proper error handling (`set -euo pipefail` where applicable).
- Keep file permissions to the minimum necessary (e.g., `chmod 755` for scripts).
- Always quote variable expansions to prevent word splitting (e.g., `"$VAR"` instead of `$VAR`).

### 5. Documentation
- Update `README.md` when introducing new infrastructure components, required environment variables, or setup instructions.

### 6. Agent Behavior
- **Questions & Exploration:** If the user asks a question, requests an explanation, or asks to investigate something, **DO NOT** make file changes or run state-modifying commands. Simply answer the question and wait for explicit instruction before making any changes.
- **Error Handling:** When encountering errors in Terraform, Ansible, or shell scripts, do not blindly apply fixes. Read the error logs, understand the root cause, and explain the proposed solution before executing it.

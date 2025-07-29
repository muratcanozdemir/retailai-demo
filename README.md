# SonarQube Enterprise on AWS (ECS/Fargate, Aurora, EFS, Internal ALB)

## Overview

This repository contains a fully modular Terraform setup to run SonarQube Enterprise in a private, production-ready AWS environment.

* **All infrastructure as code**—no manual clicks.
* Secure by default: private VPC, internal ALB, no public internet access.
* Uses managed AWS services: ECS Fargate, Aurora PostgreSQL, EFS, DataSync, Route53.

## Core Components

* **ECS Fargate:** SonarQube containers, zero server patching, minimal ops.
* **Aurora PostgreSQL:** Highly available backend DB, password rotation, IAM auth, audit logging.
* **EFS:** Persistent storage for SonarQube data and plugins.
* **DataSync:** Automated, repeatable plugin/config sync from S3 to EFS.
* **ALB (internal):** Only accessible within your VPC/landing zone.
* **Route53:** Private DNS for internal, stable service endpoints.
* **GitHub Actions:** Automated CI/CD with targeted, per-module deploys (no cowboy changes).

## What This Is NOT

* Not for public internet exposure.
* Not a "click to deploy" or demo stack—this is for real prod use with security guardrails.
* Not "one size fits all": you'll need to set up `env/prod.tfvars` for your actual VPC, subnets, etc.

---

## Prerequisites

* **Terraform 1.7+** (check with `terraform version`)
* **AWS account** with:

  * A dedicated VPC and private subnets
  * S3 bucket (for state) and (optionally) DynamoDB table (for state locking)
  * IAM Role for CI/CD with OIDC support (GitHub recommended)
* **ACM Certificate** for internal DNS (provisioned in AWS, not via this repo)
* **Secrets managed in AWS Secrets Manager** (DB creds, etc.)
* **GitHub Actions runner with access to the repo and OIDC-enabled AWS role**

---

## Repository Layout

```
modules/
  alb/
  dns/
  ecs/
  efs-datasync/
  rds/
env/
  prod.tfvars
.github/
  workflows/
    sonarqube-main.yml
    sonarqube-module-deploy.yml
backend.tf
variables.tf
versions.tf
outputs.tf
main.tf
README.md
```

* **modules/** — Reusable, minimal Terraform modules for each AWS service.
* **env/prod.tfvars** — Your environment-specific settings (VPC, subnets, ARNs, etc.)
* **backend.tf** — S3 state backend (set up before running anything else).
* **outputs.tf** — Everything your CI/CD or ops will want to automate against.
* **main.tf** — Wires all modules together for a real deployment.

---

## How to Deploy (TL;DR)

1. **Clone the repo.**

2. **Configure your AWS CLI with the right role/profile**, or just let the workflow assume the correct role via OIDC.

3. **Edit `env/prod.tfvars`** with your VPC, subnet IDs, certs, S3 bucket ARNs, etc.

4. **Bootstrap state backend** (create the S3 bucket and, optionally, DynamoDB table for locking).

5. **Run the pipeline** (GitHub Actions), or run manually:

   ```
   terraform init
   terraform plan -var-file=env/prod.tfvars
   terraform apply -var-file=env/prod.tfvars
   ```

6. **Check outputs:**
   After apply, see all resource endpoints/ARNs with:

   ```
   terraform output
   ```

   or download the `tf-outputs.json` artifact from CI.

---

## How CI/CD Works

* **Only modules with changed files or env/prod.tfvars get deployed** (no "big bang" applies unless you want).
* **ECS upgrades:**

  * Drains old containers, runs DB migrations (with pre-upgrade DB snapshot), then restarts with new version and health checks.
* **Plugins/config:**

  * Upload to S3, then DataSync copies to EFS.
  * No manual file copy or SSH.
* **Full output logs and terraform outputs.json artifact for each run.**

---

## Operational Considerations

* **DB Rollback:**
  Every migration is preceded by an Aurora snapshot. If a migration fails, ECS is not restarted until you restore (manual).
* **Plugin Changes:**
  Update the S3 plugins/config, trigger DataSync via pipeline, and ECS will mount the result.
* **State Management:**
  All infra state is in the S3 backend you provide. No local state, no snowflake infra.
* **Adding New Modules:**
  Add a new directory in `modules/`, wire in main.tf, add outputs, and CI/CD will pick it up automatically on change.

---

## Troubleshooting

* **If ECS tasks can't mount EFS:**

  * Check EFS security group ingress rules allow ECS/DataSync SGs on port 2049.
* **If ALB health checks fail:**

  * Check ECS service logs and SonarQube health endpoint via outputs.
* **If Terraform fails on version:**

  * Check you are running Terraform >= 1.7.x (`terraform version`).

---

## Security Notes

* No hardcoded credentials—everything uses AWS IAM roles and OIDC where possible.
* All network access is tightly scoped by security group (never 0.0.0.0/0).
* SonarQube only reachable inside the VPC (never public internet).
* DB secrets are rotated and never output or logged.

---

## FAQ

* **Q: Can I make SonarQube public?**
  **A:** Not with this stack. Expose only via VPN, DirectConnect, or bastion.
* **Q: Can I bring my own DB?**
  **A:** This assumes Aurora. Using RDS or external DB is possible but not out-of-the-box.
* **Q: What if I want blue/green or canary deploys?**
  **A:** This stack uses draining+zero for simplicity and reliability. Adapt as you wish.

---

## Contributing

If you spot a bug, inefficiency, or have a better way, submit a PR or open an issue.
No corporate “innovation theater,” please—only practical improvements.

---

## License

MIT, despite the org requirements

---

**Questions? Open an issue, or ask in your team’s Slack channel.**

# Phase 2 Capstone: Production-Grade DevSecOps Pipeline on AWS

This repository contains the Infrastructure as Code (IaC) and CI/CD pipeline for a secure, 3-tier polling application. It represents the transition from local development to a fully automated, cloud-native architecture.

## Architecture Overview

The system is designed with a "Lean Production" philosophy: utilising enterprise-grade security patterns (Zero Trust, Least Privilege) while optimising for cost (AWS Free Tier/Spot Instances).

### The Stack

- IaC: Terraform (Modular structure).
- Compute: AWS ECS Fargate (Serverless Containers).
- Network: Custom VPC, Application Load Balancer (ALB).
- Data: Amazon RDS (PostgreSQL), encrypted at rest.
- Security: AWS IAM (Roles), Secrets Manager, KMS, OIDC.
- CI/CD: GitHub Actions with DevSecOps gates (TruffleHog, Checkov, Trivy).

### The Traffic Flow

``` User -> Route 53 -> ALB (Public Subnet) -> Fargate Task (Public Subnet + Locked SG) -> RDS (Private Subnet) ```

## Design Decisions & Trade-Offs

I made deliberate architectural choices to balance Security vs. Cost vs. Complexity.
| Component | My Choice | Enterprise Standard | Rationale |
|---------|-----------|--------------------|-----------|
| Compute | Fargate Spot | Fargate Standard | Spot instances reduce cost by ~70%. Trade-off: capacity can be reclaimed, requiring a resilient, stateless application design. |
| Network | Public Subnets | Private Subnets + NAT Gateway | Running tasks in public subnets (locked down by security groups) avoids the ~$64/month NAT Gateway cost while maintaining isolation. |
| Database | RDS (db.t3.micro) | Aurora Serverless | RDS fits within AWS Free Tier. Aurora offers better scaling and HA but has a high minimum cost. |
| Identity | OIDC Federation | IAM Users | Zero Trust approach: GitHub Actions assumes an AWS role via OIDC. No long-lived AWS access keys are stored. |

## DevSecOps Implementation

The pipeline integrates "Shift Left" security:

1. Secret Scanning (TruffleHog): Scans git history for leaked credentials before build.
2. IaC Scanning (Checkov): Audits Terraform code for misconfigurations (e.g., unencrypted storage).
3. Container Scanning (Trivy): Checks the Docker image for OS-level vulnerabilities (CVEs) before pushing to ECR.

## The Debugging Journey (Key Challenges)

This project wasn't just about writing code; it was about debugging complex cloud interactions.

1. The "Hidden" IAM Permission Trap
    - Issue: ECS tasks failed to start with ResourceInitializationError.
    - Diagnosis: The Execution Role had permission to read the Secret (GetSecretValue) but not to decrypt the key protecting it.
    - Fix: Updated the IAM policy to include kms:Decrypt for the AWS managed key.

2. The Architecture Mismatch
    - Issue: CannotPullContainerError. Fargate failed to run the Docker image.
    - Diagnosis: The image was built on an Apple Silicon (ARM64) Mac, but Fargate expects Intel (AMD64).
    - Fix: Updated the CI/CD pipeline to explicitly cross-compile: docker build --platform linux/amd64.

3. The State Drift (Password Gap)
    - Issue: Application failed to connect to DB (Password authentication failed).
    - Diagnosis: Terraform updated the password in Secrets Manager, but the RDS instance update was pending the next maintenance window.
    - Fix: Configured Terraform apply_immediately = true and forced a full database recreation to synchronise state.

4. OIDC Audience Mismatch
    - Issue: GitHub Actions failed to authenticate with AWS (Incorrect token audience).
    - Diagnosis: The OIDC Provider was configured with a typo (sts:amazonaws.com instead of sts.amazonaws.com).
    - Fix: Corrected the client ID list in the Terraform OIDC module.

## Outcome
This project demosntrates:
- Production-grade AWS infrastructure using Terraform
- Secure, keyless CI/CD authentication via OIDC
- Practical DevSecOps tooling integrated into the pipeline
- Real-world cloud debugging across IAM, networking, containers, and state management

The result, a secure, cost-aware, and automation-first Infrastructure and DevSecOps pipeline suitable for real production workloads.
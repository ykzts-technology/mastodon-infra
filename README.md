# Mastodon Infra

Infrastructure as Code for deploying Mastodon on Google Cloud Platform using Terraform and Kubernetes.

## Overview

This repository contains Terraform configurations and Kubernetes manifests to deploy a production-ready Mastodon instance on Google Cloud Platform (GCP). The infrastructure leverages GCP managed services for high availability, scalability, and ease of maintenance.

## Architecture

The infrastructure consists of the following components:

### Core Infrastructure

- **Google Kubernetes Engine (GKE)**: Autopilot cluster for running Mastodon applications
  - Mastodon web application
  - Mastodon streaming server
  - Mastodon background workers
  - Manael (media proxy)
- **Cloud SQL for PostgreSQL**: Managed PostgreSQL 17 database with automated backups
- **Memorystore (Valkey)**: Redis-compatible cache cluster for session management and job queues
- **Cloud Storage (GCS)**: Object storage for media files and attachments
- **Cloud DNS**: DNS zone management with DNSSEC enabled
- **VPC Network**: Custom VPC with subnets for GKE and database

### Additional Services

- **Elasticsearch**: External search backend (configured via variables)
- **SMTP**: Email delivery via Resend
- **Translation**: DeepL API integration for content translation
- **Monitoring**: Grafana integration for observability

## Prerequisites

Before you begin, ensure you have the following:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud` CLI)
- A Google Cloud Platform project with billing enabled
- Appropriate GCP permissions to create resources (see `sa.tf` for required roles)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for Kubernetes cluster management
- [Skaffold](https://skaffold.dev/docs/install/) for deploying Kubernetes manifests (optional)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/ykzts-technology/mastodon-infra.git
cd mastodon-infra
```

### 2. Configure Terraform Cloud

This project uses Terraform Cloud for state management. Update `main.tf` with your organization and workspace:

```hcl
terraform {
  cloud {
    organization = "your-organization"
    workspaces {
      name = "your-workspace"
    }
  }
}
```

### 3. Set Required Variables

Create a `terraform.tfvars` file or set variables in Terraform Cloud:

```hcl
# Core Configuration
project_id = "your-gcp-project-id"
region     = "asia-northeast1"
domain     = "your-domain.com"

# Database & Cache (automatically configured)
# PostgreSQL and Valkey instances are created automatically

# Mastodon Secrets
active_record_encryption_key_derivation_salt = "your-salt"
active_record_encryption_deterministic_key   = "your-deterministic-key"
active_record_encryption_primary_key         = "your-primary-key"
vapid_private_key                            = "your-vapid-private-key"
vapid_public_key                             = "your-vapid-public-key"

# Elasticsearch Configuration
es_hostname = "your-elasticsearch-host"
es_port     = "9200"
es_username = "elastic"
es_password = "your-es-password"

# Email Configuration (Resend)
smtp_password = "your-smtp-password"

# Translation Service
deepl_api_key = "your-deepl-api-key"

# Monitoring (Grafana)
grafana_api_token       = "your-grafana-token"
grafana_datasource_uids = "your-datasource-uids"
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review and Apply Infrastructure

```bash
terraform plan
terraform apply
```

## Infrastructure Components

### Networking (`network.tf`)

- VPC with custom subnets
- Secondary IP ranges for GKE pods and services
- Private networking for database and cache

### Database (`db.tf`)

- Cloud SQL PostgreSQL 17 (db-f1-micro tier)
- Automated daily backups (retained for 7 days)
- Private IP connectivity
- Optimized database flags for Mastodon workload

### Cache (`db.tf`)

- Memorystore Valkey 8.0 cluster
- Shared core nano instance
- Private Service Connect (PSC) connectivity

### Storage (`gcs.tf`)

- GCS bucket for media storage
- HMAC keys for S3-compatible access
- CORS configured for Mastodon domain
- Asia multi-region storage

### DNS (`dns.tf`)

- Cloud DNS public zone with DNSSEC
- A and HTTPS records for main domain
- Email configuration (SPF, DKIM, DMARC)
- Status page and file server CNAMEs

### Kubernetes Resources

> **Note**: This project is transitioning from Kustomize to the official Mastodon Helm Chart. See [Helm Migration Guide](docs/helm-migration-guide.md) for details.

Kubernetes manifests are currently organized using Kustomize:

- **Base**: Common configurations for all environments (`k8s/base/`)
- **Overlays**: Environment-specific configurations
  - Development: `k8s/overlays/development/`
  - Production: `k8s/overlays/production/`
- **Jobs**: One-time jobs like database migrations (`k8s/jobs/`)

For the new Helm-based deployment, see:
- **Helm Values**: Production configuration (`helm/values-production.yaml`)
- **Migration Docs**: Complete migration guide (`docs/helm-migration-guide.md`)

## Deployment

### Deploy Infrastructure

```bash
terraform apply
```

### Configure kubectl

```bash
gcloud container clusters get-credentials mastodon-cluster \
  --region asia-northeast1 \
  --project your-project-id
```

### Deploy Kubernetes Applications

#### Option 1: Using Helm (Recommended - New)

```bash
# Add Mastodon Helm repository
helm repo add mastodon https://mastodon.github.io/helm-charts/
helm repo update

# Install or upgrade Mastodon
helm upgrade --install mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --timeout 10m

# Check deployment status
kubectl get pods -l app.kubernetes.io/instance=mastodon
```

For migration from Kustomize to Helm, see [Helm Migration Guide](docs/helm-migration-guide.md).

#### Option 2: Using Kustomize (Current)

Using Skaffold:

```bash
# Development
skaffold run

# Production
skaffold run -p production
```

Or using kubectl directly:

```bash
# Development
kubectl apply -k k8s/overlays/development

# Production
kubectl apply -k k8s/overlays/production
```

### Run Database Migrations

With Helm (automatic via hooks):
```bash
# Migrations run automatically during helm upgrade
# To run manually:
kubectl create job --from=cronjob/mastodon-db-migrate mastodon-db-migrate-manual
```

With Kustomize:
```bash
kubectl apply -f k8s/jobs/migrate.yaml
```

### Deploy Elasticsearch Indices

```bash
kubectl apply -f k8s/jobs/search-deploy.yaml
```

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `project_id` | string | Yes | - | GCP Project ID |
| `region` | string | No | `asia-northeast1` | GCP region for resources |
| `domain` | string | Yes | - | Domain name for Mastodon instance |
| `active_record_encryption_*` | string | Yes | - | Rails encryption keys |
| `vapid_private_key` | string | Yes | - | VAPID private key for push notifications |
| `vapid_public_key` | string | Yes | - | VAPID public key for push notifications |
| `es_hostname` | string | Yes | - | Elasticsearch hostname |
| `es_port` | string | Yes | - | Elasticsearch port |
| `es_username` | string | Yes | - | Elasticsearch username |
| `es_password` | string | Yes | - | Elasticsearch password |
| `smtp_password` | string | Yes | - | SMTP password for email delivery |
| `deepl_api_key` | string | Yes | - | DeepL API key for translations |
| `grafana_api_token` | string | Yes | - | Grafana API token |
| `grafana_datasource_uids` | string | Yes | - | Grafana datasource UIDs |

## Maintenance

### Updating Infrastructure

1. Update the relevant Terraform configuration files
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Updating Kubernetes Applications

#### With Helm (Recommended - New)

```bash
# Update values.yaml with desired changes
# Then upgrade the release
helm upgrade mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml

# View release history
helm history mastodon

# Rollback if needed
helm rollback mastodon
```

#### With Kustomize (Current)

1. Update manifests in `k8s/` directory
2. Apply changes using Skaffold or kubectl

### Monitoring

The infrastructure includes Grafana integration for monitoring. Access metrics through your configured Grafana instance.

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Helm Migration Guide](docs/helm-migration-guide.md)**: Complete guide for migrating from Kustomize to Helm Chart
- **[Pre-Migration Checklist](docs/pre-migration-checklist.md)**: Detailed checklist to prepare for migration
- **[Downtime Minimization Strategy](docs/downtime-minimization-strategy.md)**: Strategies to minimize downtime during migration
- **[Rollback Procedure](docs/rollback-procedure.md)**: Emergency rollback procedures if issues occur

## Security

- Database and cache use private IP addresses only
- SSL/TLS policy enforced (TLS 1.2 minimum)
- DNSSEC enabled on DNS zone
- Service accounts follow principle of least privilege
- Secrets managed via Kubernetes Secrets

## Cost Optimization

The infrastructure is configured with cost-efficient resources:

- GKE Autopilot (pay-per-pod)
- Cloud SQL db-f1-micro instance
- Memorystore Shared Core Nano
- Standard storage class for GCS

Consider upgrading instance sizes for production workloads with high traffic.

## Contributing

Contributions are welcome! Please ensure:

1. Terraform code is formatted with `terraform fmt`
2. All required variables are documented
3. Changes are tested in a development environment first

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:

- Open an issue on GitHub
- Review existing discussions and issues

## Acknowledgments

- [Mastodon](https://joinmastodon.org/) - The federated social network
- Terraform Google Modules for reusable infrastructure components

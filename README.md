# ECS Deployment with Terraform and GitHub Actions

Complete infrastructure-as-code setup for deploying a Flask application to AWS ECS using Terraform and GitHub Actions with OIDC authentication.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud (af-south-1)                │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │                  VPC (10.0.0.0/16)                  │ │
│  │                                                     │ │
│  │  ┌──────────────┐         ┌──────────────────────┐ │ │
│  │  │Public Subnets│         │  Private Subnets     │ │ │
│  │  │              │         │                      │ │ │
│  │  │    ┌───┐     │         │   ┌──────────────┐  │ │ │
│  │  │    │ALB│◄────┼─────────┼───┤  ECS Fargate │  │ │ │
│  │  │    └───┘     │         │   │    Tasks     │  │ │ │
│  │  │              │         │   └──────────────┘  │ │ │
│  │  │   ┌─────┐    │         │                      │ │ │
│  │  │   │ NAT │────┼─────────┤                      │ │ │
│  │  │   └─────┘    │         │                      │ │ │
│  │  └──────────────┘         └──────────────────────┘ │ │
│  │                                                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────┐  ┌────────┐  ┌──────────┐                  │
│  │  ECR   │  │  ECS   │  │CloudWatch│                  │
│  └────────┘  └────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────┘
```

## 📂 Project Structure

```
ecs-practice/
├── .github/
│   └── workflows/
│       ├── 1-deploy-infrastructure.yml  # Terraform deployment
│       └── 2-deploy-application.yml     # App build & deploy
├── terraform/
│   ├── main.tf           # Provider configuration
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── vpc.tf           # VPC, subnets, ALB
│   ├── ecr.tf           # ECR repository
│   ├── ecs.tf           # ECS cluster, service, tasks
│   └── iam.tf           # IAM roles
├── app.py               # Flask application
├── requirements.txt     # Python dependencies
├── Dockerfile          # Container definition
└── README.md
```

## 🚀 Quick Start

### Prerequisites

✅ AWS account with appropriate permissions
✅ GitHub repository
✅ AWS CLI installed and configured
✅ GitHub OIDC role created (use OIDC.sh script)

### Step 1: Set Up AWS OIDC (One-Time Setup)

You already have this! The `GitHubActionsDeployRole` is created and configured.

### Step 2: Add GitHub Secrets

Go to your repository: `Settings → Secrets → Actions`

Add only ONE secret:

| Secret Name | Value |
|-------------|-------|
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::686739640894:role/GitHubActionsDeployRole` |

**That's it!** Terraform will output everything else automatically.

### Step 3: Deploy Infrastructure

```bash
# Add Terraform files to your repository
git add terraform/
git add .github/workflows/1-deploy-infrastructure.yml
git commit -m "Add Terraform infrastructure"
git push origin main
```

This triggers the infrastructure workflow which creates:
- ✅ VPC with public and private subnets
- ✅ Application Load Balancer
- ✅ ECS Cluster and Service
- ✅ ECR Repository
- ✅ IAM Roles
- ✅ Security Groups
- ✅ CloudWatch Log Groups

**Wait ~5-10 minutes for infrastructure to deploy.**

### Step 4: Deploy Application

```bash
# Update your application
nano app.py  # Make changes

# Deploy
git add app.py
git commit -m "Update application"
git push origin main
```

This triggers the application workflow which:
- ✅ Builds Docker image
- ✅ Pushes to ECR
- ✅ Updates ECS task definition
- ✅ Deploys new version (zero downtime!)

## 🎯 How It Works

### Workflow 1: Infrastructure (Terraform)

**Triggers:**
- Push to `main` that modifies `terraform/**`
- Manual trigger via GitHub Actions UI

**What it does:**
1. Authenticates with AWS via OIDC
2. Runs `terraform plan`
3. On PR: Posts plan as comment
4. On merge to main: Runs `terraform apply`
5. Outputs infrastructure details for next workflow

**Terraform Outputs:**
```bash
ecr_repository_url    # Where to push images
ecs_cluster_name      # ECS cluster name
ecs_service_name      # ECS service name
container_name        # Container name
alb_url              # Application URL
```

### Workflow 2: Application Deployment

**Triggers:**
- Push to `main` that modifies app files
- Manual trigger via GitHub Actions UI

**What it does:**
1. Reads Terraform outputs (infrastructure details)
2. Builds Docker image
3. Pushes to ECR
4. Downloads current task definition
5. Updates with new image tag
6. Deploys to ECS with zero downtime

## 📊 Infrastructure Resources Created

| Resource | Name | Purpose |
|----------|------|---------|
| VPC | demo-vpc | Network isolation |
| Public Subnets | demo-public-1/2 | ALB placement |
| Private Subnets | demo-private-1/2 | ECS tasks |
| Internet Gateway | demo-igw | Internet access |
| NAT Gateway | demo-nat | Outbound for private subnets |
| ALB | demo-alb | Load balancing |
| Target Group | demo-tg | Health checks |
| ECS Cluster | demo-cluster | Container orchestration |
| ECS Service | demo-service | Task management |
| ECR Repository | demo-ecr | Image storage |
| CloudWatch Logs | /ecs/demo | Application logs |
| IAM Roles | demo-ecs-* | ECS permissions |

## 🔧 Customization

### Change Resource Names

Edit `terraform/variables.tf`:

```hcl
variable "project_name" {
  default = "myapp"  # Change this
}
```

### Change Region

```hcl
variable "aws_region" {
  default = "us-east-1"  # Change from af-south-1
}
```

### Adjust Task Resources

```hcl
variable "task_cpu" {
  default = 512  # 0.5 vCPU (was 256)
}

variable "task_memory" {
  default = 1024  # 1 GB (was 512)
}
```

### Scale Tasks

```hcl
variable "desired_count" {
  default = 2  # Run 2 tasks (was 1)
}
```

## 📋 Useful Commands

### View Terraform Outputs

```bash
cd terraform
terraform output
```

### Get Application URL

```bash
cd terraform
terraform output alb_url
```

### View Logs

```bash
aws logs tail /ecs/demo --follow --region af-south-1
```

### Check ECS Service

```bash
aws ecs describe-services \
  --cluster demo-cluster \
  --services demo-service \
  --region af-south-1
```

### Manual Infrastructure Update

```bash
cd terraform
terraform plan
terraform apply
```

### Destroy Everything

```bash
cd terraform
terraform destroy
```

⚠️ **Warning:** This deletes ALL resources!

## 🐛 Troubleshooting

### Infrastructure Deployment Fails

Check Terraform logs in GitHub Actions:
1. Go to Actions tab
2. Click the failed workflow
3. Review Terraform Plan/Apply steps

Common issues:
- Insufficient AWS permissions
- Resource limits exceeded
- Invalid configuration

### Application Deployment Fails

**Check if infrastructure exists:**
```bash
cd terraform
terraform output
```

**Check ECS service events:**
```bash
aws ecs describe-services \
  --cluster demo-cluster \
  --services demo-service \
  --region af-south-1 \
  --query 'services[0].events[0:5]'
```

**Check CloudWatch logs:**
```bash
aws logs tail /ecs/demo --follow --region af-south-1
```

### Task Won't Start

Common causes:
1. **Image doesn't exist in ECR**
   - Check: `aws ecr list-images --repository-name demo-ecr --region af-south-1`
   
2. **Health check failing**
   - Ensure `/health` endpoint returns 200
   - Check app runs on port 80

3. **Out of memory/CPU**
   - Increase task resources in `variables.tf`

## 💰 Cost Estimate

**Monthly costs (af-south-1):**
- ECS Fargate (1 task, 256 CPU, 512 MB): ~$9
- ALB: ~$22
- NAT Gateway: ~$33
- ECR: ~$1
- CloudWatch Logs: ~$2
- **Total: ~$67/month**

**Cost optimization:**
- Stop tasks when not in use
- Use smaller task sizes for dev
- Remove NAT Gateway (use public subnets for dev)

## 🎓 Learning Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

## 📝 Next Steps

### Add Auto Scaling

Edit `terraform/ecs.tf` to add auto-scaling policies based on CPU/memory.

### Add RDS Database

Create `terraform/rds.tf` for PostgreSQL database in private subnets.

### Add Custom Domain

Use Route53 and ACM for SSL/TLS with custom domain.

### Multi-Environment Setup

Create separate Terraform workspaces for dev/staging/prod.

## ✅ Checklist

- [x] AWS OIDC configured
- [x] GitHub secret added
- [x] Terraform files created
- [x] Infrastructure deployed
- [x] Application deployed
- [x] Load balancer working
- [ ] Custom domain (optional)
- [ ] SSL certificate (optional)
- [ ] Auto-scaling (optional)

---

**Created by:** DevOps Team  
**Last Updated:** February 2026

🎉 Enjoy your automated ECS deployment!

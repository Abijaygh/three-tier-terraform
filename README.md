# AWS Three-Tier Architecture with Terraform

## Project Overview

This project provisions a complete three-tier web architecture on AWS using Terraform (Infrastructure as Code). Every resource in this project was defined in code and deployed automatically — no manual clicking in the AWS console.

The architecture follows industry best practices including high availability across multiple availability zones, network isolation between tiers, and least-privilege security group rules.

---

## Architecture Diagram

```
Internet
    |
Internet Gateway
    |
Elastic Load Balancer (public subnets - AZ1 & AZ2)
    |
Web Tier - EC2 instances (public subnets - AZ1 & AZ2)
    |
App Tier - EC2 instances (private subnets - AZ1 & AZ2)
    |
Database Tier - RDS MySQL (private subnets - AZ1 & AZ2)
```

---

## What Was Built

### Networking
- VPC with CIDR block `10.0.0.0/16`
- 2 public subnets across 2 availability zones (`us-east-1a`, `us-east-1b`)
- 2 private subnets across 2 availability zones
- Internet Gateway
- Public route table (connected to the internet)
- Private route table (no internet access)
- Route table associations for all subnets

### Security Groups
- **Web tier** — allows inbound HTTP (port 80) and HTTPS (port 443) from the internet
- **App tier** — allows inbound traffic only from the web security group on port 8080
- **Database tier** — allows inbound traffic only from the app security group on port 3306

### Load Balancer
- Application Load Balancer across both public subnets
- Target group with health checks
- Listener on port 80 forwarding to the target group
- Target group attachments for both web servers

### Web Tier
- 2 EC2 instances (`t3.micro`) in public subnets
- Apache web server installed via user data script
- Registered with the load balancer target group

### App Tier
- 2 EC2 instances (`t3.micro`) in private subnets
- Accessible only from the web tier

### Database Tier
- RDS MySQL 8.0 instance (`db.t3.micro`)
- Deployed in private subnets via a DB subnet group
- Accessible only from the app tier

---

## Project Structure

```
three-tier-terraform/
├── main.tf          # All AWS resource definitions
├── variables.tf     # Input variable declarations
├── outputs.tf       # Output values after deployment
└── .gitignore       # Files excluded from version control
```

---

## Prerequisites

- Terraform installed (`terraform -v` to verify)
- AWS CLI installed and configured (`aws configure`)
- An AWS account with appropriate permissions
- VS Code or any text editor

---

## How to Deploy

1. Clone this repository:
```bash
git clone https://github.com/Abijaygh/three-tier-terraform.git
cd three-tier-terraform
```

2. Initialize Terraform:
```bash
terraform init
```

3. Preview the resources that will be created:
```bash
terraform plan
```

4. Deploy the infrastructure:
```bash
terraform apply
```
Type `yes` when prompted.

5. After deployment, Terraform will print the important outputs:
- Load balancer DNS name (visit this in your browser)
- Web server public IPs
- Database endpoint

---

## How to Destroy

When done, destroy all resources to avoid AWS charges:
```bash
terraform destroy
```
Type `yes` when prompted.

---

## Key Concepts Learned

- **Infrastructure as Code** — defining cloud resources in `.tf` files instead of clicking manually
- **Terraform workflow** — `init` → `plan` → `apply` → `destroy`
- **Resource references** — how Terraform resources reference each other (e.g. `aws_vpc.main.id`)
- **State file** — how Terraform tracks what has been built
- **Variables** — separating configuration values from resource definitions
- **Outputs** — surfacing important values after a deployment
- **Security groups** — controlling traffic between tiers using least privilege
- **High availability** — deploying across multiple availability zones

---

## Author

**Jennifer Dentsil** — ElevateHub Cloud Computing Track  
GitHub: [@Abijaygh](https://github.com/Abijaygh)

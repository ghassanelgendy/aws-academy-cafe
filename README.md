## 🎯 Scope of This Project

This repository **does not replicate the full AWS Academy Architecting course**. Instead, it focuses **only on the Challenge Labs** and reimplements them with **Terraform**.

* The theory modules (Well-Architected Framework, IAM deep dives, S3 documentation, etc.) are **not included here**.
* The Terraform code in this repo is meant to **mirror the lab challenges** you’d normally complete through the AWS Academy platform.
* Each challenge lab will be mapped to a Terraform configuration (organized in the `labs/` directory).

---

## 📂 Repository Layout (Adjusted for Labs)

```
.
├── labs/                  # Challenge lab Terraform implementations
│   ├── lab-02-vpc/        # Networking setup from Module 2
│   ├── lab-04-s3/         # S3 storage setup
│   ├── lab-05-ec2/        # Compute environment
│   ├── lab-06-database/   # RDS/DynamoDB setup
│   ├── lab-07-vpc/        # Custom VPC and subnets
│   ├── lab-08-networking/ # Connecting networks
├── modules/               # Shared reusable modules
├── README.md              # This file
└── docs/                  #  Notes, diagrams, or summaries
```

---

## ⚠️ Disclaimer

This repository is a **self-study project**. It is **not affiliated, associated, authorized, endorsed by, or in any way officially connected with Amazon Web Services (AWS) or AWS Academy**.

* The **module content** (Well-Architected Framework, IAM, S3, EC2, etc.) belongs to AWS Academy and is **not reproduced here**.
* Only the **Challenge Labs** are reimplemented in Terraform as part of personal practice.
* This repo exists to **learn Infrastructure as Code (IaC)** while reinforcing concepts from the *Architecting on AWS* course.

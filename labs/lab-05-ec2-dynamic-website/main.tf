terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
    local = { source = "hashicorp/local", version = "~> 2.0" }
  }
  required_version = ">= 1.5.0"
}

# ---------------------------------------------------------
# Providers
# ---------------------------------------------------------
provider "aws" {
  alias  = "dev"
  region = var.aws_region
}

provider "aws" {
  alias  = "prod"
  region = var.prod_region
}

# Useful default-vpc & subnet lookup (dev)
data "aws_vpc" "dev" {
  provider = aws.dev
  default  = true
}

data "aws_subnets" "dev" {
  provider = aws.dev
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dev.id]
  }
}

# default-vpc & subnet lookup (prod)
data "aws_vpc" "prod" {
  provider = aws.prod
  default  = true
}

data "aws_subnets" "prod" {
  provider = aws.prod
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.prod.id]
  }
}

# ---------------------------------------------------------
# Key pair (generate locally so you can SSH)
# ---------------------------------------------------------
resource "tls_private_key" "cafe_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cafe_key" {
  provider  = aws.dev
  key_name  = "${var.project_prefix}-key"
  public_key = tls_private_key.cafe_key.public_key_openssh
}

# write private key to local file (secure file permission is YOUR responsibility)
resource "local_file" "private_key" {
  content  = tls_private_key.cafe_key.private_key_pem
  filename = "${path.module}/id_rsa_cafe"
  file_permission = "0600"
}

# ---------------------------------------------------------
# Security group (Dev)
# ---------------------------------------------------------
resource "aws_security_group" "cafe_sg_dev" {
  provider    = aws.dev
  name        = "${var.project_prefix}-sg-dev"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.dev.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-sg-dev" }
}

# Security group (Prod)
resource "aws_security_group" "cafe_sg_prod" {
  provider    = aws.prod
  name        = "${var.project_prefix}-sg-prod"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.prod.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-sg-prod" }
}

# ---------------------------------------------------------
# IAM role and instance profile for EC2 instances (CafeRole)
# Grants Secrets Manager read access (and basic logging)
# ---------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cafe_role" {
  name               = "${var.project_prefix}-CafeRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# attach AWS managed SecretsManagerReadWrite for simplicity (lab)
resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.cafe_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "cafe_profile" {
  name = "${var.project_prefix}-profile"
  role = aws_iam_role.cafe_role.name
}

# ---------------------------------------------------------
# Random DB password
# ---------------------------------------------------------
resource "random_password" "db_password" {
  length  = 20
  special = true
}

# ---------------------------------------------------------
# Secrets in Dev region (names the lab expects)
# We'''ll create simple secret entries; the app reads these.
# ---------------------------------------------------------
resource "aws_secretsmanager_secret" "dev_dbUser" {
  provider = aws.dev
  name     = "/cafe/dbUser"
}
resource "aws_secretsmanager_secret_version" "dev_dbUser_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_dbUser.id
  secret_string = jsonencode({ value = var.db_user })
}

resource "aws_secretsmanager_secret" "dev_dbPassword" {
  provider = aws.dev
  name     = "/cafe/dbPassword"
}
resource "aws_secretsmanager_secret_version" "dev_dbPassword_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_dbPassword.id
  secret_string = jsonencode({ value = random_password.db_password.result })
}

resource "aws_secretsmanager_secret" "dev_dbHost" {
  provider = aws.dev
  name     = "/cafe/dbHost"
}
resource "aws_secretsmanager_secret_version" "dev_dbHost_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_dbHost.id
  secret_string = jsonencode({ value = "localhost" })
}

resource "aws_secretsmanager_secret" "dev_dbName" {
  provider = aws.dev
  name     = "/cafe/dbName"
}
resource "aws_secretsmanager_secret_version" "dev_dbName_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_dbName.id
  secret_string = jsonencode({ value = var.db_name })
}

resource "aws_secretsmanager_secret" "dev_region" {
  provider = aws.dev
  name     = "/cafe/region"
}
resource "aws_secretsmanager_secret_version" "dev_region_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_region.id
  secret_string = jsonencode({ value = var.aws_region })
}

resource "aws_secretsmanager_secret" "dev_publicDNS" {
  provider = aws.dev
  name     = "/cafe/publicDNS"
}
resource "aws_secretsmanager_secret_version" "dev_publicDNS_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_publicDNS.id
  secret_string = jsonencode({ value = "dev-will-update-after-launch" })
}

resource "aws_secretsmanager_secret" "dev_extra" {
  provider = aws.dev
  name     = "/cafe/extraParam"
}
resource "aws_secretsmanager_secret_version" "dev_extra_ver" {
  provider      = aws.dev
  secret_id     = aws_secretsmanager_secret.dev_extra.id
  secret_string = jsonencode({ value = "extra" })
}

# ---------------------------------------------------------
# Dev EC2 instance (boots the LAMP stack and app)
# We pass DB password and user via template interpolation to create DB.
# ---------------------------------------------------------
data "aws_ami" "amazon_linux_2" {
  provider = aws.dev
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "dev" {
  provider               = aws.dev
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.dev.ids[0]
  vpc_security_group_ids = [aws_security_group.cafe_sg_dev.id]
  iam_instance_profile   = aws_iam_instance_profile.cafe_profile.name
  key_name               = aws_key_pair.cafe_key.key_name
  user_data = templatefile("${path.module}/user_data_dev.tpl", {
    db_root_password = random_password.db_password.result
    db_user          = var.db_user
    db_password      = random_password.db_password.result
    db_name          = var.db_name
    secrets_region   = var.aws_region
    cafe_zip_url     = var.cafe_zip_url
    db_zip_url       = var.db_zip_url
    setup_zip_url    = var.setup_zip_url
  })

  tags = {
    Name = "${var.project_prefix}-dev"
  }
}

# ---------------------------------------------------------
# Create AMI from Dev instance, then copy AMI to Prod region
# ---------------------------------------------------------
resource "aws_ami_from_instance" "cafe_ami" {
  provider           = aws.dev
  name               = "${var.project_prefix}-cafe-ami"
  source_instance_id = aws_instance.dev.id
  snapshot_without_reboot = true
  depends_on = [aws_instance.dev]
}

resource "aws_ami_copy" "cafe_ami_copy" {
  provider         = aws.prod
  name             = "${var.project_prefix}-cafe-ami-copy"
  source_ami_id    = aws_ami_from_instance.cafe_ami.id
  source_ami_region= var.aws_region
  depends_on       = [aws_ami_from_instance.cafe_ami]
}

# ---------------------------------------------------------
# Prod EC2 (from copied AMI)
# ---------------------------------------------------------
resource "aws_instance" "prod" {
  provider               = aws.prod
  ami                    = aws_ami_copy.cafe_ami_copy.id
  instance_type          = var.instance_type_prod
  subnet_id              = data.aws_subnets.prod.ids[0]
  vpc_security_group_ids = [aws_security_group.cafe_sg_prod.id]
  iam_instance_profile   = aws_iam_instance_profile.cafe_profile.name
  key_name               = aws_key_pair.cafe_key.key_name
  tags = {
    Name = "${var.project_prefix}-prod"
  }

  depends_on = [aws_ami_copy.cafe_ami_copy]
}

# ---------------------------------------------------------
# After Prod is up, create Secrets in Prod region with correct publicDNS
# (App expects these in the region it runs)
# ---------------------------------------------------------
resource "aws_secretsmanager_secret" "prod_dbUser" {
  provider = aws.prod
  name     = "/cafe/dbUser"
}
resource "aws_secretsmanager_secret_version" "prod_dbUser_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_dbUser.id
  secret_string = jsonencode({ value = var.db_user })
}

resource "aws_secretsmanager_secret" "prod_dbPassword" {
  provider = aws.prod
  name     = "/cafe/dbPassword"
}
resource "aws_secretsmanager_secret_version" "prod_dbPassword_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_dbPassword.id
  secret_string = jsonencode({ value = random_password.db_password.result })
}

resource "aws_secretsmanager_secret" "prod_dbHost" {
  provider = aws.prod
  name     = "/cafe/dbHost"
}
resource "aws_secretsmanager_secret_version" "prod_dbHost_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_dbHost.id
  secret_string = jsonencode({ value = aws_instance.prod.public_ip })
}

resource "aws_secretsmanager_secret" "prod_dbName" {
  provider = aws.prod
  name     = "/cafe/dbName"
}
resource "aws_secretsmanager_secret_version" "prod_dbName_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_dbName.id
  secret_string = jsonencode({ value = var.db_name })
}

resource "aws_secretsmanager_secret" "prod_region" {
  provider = aws.prod
  name     = "/cafe/region"
}
resource "aws_secretsmanager_secret_version" "prod_region_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_region.id
  secret_string = jsonencode({ value = var.prod_region })
}

resource "aws_secretsmanager_secret" "prod_publicDNS" {
  provider = aws.prod
  name     = "/cafe/publicDNS"
}
resource "aws_secretsmanager_secret_version" "prod_publicDNS_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_publicDNS.id
  secret_string = jsonencode({ value = aws_instance.prod.public_dns })
}

resource "aws_secretsmanager_secret" "prod_extra" {
  provider = aws.prod
  name     = "/cafe/extraParam"
}
resource "aws_secretsmanager_secret_version" "prod_extra_ver" {
  provider      = aws.prod
  secret_id     = aws_secretsmanager_secret.prod_extra.id
  secret_string = jsonencode({ value = "extra" })
}

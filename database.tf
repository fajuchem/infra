resource "aws_kms_key" "db" {
  description = "Database credentials"
}

resource "aws_db_instance" "db" {
  identifier_prefix           = "db"
  allocated_storage           = 20
  engine                      = "postgres"
  instance_class              = "db.t3.micro"
  username                    = "postgres"
  manage_master_user_password = true
  # doesn't seems to work
  #master_user_secret = [{
  #  kms_key_id = aws_secretsmanager_secret.this.kms_key_id
  #  secret_status = "active"
  #  secret_arn = aws_secretsmanager_secret.this.arn
  #}]
  master_user_secret_kms_key_id = aws_kms_key.db.key_id
  skip_final_snapshot           = true
  #publicly_accessible           = true
  apply_immediately = true

  #db_subnet_group_name = module.vpc.database_subnet_group_name
  #vpc_security_group_ids = [vpc-07abf96726e463cd0]
  #vpc_security_group_ids = ["sg-00da8069c7303975b"]
}

#data "aws_availability_zones" "available" {}
#
#module "tgw" {
#  source  = "terraform-aws-modules/transit-gateway/aws"
#  version = "~> 2.0"
#
#  name        = "my-tgw"
#  description = "My TGW shared with several other AWS accounts"
#
#  enable_auto_accept_shared_attachments = true
#
#  vpc_attachments = {
#    vpc = {
#      vpc_id       = module.vpc.vpc_id
#      subnet_ids   = module.vpc.private_subnets
#      dns_support  = true
#      ipv6_support = true
#
#      tgw_routes = [
#        {
#          destination_cidr_block = "30.0.0.0/16"
#        },
#        {
#          blackhole              = true
#          destination_cidr_block = "40.0.0.0/20"
#        }
#      ]
#    }
#  }
#
#  ram_allow_external_principals = true
#  ram_principals                = [307990089504]
#
#  tags = {
#    Purpose = "tgw-complete-example"
#  }
#}

#module "vpc" {
#  source  = "terraform-aws-modules/vpc/aws"
#  version = "~> 3.0"
#
#  name = "my-vpc"
#
#  cidr = "10.10.0.0/16"
#
#  azs             = data.aws_availability_zones.available.names
#  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
#
#  enable_ipv6                                    = true
#  private_subnet_assign_ipv6_address_on_creation = true
#  private_subnet_ipv6_prefixes                   = [0, 1, 2]
#
#  create_database_subnet_group           = true
#  create_database_subnet_route_table     = true
#  create_database_internet_gateway_route = true
#
#  enable_dns_hostnames = true
#  enable_dns_support   = true
#}

#module "vpc" {
#  source  = "terraform-aws-modules/vpc/aws"
#  version = "~> 3.0"
#
#  cidr                                           = "10.0.0.0/16"
#  azs                                            = data.aws_availability_zones.available.names
#  public_subnets                                 = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#  enable_ipv6                                    = true
#  private_subnet_assign_ipv6_address_on_creation = true
#  private_subnet_ipv6_prefixes                   = [0, 1, 2]
#
#  create_database_subnet_group           = true
#  create_database_subnet_route_table     = true
#  create_database_internet_gateway_route = true
#  create_igw                             = true
#
#  enable_dns_hostnames = true
#  enable_dns_support   = true
#}

resource "aws_db_proxy" "this" {
  name                = "rds-proxy"
  debug_logging       = false
  engine_family       = "POSTGRESQL"
  idle_client_timeout = 1800
  require_tls         = true
  vpc_security_group_ids = ["sg-0e99c36e7cd010d73"]
  vpc_subnet_ids = ["subnet-0ce7fa3b0bbb8cf5f", "subnet-0dc166451b0cbc35c", "subnet-019555a5e4380b63a"]
  role_arn       = aws_iam_role.rds_proxy.arn

  auth {
    auth_scheme = "SECRETS"
    description = "secret auth"
    iam_auth    = "DISABLED"
    # todo: get the secret arn from aws_db_instace somehow, hardcoded for now
    #secret_arn = "arn:aws:secretsmanager:sa-east-1:097543692097:secret:rds!db-2fa8ae5a-5d9d-4f63-97b0-50ad4cf417df-GNjXp3"
    secret_arn = aws_db_instance.db.master_user_secret[0].secret_arn

  }
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    init_query                   = "SET x=1, y=2"
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }
}

resource "aws_db_proxy_target" "this" {
  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_instance_identifier = aws_db_instance.db.id
}

resource "aws_iam_role" "rds_proxy" {
  name = "rds_proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "rds.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "rds_proxy_iam" {
  name = "rds_proxy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [
              "arn:aws:secretsmanager:*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "secretsmanager.*.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "rds_policy" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = aws_iam_policy.rds_proxy_iam.arn
}

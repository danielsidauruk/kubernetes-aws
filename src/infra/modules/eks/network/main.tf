# --- Data & Locals ---
data "aws_availability_zones" "main" {
  state = "available"
}

locals {
  az_names = slice(data.aws_availability_zones.main.names, 0, var.az_count)

  # { "us-east-1a" = "10.0.x.x", ... }
  private_subnet_map = {
    for i, az_name in local.az_names : az_name => cidrsubnet(var.cidr_block, 3, i)
  }

  public_subnet_map = {
    for i, az_name in local.az_names : az_name => cidrsubnet(var.cidr_block, 3, i + var.az_count)
  }
}

# --- VPC & Networking ---
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# --- Subnets ---
resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true
}

# --- NAT Gateway ---
resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id

  depends_on = [aws_internet_gateway.main]
}

# --- Route Tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# --- Route Table Associations ---
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# --- VPC Endpoints ---
resource "aws_security_group" "vpc_endpoint" {
  name        = "vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint" {
  security_group_id = aws_security_group.vpc_endpoint.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster" {
  security_group_id = aws_security_group.vpc_endpoint.id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_block
  from_port         = 443
  to_port           = 443
  description       = "Allow backend to access Secrets Manager"
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.primary_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
}

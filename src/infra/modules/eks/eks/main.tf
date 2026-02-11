# --- EKS Cluster Security Group ---
resource "aws_security_group" "eks_cluster" {
  name        = "cluster"
  description = "Security group for Kubernetes cluster"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster" {
  security_group_id = aws_security_group.eks_cluster.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster" {
  security_group_id = aws_security_group.eks_cluster.id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_block
  from_port         = 443
  to_port           = 443
  description       = "Allow HTTPS Access to Cluster."
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodeport_tcp" {
  security_group_id = aws_security_group.eks_cluster.id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_block
  from_port         = 30000
  to_port           = 32768
  description       = "Allow NodePort TCP Traffic."
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodeport_udp" {
  security_group_id = aws_security_group.eks_cluster.id
  ip_protocol       = "udp"
  cidr_ipv4         = var.cidr_block
  from_port         = 30000
  to_port           = 32768
  description       = "Allow NodePort UDP Traffic."
}

resource "aws_security_group" "eks_nodes" {
  name        = "cluster-nodes"
  description = "Allow access to Cluster Nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port = 0
    to_port   = 0

    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }
}

resource "aws_security_group_rule" "eks_nodes" {
  security_group_id = aws_security_group.eks_nodes.id
  type              = "ingress"
  cidr_blocks       = [var.cidr_block]
  from_port         = 30000
  to_port           = 32768
  description       = "Nodeport tcp"
  protocol          = "tcp"
}

# --- EKS Cluster IAM ---
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_cluster.name
}


resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",                  # CNI
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",    # ECR
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",           # Cloudwatch Agent
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy", # CSI Driver
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_nodes.name
}


# --- Workload Identity IAM ---
data "tls_certificate" "workload_identity" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "workload_identity" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.workload_identity.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.workload_identity.url
}

resource "aws_iam_role" "workload_identity" {
  name = "workload-identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"

      Principal = {
        Federated = aws_iam_openid_connect_provider.workload_identity.arn
      }

      Condition = {
        StringEquals = {
          "${replace(
            aws_iam_openid_connect_provider.workload_identity.url,
            "https://",
            ""
          )}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "workload_identity" {
  name = "workload-identity"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]

      Resource = [var.secret_arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "workload_identity" {
  role       = aws_iam_role.workload_identity.name
  policy_arn = aws_iam_policy.workload_identity.arn
}

# --- EBS CSI Driver IAM ---
resource "aws_iam_role" "ebs_csi_driver" {
  name = "ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"

      Principal = {
        Federated = aws_iam_openid_connect_provider.workload_identity.arn
      }

      Condition = {
        StringLike = {
          "${replace(
            aws_iam_openid_connect_provider.workload_identity.url,
            "https://",
            ""
          )}:sub" = "system:serviceaccount:kube-system:ebs-csi-*"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "ebs_csi_driver" {
  name = "ebs-csi-driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ]
      Resource = ["*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [aws_eks_node_group.eks_nodes]
}

resource "aws_eks_access_entry" "console_user" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = var.eks_admin_arn
  kubernetes_groups = [var.kubernetes_group] # example: ["eks-console-access-group"] 
  type              = "STANDARD"
}

# --- EKS Node Group ---
resource "aws_eks_node_group" "eks_nodes" {
  for_each = {
    app = "application"
    # redis    = "redis"
    # postgres = "postgres"
  }

  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "ng-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_nodes[each.key].id
    version = aws_launch_template.eks_nodes[each.key].latest_version
  }

  labels = {
    role = each.value
  }

  depends_on = [aws_iam_role_policy_attachment.eks_nodes]
}

resource "aws_launch_template" "eks_nodes" {
  for_each = {
    app = 20
    # redis    = 20
    # postgres = 20
  }

  name = "eks-template-${each.key}"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = each.value
      volume_type = "gp3"
      iops        = 3000
      throughput  = 125
    }
  }
}

# --- EKS CloudWatch Log Group ---
# resource "aws_cloudwatch_log_group" "container_cluster" {
#   name              = "/aws/eks/${var.cluster_name}/cluster"
#   retention_in_days = 7
# }

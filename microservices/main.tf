provider "aws"{
  region = "us-east-1"
}

provider "helm" {
    kubernetes = {
        host  = data.aws_eks_cluster.eks_cluster.endpoint
        token = data.aws_eks_cluster_auth.eks_auth.token
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
        load_config_file = false
    }
}

provider "kubernetes" {
    host  = data.aws_eks_cluster.eks_cluster.endpoint
    token = data.aws_eks_cluster_auth.eks_auth.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    load_config_file = false
    }
}



resource "aws_vpc" "vpcdemo" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myvpc"
  }
  enable_dns_hostnames = true # if not enabled, we can't resolve dns names
}

resource "aws_subnet" "pubsubnet" {
  vpc_id     = aws_vpc.vpcdemo.id
  count      = 2                     #Note

  cidr_block = ["10.0.0.0/24","10.0.1.0/24"][count.index]                #Note
  availability_zone = ["us-east-1a","us-east-1b"][count.index]  #Note
  map_public_ip_on_launch = true   # to indicate that instances launched into the subnet should be assigned a public IP address
  
  tags = {
    Name = "publicsubnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpcdemo.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "pub_route_table" {
  vpc_id = aws_vpc.vpcdemo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public route table"
  }
}


resource "aws_route_table_association" "associate_with_pub_subnet" {
  count          = 2                            #NOTE
  subnet_id      = element(aws_subnet.pubsubnet[*].id, count.index)   #NOTE
  route_table_id = aws_route_table.pub_route_table.id
}


resource "aws_subnet" "prv_subnet" {
  vpc_id     = aws_vpc.vpcdemo.id
  #count      = 2                      #Note

  cidr_block = "10.0.2.0/24"               #Note
  availability_zone = "us-east-1c"  #Note
  map_public_ip_on_launch = false   # to indicate that instances launched into the subnet should not be assigned a public IP address
  
  tags = {
    Name = "prvsubnet"
  }
}

resource "aws_route_table" "priv_route_table" {
  vpc_id = aws_vpc.vpcdemo.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.nat.id
#   }

  tags = {
    Name = "private route table"
  }
}

resource "aws_route_table_association" "associate_with_prv_subnet" {
  #count          = 2 
  subnet_id      = aws_subnet.prv_subnet.id
  route_table_id = aws_route_table.priv_route_table.id
}

#################################### CREATE EKS CLUSTER ###################################

resource "aws_eks_cluster" "myekscluster" {
  name = "myekscluster"

#  access_config {
#    authentication_mode = "API"
# }

  role_arn = aws_iam_role.eksclusterrole.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [aws_subnet.prv_subnet.id]
# endpoint_private_access = false  #For a fully private cluster where kubectl access must happen from within the VPC (e.g., via a bastion host or VPN), you must:Set endpoint_private_access = true on the aws_eks_cluster resource and endpoint_public_access = false.

#    endpoint_public_access  = true
  }

  # Enable desired log types for the control plane to send to cloudwatch
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_cloudwatch_log_group.eks_cluster_log_group,
  ]
}


########################### CREATE EKS NODE GROUP ###################################

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.myekscluster.name
  node_group_name = "nodegroup"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.prv_subnet.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

 # update_config {
 #   max_unavailable = 1
 # }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy_1,
    aws_iam_role_policy_attachment.eks_node_policy_2,
    aws_iam_role_policy_attachment.eks_node_policy_3,
  ]
}


########################### EKS Cluster IAM Role ##########################################

resource "aws_iam_role" "eksclusterrole" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksclusterrole.name
}



############################ EKS Node Group Role ###########################
resource "aws_iam_role" "eks_node_role" {
  name = "${aws_eks_cluster.myekscluster.name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_1" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_2" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_3" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


 ########################################## EKS Control Plane Logging  ######################################################

# You need a log group to manage the retention policy for the EKS logs.
# EKS automatically creates the log streams within this log group.
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  # The log group name must be in the format /aws/eks/<cluster-name>/cluster
  name              = "/aws/eks/${aws_eks_cluster.myekscluster.name}/cluster"
  retention_in_days = 1 # Customize retention as needed.
}

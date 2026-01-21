module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  # v21.x input names
  name               = local.cluster_name
  kubernetes_version = "1.34"

  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  endpoint_public_access = true

  # Enable new EKS access management (v21+)
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # Allow EKS managed node groups to join the cluster
    nodegroup = {
      principal_arn = module.eks.eks_managed_node_groups["one"].iam_role_arn
      type          = "EC2_LINUX"

      policy_associations = {
        worker = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSWorkerNodePolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # Allow GitHub Actions / your IAM user to access the cluster
    admin = {
      principal_arn = data.aws_caller_identity.current.arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      # Starting on 1.30, AL2023 is the default for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

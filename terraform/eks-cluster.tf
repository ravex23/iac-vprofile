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
  authentication_mode                      = "API_AND_CONFIG_MAP"

  # EKS add-ons (recommended by module docs). Using before_compute ensures
  # critical networking components are ready before node groups are created.
  addons = {
    coredns = {}

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  access_entries = {
    # Human/admin access to the Kubernetes API (EKS Access API, v21+)
    admin = {
      principal_arn = "arn:aws:iam::182399705651:user/gitops"
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

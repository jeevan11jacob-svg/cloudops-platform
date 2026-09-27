module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr     = "10.0.0.0/16"
  project_name = var.project_name
  environment  = var.environment
}
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}
module "eks" {
  source = "../../modules/eks"

  project_name              = var.project_name
  environment               = var.environment
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  node_role_arn             = module.iam.eks_node_role_arn
  private_subnet_ids        = module.vpc.private_subnet_ids
  jenkins_security_group_id = module.jenkins.security_group_id
}
module "jenkins" {
  source = "../../modules/jenkins"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.public_subnet_ids[0]
  ami_id       = "ami-090b1140798d2d006"
}
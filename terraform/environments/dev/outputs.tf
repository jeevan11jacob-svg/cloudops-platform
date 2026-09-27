output "vpc_id" {
  description = "ID of the CloudOps Platform VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the CloudOps Platform VPC"
  value       = module.vpc.vpc_cidr
}
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}
output "eks_node_group_name" {
  description = "Name of the EKS managed node group"
  value       = module.eks.node_group_name
}
output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = module.jenkins.public_ip
}
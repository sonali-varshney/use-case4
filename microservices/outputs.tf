output "cluster_name" {
  value = aws_eks_cluster.myekscluster #module.eks.cluster_id
}

# output "kubeconfig_command" {
#   value = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_id}"
# }

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.myekscluster # module.eks.cluster_endpoint
}

output "pubsubnet"{
    value = aws_subnet.pubsubnet[*].id
}

output "vpcid"{
    value = aws_vpc.vpcdemo.id
}

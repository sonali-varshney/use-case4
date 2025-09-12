module "ec2"{
    source = "./ec2"
    pub_cidr_block = var.pub_cidr_block
    ami = var.ami
    instance_type = var.instance_type
    subnet_pub_id = module.vpc.pubsubnet
    ec2_sec_gp = [module.secgp.ec2_sec_gp]   #Note it returns a set of string that's why [] me likha h
    subnet_id = module.vpc.pubsubnet          # NOTE
    web_sec_gp_name = var.web_sec_gp_name
    ec2_sec_gp_name = var.ec2_sec_gp_name
}

module "alb"{
    source = "./alb"
    vpc_id = module.vpc.vpcid
    target_group_port = var.target_group_port
    protocol = var.protocol
    health_check_path = var.health_check_path
    alb_name = var.alb_name
    alb_sec_gp = [module.secgp.alb_sec_gp]
    pubsubnet = module.vpc.pubsubnet
    pub_cidr_block = var.pub_cidr_block
    listener_port = var.listener_port
    listener_protocol = var.listener_protocol
    ec2_id = module.ec2.ec2_id
}

module "vpc"{
    source = "./vpc"
    cidr_block = var.cidr_block
    vpc_name = var.vpc_name
    pub_cidr_block = var.pub_cidr_block
    pub_availability_zone = var.pub_availability_zone
    #prv_availability_zone = var.prv_availability_zone
    igw_name = var.igw_name
    #prv_cidr_block = var.prv_cidr_block
}

module "secgp"{
    source = "./secgp"
    vpc_id = module.vpc.vpcid
    web_sec_gp_name = var.web_sec_gp_name
    ec2_sec_gp_name = var.ec2_sec_gp_name
    alb_sec_gp_name = var.alb_sec_gp_name
    alb_ingress_port = var.alb_ingress_port
    ssh_port = var.ssh_port
    http_port = var.http_port
    container_port = var.container_port
}

resource "aws_vpc" "vpcdemo" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc_name
  }
  enable_dns_hostnames = true # if not enabled, we can't resolve dns names
}

resource "aws_subnet" "pubsubnet" {
  vpc_id     = aws_vpc.vpcdemo.id
  count      = length(var.pub_cidr_block)                      #Note

  cidr_block = var.pub_cidr_block[count.index]                #Note
  availability_zone = var.pub_availability_zone[count.index]  #Note
  map_public_ip_on_launch = true   # to indicate that instances launched into the subnet should be assigned a public IP address
  
  tags = {
    Name = "publicsubnet-${var.pub_availability_zone[count.index]}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpcdemo.id

  tags = {
    Name = var.igw_name
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
  count          = length(var.pub_cidr_block)                             #NOTE
  subnet_id      = element(aws_subnet.pubsubnet[*].id, count.index)   #NOTE
  route_table_id = aws_route_table.pub_route_table.id
}



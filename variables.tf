variable "pub_cidr_block"{
    type = list
    default = ["10.0.0.0/24","10.0.1.0/24"]
}

variable "pub_availability_zone"{
    type = list
    default = ["us-east-1a","us-east-1b"]
}

variable "cidr_block"{
    
default = "10.0.0.0/16"

}

variable "vpc_name"{
    default = "myvpc"
}


variable "igw_name"{
    default = "myigw"
}


variable "web_sec_gp_name"{
    default = "web_sec_gp"
}

variable "ec2_sec_gp_name"{
    default = "ec2_secgp" 
}

variable "ssh_port"{
    default = "22"
}

variable "http_port"{
    default = "80"
}
variable "db_sec_gp_name"{
    default = "db_sec_gp"
}

variable "allocated_storage"{
    default = 10
}
variable "db_name"{
    default = "mydb"
}
variable "engine"{
    default = "mysql"
}
variable "engine_version"{
    default = "8.0"
}
variable "instance_class"{
    default = "db.t3.micro"
}
variable "username"{
    default = "foo"
}
variable "password"{
    default ="foobarbaz"
}

variable "ami"{
    default = "ami-00ca32bbc84273381"
}

variable "instance_type"{
    default = "m7i-flex.large"
}

variable "target_group_port" {
    default = 8080
}

variable "protocol" {
    default = "HTTP"
}

variable "health_check_path" {
    default = "/login"
}
variable "alb_name" {
    default = "myalb"
}

variable "alb_sec_gp_name" {
    default = "alb_sec_gp"
}
variable "alb_ingress_port" {
    default = 80
}
variable "listener_port" {
    default = 80
}
variable "listener_protocol" {
    default = "HTTP"
}

variable "container_port"{
    default = 8080
}
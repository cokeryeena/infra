provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devops-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for K8s Nodes
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-nodes-sg"
  description = "Allow SSH and K8s traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["54.165.147.166/32"]
  }

  ingress {
    description = "Kubernetes API / App"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-security-group"
  }
}

# EC2 Instances for K8s Nodes
resource "aws_instance" "k8s_nodes" {
  count                   = 2
  ami                     = data.aws_ami.ubuntu_2204.id
  instance_type           = "t3.micro"
  subnet_id               = aws_subnet.public.id
  key_name                = "devops-key"
  vpc_security_group_ids  = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-node-${count.index + 1}"
  }
}

# Output Public IPs
output "k8s_node_public_ips" {
  value = aws_instance.k8s_nodes[*].public_ip
}

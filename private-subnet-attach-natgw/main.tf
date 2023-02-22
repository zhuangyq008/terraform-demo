terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
}
# 创建一个VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# 创建一个Internet网关
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# 创建一个公共子网
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

# 创建两个私有子网
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.3.0/24"
}

# 创建一个NAT网关
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.example.id
  subnet_id     = aws_subnet.public.id
}

# 创建一个弹性IP
resource "aws_eip" "example" {
  vpc = true
}

# 配置路由表
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }
}

# 将私有子网与路由表关联
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

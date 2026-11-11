resource "aws_vpc" "dr_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "vegah-dr-vpc"
  })
}

resource "aws_subnet" "dr_public_subnet" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.dr_availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "vegah-dr-public-subnet"
  })
}

resource "aws_internet_gateway" "dr_igw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = merge(local.common_tags, {
    Name = "vegah-dr-igw"
  })
}

resource "aws_route_table" "dr_route_table" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }

  tags = merge(local.common_tags, {
    Name = "vegah-dr-route-table"
  })
}

resource "aws_route_table_association" "dr_route_association" {
  subnet_id      = aws_subnet.dr_public_subnet.id
  route_table_id = aws_route_table.dr_route_table.id
}

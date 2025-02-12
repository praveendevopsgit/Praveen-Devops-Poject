provider "aws" {
  region = "us-west-2"  
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = element(["us-west-2a", "us-west-2b", "us-west-2c"], count.index)
  map_public_ip_on_launch = true
}


resource "aws_subnet" "private" {
  count = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index + 3)  # Start after public subnets
  availability_zone = element(["us-west-2a", "us-west-2b", "us-west-2c"], count.index)
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}


resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.main.id
}


resource "aws_eip" "nat" {
  count = 3
  domain = "vpc"
}


resource "aws_nat_gateway" "main" {
  count = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}


resource "aws_route" "nat_route" {
  count               = 3
  route_table_id      = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id      = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}




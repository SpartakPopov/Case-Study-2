resource "aws_vpc" "internal_vpc" {
  cidr_block           = "10.0.2.0/23"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-internal"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "vpc-internal-web-subnet-a"
  }

}

resource "aws_subnet" "web_b" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.2.64/26"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "vpc-internal-web-subnet-b"
  }
}

resource "aws_subnet" "monitoring" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.2.128/26"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "vpc-internal-monitoring-subnet"
  }
}

resource "aws_subnet" "data_a" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.2.192/27"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "vpc-internal-data-subnet-a"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.2.224/27"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "vpc-internal-data-subnet-b"
  }
}

resource "aws_subnet" "soar_a" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.3.0/27"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "vpc-internal-soar-subnet-a"
  }
}

resource "aws_subnet" "soar_b" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.3.32/27"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "vpc-internal-soar-subnet-b"
  }
}

resource "aws_subnet" "dns_a" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.3.64/28"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "vpc-internal-dns-subnet-a"
  }
}

resource "aws_subnet" "dns_b" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.3.80/28"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "vpc-internal-dns-subnet-b"
  }
}

resource "aws_subnet" "transit_gateway_internal_a" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.3.96/28"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "vpc-internal-transit-gateway-a"
  }
}

resource "aws_subnet" "transit_gateway_internal_b" {
  vpc_id            = aws_vpc.internal_vpc.id
  cidr_block        = "10.0.3.112/28"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "vpc-internal-transit-gateway-b"
  }
}


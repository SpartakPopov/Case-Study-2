resource "aws_vpc" "vpc-dmz" {
    cidr_block           = "10.0.1.0/24"
    tags = {
        Name = "vpc-dmz"
    }
}

resource "aws_subnet" "dmz_public_a" {
    vpc_id                  = aws_vpc.vpc-dmz.id
    cidr_block              = "10.0.1.0/26"
    availability_zone       = "eu-central-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "vpc-dmz-public-subnet-a"
    }
}

resource "aws_subnet" "dmz_public_b"{
    vpc_id                  = aws_vpc.vpc-dmz.id
    cidr_block              = "10.0.1.64/26"
    availability_zone       = "eu-central-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "vpc-dmz-public-subnet-b"
    }
}

resource "aws_subnet" "nat" {
    vpc_id                  = aws_vpc.vpc-dmz.id
    cidr_block              = "10.0.1.128/26"
    availability_zone       = "eu-central-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "vpc-dmz-nat-subnet"
    }
}

resource "aws_subnet" "transit_gateway_subnet_a" {
  vpc_id            = aws_vpc.vpc-dmz.id
  cidr_block        = "10.0.1.192/28"
  availability_zone = "eu-central-1a"
  tags              = { 
    Name = "vpc-dmz-transit-gateway-subnet-a" 
    }
}

resource "aws_subnet" "transit_gateway_subnet_b" {
  vpc_id            = aws_vpc.vpc-dmz.id
  cidr_block        = "10.0.1.208/28"
  availability_zone = "eu-central-1b"
  tags              = { 
    Name = "vpc-dmz-transit-gateway-subnet-b" 
    }
}



resource "aws_internet_gateway" "innovatech_igw" {
    vpc_id = aws_vpc.vpc-dmz.id
    tags = {
        Name = "innovatech-igw"
    }
}

resource "aws_eip" "nat_eip" {
    domain = "vpc"
    tags = {
        Name = "innovatech-nat-eip"
    }
}

resource "aws_nat_gateway" "innovatech_nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id     = aws_subnet.nat.id
    depends_on = [aws_internet_gateway.innovatech_igw]
    tags = {
        Name = "innovatech-nat"
    }
}
resource "aws_vpc" "test-vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_route_table" "public_routetable" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public_routetable.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.private-subnet.id
}

resource "aws_route_table" "private_routetable" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private_routetable.id
}

resource "aws_security_group" "SG" {
  name_prefix = "web-sg"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "s3-bucket" {
  bucket = "terraform-test-pr"
}

resource "aws_instance" "server-1" {
  ami                    = "ami-0522ab6e1ddcc7055"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id              = aws_subnet.public-subnet.id
  user_data              = base64encode(file("script1.sh"))
}

resource "aws_instance" "server-2" {
  ami                    = "ami-0522ab6e1ddcc7055"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id              = aws_subnet.private-subnet.id
  user_data              = base64encode(file("script2.sh"))
}
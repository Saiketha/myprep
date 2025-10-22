variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_cidrs" { default = ["10.0.1.0/24", "10.0.3.0/24"] }
variable "private_cidrs"{ default = ["10.0.2.0/24", "10.0.4.0/24"] }
variable "availability_zones" { default = ["us-east-1a","us-east-1b"] }

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "example-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "example-igw" }
}

# public subnets (one per AZ)
resource "aws_subnet" "public" {
  for_each = toset(var.public_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.key
  availability_zone = element(var.availability_zones, index(toset(var.public_cidrs), each.key))
  map_public_ip_on_launch = true
  tags = { Name = "public-${each.key}" }
}

# private subnets (one per AZ)
resource "aws_subnet" "private" {
  for_each = toset(var.private_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.key
  availability_zone = element(var.availability_zones, index(toset(var.private_cidrs), each.key))
  map_public_ip_on_launch = false
  tags = { Name = "private-${each.key}" }
}

# Elastic IP for NAT (one per AZ in this simple example uses 1 NAT; you can create one per AZ)
resource "aws_eip" "nat_eip" {
  vpc = true
}

# NAT Gateway in first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(keys(aws_subnet.public)[0], 0) == "" ? aws_subnet.public[0].id : aws_subnet.public[values(aws_subnet.public)[0]].id
  # Simpler: use first value:
  subnet_id = element(values(aws_subnet.public), 0).id
  tags = { Name = "example-nat" }
  depends_on = [aws_internet_gateway.igw]
}

# Public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

# Associate public subnets with public RT
resource "aws_route_table_association" "pub_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# Private route table -> NAT
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "private-rt" }
}

resource "aws_route_table_association" "priv_assoc" {
  for_each = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

# Security group for bastion (allow SSH from your IP)
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_PUBLIC_IP/32"] # replace with your IP
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for private app instances (allow only from bastion and internal)
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "SSH from bastion"
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"]
  }
}

# Key pair (local public key must exist)
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Bastion host in public subnet
resource "aws_instance" "bastion" {
  ami                    = "ami-0c94855ba95c71c99" # example; replace
  instance_type          = "t3.micro"
  subnet_id              = element(values(aws_subnet.public), 0).id
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = { Name = "bastion" }
}

# Private app instance in private subnet
resource "aws_instance" "app" {
  ami                    = "ami-0c94855ba95c71c99" # replace
  instance_type          = "t3.small"
  subnet_id              = element(values(aws_subnet.private), 0).id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  associate_public_ip_address = false
  tags = { Name = "private-app" }
}

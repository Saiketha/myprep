# count example: create N identical resources
variable "num_instances" { default = 2 }
resource "aws_instance" "count_example" {
  count = var.num_instances
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t3.micro"
  subnet_id     = element(values(aws_subnet.public), count.index).id
  tags = { Name = "count-instance-${count.index}" }
}

# for_each example: map of hostnames -> cidr
variable "named_subnets" {
  default = {
    web  = "10.0.10.0/24"
    db   = "10.0.11.0/24"
  }
}

resource "aws_subnet" "for_each_example" {
  for_each = var.named_subnets
  vpc_id   = aws_vpc.main.id
  cidr_block = each.value
  tags = { Name = "subnet-${each.key}" }
}

# count example: create N identical resources
variable "num_instances" { 
  default = {"db", "web"}
  }

resource "aws_instance" "count_example" {
  count = lenght(var.num_instances)
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t3.micro"
  tags = { 
    Name = "count-instance-$var.name{count.index}" 
    }
}

# for_each example: map of hostnames -> cidr
variable "my-instances" {
  default = {
    web  = "t2.micro"
    db   = "t2.nano"
  }
}

resource "aws_instance" "example" {
  foreach = var.my-instances
  instance_type = each.value
  ami = "ami-0c94855ba95c71c99"
  tags = {
    Name = each.key
  }
}



resource "null_resource" "example_provision" {
  provisioner "local-exec" {
    command = "echo hello > /tmp/hello.txt"
  }

  provisioner "file" {
    source     = "some source"
    destination = "/tmp/from-terraform.txt"
  }

  # remote-exec example (requires connection)
  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "whoami",
      "uname -a"
    ]
  }

  # Only run when instance changes
  triggers = {
    instance_id = aws_instance.bastion.id
  }
}

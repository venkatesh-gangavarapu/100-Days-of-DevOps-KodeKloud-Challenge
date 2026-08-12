# Generate RSA key pair in Terraform
resource "tls_private_key" "nautilus_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload public key to AWS
resource "aws_key_pair" "nautilus_kp" {
  key_name   = "nautilus-kp"
  public_key = tls_private_key.nautilus_key.public_key_openssh
}

# Read existing default security group
data "aws_security_group" "default" {
  name = "default"
}

# Launch the instance
resource "aws_instance" "nautilus_ec2" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.nautilus_kp.key_name
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = { Name = "nautilus-ec2" }
}

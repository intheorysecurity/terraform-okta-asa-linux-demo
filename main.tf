data "aws_ami" "ubuntu_image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "oktaasa_project" "asa_project" {
  project_name = "linux-project"
}

resource "oktaasa_enrollment_token" "enrollment_token" {
  project_name = oktaasa_project.asa_project.project_name
  description  = "ASA enrollment token for project"
}

resource "oktaasa_create_group" "group_name" {
  name = "linux-team"
}

resource "oktaasa_assign_group" "group-assignment" {
  project_name  = oktaasa_project.asa_project.project_name
  group_name    = oktaasa_create_group.group_name.name
  server_access = true
  server_admin  = true
}

//create new Security group
resource "aws_security_group" "security_group" {
  name = "ASA Linux Security Group"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.aws_environment_tag
  }
}

//create EC2 instance
resource "aws_instance" "ec2_instance" {
  //ami             = var.aws_instance_ami
  ami             = data.aws_ami.ubuntu_image.id
  instance_type   = var.aws_instance_type
  security_groups = [aws_security_group.security_group.name]
  user_data       = templatefile("./scripts/sftd-userdata.sh", { sftd_version = var.sftd_version, enrollment_token = oktaasa_enrollment_token.enrollment_token.token_value })
  tags = {
    Environment = var.aws_environment_tag,
    Name        = "ASA Terraform Linux Demo"
  }
}
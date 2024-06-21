provider "aws" {
  region = "us-east-1" # Set to your preferred region
}

resource "aws_iam_role" "example_role" {
  name = "Jenkins-terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "example_profile" {
  name = "Jenkins-terraform"
  role = aws_iam_role.example_role.name
}

resource "aws_security_group" "Jenkins-sg" {
  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000,3000"

  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "Allow TCP traffic"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-sg"
  }
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "example_subnet" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0" # Example AMI ID for us-east-1
  instance_type          = "t2.large"
  key_name               = "Argo key"
  subnet_id              = aws_subnet.example_subnet.id
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./install_jenkins.sh", {})
  iam_instance_profile   = aws_iam_instance_profile.example_profile.name

  tags = {
    Name = "Jenkins Server"
  }

  root_block_device {
    volume_size = 30
  }
}

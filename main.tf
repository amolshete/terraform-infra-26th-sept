terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-214234234324"
    key    = "terraform-state.tfstate"
    region = "ap-south-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

/*
# resource "aws_instance" "web" {
#   ami           = "ami-0522ab6e1ddcc7055"
#   instance_type = "t2.micro"
#   key_name = "demo-linux-21th-july"

#   tags = {
#     Name = "Terraform machine"
#   }
# }

# resource "aws_eip" "lb" {
#   instance = aws_instance.web.id
#   domain   = "vpc"
# }
*/

#creating the vpc
resource "aws_vpc" "webapp-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Webapp-VPC"
  }
}

#creating the subnets to the above custom vpc

resource "aws_subnet" "webapp-subnet-1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a" 
  map_public_ip_on_launch = true

  tags = {
    Name = "Webapp-subnet-1a"
  }
}


resource "aws_subnet" "webapp-subnet-1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b" 
  map_public_ip_on_launch = true

  tags = {
    Name = "Webapp-subnet-1b"
  }
}

resource "aws_subnet" "webapp-subnet-1c" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c" 

  tags = {
    Name = "Webapp-subnet-1c"
  }
}

# lauching aws ec2 in one of the subnet



#create keypair

resource "aws_key_pair" "webapp-keypair" {
  key_name   = "webapp-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjmom1078bzpsAFRtSBus6GH3gjEXcZo8iL8k7UugcxcCvtFJzCLUuxD4IP9bl+zuFiN8EnrPb6E2Z+l+AgeESRXdSZ10cVmMO/BxLDIu4SMi7PJDn/EObmZhZ4lQ12swUBzfDIPTw2QFH7SZk2GXoQ7TSeeaagBy8Y+6FaLd64CT8RVWE7z2e5ObeS73Lr0F3CiATpt7bf1cgnSUXbaqzOpwpghcaAt0aBWwNC5zxNdflwz28F0KFwJ4XtVg50BRvaNZgkrh0mziMEyNuzh8Gl8LEao8Ek86JRkuqBDHn3EXTn8J39ERn24YQEFsyoCwdbkIKi/LXhK5ytl7QiNBwTm2w3v1DELXYBitaA1t79ovMo8xhEDHzJNOuUSlQUjmj6tIRtVQi+D404mpg7rcTrVsvMOXq0Fvu3HhRknCY7ZbD50EprJyJ8BzmlsuaYY7PkpVU894hsjn2MnAvfEMjwL3pCeMVaa+IzfBn18CT+U0Isqas8FryH1FhtAVuqJk= Amol@DESKTOP-2MVQBON"
}

#creating the security group

resource "aws_security_group" "allow_80_22" {
  name        = "allow_80_22"
  description = "Allow 80 and 22 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.webapp-vpc.id

  tags = {
    Name = "allow_80_22"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.allow_80_22.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_22" {
  security_group_id = aws_security_group.allow_80_22.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_80_22.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#creating Internet GW

resource "aws_internet_gateway" "webapp-IGW" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "webapp-IGW"
  }
}

#creating the Route table

resource "aws_route_table" "webapp-public-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IGW.id
  }

  tags = {
    Name = "Webapp-Public-RT"
  }
}


resource "aws_route_table" "webapp-private-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Webapp-Private-RT"
  }
}


resource "aws_route_table_association" "public-RT-association-1" {
  subnet_id      = aws_subnet.webapp-subnet-1a.id
  route_table_id = aws_route_table.webapp-public-RT.id
}

resource "aws_route_table_association" "public-RT-association-2" {
  subnet_id      = aws_subnet.webapp-subnet-1b.id
  route_table_id = aws_route_table.webapp-public-RT.id
}

resource "aws_route_table_association" "private-RT-association" {
  subnet_id      = aws_subnet.webapp-subnet-1c.id
  route_table_id = aws_route_table.webapp-private-RT.id
}

#creating load balancer

# resource "aws_lb_target_group" "webapp-TG" {
#   name     = "webapp-lb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.webapp-vpc.id 
# }

# resource "aws_lb_target_group_attachment" "target_1" {
#   target_group_arn = aws_lb_target_group.webapp-TG.arn
#   target_id        = aws_instance.webapp-ec2.id
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "target_2" {
#   target_group_arn = aws_lb_target_group.webapp-TG.arn
#   target_id        = aws_instance.webapp-ec2-2.id
#   port             = 80
# }


# resource "aws_lb_listener" "webapp-listener" {
#   load_balancer_arn = aws_lb.webapp-LB.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.webapp-TG.arn
#   }
# }


# resource "aws_lb" "webapp-LB" {
#   name               = "Webapp-LB"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.allow_80_22.id]
#   subnets            = [aws_subnet.webapp-subnet-1a.id, aws_subnet.webapp-subnet-1b.id]

#   #enable_deletion_protection = true

#   tags = {
#     Environment = "production"
#   }
# }


#launch template


resource "aws_launch_template" "webapp-LT" {
  name = "Webapp-LT"
  image_id = "ami-0522ab6e1ddcc7055"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-keypair.id
  vpc_security_group_ids = [aws_security_group.allow_80_22.id]
  

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Webapp-LT-instances"
    }
  }

  user_data = filebase64("example-userdata.sh")
}


# creating the ASG
resource "aws_autoscaling_group" "webapp-asg" {
  #name_prefix = "webapp"
  vpc_zone_identifier = [aws_subnet.webapp-subnet-1a.id, aws_subnet.webapp-subnet-1b.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  target_group_arns = [aws_lb_target_group.webapp-TG-2.arn]

  launch_template {
    id      = aws_launch_template.webapp-LT.id
    version = "$Latest"
  }
}

#creating target group 2

resource "aws_lb_target_group" "webapp-TG-2" {
  name     = "webapp-lb-tg-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id 
}



resource "aws_lb_listener" "webapp-listener-2" {
  load_balancer_arn = aws_lb.webapp-LB-2.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-TG-2.arn
  }
}


resource "aws_lb" "webapp-LB-2" {
  name               = "Webapp-LB-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80_22.id]
  subnets            = [aws_subnet.webapp-subnet-1a.id, aws_subnet.webapp-subnet-1b.id]

  #enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

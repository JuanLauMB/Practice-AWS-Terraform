provider "aws" {
  access_key = "removed on purpose for privacy"
  secret_key = "removed on purpose for privacy"
  region = var.region
}

# create a VPC
resource "aws_vpc" "m1_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  
  tags = {
    Name = "mission 1 VPC"
  }
}
# create internet gateway
resource "aws_internet_gateway" "m1_igw" {
  vpc_id = aws_vpc.m1_vpc.id

  tags = {
    Name = "m1_IGW"
  }
}

# NAT gateway
# private subnets
resource "aws_subnet" "m1_priv_subnet1" {
    vpc_id = aws_vpc.m1_vpc.id
    cidr_block = var.priv_subnet1_cidr
    availability_zone = "ap-southeast-1a"
    tags = {
      "Name" = "m1 private subnet 1"
    }
  
}
resource "aws_subnet" "m1_priv_subnet2" {
    vpc_id = aws_vpc.m1_vpc.id
    cidr_block = var.priv_subnet2_cidr
    availability_zone = "ap-southeast-1b"
    tags = {
      "Name" = "m1 private subnet 2"
    }
  
}

resource "aws_eip" "NAT_eip1" {
    vpc = true
      
}
resource "aws_eip" "NAT_eip2" {
    vpc = true
  
}
resource "aws_nat_gateway" "m1_NAT1" {
  allocation_id = aws_eip.NAT_eip1.id
  subnet_id     = aws_subnet.pub_subnet1.id

  tags = {
    Name = "gw NAT 1"
  }

  depends_on = [aws_internet_gateway.m1_igw]
}
resource "aws_nat_gateway" "m1_NAT2" {
  allocation_id = aws_eip.NAT_eip2.id
  subnet_id     = aws_subnet.pub_subnet2.id

  tags = {
    Name = "gw NAT 2"
  }

  depends_on = [aws_internet_gateway.m1_igw]
}
# private route tables
resource "aws_route_table" "priv_rt1" {
  vpc_id = aws_vpc.m1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.m1_NAT1.id
  }


  tags = {
    Name = "priv route table 1"
  }
}
resource "aws_route_table" "priv_rt2" {
  vpc_id = aws_vpc.m1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.m1_NAT2.id
  }


  tags = {
    Name = "priv route table 2"
  }
}

# associate private route tables
resource "aws_route_table_association" "priv_RT_assoc1" {
    subnet_id = aws_subnet.m1_priv_subnet1.id
    route_table_id = aws_route_table.priv_rt1.id
  
}
resource "aws_route_table_association" "priv_RT_assoc2" {
    subnet_id = aws_subnet.m1_priv_subnet2.id
    route_table_id = aws_route_table.priv_rt2.id
  
}

# public route table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.m1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.m1_igw.id
  }


  tags = {
    Name = "public route table"
  }
}


# create  public subnet
# public subnet 1
resource "aws_subnet" "pub_subnet1" {
  vpc_id     = aws_vpc.m1_vpc.id
  cidr_block = var.pub_subnet1_cidr
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "public subnet 1"
  }
}
# public subnet 2
resource "aws_subnet" "pub_subnet2" {
    vpc_id = aws_vpc.m1_vpc.id
    cidr_block = var.pub_subnet2_cidr
    availability_zone = "ap-southeast-1b"

    tags = {
        Name = "public subnet 2"
    }
  
}
# subnet and route table association
resource "aws_route_table_association" "pub_RT_assoc1" {
  subnet_id      = aws_subnet.pub_subnet1.id
  route_table_id = aws_route_table.pub_rt.id
}
  
resource "aws_route_table_association" "pub_RT_assoc2" {
    subnet_id = aws_subnet.pub_subnet2.id
    route_table_id = aws_route_table.pub_rt.id
  
}

# security groups
# SG for ALB
resource "aws_security_group" "alb_sg" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.m1_vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
   
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_web"
  }
}

# SG for Instances
resource "aws_security_group" "server_sg" {
  name        = "allow_alb_traffic"
  description = "Allow alb inbound traffic"
  vpc_id      = aws_vpc.m1_vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [ aws_security_group.alb_sg.id ]

  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "10.0.0.25/32" ]


  }
   
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_alb"
  }
} 

# SG for Bastion
resource "aws_security_group" "bastion_sg" {
  name        = "allow_ssh"
  description = "Allow ssh inbound"
  vpc_id      = aws_vpc.m1_vpc.id


  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.sship]

  }
   
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_ssh"
  }
} 

# network interface for eIP
resource "aws_network_interface" "bastion_NI" {
  subnet_id       = aws_subnet.pub_subnet1.id
  private_ips     = ["10.0.0.25"]
  security_groups = [aws_security_group.bastion_sg.id]

}

# eIP for bastion host
resource "aws_eip" "bastion-eip" {
    vpc = true
    network_interface = aws_network_interface.bastion_NI.id
    associate_with_private_ip = "10.0.0.25"
    depends_on = [aws_internet_gateway.m1_igw]
}

# iam policy for bastion's access to s3
resource "aws_iam_policy" "s3-fa-pol" {
  name        = "s3-full-access"
  description = "policy to provide s3 access"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": "*"
        }
    ]
})
}

# iam role for bastion
resource "aws_iam_role" "bastion-role" {
  name = "bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

# policy and role attachment
resource "aws_iam_policy_attachment" "bastion-policy-role" {
  name = "bastion attach"
  roles = [aws_iam_role.bastion-role.name]
  policy_arn = aws_iam_policy.s3-fa-pol.arn
  
}

# instance profile for bastion
resource "aws_iam_instance_profile" "bastion-profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion-role.name
}

# Bastion host
resource "aws_instance" "bastion-server" {
    ami = "ami-0f62d9254ca98e1aa"
    instance_type = "t1.micro"
    availability_zone = "ap-southeast-1a"
    key_name = "mission1-main-key"
    iam_instance_profile = aws_iam_instance_profile.bastion-profile.name
    user_data = filebase64("${path.module}/acc_server-key.sh")
    
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.bastion_NI.id
    
    }

    tags = {
      Name = "Bastion host"
    }
  
}

# ALB
resource "aws_lb" "m1_alb" {
  name               = "m1-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.pub_subnet1.id, aws_subnet.pub_subnet2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "alb"
  }
}

# ALB target group nginx
resource "aws_lb_target_group" "m1_tg_nginx" {
  name     = "m1-tg-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.m1_vpc.id
}
# ALB target group apache
resource "aws_lb_target_group" "m1_tg_apache" {
  name     = "m1-tg-apache"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.m1_vpc.id

}

# ALB listener
resource "aws_lb_listener" "m1_alb-listener" {
  load_balancer_arn = aws_lb.m1_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.m1_tg_apache.arn
  }
}


# nginx listener rule
resource "aws_lb_listener_rule" "nginx-rule" {
  listener_arn = aws_lb_listener.m1_alb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.m1_tg_nginx.arn
  }

  condition {
    path_pattern {
      values = ["/nginx*"]
    }
  }
  
}

# apache listener rule
resource "aws_lb_listener_rule" "apache-rule" {
  listener_arn = aws_lb_listener.m1_alb-listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.m1_tg_apache.arn
  }

  condition {
    path_pattern {
      values = ["/apache"]
    }
  }
  
}

# asg launch template
resource "aws_launch_template" "nginx-launch-template" {
  name = "nginx-server"

  image_id = "ami-0f62d9254ca98e1aa"

  instance_type = "t1.micro"

  key_name = "server-key"

  vpc_security_group_ids = [aws_security_group.server_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "nginx server"
    }
  }

  user_data = filebase64("${path.module}/nginxinstall.sh")
}

resource "aws_launch_template" "apache-launch-template" {
  name = "apache-server"

  image_id = "ami-0f62d9254ca98e1aa"

  instance_type = "t1.micro"

  key_name = "server-key"

  vpc_security_group_ids = [aws_security_group.server_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "apache server"
    }
  }

  user_data = filebase64("${path.module}/apacheinstall.sh")
}

# autoscaling group for nginx
resource "aws_autoscaling_group" "nginx_asg" {
  name                      = "nginx-asg"
  max_size                  = 2
  min_size                  = 0
  desired_capacity          = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  termination_policies      = ["OldestInstance"]
  vpc_zone_identifier       = [aws_subnet.m1_priv_subnet1.id, aws_subnet.m1_priv_subnet2.id]
  target_group_arns         = [aws_lb_target_group.m1_tg_nginx.arn]
  launch_template {
    id = aws_launch_template.nginx-launch-template.id  
  }

}

# autoscaling group for apache
resource "aws_autoscaling_group" "apache_asg" {
  name                      = "apache-asg"
  max_size                  = 2
  min_size                  = 0
  desired_capacity          = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  termination_policies      = ["OldestInstance"]
  vpc_zone_identifier       = [aws_subnet.m1_priv_subnet1.id, aws_subnet.m1_priv_subnet2.id]
  target_group_arns         = [aws_lb_target_group.m1_tg_apache.arn]
  launch_template {
    id = aws_launch_template.apache-launch-template.id  
  }

}

# autoscaling out schedule for nginx
resource "aws_autoscaling_schedule" "nginx-sc-out" {
  scheduled_action_name  = "nginxscaleout"
  min_size               = 0
  max_size               = 2
  desired_capacity       = 2
  time_zone              = "Asia/Singapore"
  recurrence             = "00 08 * * 1-7"
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.name
}
# autoscaling in schedule for nginx
resource "aws_autoscaling_schedule" "nginx-sc-in" {
  scheduled_action_name  = "nginxscalein"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  time_zone              = "Asia/Singapore"
  recurrence             = "00 17 * * 1-7"
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.name
}

# autoscaling out schedule for apache
resource "aws_autoscaling_schedule" "apache-sc-out" {
  scheduled_action_name  = "apachescaleout"
  min_size               = 0
  max_size               = 2
  desired_capacity       = 2
  time_zone              = "Asia/Singapore"
  recurrence             = "00 08 * * 1-7"
  autoscaling_group_name = aws_autoscaling_group.apache_asg.name
}
# autoscaling in schedule for apache
resource "aws_autoscaling_schedule" "apache-sc-in" {
  scheduled_action_name  = "apachescalein"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  time_zone              = "Asia/Singapore"
  recurrence             = "00 17 * * 1-7"
  autoscaling_group_name = aws_autoscaling_group.apache_asg.name
}

# RDS SG
resource "aws_security_group" "db_sg" {
  name        = "allow_server"
  description = "Allow server inbound"
  vpc_id      = aws_vpc.m1_vpc.id


  ingress {
    description      = "postgre"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [var.priv_subnet1_cidr, var.priv_subnet2_cidr]

  }
   
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_server"
  }
} 

# DB subnet group
resource "aws_db_subnet_group" "m1-db-sub" {
  name       = "m1-db-sub"
  subnet_ids = [aws_subnet.m1_priv_subnet1.id, aws_subnet.m1_priv_subnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# RDS Instance master (Postgre)
resource "aws_db_instance" "rds_db_master" {
  allocated_storage    = 20
  db_name              = "m1postgremast"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpass
  skip_final_snapshot  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  availability_zone    = "ap-southeast-1a"
  port                 = 5432
  db_subnet_group_name = aws_db_subnet_group.m1-db-sub.name
}
# RDS Instance standby (Postgre)
resource "aws_db_instance" "rds_db_standby" {
  allocated_storage    = 20
  db_name              = "m1postgresdby"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpass
  skip_final_snapshot  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  availability_zone    = "ap-southeast-1b"
  port                 = 5432
  db_subnet_group_name = aws_db_subnet_group.m1-db-sub.name
}





provider "aws" {
  region = "us-east-1"
}

# Vpc
resource "aws_vpc" "main1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  tags = {
    Name = "SEC-vpc"
  }
}
#Subnet
resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.main1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1e"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Red-1"
  }
}
# second sub 
resource "aws_subnet" "sub2" {
  vpc_id     = aws_vpc.main1.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1f"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Red-2"
  }
}

#Intenet gatway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main1.id

  tags = {
    Name = "gateway"
  }
}

#public route 
resource "aws_route_table" "pub-RT" {
  vpc_id = aws_vpc.main1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-rt"
  }
}
#asssociation
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.pub-RT.id
}

# second route
resource "aws_route_table" "pub-2" {
  vpc_id = aws_vpc.main1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "pub-rt-2"
  }
}
#asssociation
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.pub-2.id
}

# Security group
resource "aws_security_group" "kiran" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main1.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.kiran.id
  cidr_ipv4         = aws_vpc.main1.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_kfc" {
  security_group_id = aws_security_group.kiran.id
  cidr_ipv4         = aws_vpc.main1.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_mnc" {
  security_group_id = aws_security_group.kiran.id
  cidr_ipv4         = aws_vpc.main1.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.kiran.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



resource "aws_instance" "three" {
    count = 3
  ami                      = "ami-04a81a99f5ec58529"
  instance_type            = "t2.micro"
  subnet_id                =  aws_subnet.sub1.id
  security_groups    = [aws_security_group.kiran.id]
  associate_public_ip_address = "true"
  key_name                 = "beankey"
  
  
  
  tags = {
    name = "Login-machine"
}
}
resource "aws_lb_target_group" "test" {
  name     = "padayappa"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.main1.id
}

# target group
resource "aws_lb_target_group_attachment" "testrt" {

    for_each = {
    for k, v in aws_instance.three :
    k => v
  }
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = each.value.id
  port             = 80
}


# Elastic load balancer
# Create a new load balancer
resource "aws_lb" "mani" {
  name               = "Application"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kiran.id]
  
  subnet_mapping {
    subnet_id = aws_subnet.sub1.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.sub2.id
  }
  tags = {
    Environment = "Rams"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.mani.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}










terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.6"
        }
    }
}

provider "aws" {
    region = var.aws_region
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "three-tier-vpc"
    }
}

resource "aws_subnet" "public_1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "public-subnet-1"
    }
}

resource "aws_subnet" "public_2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1b"

    tags = {
        Name = "public-subnet-2"
    }
}

#private subnets
resource "aws_subnet" "private_1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "private-subnet-1"
    }
}

resource "aws_subnet" "private_2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "us-east-1b"

    tags = {
        Name = "private-subnet-2"
    }
}

#internet gateway, {main gate to vpc}
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "three-tier-igw"
    }
}

#route table for public subnet{roadds to and from the internet at the moment standalone
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "public-route-table"
    }
}

#route table for private subnet{no connection to internet}
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "private-route-table"
    }
}

#associating public subnets with public route table
resource "aws_route_table_association" "public_1" {
    subnet_id      = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
    subnet_id      = aws_subnet.public_2.id
    route_table_id = aws_route_table.public.id
}

#associating private subnets with private route table
resource "aws_route_table_association" "private_1" {
    subnet_id      = aws_subnet.private_1.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
    subnet_id      = aws_subnet.private_2.id
    route_table_id = aws_route_table.private.id
}

#security groups for web severs
resource "aws_security_group" "web" {
    name         = "web-tier-sg"
    description  = "allow web traffic"
    vpc_id       = aws_vpc.main.id

    ingress {
     from_port = 80
     to_port   = 80
     protocol  = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }

    egress { 
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "web-tier-sg"
    }
}

#security group 2 app tier{ecurity groups for app servers}
resource "aws_security_group" "app" {
    name         = "app-tier-sg"
    description  = "allow app traffic"
    vpc_id       = aws_vpc.main.id

    ingress {
     from_port = 8080
     to_port   = 8080
     protocol  = "tcp"
     security_groups = [aws_security_group.web.id]
   }

    egress {
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    tags = {
      Name = "app-tier-sg"
    }
}

#security group 3 dbtier{ecurity groups for db servers}
resource "aws_security_group" "db" {
    name         = "db-tier-sg"
    description  = "allows database traffic to app tier"
    vpc_id       = aws_vpc.main.id

    ingress {
      from_port = 3306
      to_port   = 3306
      protocol  = "tcp"
      security_groups = [aws_security_group.app.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
       Name = "db-tier-sg"
    }
}

#load balancer for web tier
resource "aws_lb" "web" {
    name               = "web-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.web.id]
    subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    
    tags = {
        Name = "web-alb"
    }
}

#target group for web tier
resource "aws_lb_target_group" "web" {
    name     = "web-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id

    health_check {
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-399"
    }

    tags = {
        Name = "web-tg"
    }

}

resource "aws_lb_target_group_attachment" "web_1" {
    target_group_arn = aws_lb_target_group.web.arn
    target_id        = aws_instance.web_1.id
    port             = 80
}
resource "aws_lb_target_group_attachment" "web_2" {
    target_group_arn = aws_lb_target_group.web.arn
    target_id        = aws_instance.web_2.id
    port             = 80
}

#listener for web tier
resource "aws_lb_listener" "web" {
    load_balancer_arn    = aws_lb.web.arn
    port             = 80
    protocol         = "HTTP"
    default_action {
        type         = "forward"
        target_group_arn = aws_lb_target_group.web.arn
    }
}

#ec2 instance for web tier
resource "aws_instance" "web_1" {
    ami           = "ami-0eb38b817b93460ac"
    instance_type   = var.instance_type
    subnet_id       = aws_subnet.public_1.id
    vpc_security_group_ids = [aws_security_group.web.id]
    associate_public_ip_address = true
    user_data_replace_on_change = true

    user_data = <<-EOF
#!/bin/bash
dnf install -y httpd
systemctl enable httpd
systemctl start httpd
echo "<h1>Three Tier Architecture - Web Server</h1>" > /var/www/html/index.html
EOF

    tags = {
        Name = "web-server-1"
    }
}

resource "aws_instance" "web_2" {
    ami                  = "ami-0eb38b817b93460ac"
    instance_type        = var.instance_type
    subnet_id            = aws_subnet.public_2.id
    vpc_security_group_ids = [aws_security_group.web.id]
    associate_public_ip_address = true
    user_data_replace_on_change = true

    user_data = <<-EOF
#!/bin/bash
dnf install -y httpd
systemctl enable httpd
systemctl start httpd
echo "<h1>Three Tier Architecture - Web Server</h1>" > /var/www/html/index.html
EOF

    tags = {
        Name = "web-server-2"
    }
}

#app tier ec2 inatances
resource "aws_instance" "app_1" {
    ami                  = "ami-0eb38b817b93460ac"
    instance_type        = var.instance_type
    subnet_id            = aws_subnet.private_1.id
    vpc_security_group_ids = [aws_security_group.app.id]

    tags = {
        Name = "app-server-1"
    }
}

resource "aws_instance" "app_2" {
    ami                  = "ami-0eb38b817b93460ac"
    instance_type        = var.instance_type
    subnet_id            = aws_subnet.private_2.id
    vpc_security_group_ids = [aws_security_group.app.id]

    tags = {
        Name = "app-server-2"
    }
}

#db subnet group{tells aws which subnets the database can use}
resource "aws_db_subnet_group" "main" {
    name       = "three-tier-db-subnet-group"
    subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

    tags = {
        Name = "three-tier-db-subnet-group"
    }
}

#rds database proper 
resource "aws_db_instance" "main" {
    identifier              = "three-tier-db"
    allocated_storage       = var.db_allocated_storage
    engine                  = "mysql"
    engine_version          = "8.0"
    instance_class          = "db.t3.micro"
    db_name                 = "threetierdb"
    username                = var.db_username
    password                = var.db_password

    db_subnet_group_name   = aws_db_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.db.id]

    skip_final_snapshot     = true

    tags = {
        Name = "three-tier-db"
    }
}

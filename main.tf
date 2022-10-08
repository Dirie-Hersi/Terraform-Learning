terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

#VPC
resource "aws_vpc" "Terraformvpc" {
  cidr_block = "10.0.0.0/16"
  
  tags  = {
    Name = "Project_VPC"
  }
}


#Internet Gateway
resource "aws_internet_gateway" "TerraformIGW" {
  vpc_id = aws_vpc.Terraformvpc.id

  tags = {
    Name = "Terraform IGW"
  }
}


#Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.Terraformvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TerraformIGW.id
  }

  tags = {
    Name = "PublicRT"
  }
}


#Public Subnet 1
resource "aws_subnet" "Public1A" {
  vpc_id     = aws_vpc.Terraformvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public SBN 1"
  }
}


#Public Subnet 2
resource "aws_subnet" "Public1B" {
  vpc_id     = aws_vpc.Terraformvpc.id
  cidr_block = "10.0.2.0/24"
   availability_zone = "us-east-1a"
   map_public_ip_on_launch = true

  tags = {
    Name = "Public SBN 2"
  }
}

#Associating Public Subnets with Route Table
resource "aws_route_table_association" "Public-Subnet1-RT-Association" {
  subnet_id      = aws_subnet.Public1A.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "Public-Subnet2-RT-Association" {
  subnet_id      = aws_subnet.Public1B.id
  route_table_id = aws_route_table.public_route_table.id
}

#Private Subnet 1
resource "aws_subnet" "Private1a" {
  vpc_id     = aws_vpc.Terraformvpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private SBN 1"
  }
}

#Private Subnet 2
resource "aws_subnet" "Private1b" {
  vpc_id     = aws_vpc.Terraformvpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private SBN 2"
  }
}

#Creating an RDS Database
resource "aws_db_instance" "default" {
  allocated_storage    = 02
  db_name              = "my_tf_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "exampleusername"
  password             = "examplepassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.TF_SG.id]
  
}

#Associate RDS with Subnet Group
resource "aws_db_subnet_group" "RDS_Subnet" {
  name       = "RDS_Subnet"
  subnet_ids = [aws_subnet.Private1a.id, aws_subnet.Private1b.id]

  tags = {
    Name = "RDS_SBN_Group"
  }
}


#Security Group

resource "aws_security_group" "TF_SG" {
  name        = "TF_SG"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.Terraformvpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "TF_SG"
  }
  
  
  #Load Balancer
  resource "aws_lb" "TF_LB" {
  name               = "TF_LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.TF_SG.id]
  subnets            = [aws_subnet.Public1A.id, aws_subnet.Public1B.id ]

  tags = {
    Environment = "Application"
  }
}

#Creating Public EC2 Instances

resource "aws_instance" "Instance1A" {
  ami           = "ami-026b57f3c383c2eec"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Public1A.id
  security_groups = [aws_security_group.TF_SG.id]
}

resource "aws_instance" "Instance1B" {
  ami           = "ami-026b57f3c383c2eec"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Public1B.id
  security_groups = [aws_security_group.TF_SG.id]
  
  
}
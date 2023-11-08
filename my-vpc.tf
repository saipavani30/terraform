provider "aws" {
}
#This is VPC code

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
}

# this is Subnet code
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Public-subnet"
  }
}


resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private-subnet"
  }
}

#security group
resource "aws_security_group" "my-sg" {
  name        = "my-sg"
  description = "allow ssh and http"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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


}
#internet gateway code
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-igw"
  }
}

#Public route table code

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }


  tags = {
    Name = "public-rt"
  }
}

#route Tatable assosication code
resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}
#ssh keypair code
resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIzSNY+KCRm3zH+lTWv96NbKUEJPPC9pnKnbq4gUDjLWx6mmfc23F6oP60o2Hlg2FGX+YogTbw4ulOpRlMQDziSOf5U3mG6HE+CDVcAVL36W7akWbLmXwU9w93P8sfgFrGsga0DKhnQFDYJrq11kEctrOdKkemr6DavfVFikMRnO0z6esfrZxyIHhc/CvELa98hGr6lbW50eqbMJ8QrZqeDdKNJSfTnkyx2UqhXumc3XaT1IL7LGaruNPNTXhQoj9ScKZT6Ju1zzD/2O70zqME6eZH+pSwFbz2rIwJLS6LEykBoto6Uf5Vo4Xg6IxEmlECoJe77FOYZJlKsavEELfuwaKYPu/YRjKIMM3Se4+/rpCKX+rF/ngxxb7aw9axKOeqqzAKHfOCAjhtmWjbmcBlggFv+jcAs8/2AGbG7jZwQ4Lmre9XXmtlMxkcEbBVnWdDM27WjXB67AlfuMam2OMT7UDrvKC7LasBYBW5UCv7WK87vDJJASVIkb3KuytDFSs= root@ip-172-31-36-229.ap-south-1.compute.internal"
}

#ec2 code
resource "aws_instance" "my-server" {
  ami               = "ami-05a5f6298acdb05b6"
  availability_zone = "us-east-1f"
  subnet_id         = aws_subnet.public-subnet.id
  instance_type     = "t2.micro"
  security_groups   = ["${aws_security_group.my-sg.id}"]
  key_name          = "mykey"
  tags = {
    Name     = "my-server"
    Stage    = "testing"
    Location = "chennai"
  }

}
##create an EIP for EC2
resource "aws_eip" "ec2_eip" {
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my-server.id
  allocation_id = aws_eip.ec2_eip.id
}
###this is database ec2 code
resource "aws_instance" "dev-server" {
  ami               = "ami-05a5f6298acdb05b6"
  availability_zone = "us-east-1f"
  subnet_id         = aws_subnet.private-subnet.id
  instance_type     = "t2.micro"
  security_groups   = ["${aws_security_group.my-sg.id}"]
  key_name          = "mykey"
  tags = {
    Name     = "dev-server"
    Stage    = "stage-base"
    Location = "delhi"
  }
}

resource "aws_eip" "nat-eip" {
}

#create Nat gateway
resource "aws_nat_gateway" "my-ngw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-subnet.id
}
#create private route table
resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-ngw.id
  }


  tags = {
    Name = "pri-rt"
  }
}


#route table association code
resource "aws_route_table_association" "private-asso" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.pri-rt.id
}

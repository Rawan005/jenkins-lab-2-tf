provider "random" {}

module "tags_network" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "network"
  }
}

module "tags_bastion" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "basion-devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "bastion"
  }
}

module "tags_webserver" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "webserver-devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "webserver"
  }
}

data "aws_ami" "latest_webserver" {
  most_recent = true
  owners      = ["772816346052"]

  filter {
    name   = "name"
    values = [format("%s-web-server*", var.name)]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  tags                 = module.tags_network.tags
  enable_dns_hostnames = true
}

resource "aws_route53_zone" "bryan_dobc" {
  name = "bryan.dobc"
  tags = module.tags_network.tags

  vpc {
    vpc_id = aws_vpc.lab.id
  }
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_network.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.lab.main_route_table_id
  gateway_id             = aws_internet_gateway.lab_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "bastion" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tags_bastion.tags
}

resource "aws_subnet" "webserver" {
  count                   = 1
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = format("10.0.%s.0/24", count.index + 20)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.tags_webserver.tags
}

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_bastion.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "webserver" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_webserver.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_id" "keypair" {
  keepers = {
    public_key = file(var.public_key_path)
  }

  byte_length = 8
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s_keypair_%s", var.name, random_id.keypair.hex)
  public_key = random_id.keypair.keepers.public_key
}

resource "aws_route53_record" "webserver" {
  zone_id = aws_route53_zone.bryan_dobc.id
  name    = "webserver"
  type    = "A"
  ttl     = 300
  records = [aws_instance.webserver.0.private_ip]
}

resource "aws_instance" "webserver" {
  count                       = 1
  ami                         = data.aws_ami.latest_webserver.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.webserver[count.index].id
  vpc_security_group_ids      = [aws_security_group.webserver.id]
  key_name                    = aws_key_pair.lab_keypair.id
  associate_public_ip_address = true
  tags                        = module.tags_webserver.tags
  depends_on                  = [aws_instance.api]

  provisioner "remote-exec" {
    inline = [
      "echo \"${aws_instance.api.0.public_ip}\" > /home/ubuntu/api/index.html"
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      host                = self.private_ip
      private_key         = file(var.private_key_path)
      bastion_host        = aws_instance.bastion.public_ip
      bastion_private_key = file(var.private_key_path)
      bastion_user        = "ubuntu"
    }
  }
}

resource "aws_instance" "api" {
  count                       = 1
  ami                         = data.aws_ami.latest_webserver.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.webserver[count.index].id
  vpc_security_group_ids      = [aws_security_group.webserver.id]
  key_name                    = aws_key_pair.lab_keypair.id
  associate_public_ip_address = true
  tags                        = module.tags_webserver.tags
}

resource "aws_instance" "bastion" {
  ami                    = "ami-02c7c728a7874ae7a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.bastion.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.lab_keypair.id
  tags                   = module.tags_bastion.tags
}

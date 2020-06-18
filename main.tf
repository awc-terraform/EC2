provider "aws" {
    region  = var.aws_region
    profile = var.aws_profile 
}

#----KMS----
resource "aws_kms_key" "InstancesKMSkey" {
  description = "KMS key to be used for encrypting ebs block devices on dev instances"
  is_enabled = true

  tags = {
    Name = var.aws_name
    Owner = var.aws_owner
    Dept = var.aws_dept
    Environment = var.aws_environment
    Tool = var.aws_tool
  }
}

#----VPC----
#Referances a exisiting vpc & subnet not created via terraform

resource "aws_key_pair" "DevInstancesKey" {
  key_name   = "x"
  public_key = file("x.pub")

  tags = {
    Name = var.aws_name
    Owner = var.aws_owner
    Dept = var.aws_dept
    Environment = var.aws_environment
    Tool = var.aws_tool
  }
}

resource "aws_eip" "dev_eip" {
  count = var.aws_count
  instance = element(aws_instance.dev_instance.*.id, count.index)
  vpc = true

  tags = {
    Name = "DevInstance-${count.index}"
    Owner = var.aws_owner
    Dept = var.aws_dept
    Environment = var.aws_environment
    Tool = var.aws_tool
  }

  depends_on = [aws_instance.dev_instance]
}

#----EC2----

resource "aws_network_interface" "dev_net" {
  subnet_id   = var.aws_public_subnet
  count = var.aws_count

  tags = {
    Name = "DevInstance-${count.index}"
    Owner = var.aws_owner
    Dept = var.aws_dept
    Environment = var.aws_environment
    Tool = var.aws_tool
  }
}

resource "aws_instance" "dev_instance" {
  count = var.aws_count
  ami           = var.aws_ami 
  instance_type = var.aws_instances_type
  subnet_id = var.aws_public_subnet

  tags = {
    Name = "DevInstance-${count.index}"
    Owner = var.aws_owner
    Dept = var.aws_dept
    Environment = var.aws_environment
    Tool = var.aws_tool
  }  

  key_name = var.aws_keyname

  associate_public_ip_address = true

  depends_on = [aws_network_interface.dev_net, aws_key_pair.DevInstancesKey, aws_kms_key.InstancesKMSkey] 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 125
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "xvdf"
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
    encrypted = true
    kms_key_id = aws_kms_key.InstancesKMSkey.id
  } 
}

resource "aws_security_group" "dev_instances_sg" {

  name        = "dev_instances_sg"
  description = "Allows RDP into dev instances"
  vpc_id      = var.aws_public_vpc

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["x.x.x.x/32", "x.x.x.x/32" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.aws_name
    Owner = var.aws_owner
    Dept = var.aws_dept
    Environment = var.aws_environment
    Tool = var.aws_tool
  }
}

resource "aws_network_interface_sg_attachment" "dev_sg_attachment" {
  count = var.aws_count

  security_group_id    = element(aws_security_group.dev_instances_sg.*.id, count.index)
  network_interface_id = element(aws_instance.dev_instance.*.primary_network_interface_id, count.index)
}
#adding a comment






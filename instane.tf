resource "aws_instance" "webapp-ec2" {
  ami           = "ami-0dc0a7d8db70b5cf0" #"ami-0522ab6e1ddcc7055"
  instance_type = var.webapp-instance-type
  subnet_id = aws_subnet.webapp-subnet-1a.id
  key_name = aws_key_pair.webapp-keypair.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_80_22.id]

  tags = {
    Name = "Webapp-EC2"
  }
}




resource "aws_instance" "webapp-ec2-2" {
  ami           = "ami-0dc0a7d8db70b5cf0" #"ami-0522ab6e1ddcc7055"
  instance_type = var.webapp-instance-type
  subnet_id = aws_subnet.webapp-subnet-1b.id
  key_name = aws_key_pair.webapp-keypair.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_80_22.id]
  #user_data = filebase64("example-userdata.sh")

  tags = {
    Name = "Webapp-EC2"
  }
}
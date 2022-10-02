data "aws_availability_zones" "all" {}

# Creating EC2 instance
resource "aws_instance" "Github-Runner" {
  ami               = "${lookup(var.amis,var.region)}"
  count             = "${var.number_of_instances}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.Github-Runner.id}"]
  source_dest_check = false
  instance_type = "t3a.small"
# Tag the instance with a counter starting at 1
tags = {
    Name = "${format("Github-Runner", count.index + 1)}"
  }
}

# Creating Security Group for EC2
resource "aws_security_group" "Github-Runner" {
  name = "Github-Runner-instance-security-group"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    description = "User-service ports"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating Launch Configuration
resource "aws_launch_configuration" "Github-Runner-LC" {
  image_id               = "${lookup(var.amis,var.region)}"
  instance_type          = "t3a.small"
  security_groups        = ["${aws_security_group.Github-Runner.id}"]
  key_name               = "${var.key_name}"
# user_data is the set of commands/data you can provide to an instance at launch time
  user_data = <<-EOF
 #!/bin/bash
sudo apt update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
sudo apt update
sudo apt-get install docker-ce
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker ubuntu
 base64encode(templatefile("${path.cwd}/bootstrap.tmpl", {  runner_name = AAIC-Runner, labels = join(",", Github-Runner) }))

              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Creating AutoScaling Group
resource "aws_autoscaling_group" "Github-runner-ASG" {
  launch_configuration = "${aws_launch_configuration.Github-Runner-LC.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = 2
  max_size = 10
  load_balancers = ["${aws_elb.Github-Runner-ELB.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "Github-asg-runner"
    propagate_at_launch = true
  }
}

# Security Group for ELB
resource "aws_security_group" "Github-Runner-ELB" {
  name = "terraform-example-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating ELB
resource "aws_elb" "Github-Runner-ELB" {
  name = "Github-ELB-Runner"
  security_groups = ["${aws_security_group.Github-Runner-ELB.id}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
}
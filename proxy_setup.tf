provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_security_group" "workstation_sg_group" {
    name = "workstation_proxy_sg"
    description = "allow inbound traffic for workstation"

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

resource "aws_instance" "workstation" {
    count         = 1
    ami           = "ami-ba602bc2"
    instance_type = "t2.micro"
    key_name      = "${var.key_name}"

    security_groups = [
        "${aws_security_group.workstation_sg_group}",
    ]
}

output "workstation_ip" {
    value = "${aws_instance.workstation.public_ip}"
}
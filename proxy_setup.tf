provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.region}"
}

resource "aws_security_group" "workstation_sg" {
    name = "workstation_proxy_sg"
    description = "allow inbound traffic for workstation"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
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

resource "aws_instance" "workstation" {
    count         = 1
    ami           = "ami-ba602bc2"
    instance_type = "t2.micro"
    key_name      = "${var.key_name}"

    security_groups = [
        "${aws_security_group.workstation_sg.name}",
    ]

    tags {
        Name = "nell-workstation-demo"
    }
}

resource "aws_security_group" "proxy_sg" {
    name = "proxy_sg"
    description = "allow inbound traffic for workstation"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 3128
        to_port     = 3128
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


resource "aws_instance" "proxy_server" {
    count         = 1
    ami           = "ami-ba602bc2"
    instance_type = "t2.micro"
    key_name      = "${var.key_name}"

    security_groups = [
        "${aws_security_group.proxy_sg.name}",
    ]
    provisioner "remote-exec" {
        inline = [
            "sudo apt-get install -y squid3",
        ]

        connection {
            host        = "${self.public_ip}"
            type        = "ssh"
            user        = "ubuntu"
            private_key = "${file("${var.key_path}")}"
        }
    }

    tags {
        Name = "nell-proxy-demo"
    }
}


data "template_file" "squid_conf" {
  template = "${file("squid_conf.tpl")}"

  vars = {
    workstation_ip_addr = "${aws_instance.workstation.public_ip}"
  }
}

# This needs to be done after the squid install on the proxy server is complete
resource "null_resource" "set_squid_conf" {
    connection {
        host        = "${aws_instance.proxy_server.public_ip}"
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("${var.key_path}")}"
    } 

    provisioner "file" {
        content     = "${data.template_file.squid_conf.rendered}"
        destination = "/etc/squid/squid.conf"
        destination = "~/squid.conf"
    }

    provisioner "remote-exec" {
      inline = [
          "sudo mv ~/squid.conf /etc/squid/squid.conf",
          "sudo systemctl restart squid.service"
      ]
    }
}


resource "null_resource" "set_http_proxy" {
    connection {
        host        = "${aws_instance.workstation.public_ip}"
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("${var.key_path}")}"
    } 

    provisioner "remote-exec" {
         inline = [
             "echo \"export http_proxy=http://${aws_instance.proxy_server.public_ip}:3128\" >> ~/.bashrc",
             ". ~/.bashrc"
         ]
    }
}

resource "aws_security_group" "server_behind_proxy_sg" {
    name = "server_behind_proxy_proxy_sg"
    description = "allow inbound traffic for workstation"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["${aws_instance.proxy_server.public_ip}/32"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["${aws_instance.proxy_server.public_ip}/32"]
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
resource "aws_instance" "server_behind_proxy" {
    count         = 1
    ami           = "ami-ba602bc2"
    instance_type = "t2.micro"
    key_name      = "${var.key_name}"

    security_groups = [
        "${aws_security_group.server_behind_proxy_sg.name}",
    ]

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sleep 120",
            "sudo apt-get install -y apache2"
        ]

        connection {
            host        = "${self.public_ip}"
            type        = "ssh"
            user        = "ubuntu"
            private_key = "${file("${var.key_path}")}"
        }
    }

    tags {
        Name = "nell-server-behind-proxy"
    }
}

output "workstation_ip" {
    value = "${aws_instance.workstation.public_ip}"
}

output "proxy_server_ip" {
    value = "${aws_instance.proxy_server.public_ip}"
}

output "server_behind_proxy_ip" {
    value = "${aws_instance.server_behind_proxy.public_ip}"
}

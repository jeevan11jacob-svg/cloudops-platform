resource "terraform_data" "jenkins_bootstrap" {
  input = "jenkins-bootstrap-v1"
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  associate_public_ip_address = true

  lifecycle {
    replace_triggered_by = [
      terraform_data.jenkins_bootstrap
    ]
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y

    apt-get install -y \
      openjdk-21-jre \
      git \
      curl \
      unzip \
      docker.io

    systemctl enable --now docker

    usermod -aG docker ubuntu

    systemctl enable --now amazon-ssm-agent

    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
      -o /usr/share/keyrings/jenkins-keyring.asc

    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list

    apt-get update -y
    apt-get install -y jenkins

    systemctl enable --now jenkins

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
      -o /tmp/awscliv2.zip

    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl

    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 \
      | bash
  EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins"
    Environment = var.environment
    Project     = var.project_name
    Role        = "jenkins"
  }
}
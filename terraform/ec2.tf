# ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
# Airflow EC2 Instance
# ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

# SSH Key Pair
resource "tls_private_key" "airflow" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "airflow" {
  key_name   = "boohoo-airflow-key"
  public_key = tls_private_key.airflow.public_key_openssh
}

# Security Group
resource "aws_security_group" "airflow" {
  name        = "boohoo-airflow-sg"
  description = "Allow Airflow UI and SSH access"

  ingress {
    description = "Airflow Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for Airflow EC2
resource "aws_iam_role" "airflow_ec2_role" {
  name = "BoohooAirflowEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "airflow_ec2_policy" {
  name = "AirflowOrchestratorPolicy"
  role = aws_iam_role.airflow_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:eu-west-2:*:function:boohoo-*"
      },
      {
        Sid    = "RedshiftDataAPI"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift-serverless:GetCredentials"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::boohoo-*",
          "arn:aws:s3:::boohoo-*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_ssm_policy" {
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "airflow" {
  name = "BoohooAirflowInstanceProfile"
  role = aws_iam_role.airflow_ec2_role.name
}

# EC2 Instance
resource "aws_instance" "airflow" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.airflow.key_name
  vpc_security_group_ids      = [aws_security_group.airflow.id]
  iam_instance_profile        = aws_iam_instance_profile.airflow.name
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    # v3 - with DAG + config sync from GitHub
    set -e

    # Swap file (1GB)
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

    # Install Python and dependencies
    dnf install -y python3.11 python3.11-pip git

    # Create airflow user
    useradd -m -s /bin/bash airflow

    # Install Airflow and dbt
    export AIRFLOW_HOME=/opt/airflow
    mkdir -p $AIRFLOW_HOME/dags $AIRFLOW_HOME/logs $AIRFLOW_HOME/config
    pip3.11 install apache-airflow==2.10.5 dbt-redshift boto3 pyyaml

    # Clone the repo to sync DAGs
    git clone https://github.com/TimiOlayinka/boohoo-data-pipeline.git /opt/boohoo-repo
    cp /opt/boohoo-repo/airflow/dags/*.py $AIRFLOW_HOME/dags/
    cp /opt/boohoo-repo/airflow/config/*.yml $AIRFLOW_HOME/config/

    # Create a sync script that runs on every boot
    cat > /usr/local/bin/sync-dags.sh <<'SYNC'
    #!/bin/bash
    cd /opt/boohoo-repo
    git pull origin main
    cp /opt/boohoo-repo/airflow/dags/*.py /opt/airflow/dags/
    cp /opt/boohoo-repo/airflow/config/*.yml /opt/airflow/config/
    chown -R airflow:airflow /opt/airflow/dags/ /opt/airflow/config/
    SYNC
    chmod +x /usr/local/bin/sync-dags.sh

    # Systemd service to sync DAGs on boot
    cat > /etc/systemd/system/sync-dags.service <<SYSTEMD
    [Unit]
    Description=Sync Airflow DAGs from GitHub
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=oneshot
    ExecStart=/usr/local/bin/sync-dags.sh

    [Install]
    WantedBy=multi-user.target
    SYSTEMD

    # Initialise Airflow database
    export AIRFLOW__CORE__LOAD_EXAMPLES=False
    export AIRFLOW__WEBSERVER__EXPOSE_CONFIG=False
    /usr/local/bin/airflow db init

    # Create admin user
    /usr/local/bin/airflow users create \
      --username admin \
      --password mYGnUG7JuiCwtaH9uX6HQq93 \
      --firstname Timi \
      --lastname Olayinka \
      --role Admin \
      --email admin@boohoo.com

    # Set ownership
    chown -R airflow:airflow $AIRFLOW_HOME

    # Systemd service for Airflow webserver
    cat > /etc/systemd/system/airflow-webserver.service <<SYSTEMD
    [Unit]
    Description=Airflow Webserver
    After=network.target sync-dags.service

    [Service]
    Environment=AIRFLOW_HOME=/opt/airflow
    Environment=AIRFLOW__CORE__LOAD_EXAMPLES=False
    Environment=REDSHIFT_PASSWORD=B00h00Dwh!2026x
    Environment=REDSHIFT_IAM_ROLE=arn:aws:iam::332779204498:role/BoohooDataGeneratorRole
    User=airflow
    ExecStart=/usr/local/bin/airflow webserver --port 8080
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SYSTEMD

    # Systemd service for Airflow scheduler
    cat > /etc/systemd/system/airflow-scheduler.service <<SYSTEMD
    [Unit]
    Description=Airflow Scheduler
    After=network.target sync-dags.service

    [Service]
    Environment=AIRFLOW_HOME=/opt/airflow
    Environment=AIRFLOW__CORE__LOAD_EXAMPLES=False
    Environment=REDSHIFT_PASSWORD=B00h00Dwh!2026x
    Environment=REDSHIFT_IAM_ROLE=arn:aws:iam::332779204498:role/BoohooDataGeneratorRole
    User=airflow
    ExecStart=/usr/local/bin/airflow scheduler
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SYSTEMD

    # Enable and start services
    systemctl daemon-reload
    systemctl enable sync-dags airflow-webserver airflow-scheduler
    systemctl start sync-dags airflow-webserver airflow-scheduler

    # Force recreation for SSM agent registration (DATA-12)
  EOF

  tags = {
    Name = "boohoo-airflow"
  }
}

# Elastic IP for persistent address across stop/start cycles
resource "aws_eip" "airflow" {
  domain   = "vpc"
  instance = aws_instance.airflow.id

  tags = {
    Name = "boohoo-airflow-eip"
  }
}

# Outputs
output "airflow_instance_id" {
  description = "EC2 Instance ID for start/stop commands"
  value       = aws_instance.airflow.id
}

output "airflow_public_ip" {
  description = "Airflow Web UI URL (static Elastic IP)"
  value       = "http://${aws_eip.airflow.public_ip}:8080"
}

output "airflow_ssh_private_key" {
  description = "SSH private key (save this to connect)"
  value       = tls_private_key.airflow.private_key_pem
  sensitive   = true
}

# Terraform Outputs for EC2 Deployment

output "instance_id" {
  value       = aws_instance.epl_server.id
  description = "EC2 instance ID"
}

output "instance_public_ip" {
  value       = aws_eip.epl_server.public_ip
  description = "Public IP address of the EC2 instance"
}

output "instance_public_dns" {
  value       = aws_instance.epl_server.public_dns
  description = "Public DNS of the EC2 instance"
}

output "ssh_command" {
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${aws_eip.epl_server.public_ip}"
  description = "SSH command to connect to the instance"
}

output "deployment_commands" {
  value = <<-EOT
    # Connect to the instance
    ssh -i ${var.ssh_key_name}.pem ec2-user@${aws_eip.epl_server.public_ip}

    # Copy your code to the instance (run from your local machine)
    scp -i ${var.ssh_key_name}.pem -r services/producer ec2-user@${aws_eip.epl_server.public_ip}:/opt/epl-live/
    scp -i ${var.ssh_key_name}.pem -r services/consumer ec2-user@${aws_eip.epl_server.public_ip}:/opt/epl-live/

    # Or use rsync for better performance
    rsync -avz -e "ssh -i ${var.ssh_key_name}.pem" services/ ec2-user@${aws_eip.epl_server.public_ip}:/opt/epl-live/

    # After copying, SSH into instance and start services
    ssh -i ${var.ssh_key_name}.pem ec2-user@${aws_eip.epl_server.public_ip}
    cd /opt/epl-live
    docker-compose up -d

    # View logs
    docker-compose logs -f

    # Check service status
    docker-compose ps
  EOT
  description = "Commands to deploy and manage the application"
}

output "useful_commands" {
  value = <<-EOT
    # View all container logs
    docker-compose logs -f

    # View specific service logs
    docker-compose logs -f producer
    docker-compose logs -f consumer
    docker-compose logs -f kafka

    # Check service status
    docker-compose ps

    # Restart services
    docker-compose restart

    # Stop all services
    docker-compose down

    # Update and restart
    docker-compose down && docker-compose up -d

    # View resource usage
    docker stats

    # Enter container shell
    docker exec -it epl-producer bash
    docker exec -it epl-consumer bash

    # View Kafka topics
    docker exec epl-kafka kafka-topics --bootstrap-server localhost:9092 --list

    # Monitor Redis
    docker exec -it epl-redis redis-cli
    > INFO
    > KEYS *
  EOT
  description = "Useful commands for managing the application"
}

output "cost_estimate" {
  value = <<-EOT
    Monthly Cost Estimate:
    =====================
    Instance Type: ${var.instance_type}

    ${var.instance_type == "t3.micro" ? "FREE TIER (12 months for new accounts):" : "Cost Breakdown:"}
    ${var.instance_type == "t3.micro" ? "- t3.micro: $0/month (750 hours free)" : "- ${var.instance_type}: ~$${var.instance_type == "t3.small" ? "15" : var.instance_type == "t3.medium" ? "30" : "?"}/month"}
    - EBS Storage (20GB): $0/month (30GB free tier)
    - Data Transfer: $0/month (100GB free tier)
    - Elastic IP: $0/month (free when instance running)
    =====================
    ${var.instance_type == "t3.micro" ? "TOTAL: $0/month (first 12 months)" : "TOTAL: ~$${var.instance_type == "t3.small" ? "15" : var.instance_type == "t3.medium" ? "30" : "?"}/month"}

    After Free Tier (if using t3.micro):
    - t3.micro: ~$7/month

    Recommended for Production: t3.small (~$15/month)
    - More RAM (2GB vs 1GB)
    - Better performance
    - Still very affordable
  EOT
  description = "Cost estimate breakdown"
}

output "instance_type" {
  value       = var.instance_type
  description = "EC2 instance type being used"
}

output "security_group_id" {
  value       = aws_security_group.epl_instance.id
  description = "Security group ID"
}

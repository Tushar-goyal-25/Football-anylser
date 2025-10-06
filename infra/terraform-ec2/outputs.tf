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
  value = var.instance_type == "t3.micro" ? "Monthly Cost Estimate:\n=====================\nInstance Type: t3.micro\n\nFREE TIER (12 months for new accounts):\n- t3.micro: $0/month (750 hours free)\n- EBS Storage (20GB): $0/month (30GB free tier)\n- Data Transfer: $0/month (100GB free tier)\n- Elastic IP: $0/month (free when instance running)\n=====================\nTOTAL: $0/month (first 12 months)\n\nAfter Free Tier:\n- t3.micro: ~$7/month\n\nRecommended for Production: t3.small (~$15/month)" : var.instance_type == "t3.small" ? "Monthly Cost Estimate:\n=====================\nInstance Type: t3.small\n\nCost Breakdown:\n- t3.small: ~$15/month\n- EBS Storage (20GB): ~$2/month\n- Data Transfer: $0/month (100GB free tier)\n- Elastic IP: $0/month (free when instance running)\n=====================\nTOTAL: ~$17/month\n\nGreat choice for production!\n- 2GB RAM (vs 1GB on t3.micro)\n- Better performance\n- Still very affordable" : "Monthly Cost Estimate:\n=====================\nInstance Type: ${var.instance_type}\n\nCost Breakdown:\n- ${var.instance_type}: ~$30/month (estimated)\n- EBS Storage (20GB): ~$2/month\n- Data Transfer: $0/month (100GB free tier)\n- Elastic IP: $0/month (free when instance running)\n=====================\nTOTAL: ~$32/month (estimated)"
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

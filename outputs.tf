output "load_balancer_dns" {
    description   = "the DNS name of the load balancer"
    value         = aws_lb.web.dns_name
}

output "web_server_1_ip" {
    description  = "the public IP of web server 1"
    value        = aws_instance.web_1.public_ip
}

output "web_server_2_ip" {
    description  = "the public IP of web server 2"
    value        = aws_instance.web_2.public_ip
}

output "db_endpoint" {
    description  = "the endpoint of the RDS database"
    value        = aws_db_instance.main.endpoint
}


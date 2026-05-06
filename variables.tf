variable "aws_region" {
    description  = "the aws region to deploy resources in"
    default     = "us-east-1"
}

variable "instance_type" {
    description  = "EC2 instance type"
    default     = "t3.micro"
}

variable "db_allocated_storage" {
    description  = "allocated storage for RDS database in GB"
    default     = 20
}

variable "db_username" {
    description  = "username for RDS database"
    default      = "admin"
}

variable "db_password" {
    description  = "password for RDS database"
    default      = "pass246word"
    sensitive    = true
}
variable "aws_region" { 
    description = "AWS region for deployment" 
    default = "us-west-2" 
}

variable "project_name" { 
    description = "Name of the project" 
    default = "security-hub-dashboard" 
}

variable "alert_email" { 
    description = "Email for SNS notifications"
    type = string 
}
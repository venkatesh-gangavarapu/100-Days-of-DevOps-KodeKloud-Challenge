variable "KKE_VPC_CIDR" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "KKE_SUBNET_CIDR" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

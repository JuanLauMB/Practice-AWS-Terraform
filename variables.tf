variable "region" {
    default = "ap-southeast-1"
  
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
  
}
variable "pub_subnet1_cidr" {
    default = "10.0.0.0/24"
  
}
variable "pub_subnet2_cidr" {
    default = "10.0.1.0/24"
  
}
variable "priv_subnet1_cidr" {
    default = "10.0.2.0/24"
  
}
variable "priv_subnet2_cidr" {
    default = "10.0.3.0/24"
  
}
variable "sship" {
    default = "136.158.78.199/32"
  
}

# vars.tf

variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region for the instance"
}

variable "zone" {
  description = "The GCP zone for the instance"
}

variable "instance_name" {
  description = "The name of the GCP instance"
}

variable "private_key_path" {
  description = "Path for SSH private key"
}

variable "ssh-key" {
  description = "Add your key in RSA Format"
}

variable "image" {
  description = "GCP Image by defualt"
}

variable "subnet" {
  description = "Default subnetwork"
}

variable "disk_size" {
  description = "Default disk size 40G"
  default = "40"
}

variable "ssh-user" {
  description = "Configure the user name for ssh access"
}

variable "machine_type" {
  description = "The machine type for the GCP instance"
  default     = "e2-medium"
}

variable "image_family" {
  description = "The image family for the GCP instance"
  default     = "debian-10"
}

variable "image_project" {
  description = "The image project for the GCP instance"
  default     = "debian-cloud"
}

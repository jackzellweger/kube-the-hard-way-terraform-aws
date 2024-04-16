// ----- Variables ----


variable "private-key-filename" {
  type = string
  default = "ssh-private-key"
}

variable "control_plane_instance_count" {
  type = number
  default = 2
}

variable "worker_instance_count" {
  type = number
  default = 2
}

variable "scripts_dir_path" {
  description = "Path to the scripts directory"
  type        = string
}

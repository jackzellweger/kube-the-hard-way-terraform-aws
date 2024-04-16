// ----- Variables -----

variable "private-key-filename" {
  type = string
  default = "ssh-private-key"
}

variable "control_plane_instance_count" {
  type = number
  default = 2
}

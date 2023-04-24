variable "ivr_phone_number" {
  type        = string
  description = "Number the IVR is associated with"
}

variable "ivr_callback" {
  type        = string
  description = "Number the IVR is associated with"
}

variable "ivr_failure" {
  type        = string
  description = "Number the IVR is associated with"
}

variable "ivr_emergency_group_enabled" {
  type        = bool
  description = "IVR Emergency schedule group status"
}
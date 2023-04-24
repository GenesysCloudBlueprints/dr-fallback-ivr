variable "ivr_phone_number" {
  type        = string
  description = "Number the IVR is associated with"
}

variable "ivr_initial_greeting" {
  type        = string
  description = "Initial greeting for the IVR"
}

variable "ivr_failure" {
  type        = string
  description = "IVR failure message"
}

variable "ivr_callback" {
  type        = string
  description = "IVR Callback message"
}

variable "ivr_emergency_group_enabled" {
  type        = bool
  description = "IVR Emergency schedule group status"
}
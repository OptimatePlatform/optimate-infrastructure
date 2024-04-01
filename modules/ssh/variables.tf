# ================== #
# Required variables #
# ================== #
variable "key_pair_name" {
  type = string
}

variable "env" {
  type = string
}

variable "algorithm" {
  description = "Name of the algorithm to use when generating the private key. Currently-supported values are: RSA, ECDSA, ED25519"
  type        = string
}


# ================== #
# Optional variables #
# ================== #
variable "ecdsa_curve" {
  description = "When algorithm is ECDSA, the name of the elliptic curve to use. Currently-supported values are: P224, P256, P384, P521"
  type        = string
  default     = null
}

variable "rsa_bits" {
  description = "When algorithm is RSA, the size of the generated RSA key, in bits"
  type        = number
  default     = null
}


variable "secret_recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30"
  type        = number
  default     = 0
}
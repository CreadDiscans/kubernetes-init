variable "email" {
  type = string
}

variable "aws_key" {
  type = object({
    aws_access_key_id     = string
    aws_secret_access_key = string
  })
  default = {
    aws_access_key_id     = ""
    aws_secret_access_key = ""
  }
}

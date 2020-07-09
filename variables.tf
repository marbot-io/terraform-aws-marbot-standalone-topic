variable "endpoint_id" {
  type        = string
  description = "Your marbot endpoint ID (to get this value: select a Slack channel where marbot belongs to and send a message like this: \"@marbot show me my endpoint id\")."
}

variable "enabled" {
  type        = bool
  description = "Turn the module on or off"
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "stage" {
  type        = string
  description = "marbot stage (never change this!)."
  default     = "v1"
}
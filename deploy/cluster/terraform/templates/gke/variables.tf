variable "project_id" {
  description = "Google Project ID."
  type        = string
}

variable "cluster_name" {
  description = "Name of cluster."
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "europe-west3-b"
}

variable "machine_type" {
  description = "Google VM Instance type."
  type        = string
  default     = "n1-standard-4"
}

variable "num_nodes" {
  description = "Number of nodes."
  default     = 1
}

variable "min_num_nodes" {
  description = "Minimum number of nodes."
  default     = 1
}

variable "max_num_nodes" {
  description = "Maximum number of nodes."
  default     = 3
}
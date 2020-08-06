variable "env_global_tags" {
  type = "map"
}

variable "msk_cluster_name" {
  type = "string"
}

variable "msk_kafka_version" {
  type = "string"
}

variable "msk_number_of_broker_nodes" {
  type = "string"
}

variable "msk_broker_instance_type" {
  type = "string"
}

variable "msk_broker_ebs_volume_size" {
  type = "string"
}

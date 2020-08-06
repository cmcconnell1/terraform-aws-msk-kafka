#############################################################
# Data source to get VPC-ID
#############################################################
data "terraform_remote_state" "main_vpc" {
  backend = "s3"

  config = {
    bucket         = "terradatum-terraform-state"
    encrypt        = "true"
    region         = "us-west-2"
    dynamodb_table = "terradatum-terraform-locks"
    key            = "dev-usw2/main-vpc/terraform.tfstate"
  }
}

######################################################################## 
# Get private VPCs subnets
# ref: https://github.com/hashicorp/terraform/issues/16902
######################################################################## 
# tricky to save $ they want you to spread across all AZs
data "aws_subnet_ids" "private-2a" {
  vpc_id = "${data.terraform_remote_state.main_vpc.main_vpc_id}"

  tags {
    Name = "eks-dev-private-us-west-2a"
  }
}
data "aws_subnet_ids" "private-2b" {
  vpc_id = "${data.terraform_remote_state.main_vpc.main_vpc_id}"

  tags {
    Name = "eks-dev-private-us-west-2b"
  }
}

data "aws_security_group" "msk-sg" {
  vpc_id = "${data.terraform_remote_state.main_vpc.main_vpc_id}"

  tags = {
    Name = "msk-kafka-dev-vpc"
  }
}


resource "aws_kms_key" "kms" {
  description = "${var.msk_cluster_name}-kms-key"
}

resource "aws_msk_cluster" "msk" {
  cluster_name           = "${var.msk_cluster_name}"
  kafka_version          = "${var.msk_kafka_version}"
  number_of_broker_nodes = "${var.msk_number_of_broker_nodes}"

  broker_node_group_info {
    instance_type  = "${var.msk_broker_instance_type}"
    ebs_volume_size = "${var.msk_broker_ebs_volume_size}"
    client_subnets = [ "${data.aws_subnet_ids.private-2a.ids}", "${data.aws_subnet_ids.private-2b.ids}" ]
    security_groups = [ "${data.aws_security_group.msk-sg.id}" ]
  }

  configuration_info {
    arn      = "${aws_msk_configuration.msk.arn}"
    revision = "${aws_msk_configuration.msk.latest_revision}"
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = "${aws_kms_key.kms.arn}"
    encryption_in_transit {
      #client_broker = "TLS" # or TLS_PLAINTEXT or PLAINTEXT
      client_broker = "TLS_PLAINTEXT"
    }
  }

  tags = "${var.env_global_tags}"

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["id"]
    ignore_changes = ["cluster_name"]
    ignore_changes = ["aws_msk_configuration.msk.name"]
    #prevent_destroy = true
  }
}


######################################################################## 
# create KSM Kafka Cluster Config
######################################################################## 
# Ref: MSK cluster destroy doesn't remove `aws_msk_configuration` #9082
# https://github.com/terraform-providers/terraform-provider-aws/issues/9082
resource "random_id" "server" {
  keepers = {
    msk_cluster_name = "${var.msk_cluster_name}"
  }

  byte_length = 8
  }

resource "aws_msk_configuration" "msk" {
  kafka_versions = ["${var.msk_kafka_version}"]
  name           = "${var.msk_cluster_name}-${random_id.server.hex}"

  # https://docs.aws.amazon.com/msk/latest/developerguide/msk-configuration-properties.html
  server_properties = <<PROPERTIES
auto.create.topics.enable = true
delete.topic.enable = true
auto.create.topics.enable	= true
default.replication.factor = 3
min.insync.replicas	= 2
num.io.threads = 8
num.network.threads	= 5
num.partitions = 1
num.replica.fetchers = 2
socket.request.max.bytes = 104857600
unclean.leader.election.enable = true
log.retention.hours = 168
log.retention.bytes = 187904819200
PROPERTIES
}

output "zookeeper_connect_string" {
  value = "${aws_msk_cluster.msk.zookeeper_connect_string}"
}

output "bootstrap_brokers" {
  value       = "${aws_msk_cluster.msk.bootstrap_brokers}"
}

output "bootstrap_brokers_tls" {
  value       = "${aws_msk_cluster.msk.bootstrap_brokers_tls}"
}

output "msk_cluster_arn" {
  value       = "${aws_msk_cluster.msk.arn}"
}

# Ephemeral Dev/Test AWK MSK Cluster

## TL;DR
- The examples on this doc are from ephemeral Dev/test cluster and are subject to change at any time.
- The prod cluster will have different zk/kafka named nodes--refer to the AWS docs noted below.
- SaaS location Region = us-west-2


## AWS MSK Kafka Clusters
- https://us-west-2.console.aws.amazon.com/msk/home?region=us-west-2#/clusters

### AWS MSK Kafka Cluster Configurations 
- https://us-west-2.console.aws.amazon.com/msk/home?region=us-west-2#/configurations

## AWS VPC Security Group
- The requisite **msk-kafka-dev-vpc** security group is included in the eks-dev kube cluster worker's **eks-dev-cluster-eks_worker_sg** security group, which allows access from both internal VPC and VNP CIDR ranges.

### AWS MSK Kafka Cluster Port Information
- The following list provides the numbers of the ports that Amazon MSK uses to communicate with client machines.

  - producers, consumers **plaintext**: port **9092**
  - producers, consumers **TLS**: port **9094**
  - Apache ZooKeeper nodes: port **2181**


## Refer to the official AWS MSK Docs
- https://docs.aws.amazon.com/msk/latest/developerguide/what-is-msk.html
- https://docs.aws.amazon.com/msk/latest/developerguide/operations.html
- https://docs.aws.amazon.com/msk/latest/developerguide/msk-get-connection-string.html
- https://docs.aws.amazon.com/msk/latest/developerguide/client-access.html
- https://docs.aws.amazon.com/msk/latest/developerguide/create-topic.html


## Kafka Client tools
- kafka client and requisite client-scripts
  - MacOS
    - `brew install kafka`
- GUI: **Not**-**free** Kafka Tool: http://www.kafkatool.com
- kafkacat: (brew install kafkacat) or https://docs.confluent.io/current/app-development/kafkacat-usage.html

## AWS Commands to Get Requisite Kakfa Cluster Connectivity Details
#### Following the above AWS MSK docs, here are the requisite commands to find your connection details.
```console
aws kafka list-clusters --region us-west-2 | jq .
```

#### Get/filter on the kafka cluster 'arn'
```console
# filter on '.ClusterInfoList[].ClusterArn'
aws kafka list-clusters --region us-west-2 | jq '.ClusterInfoList[].ClusterArn'
"arn:aws:kafka:us-west-2:012345678901:cluster/kafka-dev/258333cd-3e65-478d-bed0-1234567890ab1213-1"
```

#### set variable for the msk cluster arn
```console
export msk_cluster_arn=$(aws kafka list-clusters --region us-west-2 \
| jq '.ClusterInfoList[].ClusterArn' | sed 's/"//g')
```

#### show cluster arn
```console
echo $msk_cluster_arn
arn:aws:kafka:us-west-2:012345678901:cluster/kafka-dev/258333cd-3e65-478d-bed0-1234567890ab1213-1
```

#### get msk kafka bootstrap brokers
- ref: https://docs.aws.amazon.com/msk/latest/developerguide/msk-get-bootstrap-brokers.html
- Note we have configured both TLS and PLAINTEXT in our msk_cluster_config in our terraform module so we see both
```console
aws kafka get-bootstrap-brokers --cluster-arn $msk_cluster_arn
{
    "BootstrapBrokerString": "b-2.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9092,b-1.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9092",
    "BootstrapBrokerStringTls": "b-2.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9094,b-1.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9094"
}
```

#### BootstrapBrokerString
```console
aws kafka get-bootstrap-brokers --cluster-arn $msk_cluster_arn | jq '.BootstrapBrokerString'
aws kafka get-bootstrap-brokers --cluster-arn $msk_cluster_arn | jq '.BootstrapBrokerStringTls'
```

#### set var for BootstrapBrokerString
```console
export msk_cluster_bootstrap_plaintext=$(aws kafka get-bootstrap-brokers --cluster-arn $msk_cluster_arn | jq '.BootstrapBrokerString' | sed 's/"//g')
echo $msk_cluster_bootstrap_plaintext
b-2.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9092,b-1.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9092
```

#### set var for BootstrapBrokerStringTls
```console
export msk_cluster_boostrap_tls=$(aws kafka get-bootstrap-brokers --cluster-arn $msk_cluster_arn | jq '.BootstrapBrokerStringTls' | sed 's/"//g')
echo $msk_cluster_boostrap_tls
b-2.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9094,b-1.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:9094
```

#### get apache zookeeper connection string
- ref: https://docs.aws.amazon.com/msk/latest/developerguide/msk-get-connection-string.html
```console
aws kafka list-clusters --region us-west-2 | jq '.ClusterInfoList[].ZookeeperConnectString'
"z-1.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:2181,z-2.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:2181,z-3.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:2181"
```

#### Use kafka scripts/utilities (installed with kafka) to create and list topics
- export variable for zk-nodename
```console
export zk_node="z-1.kafka-dev.q5maym.c2.kafka.us-west-2.amazonaws.com:2181"
```

- kafka create topic using var for zk-nodename
```console
kafka-topics --create --zookeeper $zk_node --replication-factor 1 --partitions 1 --topic cmcc-testing-123
Created topic cmcc-testing-123.

kafka-topics --list --zookeeper $zk_node
cmcc-test
cmcc-test-from-kafka-topics-script
cmcc-testing-123
```

#### MacOS Kafka Utilities installed (via brew)
`ls /usr/local/bin |grep kafka`
```console
kafka-acls
kafka-broker-api-versions
kafka-configs
kafka-console-consumer
kafka-console-producer
kafka-consumer-groups
kafka-consumer-perf-test
kafka-delegation-tokens
kafka-delete-records
kafka-dump-log
kafka-log-dirs
kafka-mirror-maker
kafka-preferred-replica-election
kafka-producer-perf-test
kafka-reassign-partitions
kafka-replica-verification
kafka-run-class
kafka-server-start
kafka-server-stop
kafka-streams-application-reset
kafka-topics
kafka-verifiable-consumer
kafka-verifiable-producer
kafkacat
```

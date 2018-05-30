yum install -y docker
echo "DOCKER_STORAGE_OPTIONS="--storage-driver devicemapper "" > /etc/sysconfig/docker-storage
systemctl enable docker
systemctl start docker
#Run interface.sh to duplicate your active port <em1, eno0 etc> do this for each instance of elasticsearch
read -p "Domain Name (e.g. test.lan): " DOMAIN_NAME
read -p "How many Elastic Nodes?: " NODES
read -p "which interface would you like to clone?: " INTERFACE
read -p "Configuration and data storage directory? (e.g /data): " DATA_DIR
read -p "Elasticsearch heap size (never over 32!): " HEAP
read -p "Cluster Name: ": CLUSTER
read -p "elastic password: " ELASTIC_PASSWORD
version='Please choose elastic stack version: '
options=("2.4" "5.6.7" "6.2.4")
select opt in "${options[@]}"
do
    case $opt in
        "2.4")
            version=2.4
            kibana_version=4.2
            break
            ;;
        "5.6.7")
            version=5.6.7
            echo "elasticstack 5.6.7"
            break
            ;;
        "6.2.4")
            version=6.2.4
            echo "elasticstack 6.2.4"
            break
            ;;
        *) echo invalid option;;
    esac
done
#pull necesary container images
yum install -y docker
docker pull docker.elastic.co/elasticsearch/elasticsearch-platinum:$version
docker pull docker.elastic.co/kibana/kibana:$version
#Configure rhel to run containers
mkdir -p $DATA_DIR
chmod -R 777 $DATA_DIR
service docker stop
sudo sysctl -w vm.max_map_count=262144
service docker start
echo "net.ipv4.conf.all.forwarding=1" >> /usr/lib/sysctl.d/00-system.conf
echo "vm.max_map_count=1073741824" >> /usr/lib/sysctl.d/00-system.conf
#deploy Elastic containers
COUNTER=1
while [  $COUNTER -le $NODES ]; do
  read -p "interface-$COUNTER IP address?: " CONTAINER_IP
  echo -n ""$CONTAINER_IP", "  >> iplist.txt
  ./interface.sh $INTERFACE $CONTAINER_IP $COUNTER
  ./docker.sh $CONTAINER_IP $COUNTER $DOMAIN_NAME $DATA_DIR $HEAP $CLUSTER $COUNTER $NODES $version $ELASTIC_PASSWORD
  let COUNTER=COUNTER+1
done
## restart nodes
docker exec -itd kibana sed -i s/changeme/$ELASTIC_PASSWORD/g /usr/share/kibana/config/kibana.yml
chmod -R g+rwx $DATA_DIR
chgrp -R 1000 $DATA_DIR
docker restart $(docker ps -a | grep elasticsearch_)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## kibana url
echo "Your kibana instance is now running at $(docker ps -a -f NAME=kibana | awk '{print $11}' | awk -F"->" '{print $1}')"
echo "elastic password: " $ELASTIC_PASSWORD
echo "Cluster Name: $CLUSTER"
echo "Cluster Version $version"
echo "Number of nodes $NODES"
echo "Data directory $DATA_DIR"

#Run interface.sh to duplicate your active port <em1, eno0 etc> do this for each instance of elasticsearch
read -p "Domain Name (e.g. test.lan): " DOMAIN_NAME
read -p "How many Elastic Nodes?: " NODES
read -p "which interface would you like to clone?: " INTERFACE
read -p "Configuration and data storage directory? (e.g /data/): " DATA_DIR
read -p "Elasticsearch heap size (never over 32!): " HEAP
read -p "Cluster Name:?": CLUSTER
read -p "How large would you like your docker pool to be?" POOL_SZ
read -p "How large would you like your container storage size to be?" DOCKER_SZ
#pull necesary container images
docker pull docker.elastic.co/elasticsearch/elasticsearch:5.6.5
docker pull docker.elastic.co/kibana/kibana:5.6.5
#Configure rhel to run containers
mkdir -p $DATA_DIR
chmod -R 777 $DATA_DIR
dd if=/dev/zero of=/var/lib/docker/devicemapper/devicemapper/data bs=1G count=0 seek=$POOL_SZ
service docker stop
sudo sysctl -w vm.max_map_count=262144
dockerd --storage-opt dm.basesize=$DOCKER_SZ"G"
service docker start
echo "net.ipv4.conf.all.forwarding=1" >> /usr/lib/sysctl.d/00-system.conf
echo "vm.max_map_count=1073741824" >> /usr/lib/sysctl.d/00-system.conf
#deploy Elastic containers
COUNTER=1
while [  $COUNTER -le $NODES ]; do
  read -p "interface-$COUNTER IP address?: " CONTAINER_IP
  echo -n ""$CONTAINER_IP",  "  >> iplist.txt
  ./interface.sh $INTERFACE $CONTAINER_IP $COUNTER
  ./docker.sh $CONTAINER_IP $COUNTER $DOMAIN_NAME $DATA_DIR $HEAP $CLUSTER $COUNTER $NODES
  let COUNTER=COUNTER+1
done

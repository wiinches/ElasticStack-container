# Docker.sh
#
# This script builds and clusters Elastic Stack (elasticsearch instances and kibana).
# Usage:           1               2       3           4            5       6       7         8     9         10
# ./docker.sh <IP of container> <Node#> <domain> <data directory> <HEAP> <cluster><counter><Nodes><version><elastic_password>
HOSTS=$(cat iplist.txt)
$
mkdir -p $4/elasticsearch_$2/data
chmod -R 777 $4/elasticsearch_$2
docker run -itd --name elasticsearch_$2 --restart=always \
--privileged \
-v $4/elasticsearch_$2/data:/usr/share/elasticsearch/data/ \
-e cluster.name=docker-$6 \
-e ELASTIC_PASSWORD=$10 \
-e node.name="elasticsearch_$2" \
-e "discovery.zen.ping.unicast.hosts=$HOSTS" \
-e ES_JAVA_OPTS="-Xms$5"g" -Xmx$5"g"" \
-p $1:9200:9200 -p $1:9300:9300 \
docker.elastic.co/elasticsearch/elasticsearch-platinum:$9

if [ $7 == $8 ]
then
  docker run -itd --name kibana --restart=always \
  --link elasticsearch_$2:elasticsearch -p $1:80:5601 \
  docker.elastic.co/kibana/kibana:$9
fi

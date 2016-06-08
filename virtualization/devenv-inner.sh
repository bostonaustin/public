# start all the docker containers for a monitoring server
#
# includes zookeeper, icinga containers
#
# missing mysql, logstash, redis, elasticsearch containers

start(){
	mkdir -p $APPS/zookeeper/data
	mkdir -p $APPS/zookeeper/logs
	sudo docker rm zookeeper > /dev/null 2>&1
	ZOOKEEPER=$(docker run \
		-d \
		-p 2181:2181 \
		-v $APPS/zookeeper/logs:/logs \
		-name zookeeper \
		server:2181/zookeeper)
	echo "Started ZOOKEEPER in container $ZOOKEEPER"

	mkdir -p $APPS/icinga/data
	mkdir -p $APPS/icinga/logs
	sudo docker rm icinga > /dev/null 2>&1
	ICINGA=$(docker run \
		-d \
		-p 9092:9092 \
		-v $APPS/icinga/data:/data \
		-v $APPS/icinga/logs:/logs \
		-name icinga \
		-link zookeeper:zookeeper \
		server:80/icinga)
	echo "Started ICINGA in container $ICINGA"
}
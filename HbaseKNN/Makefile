# Makefile for Hadoop MapReduce Twitter Followers project.

# Customize these paths for your environment.
# -----------------------------------------------------------
hadoop.root=/usr/local/hadoop
hbase.root=/usr/local/Hbase
jar.name=twitter-mr-1.0.jar
jar.path=target/${jar.name}
job.name=twitter.KNNHbaseInsert
local.input.nodes=input/Twitter-dataset/nodes
local.input.edges=input/Twitter-dataset/edges_test
local.output=output
# Pseudo-Cluster Execution
hdfs.user.name=kodefear
hdfs.input.nodes=nodes
hdfs.input.edges=edges
hdfs.output=output
# AWS EMR Execution
aws.emr.release=emr-5.17.0
aws.region=us-east-1
aws.bucket.name=kodefear-ass1
aws.subnet.id=subnet-fd0f899a
aws.input.nodes=nodes
aws.input.edges=edges
aws.output=output/MR-C2R2
aws.log.dir=log
aws.num.nodes=10
aws.instance.type=m4.large
# -----------------------------------------------------------

# Compiles code and builds jar (with dependencies).
jar:
	mvn clean package

# Removes local output directory.
clean-local-output:
	rm -rf ${local.output}*

# Runs standalone
# Make sure Hadoop  is set up (in /etc/hadoop files) for standalone operation (not pseudo-cluster).
# https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html#Standalone_Operation
local: jar clean-local-output
	${hadoop.root}/bin/hadoop jar ${jar.path} ${job.name} ${local.input.nodes} ${local.input.edges} ${local.output}

# Start HDFS
start-hdfs:
	${hadoop.root}/sbin/start-dfs.sh

# Stop HDFS
stop-hdfs: 
	${hadoop.root}/sbin/stop-dfs.sh
	
# Start YARN
start-yarn: stop-yarn
	${hadoop.root}/sbin/start-yarn.sh

# Stop YARN
stop-yarn:
	${hadoop.root}/sbin/stop-yarn.sh

# Reformats & initializes HDFS.
format-hdfs: stop-hdfs
	rm -rf /tmp/hadoop*
	${hadoop.root}/bin/hdfs namenode -format

# Initializes user & input directories of HDFS.	
init-hdfs: start-hdfs
	${hadoop.root}/bin/hdfs dfs -rm -r -f /user
	${hadoop.root}/bin/hdfs dfs -mkdir /user
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/input
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/input/${hdfs.input.nodes}
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/input/${hdfs.input.edges}

add-data-hdfs:
	${hadoop.root}/bin/hdfs dfs -rm -r -f /user
	${hadoop.root}/bin/hdfs dfs -mkdir /user
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/input
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/input/${hdfs.input.nodes}
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/input/${hdfs.input.edges}
	${hadoop.root}/bin/hdfs dfs -put ${local.input.nodes}/* /user/${hdfs.user.name}/input/${hdfs.input.nodes}
	${hadoop.root}/bin/hdfs dfs -put ${local.input.edges}/* /user/${hdfs.user.name}/input/${hdfs.input.edges}

# Load data to HDFS
upload-input-hdfs: start-hdfs
	${hadoop.root}/bin/hdfs dfs -put ${local.input.nodes}/* /user/${hdfs.user.name}/input/${hdfs.input.nodes}
	${hadoop.root}/bin/hdfs dfs -put ${local.input.edges}/* /user/${hdfs.user.name}/input/${hdfs.input.edges}

# Removes hdfs output directory.
clean-hdfs-output:
	${hadoop.root}/bin/hdfs dfs -rm -r -f ${hdfs.output}*

# Download output from HDFS to local.
download-output-hdfs: clean-local-output
	mkdir ${local.output}
	${hadoop.root}/bin/hdfs dfs -get ${hdfs.output}/* ${local.output}

# Runs pseudo-clustered (ALL). ONLY RUN THIS ONCE, THEN USE: make pseudoq
# Make sure Hadoop  is set up (in /etc/hadoop files) for pseudo-clustered operation (not standalone).
# https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html#Pseudo-Distributed_Operation
pseudo: jar stop-yarn stop-hbase format-hdfs init-hdfs upload-input-hdfs start-yarn clean-local-output
	${hadoop.root}/bin/hadoop jar ${jar.path} ${job.name} input/${hdfs.input.nodes} input/${hdfs.input.edges} ${hdfs.output}
	make download-output-hdfs

# Runs pseudo-clustered (quickie).
pseudoq: jar clean-local-output clean-hdfs-output
	${hadoop.root}/bin/hadoop jar ${jar.path} ${job.name} input/${hdfs.input.nodes} input/${hdfs.input.edges} ${hdfs.output}
	make download-output-hdfs

# Create S3 bucket.
make-bucket:
	aws s3 mb s3://${aws.bucket.name}

# Upload data to S3 input dir.
upload-input-aws: make-bucket
	aws s3 sync ${local.input.nodes} s3://${aws.bucket.name}/input/${aws.input.nodes}
	aws s3 sync ${local.input.edges} s3://${aws.bucket.name}/input/${aws.input.edges}

# Delete S3 output dir.
delete-output-aws:
	aws s3 rm s3://${aws.bucket.name}/ --recursive --exclude "*" --include "${aws.output}*"

# Upload application to S3 bucket.
upload-app-aws:
	aws s3 cp ${jar.path} s3://${aws.bucket.name}

# Main EMR launch.
aws: jar
	aws emr create-cluster \
		--name "Twitter MR Cluster C2R2" \
		--release-label ${aws.emr.release} \
		--instance-groups '[{"InstanceCount":${aws.num.nodes},"InstanceGroupType":"CORE","InstanceType":"${aws.instance.type}"},{"InstanceCount":1,"InstanceGroupType":"MASTER","InstanceType":"${aws.instance.type}"}]' \
	    --applications Name=Hadoop \
	    --ec2-attributes SubnetId=${aws.subnet.id} \
	    --steps '[{"Args":["${job.name}","s3://${aws.bucket.name}/input/${aws.input.nodes}","s3://${aws.bucket.name}/input/${aws.input.edges}","s3://${aws.bucket.name}/${aws.output}"],"Type":"CUSTOM_JAR","Jar":"s3://${aws.bucket.name}/${jar.name}","ActionOnFailure":"TERMINATE_CLUSTER","Name":"Custom JAR"}]' \
		--log-uri s3://${aws.bucket.name}/${aws.log.dir} \
		--use-default-roles \
		--enable-debugging \
		--auto-terminate

# Download output from S3.
download-output-aws: clean-local-output
	mkdir ${local.output}
	aws s3 sync s3://${aws.bucket.name}/${aws.output} ${local.output}

# Change to standalone mode.
switch-standalone:
	cp config/standalone/*.xml ${hadoop.root}/etc/hadoop

# Change to pseudo-cluster mode.
switch-pseudo:
	cp config/pseudo/*.xml ${hadoop.root}/etc/hadoop

# Package for release.
distro:
	rm -f MR-Demo.tar.gz
	rm -f MR-Demo.zip
	rm -rf build
	mkdir -p build/deliv/MR-Demo
	cp -r src build/deliv/MR-Demo
	cp -r config build/deliv/MR-Demo
	cp -r input build/deliv/MR-Demo
	cp pom.xml build/deliv/MR-Demo
	cp Makefile build/deliv/MR-Demo
	cp README.txt build/deliv/MR-Demo
	tar -czf MR-Demo.tar.gz -C build/deliv MR-Demo
	cd build/deliv && zip -rq ../../MR-Demo.zip MR-Demo

start-region:
	${hbase.root}/bin/local-regionservers.sh start 2

start-backup:
	${hbase.root}/bin/local-master-backup.sh start 2

# Start HDFS
start-hbase:
	${hbase.root}/bin/start-hbase.sh

stop-region:
	${hbase.root}/bin/local-regionservers.sh stop 2

stop-backup:
	${hbase.root}/bin/local-master-backup.sh stop 2

# Start HDFS
stop-hbase:
	${hbase.root}/bin/stop-hbase.sh

pseudohbase: stop-yarn format-hdfs init-hdfs upload-input-hdfs start-yarn clean-local-output
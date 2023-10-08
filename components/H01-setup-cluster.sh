#!/bin/bash
SCRN=$(basename "$0")

#### PREM-CHECKS ####
function helper() {
	echo "Usage: ./$SCRN <directory of hadoop, default: \"~/hadoop\">"
	echo "E.g: ./$SCRN /home/hduser/hadoop"
	echo
	echo "NOTE: ~/.bashrc should have HADOOP_HOME at the bottom"
	echo "      after running H00-download-hadoop.sh"
	echo
}

# source from .bashrc in case of batch runs
source ~/.bashrc

# check if HADOOP_HOME was defined (script installed)
if [[ -z "${HADOOP_HOME}" || -z "${JAVA_HOME}" ]] ;
then
	echo "$SCRN: Error: HADOOP_HOME or JAVA_HOME not defined,"
	echo "$SCRN:        try running script H00-download-hadoop.sh again"
	echo "$SCRN: Exiting..."
	exit 1
fi

#### START SCRIPT ####
cd ${HADOOP_HOME}
echo "$SCRN: Setting up Hadoop configuration"

# etc/hadoop/hadoop-env.sh
echo "$SCRN: hadoop-env: Fill in JAVA_HOME"
TARGET="etc/hadoop/hadoop-env.sh"
sed -i '/^# export JAVA_HOME=$/c\'"export JAVA_HOME=${JAVA_HOME}" "${TARGET}"
#^ The sed regex ensures no hit after modify, no need to check.

# etc/hadoop/core-site.xml
echo "$SCRN: core-site.xml: Fill in configurations"
TARGET="etc/hadoop/core-site.xml"
NEW_CONF="
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://namenode:9000</value>
	</property>
"

#- insert in-between the tags
if sed -n '/<configuration>/,/<\/configuration>/{//!p}' "${TARGET}" | grep -q . ;
then
	echo "$SCRN: core-site.xml: Content exists, skipping..."
else
	sed -i '/<configuration>/a\'$'\n'"${NEW_CONF//$'\n'/\\n}"$'\n' "${TARGET}"
	echo "$SCRN: core-site.xml: Done."
fi

# etc/hadoop/hdfs-site.xml
echo "$SCRN: hdfs-site.xml: Fill in configurations"
TARGET="etc/hadoop/hdfs-site.xml"
NEW_CONF="
	<property>
		<name>dfs.replication</name>
		<value>2</value>
	</property>
	<property>
		<name>dfs.namenode.name.dir</name>
		<value>${HADOOP_HOME}/hdfs/namenode</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>${HADOOP_HOME}/hdfs/datanode</value>
	</property>
	<property>
		<name>dfs.permissions.enabled</name>
		<value>false</value>
	</property>"

if sed -n '/<configuration>/,/<\/configuration>/{//!p}' "${TARGET}" | grep -q . ;
then
	echo "$SCRN: hdfs-site.xml: Content exists, skipping..."
else
	sed -i '/<configuration>/a\'$'\n'"${NEW_CONF//$'\n'/\\n}"$'\n' "${TARGET}"
	echo "$SCRN: hdfs-site.xml: Done."
fi

# etc/hadoop/mapred-site.xml 
echo "$SCRN: mapred-site.xml: Fill in configurations"
TARGET="etc/hadoop/mapred-site.xml"
NEW_CONF="
	<property>
		<name>mapreduce.job.tracker</name>
		<value>namenode:5431</value>
	</property>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
	<property>
		<name>yarn.app.mapreduce.am.env</name>
		<value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
	</property>
	<property>
		<name>mapreduce.map.env</name>
		<value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
	</property>
	<property>
		<name>mapreduce.reduce.env</name>
		<value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
	</property>"

if sed -n '/<configuration>/,/<\/configuration>/{//!p}' "${TARGET}" | grep -q . ;
then
	echo "$SCRN: mapred-site.xml: Content exists, skipping..."
else
	sed -i '/<configuration>/a\'$'\n'"${NEW_CONF//$'\n'/\\n}"$'\n' "${TARGET}"
	echo "$SCRN: mapred-site.xml: Done."
fi

# etc/hadoop/yarn-site.xml 
echo "$SCRN: yarn-site.xml: Fill in configurations"
TARGET="etc/hadoop/yarn-site.xml"
NEW_CONF="
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
	<property>
		<name>yarn.resourcemanager.webapp.address</name>
		<value>namenode:8088</value>
	</property>
	<property>
		<name>yarn.resourcemanager.scheduler.address</name>
		<value>namenode:8030</value>
	</property>
	<property>
		<name>yarn.resourcemanager.resource-tracker.address</name>
		<value>namenode:8031</value>
	</property>
	<property>
		<name>yarn.resourcemanager.address</name>
		<value>namenode:8032</value>
	</property>
	<property>
		<name>yarn.resourcemanager.admin.address</name>
		<value>namenode:8033</value>
	</property>
	<property>
		<name>yarn.scheduler.capacity.root.support.user-limit-factor</name>
		<value>2</value>
	</property>
	<property>
		<name>yarn.nodemanager.disk-health-checker.min-healthy-disks</name>
		<value>0.0</value>
	</property>
	<property>
		<name>yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage</name>
		<value>100.0</value>
	</property>"

#- different logic (check <= 5 lines) because someone decides to add
#- <!-- Site specific YARN configuration properties -->
#-
#- just lol
if awk -v RS='</?configuration>' 'END{if (NR<=5) exit 0; else exit 1}' "${TARGET}";
then
	sed -i '/<configuration>/a\'$'\n'"${NEW_CONF//$'\n'/\\n}"$'\n' "${TARGET}"
	echo "$SCRN: yarn-site.xml: Done."	
else
	echo "$SCRN: yarn-site.xml: Content exists, skipping..."
fi

# Folders for node storage | need not care if empty though
sudo mkdir -p hdfs/namenode
sudo mkdir -p hdfs/datanode
sudo chmod 777 hdfs/namenode
sudo chmod 777 hdfs/datanode

# Define workers
echo "$SCRN: workers: Fill in node entries"
echo "namenode" > etc/hadoop/namenode
echo "datanode1
datanode2" > etc/hadoop/workers

exit

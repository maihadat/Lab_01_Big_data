#!/bin/bash

RET=${PWD}
SCRN=$(basename "$0")
# Change this if you want different Hadoop version
# NOTE: check if that website exists first. I won't, I'm lazy
VERS=3.3.6

# Directory to install hadoop to
# DEFAULT: ~/hadoop
INST_DIR=${1:-~/hadoop}
echo $INST_DIR

echo "$SCRN: Downloading Hadoop ${VERS} to $INST_DIR"
if [[ ! -d "$INST_DIR" ]] ;
then
	mkdir -p $INST_DIR
	cd $INST_DIR

	# Download Hadoop
	[[ ! -f hadoop-${VERS}.tar.gz ]] && wget https://dlcdn.apache.org/hadoop/common/hadoop-${VERS}/hadoop-${VERS}.tar.gz -O hadoop-${VERS}.tar.gz

	# Install to $INST_DIR
	echo "$SCRN: Installing Hadoop to ${INST_DIR}"
	tar -xzvf hadoop-${VERS}.tar.gz -C . --strip-components=1
else
	echo "$SCRN: Install directory exists, assuming installed, skipping..."
fi

# Check if java8 exists, Hadoop sucks with other LTS versions
echo "
############################################################

$SCRN: Checking java version
"

if apt-cache show "openjdk-8-jdk" &>/dev/null; then
	echo "$SCRN: installing openjdk-8-jdk"
	sudo apt install -y openjdk-8-jdk
	JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
	USE_JAVA_11=0
else
	echo "$SCRN: Java 8 is N/A on your distro"
	echo "$SCRN: Using Java 11 now, but it is not recommended on Hadoop's docs"
	JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
	USE_JAVA_11=1

	# if too erroneous, revert to Java 8 with Zulu's instead
	echo
	echo "NOTE: if Java 11 is causing problems, you might want to try Zulu's Java 8 instead"
	echo "https://www.azul.com/downloads/?version=java-8-lts&os=debian&architecture=x86-64-bit&package=jdk#zulu"
	echo
	echo "NOTE: install the .deb, then set JAVA_HOME in ~/.bashrc to \"/usr/lib/jvm/zulu-8-amd64/\" (without quotes)"
fi

# Add some basic Hadoop env vars to .bashrc
[[ ! $(grep HADOOP_HOME ~/.bashrc) ]] && echo "
# $SCRN: add entries for Hadoop
export HADOOP_HOME=$INST_DIR
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
" >> ~/.bashrc

if [[ ! $(grep JAVA_HOME ~/.bashrc) ]] ;
then
	[[ USE_JAVA_11 -eq 1 ]] && echo "# $SCRN: Reminder: use Java 8 instead if Java 11 is broken" >> ~/.bashrc
	echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
fi

exit

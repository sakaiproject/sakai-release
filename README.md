sakai-listdir-plugin
====================

Maven plugin to list what directory the artifact is in

 In the Sakai trunk directory

1. Get a list of all provided dependencies with a plugin and put in a unique list
  
  * rm /tmp/dependency-list.txt ; mvn org.apache.maven.plugins:maven-dependency-plugin:2.2:list -Dsort=true -DincludeScope=compile -DappendOutput=true -DoutputFile=/tmp/dependency-list.txt
  * grep ":provided" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | uniq > /tmp/pdeps.txt
  * grep ":compile" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | uniq > /tmp/cdeps.txt
    * TODO: Do we have to include cross project compile dependencies? How much to actually release? Do something with cdeps.txt

2. Use this plugin (I couldn't find one) that will list what directory the pom 
for all artifacts is in. This could be done without a plugin, but seems pretty 
easy.
  * mvn org.sakaiproject:sakai-dirlist-plugin:list-dirs > /tmp/artifacts-list.txt
  * grep ":::" /tmp/artifacts-list.txt | sort | uniq > /tmp/artifacts.txt

3. Match up list in #1 (pdeps.txt) with list in #2 (artifacts.txt), write as <modules>  </modules> (This script)
  * Run as artparse.rb 


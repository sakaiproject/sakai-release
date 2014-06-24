sakai-listdir-plugin
====================

Maven plugin to list what directory the artifact is in

 In the Sakai trunk directory

 Get a list of all provided dependencies with a plugin and put in a unique list
 1) 
 rm /tmp/dependency-list.txt ; mvn org.apache.maven.plugins:maven-dependency-pl
ugin:2.2:list -Dsort=true -DincludeScope=compile -DappendOutput=true -DoutputFi
le=/tmp/dependency-list.txt
 grep ":provided" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | 
uniq > /tmp/pdependencies.txt
 grep ":compile" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | u
niq > /tmp/cdependencies.txt
 TODO: Do we have to include cross project compile dependencies? How much to ac
tually release?

 3) Write a plugin (I couldn't find one) that will list what directory the pom 
for all artifacts is in. This could be done without a plugin, but seems pretty 
easy.
 mvn org.sakaiproject:sakai-dirlist-plugin:list-dirs > /tmp/artifacts-list.txt
 grep ":::" /tmp/artifacts-list.txt | sort | uniq > /tmp/artifacts.txt

 4) Match up list in #2 (dependency-list.txt) with list in #3 (artifacts-list.t
xt), write as <modules>  </modules> (This script)
 Run as artparse.rb 


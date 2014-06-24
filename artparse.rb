#!/usr/bin/env ruby
#
# Helper module to make sense of artifacts and dependencies.
#
#
=begin

 In the Sakai trunk directory

 Get a list of all provided dependencies with a plugin and put in a unique list
 1) 
 rm /tmp/dependency-list.txt ; mvn org.apache.maven.plugins:maven-dependency-plugin:2.2:list -DincludeScope=provided -DappendOutput=true -DoutputFile=/tmp/dependency-list.txt
 grep org.sakaiproject /tmp/dependency-list.txt | sort | uniq > /tmp/dependencies.txt

 3) Write a plugin (I couldn't find one) that will list what directory the pom for all artifacts is in. This could be done without a plugin, but seems pretty easy.
 mvn org.sakaiproject:sakai-dirlist-plugin:list-dirs > /tmp/artifacts-list.txt
 grep ":::" /tmp/artifacts-list.txt | sort | uniq > /tmp/artifacts.txt

 4) Match up list in #2 (dependency-list.txt) with list in #3 (artifacts-list.txt), write as <modules>  </modules> (This script)
 Run as artparse.rb | sort

=end

if (!File.exists?("/tmp/artifacts.txt") || !File.exists?("/tmp/dependencies.txt")) then

	abort("No artifacts.txt or dependencies.txt file. Please see directions. exiting")
end

file = File.open("/tmp/artifacts.txt")

art = Hash.new
file.each do |line|
	values = line.split(":::");
	art[values[0].strip] = values[2].strip;
end

file = File.open("/tmp/dependencies.txt");

file.each do |line|
	a = line.rpartition(":provided");
	thisart = a[0].strip
	if (art[thisart] != nil) then
		puts "<module>#{art[thisart]}</module>";
	end

end


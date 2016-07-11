#!/usr/bin/env ruby
#
# Helper module to make sense of artifacts and dependencies.
#
# Look at README.md for info

if (!File.exists?("/tmp/artifacts.txt") || !File.exists?("/tmp/pdeps.txt")) then

	abort("No artifacts.txt or dependencies.txt file. Please see directions. exiting")
end

file = File.open("/tmp/artifacts.txt")

art = Hash.new
file.each do |line|
	values = line.split(":::");
	art[values[0].strip] = values[2].strip;
end

file = File.open("/tmp/pdeps.txt");

puts "<profile>"
puts "	<id>sakai-provided</id>"
puts "	<modules>"
#Put master in as default, and jsf modules.
puts "		<module>master</module>"
puts "		<module>jsf</module>"
puts "		<module>velocity</module>"
#Also add portal-util for now, probably won't be needed after LSNBLDR-391
puts "      <!-- LSNBLDR-391 -->"
puts "      <module>portal/portal-util/util</module>"
file.each do |line|
	a = line.rpartition(":provided");
	thisart = a[0].strip
	#Exclude jsf and velocity stuff cause we put it up top
	if (art[thisart] != nil && thisart !~ /jsf/ && thisart !~ /velocity/) then
		puts "		<module>#{art[thisart]}</module>";
	end

end
puts "	</modules>"
puts "</profile>"


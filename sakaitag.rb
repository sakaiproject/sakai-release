#!/usr/bin/env ruby

# Script to tag a release a new release

=begin

General idea
* Go through the .externals split tool and externals
* Take each branch defined and copy to a similarly named tag
* Go through each local tool and do an svn switch over to that tag
* Commit to the tag the changes for each revision
* Commit the new .externals
* TODO: 
  Automate the following steps (Just have to figure out a few things)
  svn cp https://source.sakaiproject.org/svn/sakai/branches/sakai-10.x/
  https://source.sakaiproject.org/svn/sakai/tags/sakai-10.0
  svn co svn co https://source.sakaiproject.org/svn/sakai/tags/sakai-10.0 --ignore-externals
  cp .externals.new sakai-10.0/.externals
  cd sakai-10.0
  svn propset svn:externals -F .externals .
  svn commit --depth empty . .externals 

  And commit the externals from newexternals

Go to the next step in the process!
=end

#Flag to make tags or not, only need to run once, for testing
$domaketags = 0;
$doswitchtags = 0;
$docommittags = 0;
$doupdateexternals = 0;

$releasetag = "sakai-10.0"
$releasejira = "SAK-26575" 

class SakaiTag

	def initialize
		@exts = Hash.new
		File.open(".externals") {|file|
			file.each do |line|
				m = line.match /(.*)(-r\d+)?(\s+.+source.sakaiproject.org\/svn.*)/
				if (m != nil )
					@exts[m[1]] = m[3].strip 
				end
			end
		}
	end

	def newexternals()
		`svn co --ignore-externals tmpdir`

		File.open(".externals.new","w") { |file|
			file.puts("# Sakai CLE Externals")
			file.puts("# Updating: svn propset svn:externals -F .externals .")
			file.puts("# Corporate POM for ${releasetag}")

			@exts.each {|tool,branch|
				tag=mktag(branch)
				file.puts("#{tool} #{tag}")
			}
		}	
	end


	def mktag(branch)
		tag = branch.chop.rpartition("/")[0].rpartition("/")[0] + "/tags/#{$releasetag}"
	end

	#Runs svnmucc on all exts (tool=>branch from externals) to make tags
	def maketags()
		svncp = ""
		#Copy all of the branches to a tag
		@exts.each {|tool,branch|
			tag = mktag(branch)
			svncp += "cp HEAD #{branch} #{tag} "
		}

		puts svncp
		`svnmucc #{svncp} -m '#{$releasejira} Creating branch for #{$releasetag}'`;
	end 

	def committags()
		tools = "";
		#Make a string of all the tools
		@exts.each {|tool,branch|
			tools += "#{tool} "
		}
		`svn ci #{tools} -m '#{$releasejira} Commiting poms for #{$releasetag}'`
	end

	def switchtags()
		@exts.each {|tool,branch|
			tag = mktag(branch)
			puts "Switching #{tool} to #{tag}"
			puts `cd #{tool};svn switch #{tag};`
		}
	end
end

s=SakaiTag.new

if ($domaketags == 1) then
	puts "Making tags"
	s.maketags()
end

if ($doswitchtags == 1) then
	puts "Switching tags"
	s.switchtags()
end

if ($docommittags == 1) then 
	puts "Committing tags"
	s.committags()
end

if ($doupdateexternals == 1) then
	puts "Updating externals"
	s.newexternals()
end


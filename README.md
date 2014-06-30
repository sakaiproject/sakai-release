Releasing sakai involves 

1. Changing versions 
2. Creating tags 
3. Deploying artifacts to maven repo's.

We previously used the maven release plugin, but that generally doesn't work out that great. It does a lot of these steps and would have been nice for sure. A lot of other people aren't fans either. http://axelfontaine.com/blog/final-nail.html

*This guide is a WIP.*

# Versioning the new version
For this task we will leverage the maven versions plugin http://mojo.codehaus.org/versions-maven-plugin/

When a branch is ready to be made a version the first thing is to update versions

In order to ensure all the versions were updated accurately it's important to find out how many versions there currently are with something like:

```
grep -rl "<version>10-SNAPSHOT</version>" --include=*.xml * |wc -l
539
``` 

Then update the version using the appropriate new version, in this case 10.0:

```
mvn versions:set -DnewVersion=10.0 -DgenerateBackupPoms=false -f master/pom.xml
```

*Note currently there are some properties that will need to be updated manually in master/pom.xml currently they are below. The plugin does not update these:*

```
<sakai.version>10-SNAPSHOT</sakai.version>
<sakai.kernel.version>10-SNAPSHOT</sakai.kernel.version>
<sakai.msgcntr.version>10-SNAPSHOT</sakai.msgcntr.version>
```

This will update all the relevant versions of all the sakai modules to the 10.0 version. But to be sure we check there are no SNAPSHOTS. You might just want to look for any SNAPSHOT. RSF SNAPSHOT's also need to be updated in master if they exist (RSF is released separately).

```
grep -rl "10-SNAPSHOT" --include=*.xml * |wc -l
0
```

relevant xml in pom:

```
<project>
    ...
    <version>10-SNAPSHOT</version>
    ...
    <build>
      <plugins>
        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>versions-maven-plugin</artifactId>
            <version>2.1</version>
        </plugin>
      </plugins>
    </build>
</project>
```

Now that all of the versions are set locally, we need to create tags and switch over to this tag.

# Tagging
The maven plugin that would typically handle this is the scm plugin http://maven.apache.org/scm/maven-scm-plugin/ but currently there is an issue with this plugin and our project structuring see http://jira.codehaus.org/browse/SCM-342.

So there is ruby script in this project directory that

1. Reads through the .externals file
2. Take each branch and make tags off of it (domaketags)
3. Go through each local directory that's checked out and do an svn switch over to that tag (doswitchtags)
4. Commit to the tag the changes for the versions (docommittags)
5. Commit the new .externals (doupdateexternals)

This has been tested with ruby 2.0 and 1.9 and requires no gems. It does (at the moment) require some manual configuration to run and doesn't do anything otherwise because I've only ran it once.

At the top of the file there are 4 variables that correspond to each phase, set these all to 1 to run them. If they're 0 it won't run that phase. Also define the release tag that will be created and the jira that will be used in the message.

For this to work you have to be in the directory with .externals and have full commit access. After all of these steps are run successfully, there's a few more easy manual steps that need to be done that might be automated later.

- Copy the main sakai branch into a tag
```
  svn cp https://source.sakaiproject.org/svn/sakai/branches/sakai-10.x/ https://source.sakaiproject.org/svn/sakai/tags/sakai-10.0
```
- Checkout the tag locally, no externals
```
  svn co svn co https://source.sakaiproject.org/svn/sakai/tags/sakai-10.0 --ignore-externals
```
- Copy the .externals.new that was generated here by doupdateexternals into the .externals
```
  cp .externals.new sakai-10.0/.externals
```
- Do into the directory, set the property on the externals and commit it
```
  cd sakai-10.0
  svn propset svn:externals -F .externals .
  svn commit --depth empty . .externals 
```

# Deploy artifacts and binaries
Recently there have been discussions that sakai should only release api's to maven repositories, with the regular pack-demo,pack-bin,pack-src to the source.sakaiproject.org.

They are possibly a few ways to handle this but we could configure the deploy plugin or possibly use profiles. It looks like it worked out well to just use profiles.

Profiles were added to the main build pom.

## Pre-setup : Credentials for deployment
All artifacts are uploaded and released from Sonatype. You need an account and gpg key in sonatype. Make sure that these the passwords for these are properly configured in ~/.m2/settings.xml. Read the guide below
 
* https://docs.sonatype.org/display/Repository/Sonatype+OSS+Maven+Repository+Usage+Guide

The actual process is under "Signup" and it involves signing up for a Jira account and adding a comment to the Sakai CLE project. https://issues.sonatype.org/browse/OSSRH-2835

Your request will be approved (denied?) and you will be able to publish org.sakaiproject artifacts.

*TODO: Expand on this section as I didn't have to get these credentials*

## Creating profiles for a build

1. Get a list of all provided dependencies with a plugin and put in a unique lis
t

  * rm /tmp/dependency-list.txt ; mvn org.apache.maven.plugins:maven-dependency-plugin:2.2:list -Dsort=true -DincludeScope=compile -DappendOutput=true -DoutputFile=/tmp/dependency-list.txt
  * grep ":provided" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | uniq > /tmp/pdeps.txt
  * grep ":compile" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | uniq > /tmp/cdeps.txt
  * TODO: Do we have to include cross project compile dependencies? How much to actually release? Do something with cdeps.txt

2. Use this plugin (I couldn't find one) that will list what directory the pom for all artifacts is in. This could be done without a plugin, but seems pretty easy.
  * mvn org.sakaiproject:sakai-dirlist-plugin:list-dirs > /tmp/artifacts-list.txt
  * grep ":::" /tmp/artifacts-list.txt | sort | uniq > /tmp/artifacts.txt

3. Match up list in #1 (pdeps.txt) with list in #2 (artifacts.txt), write as <modules>  </modules> (This script)
  * Run as artparse.rb
  * Put these modules into the base pom.xml


*artparse.rb is experimental and might need modifications*

## Deploying artifacts from this profile

This is typically handled with the deploy plugin. This should be in the parent oss sonatype pom. Because of sonatype requirements, you also need jar's for the sources and for javadocs.

It also seemed like it had to run the site plugin as well. 
So the full command to get this all deployed with that profile was
```
mvn clean install site source:jar javadoc:jar gpg:sign deploy -DdeployAtEnd=true -P sakai-provided -Dmaven.test.skip=true`
```

However after doing this and logging into the sonatype UI to verify the release, it said it failed signature validation for me.

I used this script to verify that there were bad signatures locally
```
find . -name "*.asc" | xargs -I{} gpg -v --verify {} 2>&1>/dev/null | grep -B 3 BAD
```

I'm not sure what's causing those bad signatures it would be really nice to know. There were only like 3 bad signatures out of 600 or so files released. The hopefully temporary workaround was this.

- Get the source for the latest deploy plugin that the poms reference (2.8.1) 
http://maven.apache.org/plugins/maven-deploy-plugin/source-repository.html
- Apply the patch in this directory DeployMojoSleep.patch
- Compile this plugin with the patch
- Go to the directory that is failing and run
```
 mvn install gpg:sign deploy -DdeployAtEnd=true -DdeployAtEndSleepTime=60000 -P sakai-provided
```
- Note this doesn't have the extra goals on it, just what you need. After it gets all built, open another window and verify that the asc files are signed incorrectly.
- Run `gpg -ab <filename>` on the incorrect files. It will prompt you to overwrite. Note you have to actually sign the jar, and not the asc that the find command gives you.
- Ideally this won't be a problem for you or will be figured out and this section can be removed!

- Some References
http://maven.apache.org/plugins/index.html (Maven plguins)
http://mojo.codehaus.org/plugins.html (Codehaus plugins)

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

1. Reads through the.
2. Take each branch and make tags off of it (domaketags)
3. Go through each local directory that's checked out and do an svn switch over to that tag (doswitchtags)
4. Commit to the tag the changes for the versions (docommittags)
5. Commit the new .externals (doupdateexternals)

This has been tested with ruby 2.0 and 1.9 and requires no gems. It does (at the moment) require some manual configuration to run and doesn't do anything otherwise because I've only ran it once.

At the top of the file there are 4 variables that correspond to each phase, set these all to 1 to run them. If they're 0 it won't run that phase. Also define the release tag that will be created and the jira that will be used in the message.

For this to work you have to be in the directory with .externals and have full commit access. After all of these steps are run successfully, there's a few more easy manual steps that need to be done that might be automated later.

```
#Copy the main sakai branch into a tag
  svn cp https://source.sakaiproject.org/svn/sakai/branches/sakai-10.x/ https://source.sakaiproject.org/svn/sakai/tags/sakai-10.0
#Checkout the tag locally, no externals
  svn co svn co https://source.sakaiproject.org/svn/sakai/tags/sakai-10.0 --ignore-externals
#Copy the .externals.new that was generated here by doupdateexternals into the .externals
  cp .externals.new sakai-10.0/.externals
#Do into the directory, set the property on the externals and commit it
  cd sakai-10.0
  svn propset svn:externals -F .externals .
  svn commit --depth empty . .externals 
```

# Deploy artifacts
This is typically handled with the deploy plugin. This should be in the parent oss sonatype pom.

Recently there have been discussions that sakai should only release api's to maven repositories.

They are possibly a few ways to handle this but we could configure the deploy
plugin or possibly use profiles.

Profiles were added to the main build pom
https://github.com/jonespm/sakai-listdir-plugin

Ideally it should be able to follow this process now if your settings.xml is setup for sonatype
https://docs.sonatype.org/display/Repository/Sonatype+OSS+Maven+Repository+Usage+Guide#SonatypeOSSMavenRepositoryUsageGuide-7a.DeploySnapshotsandStageReleaseswithMaven

Running mvn clean deploy -P sakai-provided

Should be all we need to do to deploy all artifacts to sonatype after the other steps on this guide are correct.

- Some References
http://maven.apache.org/plugins/index.html (Maven plguins)
http://mojo.codehaus.org/plugins.html (Codehaus plugins)

Releasing sakai involves changing versions and creating tags and deploying artifacts to maven repo's.

* maybe a snippet why maven release plugin is a pain and can't be used see http://axelfontaine.com/blog/final-nail.html

# Versioning the new version
For this task we will leverage the maven versions plugin http://mojo.codehaus.org/versions-maven-plugin/
When a branch is ready to be made a version the first thing is to update versions

In order to ensure all the versions were updated accuratley its important to find out how many versions there currently are with something like:
```
grep -rl "<version>10-SNAPSHOT</version>" --include=*.xml * |wc -l
539
``` 

Then update the version using:
mvn versions:set -DnewVersion=10.0 -DgenerateBackupPoms=false -f master/pom.xml

*Note currently there are some properties that will need to be updated manually in master currently they are:*
```
<sakai.version>11-SNAPSHOT</sakai.version>
<sakai.kernel.version>11-SNAPSHOT</sakai.kernel.version>
<sakai.msgcntr.version>11-SNAPSHOT</sakai.msgcntr.version>
```
this will update all the relevant versions of all the sakai modules to the 10.0 version but to be sure we check it with
```
grep -rl "<version>10-SNAPSHOT</version>" --include=*.xml * |wc -l
0
```
relevant xml in pom:
````
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
````
Finally we commit the changes to the version in all projects:
svn commit --include-externals -m "Update Sakai Version to 10.0"

# Tagging
The maven plugin that would typically handle this is the scm plugin http://maven.apache.org/scm/maven-scm-plugin/
but currently there is an issue with this plugin and our project structuring see http://jira.codehaus.org/browse/SCM-342

Write a script to
1) Read through the .externals, and take each branch defined and copy that to a similar tag
2) Rewrite the externals to point to these new tags
3) Go through each local directory that's checked out and do an svn switch over to that tag
4) Commit to the tag the changes for the versions
5) Commit the new .externals

relevant xml in pom:
```
<project>
  <scm>
    <connection>scm:svn:https://source.sakaiproject.org/svn/sakai/trunk</connection>
    <developerConnection>scm:svn:https://source.sakaiproject.org/svn/sakai/trunk</developerConnection>
    <url>https://source.sakaiproject.org/svn/sakai/trunk</url>
  </scm>
  <build>
    <plugins>
      <plugin>
        <artifactId>maven-scm-plugin</artifactId>
          <version>1.8.1</version>
          <configuration>
            <tag>${project.artifactId}-${project.version}</tag>
          </configuration>
        </plugin>
    </plugins>
  </build>
</project>
```

# Deploy artifacts
This is typically handled with the deploy plugin

Recently there have been discussions that sakai should only release api's to maven repositories.

They are possibly a few ways to handle this but we could configure the deploy
plugin or possibly use profiles.

Profiles were added to the main build pom
https://github.com/jonespm/sakai-listdir-plugin

Ideally it should be able to follow this process now if your settings.xml is setup for sonatype
https://docs.sonatype.org/display/Repository/Sonatype+OSS+Maven+Repository+Usage+Guide#SonatypeOSSMavenRepositoryUsageGuide-7a.DeploySnapshotsandStageReleaseswithMaven

Running mvn clean deploy -P sakai-provided

Should be all we need to do to deploy all artifacts to sonatype after the other steps on this guide are correct.

- References
http://maven.apache.org/plugins/index.html (Maven plguins)
http://mojo.codehaus.org/plugins.html (Codehaus plugins)

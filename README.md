Releasing sakai involves 

1. Changing versions 
2. Creating tags 
3. Deploying artifacts to maven repo's.

We previously used the maven release plugin, but that generally doesn't work out that great. It does a lot of these steps and would have been nice for sure. A lot of other people aren't fans either. http://axelfontaine.com/blog/final-nail.html

*This guide still is a WIP.*
Last updated for 10.3 on 12/18/2014, corrections/updates/improvments are usually made each release.
# Set the envorinment version for the version
Since this is used many times in this document, just set this variable now!
````
export SAKAI_RELEASE="10.3"
```

# Checkout the version to release
The first step is to check out the branch of Sakai you plan to release and work with. For instance this guide is based of 10.x releases. This will need to be on a system you already have some access to the version control system or plan to establish access. I put this in a directory like "source" or "release"

```
svn co https://source.sakaiproject.org/svn/sakai/branches/sakai-10.x/
```

# Versioning the new version
For this task we will leverage the maven versions plugin http://mojo.codehaus.org/versions-maven-plugin/

When a branch is ready to be made a version the first thing is to update versions

In order to ensure all the versions were updated accurately it's important to find out how many versions there currently are with something like:

```
grep -rl "<version>10-SNAPSHOT</version>" --include=*.xml * |wc -l
539
``` 

Then update the version using the appropriate new version.

```
mvn versions:set -DnewVersion=${SAKAI_RELEASE} -DgenerateBackupPoms=false -f master/pom.xml
```

*Note currently there are some properties that will need to be updated manually in master/pom.xml currently they are below. The plugin does not update these:*
*Pay particular attention to the following properties (may not be in order) - RSF may not be at the same version, please see https://github.com/rsf/RSFCheckouts*
*RSF SNAPSHOT's also need to be updated in master if they exist (RSF is released separately and should be released if updates are made to it).*

```

<sakai.version>10-SNAPSHOT</sakai.version>
<sakai.kernel.version>10-SNAPSHOT</sakai.kernel.version>
<sakai.msgcntr.version>10-SNAPSHOT</sakai.msgcntr.version>

<rsfutil.version>0.8.1-SNAPSHOT</rsfutil.version>
<sakairsf.components.version>10-SNAPSHOT</sakairsf.components.version>
<sakairsf.version>10-SNAPSHOT</sakairsf.version>

```

This will update all the relevant versions of all the sakai modules to the correct version. But to be sure we check there are no SNAPSHOTS. You might just want to look for any -SNAPSHOT. Some of these are in profiles that are not relevant to the Sakai 10 build. (Like old 2.9 profiles in lessons and lti) 

```
grep -rl "10-SNAPSHOT" --include=*.xml * |wc -l
0

After it says 0, you can move on to the tagging!
```

Relevant xml in pom for maven versions plugin (Just for reference):

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

There is ruby script in this project directory (sakaitag.rb) that

1. Reads through the .externals file
2. Take each branch and make tags off of it (domaketags)
3. Go through each local directory that's checked out and do an svn switch over to that tag (doswitchtags)
4. Commit to the tag the changes for the versions (docommittags)
5. Commit the new .externals (doupdateexternals)

This has been tested with ruby 2.0 and 1.9 and requires no gems. It does (at the moment) require some manual configuration to run and doesn't do anything otherwise because I've only ran it a few times. 
TODO: Make this script run with command line options so we don't have to change the source.

You're going to need to have ruby installed (either via a package manager or RVM) and run this script. 

At the top of the file there are 4 variables that correspond to each phase, set these all to 1 to run them. Also define the release tag that will be created and the jira that will be used in the message.

If they're set to 0 it won't run that phase so you can set each to 1 and run it four times in order. (TODO: Make it accept command line arguments) 

*Note this script can be run by setting 1 in each phase in order, domaketags, doswitchtags, docommittags, doupdateexternals*.

For this to work you have to be in the directory with .externals and have svn full commit access. So for instance I go edit this script, set all variables to 1, fill in the tag and SAK and in my 10.x source directory run. 
```
ruby ~/sakai-release/sakaitag.tb
```

It's going to have a huge wall of text where it creates tags, then a lot of processing where it switches tags, and well the rest of the process. There shouldn't be any errors on any of the phases and has been pretty reliable. Afer this is all done, there's a few more things left to do that would be nice to automate later.

*Note these examples use the environment variable so they should work if this is enter correctly above*

- Copy the main sakai branch into a tag
```
  svn cp https://source.sakaiproject.org/svn/sakai/branches/sakai-10.x/ https://source.sakaiproject.org/svn/sakai/tags/sakai-${SAKAI_RELEASE} -m "Creating tag for Sakai ${SAKAI_RELEASE}"
```
- Checkout the tag locally, no externals
```
  cd ..
  svn co https://source.sakaiproject.org/svn/sakai/tags/sakai-${SAKAI_RELEASE} --ignore-externals
```
- Copy the .externals.new that was generated in this directory by the doupdateexternals step into the .externals
```
  cp sakai-10.x/.externals.new sakai-${SAKAI_RELEASE}/.externals
```
- Do into the directory, set the property on the externals and commit it
```
  cd sakai-${SAKAI_RELEASE}
  svn propset svn:externals -F .externals .
  svn commit --depth empty . .externals -m "Comming new externals for Sakai ${SAKAI_RELEASE}" 
```
* Run an svn up now to get the new externals and also build the SAKAI_RELEASE master so it's available
```
  svn up
  cd master
  mvn clean install
  cd ..
```
* Now the deploy project still has the wrong version (SNAPSHOT) and needs a version set run on it. Remember this newVersion still has to match. If you build the master above, update-parent should set the correct version, verify that it is whatever version you set as SAKAI_RELEASE and not the previous version.
```
  cd deploy
  mvn versions:update-parent -DparentVersion=${SAKAI_RELEASE} -DgenerateBackupPoms=false
  mvn versions:set -DnewVersion=${SAKAI_RELEASE} -DgenerateBackupPoms=false
  svn commit -m "Commtting deploy for ${SAKAI_RELEASE}"
  cd ..
```

# Deploy artifacts and binaries
Recently there have been discussions that sakai should only release api's to maven repositories, with the regular pack-demo,pack-bin to the source.sakaiproject.org.

They are possibly a few ways to handle this but we could configure the deploy plugin or possibly use profiles. It looks like it worked out well to just use profiles.

Profiles were added to the main build pom.

## Pre-setup : Credentials for deployment (Only need to do this once)
All artifacts are uploaded and released from Sonatype. You need an account and gpg key in sonatype. Make sure that these the passwords for these are properly configured in ~/.m2/settings.xml. Read the guide below
 
* https://docs.sonatype.org/display/Repository/Sonatype+OSS+Maven+Repository+Usage+Guide

The actual process is under "Signup" and it involves signing up for a Jira account and adding a comment to the Sakai CLE project. https://issues.sonatype.org/browse/OSSRH-2835

Your request will be approved (denied?) and you will be able to publish org.sakaiproject artifacts.

*TODO: Expand on this section as I didn't have to get these credentials*

## Creating profiles for a build (Only need to do this once per release cycle, already done for 10)

1. Get a list of all provided dependencies with a plugin and put in a unique lis
t

  * `rm /tmp/dependency-list.txt ; mvn org.apache.maven.plugins:maven-dependency-plugin:2.2:list -Dsort=true -DincludeScope=compile -DappendOutput=true -DoutputFile=/tmp/dependency-list.txt`
  * `grep ":provided" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | uniq > /tmp/pdeps.txt`
  * `grep ":compile" /tmp/dependency-list.txt | grep "org\.sakaiproject" | sort | uniq > /tmp/cdeps.txt`
  * TODO: Do we have to include cross project compile dependencies? How much to actually release? Do something with cdeps.txt

2. Use this plugin (I couldn't find one) that will list what directory the pom for all artifacts is in. This could be done without a plugin, but seems pretty easy.
  * `mvn org.sakaiproject:sakai-dirlist-plugin:list-dirs > /tmp/artifacts-list.txt`
  * `grep ":::" /tmp/artifacts-list.txt | sort | uniq > /tmp/artifacts.txt`

3. Match up list in #1 (pdeps.txt) with list in #2 (artifacts.txt), write as <modules>  </modules> (This script)
  * Run as artparse.rb
  * Put these modules into the base pom.xml

*artparse.rb is experimental and might need modifications*

## Deploying artifacts from this profile (You do need to do this)

This is typically handled with the deploy plugin. This process changed by sonatype in the 10.? release with the sonatype nexus plugin. (https://github.com/sonatype/nexus-maven-plugins/tree/master/staging/maven-plugin)

Go into the top level of your 10.? directory and first make the pack
`mvn clean install -P pack`

These artifacts need to be deployed to source.sakaiproject.org. There is a special user name and password assigned to us by Wush to access this location and you're on your own to figure out the details.

After this is done you can release the apis. The command below (If your settings.xml is setup correctly and you have the ability to release to sonatype) should deploy to sonatype. Note the plugin doesn't close by or drop if there is a failure.

`mvn deploy -Psakai-release,sakai-provided -Ddescription="Sakai ${SAKAI_RELEASE} release"`

After you have done this first step, you need to get the repository id and deploy the parent poms. You can get the id by running the command.

`mvn nexus-staging:rc-list -Psakai-release`

It should show a bunch of ids, one of them will come up as 

*[INFO] orgsakaiproject-1034 OPEN     org.sakaiproject:master:10.3*

You need that ID for the next command parameter stagingRepositoryId. 

`export STAGING_ID="orgsakaiproject-1034"`

It's going to run a mvn deploy with the -N option so only the poms are deployed.  
__Note: This script probably probably needs to release almost every pom.xml in Sakai, see SAK-26598, it loops through the projects listed in provided, then loops again through all of it's poms. This will take awhile.__

```
provided=( reset-pass announcement assignment basiclti external-calendaring-service calendar common content content-review courier delegatedaccess edu-services emailtemplateservice entitybroker entitybroker hierarchy kernel lessonbuilder login mailarchive mailsender message metaobj msgcntr  polls portal presence profile2 chat citations help dav web podcasts postem rights rwiki syllabus usermembership samigo jobscheduler search search shortenedurl signup site-manage sitestats taggable userauditservice warehouse )
for i in "${provided[@]}"; do
  pomdirs=`find "$i" -name "pom.xml" -printf "%h;" | grep -v "/target/"`
  pomdirs=(${pomdirs//;/ })
  for j in "${pomdirs[@]}"; do
    pushd .; cd $j ;mvn deploy -N -Psakai-release -Dmaven.test.skip=true -Ddescription="Sakai ${SAKAI_RELEASE} release" -DstagingRepositoryId=${STAGING_ID}; popd 
  done
done
```

Finally you should upload all of the artifacts.
You have to have an alias in .ssh/config to the sakai static release directory for the command below to work. Otherwise set one up or have something comparable.

cd pack
`find . -name "*sakai-*" | xargs -I {} scp {} sakaistatic:/home/sakai/public_html/release/${SAKAI_RELEASE}/artifacts`

These have only been run a few times, so hopefully they work for you. Will update this next release cycle!

## Some additional information

There was a previous problem with GPG signing but this seems to work with maven 3.2.1 and the new nexus plugin. This is just left here for historical reference at the moment.
- Get the source for the latest deploy plugin that the poms reference (2.8.1) 
http://maven.apache.org/plugins/maven-deploy-plugin/source-repository.html
- Apply the patch in this directory DeployMojoSleep.patch
- Compile this plugin with the patch
- Go to the directory that is failing and run `mvn install gpg:sign deploy -DdeployAtEnd=true -DdeployAtEndSleepTime=60000 -P sakai-provided`
- Note this doesn't have the extra goals on it, just what you need. After it gets all built, open another window and verify that the asc files are signed incorrectly.
- Run `gpg -ab <filename>` on the incorrect files. It will prompt you to overwrite. Note you have to actually sign the jar, and not the asc that the find command gives you.
- Ideally this won't be a problem for you or will be figured out and this section can be removed!

- Some References
http://maven.apache.org/plugins/index.html (Maven plugins)
http://mojo.codehaus.org/plugins.html (Codehaus plugins)

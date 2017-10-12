Work in Progress for doing the 12 release

## Command line release in the git repository

```
# I like to tmux before I do any of this so I can reattach to it later since this takes a long time, especially on the deploy
tmux new -s release

# Change this each release
export SAKAI_VERSION=12.0

#This should be static
export SAKAI_SNAPSHOT_VERSION=12-SNAPSHOT

git clone git@github.com:sakaiproject/sakai.git sakai-source-release
# Or  git pull --rebase  if you're in an already existing directory
cd sakai-source-release
git fetch
git checkout 12.x

# Now that you're in the 12 branch, setup the repo to release!
cd master
#First run the plugin to process and set the version
mvn versions:set -DnewVersion=${SAKAI_VERSION} -DgenerateBackupPoms=false
#Then fix up the SNAPSHOT in the properties
sed -i -e "s/${SAKAI_SNAPSHOT_VERSION}/${SAKAI_VERSION}/" pom.xml
cd ..

#Release all the needed binaries to the repo
# The skipLocalStaging here is optional, and probably better to leave it off then it deploys all at the end
# Also you might need -DstagingRepositoryId=orgsakaiproject-1059
# Where the id is whatever id you've previously deployed into, if you're adding additional artifacts


mvn deploy -Dsakai-release=true -Dmaven.test.skip=true -DskipLocalStaging=true

#Build Sakai and the packs
mvn clean install -Ppack-bin -Dmaven.test.skip=true

#Now do the necessary commits to git with the tag if everything's completed successfully so far
git commit -a -m "Releasing Sakai ${SAKAI_VERSION}"
git tag -a ${SAKAI_VERSION} -m "Tagging Sakai version ${SAKAI_VERSION}"

cd master
mvn versions:set -DnewVersion=${SAKAI_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
#Then fix up the SNAPSHOT in the properties
sed -i -e "s/${SAKAI_VERSION}/${SAKAI_SNAPSHOT_VERSION}/" pom.xml 
cd ..
git commit -a -m "Switching Sakai back to ${SAKAI_SNAPSHOT_VERSION}"
```

## Checking sonatype and releasing artifacts

Now if everythings okay (examine the git log, check sonatype close/release the artifacts there at https://oss.sonatype.org/index.html#welcome), push it!

If for some reason closing the artifacts doesn't work (like maven it fails a rule) you can try to re-deploy to the same repository by using the -DstagingRepositoryId parameter like below. Remember you might have to checkout the tag again to work on that, since you might be already at the SNAPSHOT phase.

```
mvn deploy -Dsakai-release=true -Dmaven.test.skip=true -DskipLocalStaging=true -DstagingRepositoryId=orgsakaiproject-1068
```

You can also delete and try again back on the deploy step.

```
git push origin ${SAKAI_VERSION}
git push origin 12.x

```

## Deploying binaries and javadocs

Afterward you should generate the javadocs upload all of the artifacts.

You have to have an alias in .ssh/config to the sakai static release directory for the command below to work. Otherwise set one up or have something comparable.

Because this hits the server multiple times you might also want to use an app like keychain or ssh-agent.

First clean up and make the directory you'll need

`ssh sakaistatic "rm -rf ~/public_html/release/${SAKAI_VERSION}/artifacts ~/public_html/release/${SAKAI_VERSION}/apidocs"` 

`ssh sakaistatic "mkdir -p ~/public_html/release/${SAKAI_VERSION}/artifacts ~/public_html/release/${SAKAI_VERSION}/apidocs"` 

Then you can copy the files over

`cd pack ; find . -name "*sakai-*" | xargs -I {} scp {} sakaistatic:~/public_html/release/${SAKAI_VERSION}/artifacts; cd ..`

Finally generate the javadocs

Checkout 12.3 again so the docs are right
`git checkout 12.3`

Run this in the top level directory to generate and aggregate the java docs
`mvn javadoc:aggregate`

And then upload them to the release directory (Make sure it's empty)
`rsync -r target/site/apidocs sakaistatic:~/public_html/release/${SAKAI_VERSION}/`

And checkout 12.x again
`git checkout 12.x`

* And that should be it! Close the Jira, check the release page for working links and send out the release notes! *

These have only been run a few times, so hopefully they work for you. Will update this next release cycle!

## Special cases (Webjars)

To deploy the local webjars we have currently these are just based off the sonatype parent. These will eventually be moved to the central webjars location.
* Update the webjar version in both the master pom.xml and in the webjar pom.xml
* Run this command to release the webjar in the webjar directory (like autosave), note the profile
`mvn deploy -Dsakai-release=true -Dmaven.test.skip=true -DskipLocalStaging=true -Psonatype-oss-release
* Do a commit to update the master and the local, push this as a PR to regular Sakai. It may fail the first Travis build, just rebuild

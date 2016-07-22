Work in Progress for doing the 11 release
```
export SAKAI_VERSION=11.0
git clone git@github.com:sakaiproject/sakai.git
# Or  git pull --rebase  if you're in an already existing directory
git fetch
git checkout 11.x

# Now that you're in the 11 branch, setup the repo to release!

cd master
mvn versions:set -DnewVersion=${SAKAI_VERSION}

mvn clean install

mvn mvn deploy -DaltDeploymentRepository=snapshot-repo::default

mvn -Dtag="${SAKAI_VERSION}" scm:tag
```

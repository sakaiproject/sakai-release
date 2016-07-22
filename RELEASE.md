Work in Progress for doing the 11 release
```
export SAKAI_VERSION=11.0
git clone git@github.com:sakaiproject/sakai.git
# Or  git pull --rebase  if you're in an already existing directory
git fetch
git checkout 11.x

# Now that you're in the 11 branch, setup the repo to release!

cd master
#Fix the SNAPSHOT's in the properties first
sed -i -e "s/11-SNAPSHOT/${SAKAI_VERSION}/" pom.xml
mvn versions:set -DnewVersion=${SAKAI_VERSION} -DgenerateBackupPoms=false

mvn clean install -P pack-bin -Dmaven.test.skip=true

mvn deploy -DaltDeploymentRepository=snapshot-repo::default -Dmaven.test.skip=true

mvn -Dtag="${SAKAI_VERSION}" scm:tag
```

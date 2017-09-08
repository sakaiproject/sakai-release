# sakai-release
Tools for performing community releases of Sakai

Sakai 11 scripts (forthcoming)

# Cherry picking tips

When working on the actual source (not a fork)

```
git checkout master
git pull upstream master (ensure your master working copy is updated)
git checkout 12.x
git pull upstream 12.x (ensure your 12.x working copy is updated)
```
(Those steps are equivalent to `cherrypicks -u`)

`git cherry 12.x master -v | grep SAK-31389`

This will return something like:

\+ 0188650616ba6690e319db3c745345c7a3511252 SAK-31389 Cleanup buttonBar macro. (#2964)

The + sign means that this commit is missing in 12.x branch.

Then you can type:

`git cherry-pick 0188650616ba` (You don’t need to use the complete hash string just the enough characters to identify the commit)

If you are not sure is really easy to get back, just type:

```
git cherry-pick --abort (If the cherry-pick does not finish successfully)
git reset --hard HEAD~1 (If the cherry-pick finish but you are not happy with the result, for example the build fails)
```

# Cherry Pick Script

Use the new node script to manage cherry picking in Sakai, you must install node before run it !

Clone this repo and type: `npm install -g`

Now you have the new _cherrypicks_ command in your system.

## list of commands

- Get the script help `cherrypicks -h`

## Common work

- Get the list of all jira's ready to cherry pick (with commands) `cherrypicks -j -p`

	- You can control what is checked in jira, default verified:merge (status=verified and 11 status=merge)

- Find a concrete jira/text in commit to cherry pick it `cherrypicks -c SAK-YYYY -p`

- Find if some jira/commit is already in 12.x branch `cherrypicks -f SAK-YYYY`

- Find missing github issue commits `cherrypicks -g -p`

- Find missing commits not related with jira or github `cherrypicks -m`


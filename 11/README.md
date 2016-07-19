# sakai-release
Tools for performing community releases of Sakai

Sakai 11 scripts (forthcoming)

# Cherry picking tips

When working on the actual source (not a fork)

```
git co master
git pull upstream master (ensure your master working copy is updated)
git co 11.x
git pull upstream 11.x (ensure your 11.x working copy is updated)
```
(Those steps are equivalent to get-cherry-picks.sh -u)

`git cherry 11.x master -v | grep SAK-31389`

This will return something like:

+ 0188650616ba6690e319db3c745345c7a3511252 SAK-31389 Cleanup buttonBar macro. (#2964)

The + sign means that this commit is missing in 11.x branch.

Then you can type:

`git cherry-pick 0188650616ba` (You don’t need to use the complete hash string just the enough characters to identify the commit)

If you are not sure is really easy to get back, just type:

```
git cherry-pick --abort (If the cherry-pick does not finish successfully)
git reset --hard HEAD~1 (If the cherry-pick finish but you are not happy with the result, for example the build fails)
```

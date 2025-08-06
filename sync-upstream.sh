#!/bin/bash
echo "Syncing with upstream miku.gg repository..."
echo

echo "Fetching latest changes from upstream..."
git fetch upstream

echo
echo "Checking out master branch..."
git checkout master

echo
echo "Merging upstream changes..."
git merge upstream/master

echo
echo "Pushing updates to your fork..."
git push origin master

echo
echo "Sync complete!"
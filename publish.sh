#!/usr/bin/env bash

echo "--> Building site..."
jekyll build

echo ""
echo "--> Updating RSS Feed..."
cp _site/rss.xml rss.xml
git add rss.xml
git commit -m "Updating RSS Feed"

echo ""
echo "--> Publishing site..."
git push origin $(git name-rev HEAD 2> /dev/null | sed 's#HEAD\ \(.*\)#\1#'):master

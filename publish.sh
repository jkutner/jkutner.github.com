#!/usr/bin/env bash

echo ""
echo "--> Publishing site..."
git push origin $(git name-rev HEAD 2> /dev/null | sed 's#HEAD\ \(.*\)#\1#'):master

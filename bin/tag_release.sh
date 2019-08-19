#!/bin/bash

#
# Tag the release version after release branch has been merged to master
# Tag is in the format: vYYYYMMDD-HHMM
#

version=`TZ=UTC date "+v%Y%m%d-%H%M"`
git tag -a $version -m $version

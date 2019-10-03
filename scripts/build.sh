#!/bin/sh

set -ex

cd $(mktemp -d)
wget https://github.com/tootsuite/mastodon/archive/master.tar.gz
tar xf master.tar.gz
cd mastodon-master
docker build --add-host="archive.ubuntu.com:2001:df0:2ed:feed::feed" --tag asia.gcr.io/ykzts-technology/mastodon:$(date -u +'%Y%m%d%H%M%S') .

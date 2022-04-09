FROM tootsuite/mastodon:v3.5.1

# TODO: なんかうまく動いていなかったので一旦コメントアウト
# USER root
#
# RUN set -ex \
# 	&& mkdir -p /var/cache/apt/archives/partial \
# 	&& touch /var/cache/apt/archives/lock \
# 	&& chmod 640 /var/cache/apt/archives/lock \
# 	&& apt update \
# 	&& apt install -y git \
# 	&& bundle config --delete frozen \
# 	&& bundle add newrelic_rpm \
# 	&& bundle config frozen \
# 	&& rm -rf /var/cache \
# 	&& rm -rf /var/lib/apt/lists/*
#
# COPY newrelic.yml config/newrelic.yml

USER mastodon

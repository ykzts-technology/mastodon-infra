FROM tootsuite/mastodon:v3.0.1

USER root

RUN set -ex \
	&& mkdir -p /var/cache/apt/archives/partial \
	&& touch /var/cache/apt/archives/lock \
	&& chmod 640 /var/cache/apt/archives/lock \
	&& apt update \
	&& apt install -y git \
	&& bundle config --delete frozen \
	&& bundle add elastic-apm \
	&& bundle config frozen \
	&& rm -rf /var/cache \
	&& rm -rf /var/lib/apt/lists/* \
	&& echo "server_url: <%= ENV['ELASTIC_APM_SERVER_URL'] %>" >> config/elastic_apm.yml \
	&& echo "secret_token: <%= ENV['ELASTIC_APM_SECRET_TOKEN'] %>" >> config/elastic_apm.yml

USER mastodon

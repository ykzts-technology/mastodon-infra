FROM tootsuite/mastodon:v3.1.0 as mastodon

FROM nginx:1.17.8-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=mastodon /opt/mastodon/public/assets /usr/share/nginx/html/assets
COPY --from=mastodon /opt/mastodon/public/emoji /usr/share/nginx/html/emoji
COPY --from=mastodon /opt/mastodon/public/packs /usr/share/nginx/html/packs
CMD ["nginx", "-g", "daemon off;"]

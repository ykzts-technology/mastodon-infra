# ytech-infra

## Mastodon

```console
$ kubectl create secret generic mastodon-credentials \
  --from-literal=secret-key-base=... --from-literal=otp-secret=... \
  --from-literal=vapid-private-key=... --from-literal=vapid-public-key=...
```

## Cloud SQL

```consol
$ kubectl create secret generic cloudsql-instance-credentials \
  --from-file=credentials.json=$(pwd)/credentials.json
$ kubectl create secret generic cloudsql-db-credentials \
  --from-literal=username=mastodon --from-literal=password=...
```

## Redis Labs

```console
$ kubectl create secret generic redislabs-credentials \
  --from-literal=hostname=... --from-literal=port=... --from-literal=password=...
```

## Elastic Cloud

```console
$ kubectl create secret generic elasticcloud-es-credentials \
  --from-literal=hostname=... --from-literal=port=...
```

## Sendgrid

```console
$ kubectl create secret generic sendgrid-smtp-credentials \
  --from-literal=password=...
```

## Cloud Storage

```console
$ kubectl create secret generic cloudstorage-credentials \
  --from-literal=access-key=... --from-literal=secret-key=...
```

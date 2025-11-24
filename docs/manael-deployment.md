# Manael Deployment for Helm Environment

Manael（メディアプロキシ）はMastodon公式Helm Chartに含まれていないため、別途デプロイメントとして管理します。

## 概要

ManaelはMastodonのメディアファイルをプロキシするサービスで、`files.ykzts.technology`ドメインで提供されています。Helm移行後も、Manaelは独立したDeploymentとして継続運用します。

## Helm移行時の対応

Helm chartでMastodonをデプロイした場合でも、Manaelは現在のKustomize構成をそのまま維持します。

### 現行構成の維持

```bash
# Manaelのリソースは削除しない
kubectl get deployment manael
kubectl get service manael
kubectl get hpa manael
```

### Ingress設定の更新

Helm chartによるIngressを使用する場合、Manaelへのルーティングを追加する必要があります。

#### オプション1: Helm IngressにManaelルートを追加

values.yamlにManaelへのルーティングを追加する方法（将来的な対応）:

```yaml
# helm/values-production.yaml
ingress:
  enabled: true
  hosts:
    - host: ykzts.technology
      paths:
        - path: "/"
          pathType: Prefix
    # Manael用の追加ホスト
    - host: files.ykzts.technology
      paths:
        - path: "/"
          pathType: Prefix
          # 注意: この設定はHelm chartがサポートしていない場合、手動で追加が必要
```

ただし、Helm chartが`files.ykzts.technology`へのルーティングをサポートしていない場合は、以下の方法を使用します。

#### オプション2: 既存のIngressを維持（推奨）

Helm chartのIngressとは別に、Manaelへのルーティングを独立したIngressとして維持します。

**k8s/manael/ingress.yaml** を作成:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: manael
  annotations:
    kubernetes.io/ingress.global-static-ip-name: ykzts-technology-ip
    networking.gke.io/managed-certificates: mastodon-certificate
spec:
  rules:
  - host: files.ykzts.technology
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: manael
            port:
              number: 8080
```

適用:

```bash
kubectl apply -f k8s/manael/ingress.yaml
```

#### オプション3: Helm Ingressへのパッチ適用

Helm chartでデプロイしたIngressに、Manaelへのルーティングをパッチで追加します。

```bash
kubectl patch ingress mastodon --type=json -p='[
  {
    "op": "add",
    "path": "/spec/rules/-",
    "value": {
      "host": "files.ykzts.technology",
      "http": {
        "paths": [
          {
            "path": "/",
            "pathType": "Prefix",
            "backend": {
              "service": {
                "name": "manael",
                "port": {
                  "number": 8080
                }
              }
            }
          }
        ]
      }
    }
  }
]'
```

## Manael用リソース定義

将来的にHelm化する場合に備え、Manaelのリソース定義を以下にまとめます。

### k8s/manael/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: manael
  labels:
    app: manael
spec:
  selector:
    matchLabels:
      app: manael
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: manael
    spec:
      containers:
      - name: manael
        # 注意: 実際の運用では、正しいイメージタグとダイジェストを使用してください
        # 以下は現在のKustomize設定からコピーしたものです
        image: ghcr.io/manaelproxy/manael:2.0.6@sha256:73a2c1003d75c44e009bcdd974e78ee0f682ba67896d590affc4dc40ec90174e
        ports:
        - containerPort: 8080
        env:
        - name: MANAEL_UPSTREAM_URL
          value: https://ykzts-technology-storage.storage.googleapis.com
        resources:
          requests:
            memory: 2Gi
            cpu: 2
          limits:
            memory: 2Gi
            cpu: 2
        livenessProbe:
          httpGet:
            port: 8080
            path: /health
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            port: 8080
            path: /health
          initialDelaySeconds: 30
          periodSeconds: 30
      nodeSelector:
        cloud.google.com/gke-spot: "true"
      terminationGracePeriodSeconds: 25
```

### k8s/manael/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: manael
  annotations:
    beta.cloud.google.com/backend-config: '{"default": "manael-backend-config"}'
    cloud.google.com/neg: '{"ingress": true}'
spec:
  selector:
    app: manael
  type: NodePort
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
```

### k8s/manael/hpa.yaml

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: manael
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: manael
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 80
        type: Utilization
  - type: Resource
    resource:
      name: memory
      target:
        averageUtilization: 80
        type: Utilization
```

### k8s/manael/backendconfig.yaml

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: manael-backend-config
spec:
  timeoutSec: 60
  cdn:
    enabled: true
    cacheMode: CACHE_ALL_STATIC
    defaultTtl: 86400
    maxTtl: 86400
    requestCoalescing: true
```

## デプロイ方法

### 一括デプロイ

```bash
kubectl apply -f k8s/manael/
```

### 個別デプロイ

```bash
kubectl apply -f k8s/manael/deployment.yaml
kubectl apply -f k8s/manael/service.yaml
kubectl apply -f k8s/manael/hpa.yaml
kubectl apply -f k8s/manael/backendconfig.yaml
kubectl apply -f k8s/manael/ingress.yaml  # 必要に応じて
```

## 更新方法

### イメージの更新

```bash
kubectl set image deployment/manael manael=ghcr.io/manaelproxy/manael:NEW_VERSION
```

### リソース設定の更新

```bash
# deployment.yamlを編集後
kubectl apply -f k8s/manael/deployment.yaml
```

## モニタリング

### 動作確認

```bash
# Podの状態確認
kubectl get pods -l app=manael

# ログ確認
kubectl logs -l app=manael --tail=100

# ヘルスチェック
kubectl exec deployment/manael -- curl -f http://localhost:8080/health
```

### GCP Cloud Monitoringとの統合

現在の`k8s/overlays/production/monitoring.yaml`にManaelのPodMonitoring設定が含まれていない場合、追加します:

```yaml
apiVersion: monitoring.googleapis.com/v1
kind: PodMonitoring
metadata:
  name: manael
  labels:
    app: manael
spec:
  selector:
    matchLabels:
      app: manael
  endpoints:
  - port: 8080
    interval: 30s
```

## 将来的な改善案

### オプション1: Manael専用Helm Chart作成

Manaelを独立したHelm chartとして管理する方法。

```bash
# 将来的な利用例
helm install manael ./charts/manael \
  --namespace default \
  --values helm/values-manael.yaml
```

### オプション2: Mastodon Helm Chartへの統合

Mastodon公式Helm chartにManaelサポートを追加するプルリクエストを提出する。

### オプション3: 外部ツールでの管理

Kustomizeでのmanael管理を継続し、Helm chartと併用する。

```bash
# Mastodon: Helm管理
helm upgrade mastodon mastodon/mastodon --values helm/values-production.yaml

# Manael: Kustomize管理
kubectl apply -k k8s/manael/
```

## トラブルシューティング

### Manaelが起動しない

```bash
# Pod状態の確認
kubectl describe pod -l app=manael

# イベント確認
kubectl get events --field-selector involvedObject.name=manael

# ログ確認
kubectl logs -l app=manael
```

### GCSへの接続エラー

```bash
# 環境変数の確認
kubectl exec deployment/manael -- env | grep MANAEL

# GCSバケットへの接続テスト
kubectl exec deployment/manael -it -- \
  curl -I https://ykzts-technology-storage.storage.googleapis.com
```

### Ingressからのルーティングエラー

```bash
# Ingress設定の確認
kubectl get ingress manael -o yaml

# Service Endpointsの確認
kubectl get endpoints manael

# BackendConfigの確認
kubectl get backendconfig manael-backend-config -o yaml
```

## まとめ

- Manaelは独立したDeploymentとして管理を継続
- Helm移行時はIngressの設定に注意
- 将来的にはHelm chart化を検討
- 現在の運用は問題なく継続可能

---

**注意**: この構成はHelm移行時にも変更不要ですが、Ingress設定だけは確認が必要です。

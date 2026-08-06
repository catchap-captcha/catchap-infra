# metrics-server — 관리형 클러스터에서는 그냥 깔면 안 됩니다

**0805 설치.** `kubectl top` 과 **HPA(자동 확장)** 의 전제입니다.

## 설치

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json --patch-file 아래-패치.json
```

## ★왜 패치가 필요한가 — 깔았더니 안 됐습니다

기본 설정 그대로 깔면 파드는 정상인데 `kubectl top` 이 계속 실패합니다.

```
파드            Running · ready · 재시작 0 · ★로그에 오류 없음
kubectl top     ★"Metrics API not available"  (60초 넘게 기다려도 그대로)

APIService v1beta1.metrics.k8s.io
  Available = False · FailedDiscoveryCheck
  "Get https://10.103.126.39:443/apis/metrics.k8s.io/v1beta1:
   ★request canceled while waiting for connection (Client.Timeout ...)"
```

### ★원인을 어떻게 갈랐나

```
클러스터 안 파드에서 metrics-server.kube-system.svc:443  →  ★연결 됨
apiserver 에서 같은 주소                                  →  ★타임아웃
```

★**카카오가 운영하는 컨트롤 플레인이 워커의 파드 네트워크(Calico ClusterIP)에 못 닿습니다.**

★★**힌트가 이미 클러스터 안에 있었습니다** — `ingress-nginx` 가 `hostNetwork: true` 로 돌고 있습니다.
같은 이유입니다. **밖에서 들어오는 것은 노드 IP 로만 닿습니다.**

## ★패치 — hostNetwork 로 옮기고 포트를 비켜 줍니다

⚠️**기본 포트가 `10250` 인데 이건 ★kubelet 이 쓰는 포트입니다.**
hostNetwork 로 바꾸면서 포트를 안 옮기면 **노드에서 충돌합니다.** `4443` 으로 옮깁니다.

★probe 와 Service 는 포트를 **이름**(`https`)으로 참조하므로 **번호만 바꾸면 따라옵니다.**

```json
[
  {"op":"add","path":"/spec/template/spec/hostNetwork","value":true},
  {"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"},
  {"op":"replace","path":"/spec/template/spec/containers/0/args","value":[
      "--cert-dir=/tmp",
      "--secure-port=4443",
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s"
  ]},
  {"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":4443}
]
```

⚠️★**전략적 병합 패치(`--patch-file` 기본)로 하면 거부됩니다.**

```
The Deployment "metrics-server" is invalid:
  spec.template.spec.containers[0].ports[1].name: ★Duplicate value: "https"
```

포트 목록을 **합치려 해서** 옛 10250/https 와 새 4443/https 가 둘 다 남습니다.
→ ★`--type=json` (RFC 6902) 으로 **정확히 교체**해야 합니다.

## ✅결과 (0805 실측)

```
APIService   Available=★True

kubectl top nodes
  host-10-0-2-128   122m  3%   2084Mi  13%
  host-10-0-6-202    75m  1%   1951Mi  12%

kubectl top pods -n catchap
  backend-api  ×2   3m    216Mi / 215Mi
  behavior-ai  ×2   1m    142Mi
  captcha-api  ×2   4~5m  111Mi
  frontend     ×2   1m      4Mi
```

★**교훈 — 「파드가 Running 이고 로그가 깨끗하다」는 동작한다는 증거가 아닙니다.**
이 경우 문제는 **파드 밖**(apiserver → 파드 네트워크)에 있었고, 로그에는 아무것도 안 남았습니다.

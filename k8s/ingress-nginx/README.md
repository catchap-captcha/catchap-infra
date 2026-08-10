# ingress-nginx — 이 폴더는 ★자동 반영되지 않는다

⚠️★**ArgoCD 가 이 폴더를 보지 않습니다.** 여기에 있는 것은 **손으로 적용해야** 합니다.
`k8s/argocd/app-*.yaml` 이 가리키는 경로는 `k8s/{backend,frontend,captcha,behavior-ai}` 뿐입니다.

**그런데도 git 에 두는 이유** — 이 설정이 없으면 **보안 기능 하나가 조용히 죽습니다.**
클러스터를 다시 만들 때 이 파일이 없으면 아무도 그것을 모릅니다.

---

## 어떻게 설치돼 있나 (0808 실측)

```
설치 방식   ★Helm 아님 — 정적 매니페스트를 kubectl apply
            (helm list -n ingress-nginx 가 ★비어 있음)
판본        app.kubernetes.io/version: ★1.14.5
컨트롤러    ★DaemonSet (노드마다 한 벌 · Deployment 아님)
            ★hostNetwork: true → 파드 IP = ★노드 IP
서비스      ★ClusterIP (0810 실측)
            ⚠️전에 이 문서에 「LoadBalancer」로 적혀 있었는데 ★틀렸습니다.
            바깥 노출은 Service 가 아니라 ★카카오클라우드 LB 가 노드 4대의
            80·443 을 직접 가리켜서 합니다.
```

---

## ★이 설정이 무엇을 지키나

```yaml
use-forwarded-headers: "true"
proxy-real-ip-cidr:    "10.0.0.0/16"
```

### 없으면 무슨 일이 생기나

앱이 보는 클라이언트 IP 가 **진짜 사용자**가 아니라 **앞단의 주소**가 됩니다.
그러면 **IP 로 묶인 횟수 제한 9개가 전부 「전체 한 덩어리」로 돕니다** —
한 사람이 한도를 채우면 **그 시간 동안 전원이 막힙니다.**

★2026-08-08 이전이 실제로 그 상태였습니다. 실측:

```
captcha_challenges_v2   2,996건에 서로 다른 client_ip_hash ★5개 (2주치)
   → 그 5개는 사람이 아니라 인프라 주소(도커 브리지·노드)였습니다
```

### ★★그리고 앱의 안전이 여기에 의존합니다

`catchap-captcha` 의 `client_ip()` 는 `X-Forwarded-For` 의 **맨 앞**을 읽습니다.
보통은 **사용자가 위조할 수 있는 자리**입니다. 위조를 막는 것은 **앱이 아니라 여기**입니다.

```
real_ip_recursive on · set_real_ip_from 10.0.0.0/16
   → 오른쪽부터 훑어 ★신뢰 대역이 아닌 첫 주소를 고름 (위조한 맨 앞은 버려짐)

proxy_set_header X-Forwarded-For ★$remote_addr
   → 덧붙이지(append) 않고 ★통째로 교체. 앱에 가는 XFF 는 ★값 하나뿐
```

⚠️★**`proxy-real-ip-cidr` 를 넓히지 마십시오.** `0.0.0.0/0` 으로 열면 **아무나 보낸
`X-Forwarded-For` 를 믿게 되어**, 사용자가 IP 를 속여 횟수 제한을 우회할 수 있습니다.
지금 값은 **LB 가 들어오는 대역만**입니다.

⚠️★**캡차를 인그레스 없이 노출하지 마십시오**(NodePort 직결 등). 그 순간 이 방어가
통째로 없어집니다. 0808 기준 `captcha-api` 는 **ClusterIP** 이고 입구는
`captcha.catchap5.com` **하나뿐**입니다.

---

## 적용 방법

★**두 키만 건드립니다.** 다른 키를 지우지 않게 `patch` 를 씁니다.

```bash
kubectl patch configmap ingress-nginx-controller -n ingress-nginx --type merge \
  -p '{"data":{"use-forwarded-headers":"true","proxy-real-ip-cidr":"10.0.0.0/16"}}'
```

컨트롤러가 알아서 nginx.conf 를 다시 씁니다. **파드를 다시 띄울 필요는 없습니다.**

### 적용됐는지 확인

```bash
kubectl exec -n ingress-nginx ds/ingress-nginx-controller -- \
  grep -E "real_ip_recursive|set_real_ip_from|X-Forwarded-For" /etc/nginx/nginx.conf | sort -u
```

⚠️★`deploy/` 가 아니라 `ds/` 입니다. 전에 이 문서에 `deploy/` 로 적혀 있었는데
컨트롤러는 **DaemonSet** 이라 그 명령은 **실패합니다**(0810 정정).

**이렇게 나와야 합니다.**

```
real_ip_header      X-Forwarded-For;
real_ip_recursive   on;
set_real_ip_from    10.0.0.0/16;
proxy_set_header X-Forwarded-For        $remote_addr;
```

### ★진짜 확인은 밖에서 두드리는 것입니다

설정이 바뀐 것과 **동작이 바뀐 것**은 다릅니다. 사내가 아니라 **바깥 회선**에서 보내야
의미가 있습니다(사내에서 보내면 신뢰 대역이라 결과가 달라집니다).

```bash
# 위조를 시도해 본다 — 기록되는 것이 이 값이면 ★방어 실패
curl -s -o /dev/null --resolve api.catchap5.com:443:210.109.55.233 \
  -X POST https://api.catchap5.com/api/v1/auth/password-reset/request \
  -H "Content-Type: application/json" -H "X-Forwarded-For: 203.0.113.99" \
  -d '{"email":"iptest@example.com"}'
```

그 다음 `login_throttle` 에 `pwresetip:<진짜 공인 IP>` 가 쌓였는지 봅니다.
`pwresetip:203.0.113.99` 가 보이면 **방어가 뚫린 것**입니다.

⚠️**LB 가 두 대이므로 두 IP 모두**에서 재야 합니다. 0808 에 **한쪽만 헤더를 보내고 있던
일**이 실제로 있었습니다(`인프라-캡처/30-작업이력/0808-클라이언트IP-측정-...`).

---

## 함께 봐야 하는 것 — 세 층이 다 맞아야 동작합니다

```
① 로드밸런서   리스너 insert_headers 에 X-Forwarded-For: true
               ⚠️★콘솔에 그 항목이 없습니다 → Octavia API 로만 고칠 수 있습니다
               ⚠️쓰기 권한이 있는 계정이 ★catchap-ci 하나뿐이었습니다
② ingress      ★이 문서
③ 앱           백엔드  uvicorn --proxy-headers --forwarded-allow-ips 10.0.0.0/16,192.168.0.0/16
               캡차    TRUST_PROXY: "true"   (k8s/captcha/10-configmap.yaml)
               행동AI  IP 를 안 써서 해당 없음
```

★**하나라도 빠지면 조용히 옛 상태로 돌아갑니다.** 에러가 나지 않으므로 아무도 모릅니다.

---

## ⬜아직 안 한 것

```
✅ 컨트롤러 본체를 git 에 넣기 (0810 완료)
   → 20-controller-내려받음.yaml
   살아 있는 것을 그대로 내려받았습니다. ★원본 매니페스트로는 재현이 안 됩니다
   (원본은 Deployment·hostNetwork 없음인데 우리는 DaemonSet·hostNetwork).
   ⚠️웹훅용 TLS 인증서는 ★일부러 뺐습니다 — 설치 때 Job 이 새로 만듭니다.

⬜ ArgoCD 로 관리하기
   ⚠️기존 설치와 충돌하는지 ★먼저 시험해야 합니다
   ⚠️★prune 이 켜져 있어 잘못 붙이면 인그레스가 통째로 지워질 수 있습니다.
      지금은 ★기록용으로만 둡니다.
```

---

## ⚠️★hostNetwork 가 다른 작업에 준 영향

0810 에 NetworkPolicy 를 걸다가 여기 걸려 되돌렸습니다.

```
· 출발지가 파드가 아니라 ★호스트라서 `namespaceSelector` 로
  「인그레스에서 온 것」을 고를 수 ★없습니다
· Calico 가 IPIP 터널을 써서, 받는 쪽이 보는 출발지는
  노드 IP(10.0.2.128)가 아니라 ★터널 주소(192.168.57.1)입니다
```

자세한 것 = `인프라-캡처/30-작업이력/84-0810-클러스터-내부-방화벽/`

# 쿠버네티스 매니페스트 — 무엇을 어떤 순서로 올리나

**0805 기준.** 프론트엔드와 인그레스는 **이미 클러스터에서 돌고 있습니다.**

```
k8s/
  captcha/            ✅ 캡차          (namespace 도 여기 있음)
  backend/            ✅ 백엔드
  frontend/           ★★적용 완료 — 2벌 Running · 실제 화면 확인
  behavior-ai/        ✅ 0805 신설 — 옛 서버에서 이미지를 가져왔다
  50-ingress-공통.yaml ★★적용 완료 — 루트→www 308 · 경로 보존 확인
```

---

## ★값을 어디서 가져왔나 — 이게 이 문서에서 가장 중요합니다

**추측한 값이 없습니다.** 포트·기동 명령·설정 이름을 **구워진 이미지 안에서 직접 읽었습니다.**

```bash
docker inspect <이미지> --format '{{json .Config.ExposedPorts}} {{json .Config.Cmd}}'
docker run --rm --entrypoint grep <이미지> -oE '^    [A-Z][A-Z0-9_]*:' /app/app/core/config.py
```

★★**왜 이렇게까지 하나 — 로컬 작업트리가 프로덕션 코드가 아니기 때문입니다.**

```
로컬 catchap-backend/app/core/config.py   설정 14개
구워진 이미지 안의 같은 파일               설정 60개
```

**로컬을 보고 썼으면 46개를 빠뜨렸습니다.** 미디어(Object Storage)·자막(STT)·결제(PortOne)·
캡차 연동이 전부 그 46개 안에 있습니다. 로컬 `Dockerfile` 은 아예 **빈 파일**입니다.

---

## 올리는 순서

**순서를 지켜야 합니다.** 뒤에 것이 앞의 것을 참조합니다.

```
✅1 kubectl apply -f captcha/00-namespace.yaml        namespace catchap
 2  시크릿을 명령으로 생성                             ★파일에 값을 안 남긴다
      backend-secret · captcha-secret · behavior-ai-secret
      (각 폴더의 20-secret.예시.yaml 주석에 명령이 그대로 있음)
 3  kubectl apply -f */10-configmap.yaml
✅   frontend 는 완료
 4  ★behavior-ai 를 먼저 올린다 — 캡차가 이 서비스를 부른다
      kubectl apply -f behavior-ai/30-deployment.yaml -f behavior-ai/40-service.yaml
    그다음 backend → captcha
✅5 인그레스 컨트롤러                                  0804 설치 완료 (v1.14.5 · 노드마다 1벌)
✅6 kubectl apply -f 50-ingress-공통.yaml              적용 완료
    ⬜ captcha/50-ingress.yaml 은 캡차 배포 뒤에
 7  파드가 Ready 인지 · 로드밸런서 대상이 Healthy 인지 확인
✅   프론트 기준으로는 0804 에 전부 ONLINE 확인
 8  ★그 다음에 컷오버 (가비아 레코드 3~4줄)
```

★**8번을 7번보다 먼저 하면 접속이 끊깁니다.** 도메인을 먼저 옮기면 아직 뜨지도 않은
곳으로 사용자를 보내게 됩니다.

---

## 적용 전에 아직 안 된 것

```
✅ cluster-admin          0804 해결 — ★권한 문제가 아니라 잘못된 계정으로 재고 있었다
✅ 인그레스 컨트롤러       0804 설치
✅ 워커2 보안그룹          10.0.6.0/24 대역으로 허용
✅ behavior-ai 이미지     0805 — ★굽지 않고 옛 서버에서 가져왔다
✅ ★비밀값                0805 해결 — 금고 8건 + K8s Secret. 아래 ⚠️ 참고
✅ ★네 서비스 전부 배포     0805 — 각 2벌 · 서로 다른 노드 · 경로 6개 200/308
⬜ ★컷오버                 남은 전부. 가비아 레코드 3~4줄
```

✅★★**2026-08-10 — 세 앱 전부 금고에서 직접 읽습니다. K8s 에는 열쇠만 남습니다.**

```
backend-secret      2개   SECRETS_ACCESS_KEY · SECRETS_SECRET_KEY   (0807)
captcha-secret      2개   같음                                       (0810)
behavior-ai-secret  2개   같음                                       (0810)
catchap-registry    1개   .dockerconfigjson  ★이것만 못 옮깁니다 —
                          쿠버네티스가 파드를 띄우기 ★전에 필요한 값이라
                          앱이 읽어 올 수 없습니다
── 클러스터 비밀값 총 ★7개 (전에는 15개)
```

★**값을 바꿀 때는 금고에서 새 버전을 만들고 `kubectl rollout restart` 만 하면 됩니다.**
코드도 git 도 안 고칩니다. 로더가 `default_version` 을 따라갑니다.

<details>
<summary>⚠️(지난 이야기 — 0805 에 두 번 바뀌었습니다. ★따르지 마십시오)</summary>

```
0805 아침    금고에서 앱이 직접 읽는 방식으로 정리
0805 저녁    ★팀이 그날 구운 새 이미지에 그 코드가 ★없어서
             비밀값 10개를 다시 backend-secret 에 넣었습니다
0807         코드를 병합해 백엔드가 금고로 돌아갔습니다
0810         캡차·행동AI 도 같은 길로 왔습니다  ← ★지금
```

</details>

★**스키마 검증(`kubectl apply --dry-run=server`)을 0804·0805 에 실제로 했습니다.**

```
YAML 문법        전부 통과
참조 대조         인그레스 → 서비스 · ConfigMap 주소 · Secret 이름  전부 일치
★서버 스키마      behavior-ai 3벌 · backend ConfigMap  통과
```

★**⚠️kubectl 이 간헐적으로 인증서 검증에 실패하면** `~/.catchap/ca.crt` 를 의심하십시오.
0805 에 **서버 인증서가 CA 자리에 들어가 있는 것**을 찾아 진짜 CA 로 바꿨습니다
(자세한 것은 `인프라-캡처/00-작업기록.md` 37-6).

---

## 서비스별로 다르게 한 것과 그 이유

| | 캡차 | 백엔드 | 프론트 | behavior-ai |
|---|---|---|---|---|
| 포트 | 8000 | 8000 | 80 | 8010 |
| liveness | `/health/live` | `/health` | `/healthz` | `/health` |
| readiness | `/health/ready` | **`/api/v1/health`** | `/healthz` | `/health` ⚠️ |
| 볼륨 | `emptyDir` (행동 이벤트를 씀) | **없음** (파일을 안 씀) | `emptyDir` ×2 (nginx 캐시·PID) | `emptyDir` (`/tmp` 만) |
| 루트 읽기전용 | 아니오 | 아니오 | **예** | **예** |
| 밖에서 보이나 | 예 (`captcha.`) | 예 (`api.`) | 예 (`www.`) | **아니오** (클러스터 안에서만) |

⚠️**behavior-ai 의 readiness 에 별표를 단 이유** — 그 `/health` 는 **DB 가 죽어도 200** 을
주고 본문에만 `degraded` 라고 씁니다. **DB 끊김을 못 잡습니다.** 그래도 이대로 둔 것은
지금 정책이 `shadow` 라 **판정에 관여하지 않기** 때문입니다. `active` 로 바꾸는 날
이 판단을 다시 해야 합니다.

★★**백엔드의 두 health 가 하는 일이 다릅니다.** 이미지 안에서 확인했습니다.

```
/health          main.py       DB 를 안 본다.  "프로세스가 살아 있나"
/api/v1/health   health.py     SELECT 1 을 한다. "DB 까지 준비됐나"
```

**거꾸로 쓰면 DB 가 잠깐 끊길 때 파드를 죽여 버립니다** — DB 장애가 앱 장애로 번집니다.
liveness 에는 DB 를 안 보는 쪽을 씁니다.

★★**`ENV=prod` 는 스위치가 아니라 관문입니다.** 백엔드는 부팅할 때 아래를 검사하고
하나라도 걸리면 **부팅을 거부**합니다.

```
JWT_SECRET_KEY 가 비었거나 개발용 기본값       거부
JWT_SECRET_KEY 가 32자 미만                   거부
CORS_ORIGINS 에 * 가 있음                     거부
SMTP_USER / SMTP_APP_PASSWORD 가 비었음        거부   ← 메일이 "보낸 척" 되는 걸 막는 설계
```

**시크릿이 하나라도 빠지면 `CrashLoopBackOff` 로 돕니다.** 이유는 로그에 한국어로 찍힙니다.

★**프론트는 설정을 바꿔도 화면이 안 바뀝니다.** 빌드할 때 값이 코드에 박히기 때문입니다.
**API 주소를 바꾸려면 다시 구워야 합니다.** 쿠버네티스의 한계가 아니라 Vite 빌드 방식입니다.

---

## 인그레스를 한 파일에 모은 이유

`www.catchap5.com` 하나에 **프론트와 백엔드가 경로로 갈려** 붙습니다.
두 파일로 나누면 같은 host 규칙이 흩어져 **나중에 한쪽만 고치는 사고**가 납니다.
캡차는 host 가 달라서(`captcha.catchap5.com`) 그쪽 폴더에 그대로 뒀습니다.

★**루트 → www 301 규칙이 여기 있습니다.** 루트에는 규격상 CNAME 을 못 붙여서
IP 를 직접 적게 되는데, **DNS 는 건강검진을 안 해** 그 입구가 죽으면 절반이 실패합니다.
**루트로 온 사람을 www 로 넘겨** 그 뒤부터 고가용성 그룹이 처리하게 합니다.
옛 구조에서 Caddy 가 하던 일과 같습니다.

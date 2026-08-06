# behavior-ai — 행동 판별 서비스

★★**0805 전면 개정.** 예전 판은 *"이미지가 없어서 매니페스트를 못 씁니다"* 였습니다.
**전제가 틀렸습니다.**

## 무엇이 틀렸나

예전 판은 이렇게 적었습니다.

> 빌드 서버(VM2)에 **behavior-ai 소스가 없습니다.** 담당은 **sw님**이고
> 어느 참조를 구워야 하는지도 확정이 필요합니다.

★**소스를 찾을 필요가 없었습니다.** 옛 프로덕션 백엔드 서버에서 **완성된 이미지가
7일째 돌고 있었습니다.**

```
210.109.52.124  $ docker ps
  catchap-backend-api-1   catchap-backend:latest       Up 16 hours (healthy)
★ catchap-behavior-ai     catchap-behavior-ai:latest   Up 7 days  (healthy)
  catchap-backend-caddy-1 caddy:2-alpine               Up 2 weeks
```

★**교훈** — *"소스가 없다"* 와 *"이미지가 없다"* 는 다른 문제입니다. **컨테이너는 소스 없이도
옮길 수 있습니다.** 그게 컨테이너를 쓰는 이유입니다. 옛 서버 조사 때 **백엔드 서버에 AI 가
같이 있는 것을 못 봤던 것**이 원인입니다(「AI 서버」라는 이름의 서버는 빈 껍데기였습니다).

## 어떻게 옮겼나

두 VPC 가 서로 안 통해서 **제 PC 를 파이프로 통과**시켰습니다. 디스크에 안 남겼고,
**프로덕션 서버에 배포 키를 올리지 않았습니다.**

```
ssh 옛서버 'docker save catchap-behavior-ai:latest | gzip -1' \
  | ssh -J 점프서버 VM2 'gunzip | docker load'

docker tag  → kc-sfacspace05.kr-central-2.kcr.dev/catchap-ai-repo/catchap-behavior-ai:eb8d67e57a34
docker push → sha256:eb8d67e57a3459dfe2587418bed6876a13f1eaba864aebd41df83371b5264058
```

## ⚠️★★0805 저녁 정정 — 위 이미지는 낡았습니다. 다시 구웠습니다

**옛 백엔드 서버의 도커 이미지(7/28)를 가져왔는데, 그게 라이브가 아니었습니다.**

```
★라이브   옛 GPU /home/sw/catchap-behavior — ★캡차가 부르는 127.0.0.1:8010 이 이것입니다
가져온 것  옛 백엔드 서버의 도커 이미지 — ★아무도 안 부르는 것이었습니다

database/mysql_models.py   17,761  ≠  ★18,538
database/repositories.py   23,093  ≠  ★23,794
schemas/requests.py         6,770  ≠  ★7,459
```

★★**`/health` 로는 못 잡았습니다** — 모델 이름·버전·스키마가 셋 다 같아서 「같은 것」으로
판단했습니다. **응답이 같다고 코드가 같은 게 아닙니다.** 파일 크기를 대조해야 나왔습니다.

**다시 구운 방법 — `app/` 만 덮었습니다**

```dockerfile
FROM …catchap-behavior-ai:eb8d67e57a34
USER root
COPY app/ /app/app/
RUN chown -R aiservice:aiservice /app/app
USER aiservice
```

★**밑바닥부터 안 구운 이유** — ①GPU 소스에 Dockerfile 이 없다 ②★이미지 안의
`requirements-serve.txt` 가 GPU 것보다 낫다(`cryptography`·`pandas` 가 더 있고,
`cryptography` 는 MySQL 8 기본 인증에 필요) ③`learning/`·`models/` 는 **지문이 이미 같았다.**

**지금 도는 것**

```
kc-sfacspace05.kr-central-2.kcr.dev/catchap-ai-repo/catchap-behavior-ai:★feea9a597269
검증   코드 지문이 GPU 소스와 일치(cee2a9883c808024)
       model_loaded:true · mysql_connected:true · 캡차가 부름(reachable:true)
```

★**태그가 이미지 ID 입니다. 커밋 해시가 아닙니다.** 다른 셋(백엔드·프론트·캡차)은 커밋
해시를 태그로 씁니다. 이것만 **어느 커밋인지 모르므로** 커밋 해시를 붙이면 거짓말이 됩니다.
소스를 확보하면 다시 구워 태그를 바꿉니다.

## 확인한 것 — 전부 이미지와 도는 프로세스에서 직접 읽었습니다

| | 값 | 어떻게 알았나 |
|---|---|---|
| 포트 | `8010` | `docker inspect` 의 `ExposedPorts` · 기동 명령 |
| 기동 명령 | `uvicorn app.main:app --host 0.0.0.0 --port 8010` | `Config.Cmd` |
| 사용자 | `aiservice` **uid/gid 10001** | 이미지 안에서 `id` |
| 건강검진 | `GET /health` · **인증 없음** | 7일째 `healthy` |
| 볼륨 | **없음** | `Mounts` 비어 있음 |
| 디스크 쓰기 | **없음** | 이미지 전수 검색 0건 |
| 메모리 | **153.4MiB** | `docker stats` |
| CPU | **0.26%** | 〃 |

★예전 판은 *"포트 8010 은 캡차가 그렇게 부른다는 사실이지 그 앱이 8010 으로 뜬다는
확인이 아니다"* 라고 미뤄 뒀습니다. **이제 실제 기동 명령으로 확인됐습니다.**

### ★★프로덕션에 직접 물어본 것

```
$ curl http://127.0.0.1:8010/health
{"status":"ok","mysql_connected":true,"model_loaded":true,
 "model_name":"lightgbm_general_dynamics_min_fusion",
 "model_version":"revalidation_two_view_participant_safe_20260722",
 "feature_schema_version":"2.3","policy_mode":"shadow"}
```

★**이게 없었으면 모델 경로를 틀렸을 것입니다.** 코드 기본값은 `models/production` 인데
**이미지에 그 폴더가 없습니다.** 실제 번들은 `models/candidate/revalidation_…/` 하나뿐이고,
`/health` 의 `model_version` 이 그 폴더 이름과 같아서 확정할 수 있었습니다.

⚠️**기본값으로 뒀으면 모델이 말없이 안 떴을 것입니다** — 앱은 그래도 200 을 줍니다.

## 파일

```
10-configmap.yaml     비밀 아닌 설정 (DB 주소 · 모델 경로 · 정책)
20-secret.예시.yaml   ★예시. 실제 값은 kubectl 명령으로 만든다
30-deployment.yaml    2벌 · 노드 분리 · 읽기 전용 루트
40-service.yaml       ClusterIP behavior-ai:8010
```

네임스페이스(`catchap`)는 다른 서비스와 공유하므로 여기 없습니다.

## ★열쇠 세 개가 각각 다른 길을 지킵니다

```
/collect     COLLECT_API_KEY           app/api/collect.py:37
/challenge   CAPTCHA_BACKEND_API_KEY   app/api/challenge.py:28   ★캡차가 부르는 길
/admin       ADMIN_API_KEY             app/api/admin.py:22
```

★★`CAPTCHA_BACKEND_API_KEY` 는 캡차 쪽 `BEHAVIOR_AI_BACKEND_KEY` 와 **같은 값이어야
합니다.** 한쪽만 바꾸면 캡차→AI 호출이 전부 거절됩니다.

★비어 있으면 그 길이 **모든 요청을 거절**합니다 — 조용히 통과시키지 않습니다.
이미지 안 주석에 그렇게 적혀 있습니다: *"missing secrets simply disable the guarded path"*.

## ★shadow 모드 — 판정에 관여하지 않습니다

```
shadow   AI 가 "이렇게 판단했을 것이다"를 기록만 한다. ★캡차 결과를 안 바꾼다
active   AI 판단이 실제로 검증 단계를 올린다
```

프로덕션이 지금 **shadow** 입니다. 이전은 **그대로 옮기는 것이 원칙**이라 여기서 바꾸지
않았습니다. 이 사실은 프로브 설계에도 영향을 줍니다 — 아래를 보십시오.

## ⚠️/health 가 DB 장애를 숨깁니다

`app/api/health.py` 는 MySQL 이 죽어도 **HTTP 200** 을 주고, 본문에만 `"degraded"` 라고 씁니다.

```
liveness   ○ 알맞다  — DB 장애 조치 중에 파드를 죽이지 않는다.
                       프로세스가 먹통이면 응답 자체가 없어서 걸린다.
readiness  △ DB 끊김을 못 잡는다.
             그래도 이대로 두는 이유 = ★지금은 shadow 라 판정에 관여하지 않는다.
             DB 없는 AI 는 점수가 나빠질 뿐, 서비스를 막지 않는다.
```

★**active 로 바꾸는 날에는 이 판단을 다시 해야 합니다.**

## 올리는 순서

```
1  kubectl -n catchap create secret generic behavior-ai-secret --from-literal=…
2  kubectl apply -f 10-configmap.yaml
3  kubectl apply -f 30-deployment.yaml -f 40-service.yaml
4  kubectl -n catchap get pod -l app.kubernetes.io/name=behavior-ai -o wide
     → ★두 파드가 **다른 노드**에 있는지 본다
5  kubectl -n catchap exec deploy/behavior-ai -- curl -s localhost:8010/health
     → ★model_loaded 가 true 인지 본다. false 면 PRODUCTION_MODEL_DIR 이 틀린 것이다
```

★**캡차보다 먼저 올립니다.** 캡차의 `BEHAVIOR_AI_URL` 이 이 서비스를 가리킵니다.

## ⬜ 남은 것

```
⬜ API 열쇠 3개의 값        옛 서버 환경변수 읽기가 안전장치에 막혔다.
                          → 캡차 쪽과 짝이 맞아야 하므로 ★컷오버 때 양쪽을 같이
                            새로 만드는 것을 권한다
⬜ MYSQL_PASSWORD          자격증명.txt 2-3 (`catchap_ai_app`)
⬜ catchap_ai 데이터베이스   옛 DB 에서 옮겼는지 확인 필요
⬜ 소스 확보               커밋 해시로 다시 굽기 위해. sw님께 문의
⬜ Secrets Manager 연동     백엔드에는 있고(`app/core/secrets_loader.py`) 여기에는 없다.
                          코드를 고쳐야 해서 이번 이전에서는 K8s Secret 으로 간다
```

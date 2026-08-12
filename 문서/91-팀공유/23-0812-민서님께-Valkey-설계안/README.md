# 민서님께 — Valkey 준비 끝났습니다 + 설계 초안 (2026-08-12)

민서님, 답변 감사합니다. **②를 진행하기로 해서 인프라 쪽을 먼저 깔아 뒀습니다.**

*"우선순위 잡고 설계안 만들어 공유드릴게요"* 하셨는데, 기다리는 동안
**제가 초안도 만들어 봤습니다.** 코드를 읽고 쓴 것이라 틀린 데가 있을 겁니다.
**고쳐 주시라고** 드리는 것입니다 — 이대로 하자는 게 아닙니다.

---

## ✅제가 해 둔 것 (민서님이 하실 일 없습니다)

| 무엇 | 상태 |
|---|---|
| 금고 시크릿 `catchap-valkey-auth` | ✅만듦 · `VALKEY_PASSWORD` |
| 캡차 ConfigMap 에 접속 설정 | ✅병합 (`catchap-infra` PR #43·#44) |
| 로더가 시크릿 7건을 읽는지 | ✅파드 재기동해서 확인 |
| 실제로 Valkey 에 붙는지 | ✅`AUTH +OK` · `PING +PONG` · `DBSIZE :0` |
| CA 인증서 | ✅받아 둠 — ★필요해지면 저희가 마운트합니다 |

★**코드에서 `os.environ` 만 읽으시면 바로 붙습니다.**

### ⚠️덤으로 찾은 것 — 배포 중 502 (민서님 배포에도 영향)

파드가 뜨는지 확인하려고 재기동하며 두드려 봤더니 **끊겼습니다.**

```
고치기 전    90번 중 ★3번 실패 (502 둘 · 연결끊김 하나)
원인        파드가 종료 표시되는 것과 인그레스가 대상에서 빼는 것이 ★동시가 아님
고친 뒤     130번 중 ★0번   (다섯 서비스에 preStop: sleep 5 추가 · PR #45)
```

★**0804 주석에 "안 끊긴다"고 적혀 있었는데 사실이 아니었습니다.**
이제 캡차 배포도 조금 더 조용해집니다.

---

## 0. 바로 쓰실 수 있는 값

```python
os.environ["VALKEY_HOST"]              # primary.catchap-valkey-prod….kakaocloud.com
os.environ["VALKEY_READ_HOST"]         # reader.… (읽기 전용 복제)
os.environ["VALKEY_PORT"]              # 6379
os.environ["VALKEY_USERNAME"]          # catchap
os.environ["VALKEY_PASSWORD"]          # ★금고에서 자동 주입 (catchap-valkey-auth)
os.environ["VALKEY_TLS"]               # true
os.environ["VALKEY_TLS_SERVER_NAME"]   # service.kakaoenterprise.com
```

### ⚠️붙일 때 두 가지만 조심하십시오 (제가 다 겪었습니다)

```python
# ① AUTH 는 ★두 인자다. 한 인자로 보내면 default 사용자로 붙어 -WRONGPASS.
r = valkey.Valkey(host=..., username="catchap", password=...)

# ② TLS 의 server_hostname 은 ★엔드포인트가 아니라 인증서 CN 이다.
#    서버 인증서에 subjectAltName 이 없어서, 엔드포인트로 붙으면 Hostname mismatch.
ssl_ctx = ssl.create_default_context(cafile="ca.crt")
ssl_ctx.check_hostname = True                       # ★끄지 마십시오
sock = ssl_ctx.wrap_socket(raw, server_hostname="service.kakaoenterprise.com")
```

### ★CA 파일은 민서님이 챙기실 필요 없습니다 — 저희가 마운트합니다

인증서가 필요한 것은 **개발자가 아니라 파드**입니다. 코드에 파일을 끼워 넣거나
이미지에 굽는 대신, **저희가 ConfigMap 으로 마운트**하겠습니다.

```python
# 민서님 코드는 ★경로만 읽으시면 됩니다
ca_path = os.environ["VALKEY_TLS_CA_FILE"]        # 예: /etc/valkey/ca.crt
ssl_ctx = ssl.create_default_context(cafile=ca_path)
```

⬜**아직 안 붙였습니다.** 쓰실 때가 되면 말씀해 주십시오 — 그때 ConfigMap 과
볼륨 마운트를 넣겠습니다. **원하시는 경로가 따로 있으면 그 경로로** 하겠습니다.

(급하게 확인해 보실 일이 있으면 파일은
`30-작업이력/96-0812-Valkey-금고시크릿과-설정/valkey-ca.crt` 에 있습니다 —
공개 인증서라 비밀이 아닙니다 · 지문 `22399e67…`)

★**실제로 붙여서 확인했습니다** — TLSv1.3 · `AUTH +OK` · `PING +PONG` · `DBSIZE :0`.

---

## 1. 🚨먼저 — 제가 착각했던 것을 바로잡습니다

처음에 저는 *"임시 상태를 캐시로 옮기면 CASCADE 위험이 사라진다"* 고 적었습니다.
**엄밀히는 틀렸습니다.**

```
민서님 말씀    "챌린지 행 자체·attempts·batches 는 기록/학습이라 DB 에 남긴다"
그러면         captcha_challenges_v2 행은 ★그대로 남는다
             → 그 행을 지우면 ★여전히 CASCADE 로 batches 가 날아간다
```

★**진짜 해결은 「지우는 위험이 없어지는 것」이 아니라 「지울 이유가 없어지는 것」입니다.**

```
지금        만료 챌린지 3,903행 = 2.41MB
           → 지우고 싶은 이유는 「만료된 쓰레기니까」였다
바뀐 뒤     만료·정답 좌표가 캐시에 있으니, DB 의 행은 ★기록으로만 남는다
           → 2.41MB 는 그냥 둬도 되는 크기다. ★청소 자체가 필요 없어진다
```

⚠️**그래도 언젠가 지워야 한다면**, 그때는 CASCADE 를 손봐야 합니다
(`captcha_behavior_batches` 의 외래키를 `ON DELETE RESTRICT` 로 바꾸거나,
학습 데이터를 먼저 다른 표로 복사). **이번 작업의 범위는 아니라고 봅니다.**

---

## 2. 무엇을 옮기고 무엇을 두나

| 지금 있는 곳 | 무엇 | 어떻게 | 왜 |
|---|---|---|---|
| `captcha_challenges_v2` 행 | 챌린지 기록 | 🚫**DB 유지** | 민서님 말씀대로 기록 |
| `captcha_challenge_objects` | ★정답 좌표·임시 ID 매핑 | ✅**캐시** | 챌린지 TTL(180초) 지나면 무의미 |
| `expires_at` 로 만료 판정 | ★만료 | ✅**캐시 EX** | 키가 없어지는 것이 곧 만료 |
| `request_pattern()` 4개 질의 | ★레이트리밋 | ✅**캐시 INCR+EX** | 아래 3절 — 가장 큰 이득 |
| `captcha_tokens` | ★토큰 유효성 | ✅**캐시** | TTL 300초 |
| `captcha_behavior_sessions` 의<br/>`next_batch_seq`·`last_receipt_hash` | ⚠️사슬 머리 | ⚠️**신중히** | 아래 4절 |
| `captcha_attempts` | 시도 기록 | 🚫**DB 유지** | 기록 |
| `captcha_behavior_batches` | ★행동 원자료 | 🚫**DB 유지** | ★성원님 학습 데이터 |

---

## 3. 가장 큰 이득은 레이트리밋입니다

`request_pattern()` 이 **챌린지를 만들 때마다 질의 4개**를 돕니다.
그중 둘은 표 2~3개를 JOIN 합니다.

```sql
① captcha_challenges_v2  WHERE client_ip_hash=… AND created_at > now-1분
② captcha_challenges_v2  WHERE session_id=…     AND created_at > now-10분
③ captcha_attempts JOIN captcha_challenges_v2                (실패 수)
④ behavior_shadow_predictions JOIN captcha_attempts
     JOIN captcha_challenges_v2                              (텔레메트리 실패 수)
```

캐시로 옮기면 **질의 4개 → 0개**가 됩니다.

```
rl:ip:{ip_hash}:1m         INCR · EX 60
rl:sess:{session}:10m      INCR · EX 600
rl:fail:{session}:10m      INCR · EX 600   ← 채점에서 틀렸을 때만 증가
rl:tele:{session}:10m      INCR · EX 600   ← 텔레메트리 실패 때만 증가
```

★**고정 창(fixed window)으로 충분하다고 봅니다.** 슬라이딩 창은 정확하지만
`ZADD`+`ZREMRANGEBYSCORE` 로 키가 커집니다. 지금 한도(분당 N회)에서
경계 효과는 무시할 만합니다 — **민서님 판단을 듣고 싶습니다.**

⚠️**지금 값은 DB 를 세므로 「진짜 과거 10분」이고, 캐시 카운터는 「이번 창」입니다.**
값이 미묘하게 달라집니다. 한도 숫자를 조정해야 할 수 있습니다.

---

## 4. ⚠️receipt-chain 머리는 조심해야 합니다

`captcha_behavior_sessions` 에 `next_batch_seq` 와 `last_receipt_hash` 가 있고,
배치가 올 때마다 갱신됩니다. **뜨거운 상태**라 캐시가 어울려 보이지만,

```
★캐시가 이 값을 잃으면 → 다음 배치의 previous_receipt_hash 대조가 깨진다
                        → behavior_receipt_chain_invalid 로 거부
                        → ★그 세션의 행동 데이터가 통째로 버려진다
```

Valkey 는 노드 2개에 자동 장애조치가 있지만, **복제는 비동기**라
장애조치 순간의 마지막 갱신은 사라질 수 있습니다.

### 제안 — 세 가지 중에 골라 주십시오

```
가) ★안 옮긴다 (제 추천)
    사슬 머리는 DB 에 그대로. 배치가 올 때만 UPDATE 하니 부하가 크지 않다.
    → 잃을 것이 없다. 이득도 작다.

나) 캐시를 앞에 두고 DB 에도 쓴다 (write-through)
    읽기는 캐시, 없으면 DB 에서 채운다. 쓰기는 둘 다.
    → 읽기 부하는 줄고 안전하다. 코드가 조금 는다.

다) 캐시만 쓴다
    → ★권하지 않습니다. 장애조치 한 번에 세션이 깨집니다.
```

---

## 5. 캐시가 죽으면 어떻게 하나 — ★이게 설계의 핵심입니다

용도마다 답이 다릅니다.

| 무엇 | 캐시가 죽으면 | 왜 |
|---|---|---|
| 레이트리밋 | ★**DB 질의로 되돌아간다** | 못 세면 무제한 허용이 된다. 느려도 막아야 한다 |
| 정답 좌표 | ★**그 챌린지는 만료 처리** | 정답을 모르면 채점을 못 한다. 새로 내주면 된다 |
| 토큰 유효성 | ★**DB 조회로 되돌아간다** | 토큰이 무효가 되면 사용자가 다시 풀어야 한다 |
| 사슬 머리 | (가)안이면 해당 없음 | |

★**「캐시가 죽으면 통과시킨다」는 절대 안 됩니다.** 캐시를 죽이는 것이
곧 레이트리밋 우회가 됩니다.

---

## 6. 옮기는 순서 — 한 번에 하나씩

```
1단계  레이트리밋만          이득이 가장 크고 되돌리기 쉽다
       · 캐시에 세면서 DB 질의도 그대로 돌린다(양쪽 비교)
       · 값이 비슷한지 며칠 보고, 맞으면 DB 질의를 뗀다
2단계  토큰 유효성
3단계  정답 좌표·만료         ★가장 조심. 여기서 틀리면 채점이 깨진다
4단계  사슬 머리              (나)안을 고르셨다면
```

★**1단계에서 양쪽을 같이 돌리는 것**이 중요합니다. 캐시 카운터와 DB 카운터가
얼마나 다른지 **숫자로 보고** 한도를 정할 수 있습니다.

---

## 7. 지금 부하는 어떤가 (참고)

★**성능 때문에 하는 일이 아닙니다.** 여유는 큽니다.

```
DB 초당 질의수    6.6회
DB 연결          14 / 682   (2%)
캐시 적중률       0%  · 키 0개 (DBSIZE :0) — 아직 아무도 안 씀
```

**진짜 이유는 「청소 코드와 CASCADE 함정을 없애는 것」**이고,
레이트리밋 질의 4개가 사라지는 것은 덤입니다.

---

## 8. 여쭙고 싶은 것

```
① 3절 — 고정 창으로 충분할까요? 슬라이딩이 필요할까요?
② 4절 — 사슬 머리는 (가)(나)(다) 중 어느 쪽이 좋을까요?
③ 5절 — 「캐시가 죽으면 DB 로 되돌아간다」에 동의하시나요?
④ 6절 — 순서가 이대로 괜찮을까요? 1단계에서 양쪽 비교하는 것은 어떠신지?
⑤ 키 이름 규칙(`rl:ip:…`)을 이렇게 가도 될까요? 접두어를 따로 두실 계획이 있으신지?
⑥ CA 파일 마운트 경로 — `/etc/valkey/ca.crt` 로 할까요? 다른 곳이 편하시면 말씀만.
```

★**민서님 레이트리밋 Redis화 계획과 겹친다고 하셨는데, 그쪽 설계가 이미 있으면
이 문서는 버리고 그걸 따르겠습니다.** 제가 인프라 쪽만 준비해 두겠습니다.

---

## 9. 요약 — 지금 상태

```
✅ 붙을 준비는 다 됐습니다      값·설정·확인 전부 끝
⬜ 코드는 아직 없습니다         민서님 설계·구현 대기
⬜ CA 마운트                   쓰실 때 말씀하시면 바로
🚫 SECRETS_REQUIRED_VARS       ★일부러 안 넣었습니다 (코드가 쓰기 시작할 때 같이)
```

★**급하지 않습니다.** 8절의 여섯 가지만 편하실 때 봐 주시면 됩니다.
아니라고 하셔도 되고, 순서를 바꾸셔도 됩니다. 인프라는 이미 깔려 있으니
민서님 설계가 어떻게 나오든 맞춰 가겠습니다.

— CEO

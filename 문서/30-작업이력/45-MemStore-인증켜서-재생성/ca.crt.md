# ca.crt — MemStore Valkey TLS 인증서

`catchap-valkey-prod` 에 TLS 로 붙을 때 쓴다. 2026-08-03 콘솔에서 받았다.
콘솔 경로: Data Store → MemStore → Valkey → 클러스터 → catchap-valkey-prod
          → 접근 제어 → 전송 암호화(TLS) → [CA 파일]

## 이 파일의 성격

**비밀이 아니다.** 서버가 자기 신원을 증명하는 **공개 인증서**다.
새어도 잃을 것이 없다. 그래서 `인프라-캡처-비공개` 가 아니라 여기에 둔다.

```
subject = issuer   C=KR, O=Kakao Enterprise Corp., OU=Data Managed,
                   CN=service.kakaoenterprise.com
자기서명 루트 CA (CA:TRUE, critical)
유효기간  2025-02-18 ~ 2125-01-25   (100년)
확장      Subject Key Identifier · Authority Key Identifier  ★subjectAltName 없음
sha256    22:39:9E:67:68:81:44:7A:68:2D:3D:49:73:2C:6A:1E:
          F4:3A:5C:5A:28:F7:58:13:11:9F:EB:05:21:86:87:4C
```

★지문을 적어 둔 이유 — 나중에 파일을 다시 받았을 때 **같은 인증서인지** 대조하기 위해서다.

## ★앱에서 쓸 설정 — 검증을 끄지 않는다

```python
import ssl

ctx = ssl.create_default_context(cafile="ca.crt")
ctx.check_hostname = True                    # ★끄지 않는다
sock = ctx.wrap_socket(raw_socket,
                       server_hostname="service.kakaoenterprise.com")
```

★**`server_hostname` 에 엔드포인트 주소가 아니라 인증서의 CN 을 넣는 것**이 요령이다.
서버 인증서에 `subjectAltName` 이 없어 우리 엔드포인트 이름이 인증서에 없기 때문이다.
엔드포인트 이름으로 붙으면 `Hostname mismatch (code 62)` 로 거부된다.

  SAN 이 없을 때 OpenSSL 은 CN 으로 대조한다. 그래서 CN 을 제시하면 통과한다.

### 실측으로 확인했다 — 양방향으로

| 설정 | 결과 |
|---|---|
| `cafile=ca.crt` · `check_hostname=True` · `server_hostname=CN` | **통과** · TLSv1.3 · `TLS_AES_256_GCM_SHA384` · `+OK +PONG :0` |
| 같은 설정 · `server_hostname="wrong.example.com"` | **거부** — `Hostname mismatch` |
| `server_hostname=CN` · **가짜 CA** | **거부** — `CERTIFICATE_VERIFY_FAILED` |
| `server_hostname=`엔드포인트 주소 | **거부** — 인증서에 그 이름이 없다 |
| `CERT_NONE` | 통과하지만 **쓰지 말 것** — 아무 인증서나 받는다 |

★두 가지가 다 거부되므로 **체인 검증과 이름 검증이 모두 살아 있다.**
Primary(10.0.6.101)·Replica(10.0.2.231) 둘 다 같은 결과였다.

### ★처음에 틀리게 적었던 것

처음에는 `check_hostname=False` 로 쓰라고 적었다. 엔드포인트 주소로 붙어 보고
거부되니까 "호스트명 검증은 구조적으로 불가능하다" 고 결론을 냈는데, **틀렸다.**
**제시하는 이름을 바꿀 생각을 못 했다.** 보안 검사 훅이 경고를 띄워서 다시 봤다.

→ 교훈: **"안 된다" 는 결론은 "다른 방법을 다 해 봤다" 를 전제한다.**
  한 가지 방법이 막힌 것을 구조적 한계로 단정했다.

## 이 설정이 지켜 주는 것과 못 지키는 것

**지켜 준다**
- 통신 내용 암호화 (TLS 1.3). 비밀번호가 평문으로 안 흐른다.
- 상대가 **카카오 CA 가 서명한 인증서**를 내민다는 것.
- 그 인증서의 이름이 **우리가 기대한 이름**이라는 것.

**못 지킨다**
- **"이 호스트가 우리 클러스터냐" 는 구분하지 못한다.**
  카카오가 모든 MemStore 클러스터에 같은 정적 인증서를 쓰는 것으로 보이기 때문이다.
  즉 다른 팀의 MemStore 로 유인당해도 인증서만으로는 못 가린다.

  다만 그러려면 **이미 VPC 안에 들어와 있어야** 하고(사설 IP + 보안그룹 `10.0.0.0/16`),
  비밀번호도 따로 필요하다. 수용 가능한 잔여 위험으로 판단한다.

★카카오가 나중에 클러스터별 인증서(SAN 포함)로 바꾸면 이 설정은 **소리 나게 깨진다**
  (`Hostname mismatch`). 조용히 약해지는 게 아니라서 그게 낫다.
  그때는 `server_hostname` 을 실제 엔드포인트로 바꾸면 된다.

## 참고

- 문서에는 "TLS 1.2 연결 지원" 이라 돼 있으나 **실제 협상 결과는 TLS 1.3** 이었다.
- 나중에 이 파일이 필요한 곳: 백엔드 앱 (K8s ConfigMap 또는 이미지에 포함)

# Changelog

## 2.0.0 (발행 전)

앱마다 자기 링크 도메인을 쓰는 서버(2026-11-21)에 맞춘 버전. **호환성이 깨진다** — 1.x 는 `https://appdoor.app` 을 기본 주소로 썼고,
그 주소는 2027-11-04 에 만료된다(그때까지는 1.x 도 동작한다).

- 서버 주소 `baseURL` 은 필수다. 기본값이 없다 — 앱마다 자기 링크 도메인을 넘긴다: `AppDoorConfig(baseURL: URL(string: "https://link.nelloom.app")!)`.
  한 백엔드에 앱별 커스텀 도메인이 여럿 붙고 요청 호스트로 앱을 가르기 때문이다.
  init 인자에 기본값이 없어 빠뜨리면 컴파일되지 않고, 호스트가 없거나 HTTPS 가 아니면(localhost 제외) `AppDoorError.invalidConfiguration` 으로 초기화가 실패한다.
- 링크는 `https://link.nelloom.app/<code>`(또는 `/<templateSlug>/<code>`) 꼴이다. 경로에 앱 슬러그가 없다.
- 들어온 링크는 호스트가 `baseURL` 의 호스트와 같을 때만 서버(`/api/sdk/v1/resolve/...`)에서 해석한다. 다른 도메인이나 커스텀 스킴은 로컬 파싱만 한다.

## 1.0.0 (2026-11-04)

AppDoor 첫 릴리스. 우수기술(Woosu Gisul. Inc.)이 운영하는 AppDoor(https://appdoor.app) 용 SDK 다.
Human Labs 의 HumanlabsLink SDK(MIT)를 이름·기본 주소만 바꿔 가져왔고 기능은 같다.

- 기본 서버 주소: `https://appdoor.app`
- 설치 귀속 파라미터: `apd_cid`

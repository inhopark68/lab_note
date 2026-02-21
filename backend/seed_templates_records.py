"""Seed defaults: templates + records (qPCR / Cell culture)

Run:
    cd backend
    .\.venv\Scripts\Activate.ps1
    python seed_templates_records.py
"""
from sqlmodel import Session, select

from app.db.session import engine, init_db
from app.models.experiment_template import ExperimentTemplate
from app.models.experiment_record import ExperimentRecord

init_db()

TEMPLATES = [
    dict(
        title="공통 실험기록 템플릿 (MVP)",
        experiment_type="공용",
        summary="모든 실험에 공통으로 쓰는 기본 구조(목적/방법/결과/결론/후속)",
        body_markdown="""# 공통 실험기록 템플릿

## 실험명
- 

## 목적
- 

## 샘플/재료
- 샘플:
- 조건/군:
- 사용 시약/장비(연결로 관리 권장):

## 방법
- 설계:
- 조건(농도/시간/온도/사이클):
- QC/체크리스트:

## 결과
- 정량/정성 요약:
- 첨부(RAW/이미지) 링크:

## 결론
- 

## 이슈/편차(Deviation)
- 

## 후속 실험 추천
1. 
""",
        tags="공용,기록",
    ),
    dict(
        title="qPCR (SYBR) 템플릿 (MVP)",
        experiment_type="qPCR",
        summary="SYBR qPCR 기록용: primer/plate map/QC/ΔΔCt",
        body_markdown="""# qPCR (SYBR) 템플릿

## 목적
- 목표 유전자 발현 비교(ΔΔCt)

## 준비물
- cDNA, primer(F/R), SYBR master mix, NTC, No-RT(필요시)

## 설계
- Housekeeping:
- Target:
- Replicate(n=):
- 대조군/처리군:

## Plate map
- (여기에 8x12 또는 384 plate layout 텍스트로 기록)

## 반응 조성(예: 20 µL)
- 2X SYBR mix: __ µL
- Primer F/R: __ µL (final __ nM)
- Template: __ µL
- Nuclease-free water: __ µL

## 사이클 조건
- Initial denaturation:
- Cycling(×__):
- Melt curve:

## QC
- NTC: (Ct/undetermined)
- Melt curve: (single peak?)
- Efficiency(가능 시):
- 표준편차/Outlier:

## 결과/계산
- Ct table 링크:
- ΔCt / ΔΔCt / Fold change:
- 통계(가능 시):
""",
        tags="qPCR,SYBR,template",
    ),
    dict(
        title="부착세포 계대배양(passaging) 템플릿 (MVP)",
        experiment_type="세포배양",
        summary="세포 계대/배양 기록용: confluency/split ratio/오염/QC",
        body_markdown="""# 부착세포 계대배양 템플릿

## 목적
- 세포 유지/증식 및 다음 실험 준비

## 시작 상태
- Cell line:
- Passage No.:
- Confluency(%):
- Morphology:
- Contamination check(현미경):
- Mycoplasma(최근 검사일):

## 절차(요약)
1. 배지 제거 → PBS wash
2. Trypsin 처리(__분) → 중화
3. Cell count:
4. Split ratio(예: 1:__):
5. Seeding density:
6. 배양 조건(37℃, 5% CO2)

## 결과
- Final seeding:
- Incubator 위치/플라스크 라벨:
- 이상 소견:

## 결론/다음 일정
- 다음 관찰/처리 예정일:
- 후속 실험:
""",
        tags="세포배양,passage,template",
    ),
]

RECORDS = [
    dict(
        title="qPCR: Drug A 처리 후 IL6 발현 변화 (예시)",
        date="2026-02-18",
        performer="홍길동",
        project="Pilot",
        experiment_type="qPCR",
        purpose="Drug A(24h)가 IL6 발현에 미치는 영향 확인",
        status="완료",
        sample_summary="Cell line X, Control vs Drug A(10uM, 24h), n=3",
        key_parameters="SYBR, 20uL rxn, 95/60 cycling, melt curve enabled",
        method_markdown="""## 목적
- Drug A 처리에 따른 IL6 발현 변화 확인

## 방법
- RNA 추출 → cDNA 합성
- qPCR(SYBR): IL6, GAPDH
- NTC 포함, technical replicate 2

## 결과
- NTC: undetermined
- Melt curve: single peak
- Ct(IL6) 평균: Control 28.3, DrugA 26.1
- ΔΔCt 기반 fold change ~ 4.2x 증가(경향)

## 결론
- Drug A가 IL6 발현 증가 경향. 반복/통계 필요.

## 후속실험 추천
1. biological replicate 확대(n≥5)
2. housekeeping 2종 추가(B2M 등)
3. 농도/시간 dose-response""",
        results_summary="NTC 음성, melt curve 단일 peak. IL6 Ct 감소(발현 증가 경향).",
        conclusion="반복 확대 시 유의성 확인 필요",
        followup_recommendations="replicate 확대, housekeeping 추가, dose-response 설계",
        tags="qPCR,IL6,DrugA,예시",
    ),
    dict(
        title="세포배양: Cell line X passaging (1:5 split) (예시)",
        date="2026-02-18",
        performer="홍길동",
        project="Pilot",
        experiment_type="세포배양",
        purpose="Drug 처리 실험 대비 세포 확보",
        status="완료",
        sample_summary="Cell line X, T75 flask, confluency 85%",
        key_parameters="Trypsin 0.25%, 3min, split 1:5",
        method_markdown="""## 목적
- 다음날 Drug 처리 실험 대비 세포량 확보

## 방법
- PBS wash 1회
- Trypsin 0.25% 3분 처리 후 complete media로 중화
- 세포 현탁 후 1:5 split로 재분주

## 결과
- 오염 소견 없음
- morphology 정상
- Incubator shelf: middle / position B3

## 결론
- D+1 confluency 확인 후 처리 진행

## 후속실험 추천
1. Mycoplasma test 수행
2. seeding density 기록 표준화""",
        results_summary="오염 소견 없음. confluency 85%에서 1:5 split",
        conclusion="D+1 관찰 후 Drug 처리 진행",
        followup_recommendations="mycoplasma test 진행, seeding density 표준화",
        tags="세포배양,passage,예시",
    ),
]


def upsert_templates(session: Session) -> dict[str, int]:
    """Create templates if missing; return title->id map."""
    title_to_id: dict[str, int] = {}
    for t in TEMPLATES:
        existing = session.exec(select(ExperimentTemplate).where(ExperimentTemplate.title == t["title"])).first()
        if existing:
            title_to_id[t["title"]] = existing.id  # type: ignore
            continue
        obj = ExperimentTemplate(**t)
        session.add(obj)
        session.commit()
        session.refresh(obj)
        title_to_id[t["title"]] = obj.id  # type: ignore
    return title_to_id


def upsert_records(session: Session, template_map: dict[str, int]) -> None:
    """Create example records if missing; link to template if matches type."""
    # Simple mapping: record_type -> template title
    preferred = {
        "qPCR": "qPCR (SYBR) 템플릿 (MVP)",
        "세포배양": "부착세포 계대배양(passaging) 템플릿 (MVP)",
    }
    for r in RECORDS:
        existing = session.exec(select(ExperimentRecord).where(ExperimentRecord.title == r["title"])).first()
        if existing:
            continue
        t_title = preferred.get(r["experiment_type"], "공통 실험기록 템플릿 (MVP)")
        template_id = template_map.get(t_title)
        obj = ExperimentRecord(**r, template_id=template_id)
        session.add(obj)
        session.commit()


with Session(engine) as session:
    tmap = upsert_templates(session)
    upsert_records(session, tmap)

print("✅ Seeded templates + example records (if missing).")

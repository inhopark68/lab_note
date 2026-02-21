"""Seed sample data (optional).
Run:
    python seed.py
"""
from sqlmodel import Session, select
from app.db.session import engine, init_db
from app.models.facility import Facility
from app.models.equipment import Equipment
from app.models.reagent import Reagent
from app.models.sop import SOP
from app.models.experiment_template import ExperimentTemplate
from app.models.experiment_record import ExperimentRecord

init_db()

FACILITIES = [
    Facility(name="세포배양실 (Cell Culture Room)", facility_type="세포배양", location="3층 305호", bsl_level="BSL2",
             rules_summary="클린존 반입 최소화, 작업 전/후 소독, 오염 의심 즉시 격리/보고",
             waste_flow="생물: Biohazard bin / 샤프스: Sharps / 일반: 일반폐기", tags="클린존,예약필수"),
    Facility(name="분자실 (Molecular Lab)", facility_type="분자실", location="3층 307호", bsl_level="해당없음",
             rules_summary="시약/템플릿/증폭산물 구역 분리, 공용장비 로그 작성", tags="공용"),
]

EQUIPMENT = [
    Equipment(name="Micropipette P200", model_vendor="Eppendorf Research Plus", asset_no="EQ-2026-001", domain="공용",
              hazards="Sharps", facility_id=2, location_detail="벤치 A, 피펫 스탠드 1번", tags="공용,교정필요",
              body_markdown="✅ 20–200 µL 정밀 분주\n\n- 사용 전: 팁 확인, 범위 내 볼륨 설정\n- 주의: 범위 밖 설정 금지, 급격한 흡입/배출 금지"),
    Equipment(name="Microcentrifuge (냉장)", model_vendor="Eppendorf 5424R", asset_no="EQ-2026-010", domain="분자",
              hazards="High speed", facility_id=2, location_detail="벤치 B", tags="공용"),
    Equipment(name="CO₂ Incubator", model_vendor="Thermo", asset_no="EQ-2026-020", domain="세포",
              hazards="", facility_id=1, location_detail="INC-01", tags="공용"),
    Equipment(name="qPCR System", model_vendor="Applied Biosystems", asset_no="EQ-2026-030", domain="분자",
              hazards="High voltage", facility_id=2, location_detail="qPCR 코너", tags="예약필요"),
    Equipment(name="Class II BSC", model_vendor="NUAIRE", asset_no="EQ-2026-040", domain="세포",
              hazards="Biohazard", facility_id=1, location_detail="BSC-02", tags="클린존"),
]

REAGENTS = [
    Reagent(name="Trypsin-EDTA 0.25%", category="Cell culture", vendor="Gibco", cat_no="25200-056", lot_no="12345AB",
            storage_temp="4℃", hazards="Irritant", ppe="장갑,보안경,가운", tags="공용",
            body_markdown="부착 세포 분리용. 과처리 주의(세포 손상)."),
    Reagent(name="SYBR Green qPCR Master Mix (2X)", category="Molecular", vendor="Bio-Rad", cat_no="1725124", lot_no="MIX-01",
            storage_temp="-20℃", light_sensitive=True, tags="차광",
            body_markdown="빛/열 노출 최소화. NTC 포함 권장."),
    Reagent(name="70% Ethanol", category="Disinfectant", vendor="In-house", cat_no="", lot_no="",
            storage_temp="RT", hazards="Flammable", ppe="장갑,보안경", tags="소독",
            body_markdown="표면 소독용. 화기 주의."),
]

SOPS = [
    SOP(title="qPCR(SYBR) SOP", version="v1.2", domain="분자", summary="SYBR 기반 qPCR 표준 절차", tags="qPCR,SYBR"),
    SOP(title="Cell passaging SOP", version="v2.0", domain="세포", summary="부착세포 계대배양 표준 절차", tags="세포배양,passage"),
]

TEMPLATES = [
    ExperimentTemplate(title="공통 Run Sheet", experiment_type="공용", summary="모든 실험 공통 실행 기록 템플릿",
                       body_markdown="- 실험명/날짜/수행자\n- 샘플 목록\n- 사용 장비/시약\n- 파라미터\n- RAW 링크"),
    ExperimentTemplate(title="qPCR 템플릿", experiment_type="qPCR", summary="plate map/QC 포함",
                       body_markdown="- 목표 유전자/프라이머\n- plate map\n- NTC/No-RT\n- ΔΔCt"),
]

RECORDS = [
    ExperimentRecord(title="qPCR: Drug A 처리 후 IL6 발현 변화", date="2026-02-18", performer="홍길동",
                     project="Pilot", experiment_type="qPCR", purpose="Drug A(24h)가 IL6 발현에 미치는 영향 확인",
                     results_summary="NTC 음성, melt curve 단일 peak. IL6 Ct 감소(발현 증가 경향).",
                     conclusion="추가 반복 필요", followup_recommendations="replicate 확대, housekeeping 추가",
                     sop_id=1, template_id=2, tags="qPCR,IL6"),
    ExperimentRecord(title="세포배양: Cell line X passaging (1:5 split)", date="2026-02-18", performer="홍길동",
                     project="Pilot", experiment_type="세포배양", purpose="Drug 처리 실험 대비 세포 확보",
                     results_summary="오염 소견 없음. confluency 85%에서 1:5 split",
                     conclusion="D+2 관찰 후 처리 진행", followup_recommendations="mycoplasma test 진행",
                     sop_id=2, template_id=1, tags="세포배양,passage"),
]

with Session(engine) as session:
    # idempotent-ish: only seed if empty
    if session.exec(select(Facility)).first():
        print("DB already has data; skipping seed.")
    else:
        session.add_all(FACILITIES)
        session.commit()
        session.add_all(EQUIPMENT)
        session.commit()
        session.add_all(REAGENTS)
        session.commit()
        session.add_all(SOPS)
        session.commit()
        session.add_all(TEMPLATES)
        session.commit()
        session.add_all(RECORDS)
        session.commit()
        print("Seeded.")

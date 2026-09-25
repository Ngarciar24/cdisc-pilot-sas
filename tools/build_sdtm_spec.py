"""Build the SDTMIG 3.4 target spec and CT for this repo.

Inputs
  - CDISC CORE rules-engine cache (standards metadata and CT packages), from a
    clone of https://github.com/cdisc-org/cdisc-rules-engine: resources/cache
  - specs/pilot_spec.csv and specs/pilot_ct.csv (pilot SDTMIG 3.1.2 metadata)

Outputs
  - specs/sdtm_spec.csv     target spec, SDTMIG 3.4, same columns as pilot_spec
  - specs/sdtm_ct.csv       codelists used by the spec: CDISC CT + sponsor
  - specs/sdtm_changes.csv  every variable change from the pilot to the target

Variables kept per domain: all Req and Exp variables of SDTMIG 3.4, the
variables in FORCE (needed for conformance fixes), every variable the pilot
has (pilot variables that SDTMIG 3.4 allows but does not list in the domain
table, such as AEDTC, stay after the pilot variable they followed), and
--DY/--STDY/--ENDY where the matching --DTC is kept. Lengths come from the
pilot; new variables get a provisional length.

Usage: python tools/build_sdtm_spec.py <core>/resources/cache [sdtmct-YYYY-MM-DD]
"""
import csv
import pathlib
import pickle
import sys
from collections import defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = pathlib.Path(sys.argv[1])
CT_PKG = sys.argv[2] if len(sys.argv) > 2 else "sdtmct-2026-03-27"
FALLBACK_CT = "sdtmct-2025-09-26"   # for codelists retired in CT_PKG
IG, OLD_IG = "standards/sdtmig/3-4", "standards/sdtmig/3-1-2"

DOMAINS = ["TA", "TE", "TV", "TI", "TS", "DM", "SUPPDM", "SE", "SV",
           "EX", "AE", "SUPPAE", "DS", "SUPPDS"]
# Permissible variables added because a conformance fix needs them.
FORCE = {"AE": ["EPOCH"], "DS": ["EPOCH"], "EX": ["EPOCH"], "TS": ["TSVALNF"]}
NEW_LENGTH = {"EPOCH": 20, "ARMNRS": 40, "ACTARMUD": 200, "TSVALNF": 8,
              "TSVALCD": 20, "TSVCDREF": 20, "TSVCDVER": 20,
              "SVPRESP": 1, "SVOCCUR": 1}


def ig_datasets(key):
    std = pickle.load(open(CACHE / "standards_details.pkl", "rb"))[key]
    return {ds["name"]: ds for c in std["classes"] for ds in c.get("datasets", [])}


def read_csv(path):
    with open(path, encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


ig, old_ig = ig_datasets(IG), ig_datasets(OLD_IG)
var_cl = pickle.load(open(CACHE / "variable_codelist_maps.pkl", "rb"))["sdtmig-3-4-codelists"]
ct_new = {c["conceptId"]: c for c in pickle.load(open(CACHE / f"{CT_PKG}.pkl", "rb"))["codelists"]}
ct_old = {c["conceptId"]: c for c in pickle.load(open(CACHE / f"{FALLBACK_CT}.pkl", "rb"))["codelists"]}

pilot = defaultdict(dict)
for r in read_csv(ROOT / "specs" / "pilot_spec.csv"):
    pilot[r["dataset"]][r["variable"]] = r
pilot_ct = defaultdict(list)
for r in read_csv(ROOT / "specs" / "pilot_ct.csv"):
    pilot_ct[r["codelist"]].append(r)

spec, changes, used_cdisc, used_sponsor = [], [], {}, set()
for dom in DOMAINS:
    igname = "SUPPQUAL" if dom.startswith("SUPP") else dom
    ds = ig[igname]
    old_vars = {v["name"]: v for v in old_ig.get(igname, {}).get("datasetVariables", [])}
    pv = pilot[dom]
    # SUPPQUAL variables are generic; everything else is prefixed by domain.
    ig_vars = sorted(ds["datasetVariables"], key=lambda v: int(v["ordinal"]))
    for v in ig_vars:
        v["name"] = v["name"].replace("--", dom[:2])
    # Pilot variables missing from the domain table go after the pilot
    # variable they followed; a --DY is created for any --DTC without one.
    by_name = {v["name"]: v for v in ig_vars}
    pv_order = sorted(pv, key=lambda n: int(pv[n]["order"]))
    for i, name in enumerate(pv_order):
        if name in by_name:
            continue
        extra = {"name": name, "label": pv[name]["label"], "core": "Perm",
                 "role": pv[name]["role"].title(), "extra": True,
                 "simpleDatatype": pv[name]["type"]}
        prev = pv_order[i - 1] if i else None
        pos = next((k + 1 for k, v in enumerate(ig_vars) if v["name"] == prev), len(ig_vars))
        ig_vars.insert(pos, extra)
        by_name[name] = extra
    for v in list(ig_vars):
        n = v["name"]
        if n == dom[:2] + "DTC" and n[:-3] + "DY" not in by_name:
            dy = {"name": n[:-3] + "DY", "label": "Study Day of Visit/Collection/Exam",
                  "core": "Perm", "role": "Timing", "extra": True, "simpleDatatype": "Num"}
            ig_vars.insert(ig_vars.index(v) + 1, dy)
            by_name[dy["name"]] = dy
    names = [v["name"] for v in ig_vars]
    kept = set()
    for v in ig_vars:
        if v["core"] in ("Req", "Exp") or v["name"] in pv or v["name"] in FORCE.get(dom, []):
            kept.add(v["name"])
    for name in list(kept):
        for dtc, dy in (("DTC", "DY"), ("STDTC", "STDY"), ("ENDTC", "ENDY")):
            if name.endswith(dtc) and name[:-len(dtc)] + dy in names:
                kept.add(name[:-len(dtc)] + dy)

    first = next(iter(pv.values()), {})
    label = ds["label"] if not dom.startswith("SUPP") else first.get("dataset_label", f"Supplemental Qualifiers for {dom[4:]}")
    order = 0
    for v, name in zip(ig_vars, names):
        if name not in kept:
            continue
        order += 1
        p = pv.get(name, {})
        old = old_vars.get(v["name"].replace(dom[:2], "--", 1) if not dom.startswith("SUPP") else v["name"]) \
            or old_vars.get(v["name"])
        # Codelists: CDISC CT (latest package, else the fallback) or the pilot's sponsor list.
        cls, notes = [], []
        for code in dict.fromkeys(var_cl.get(name, [])):
            c = ct_new.get(code) or ct_old.get(code)
            if c is None:
                continue
            src = CT_PKG if code in ct_new else f"{FALLBACK_CT} (not in {CT_PKG})"
            used_cdisc[code] = (c, src)
            cls.append(c["submissionValue"])
            if code not in ct_new:
                notes.append(f"codelist {c['submissionValue']} not in {CT_PKG}")
        if not cls and p.get("codelist"):
            cls = [p["codelist"]]
            used_sponsor.add(p["codelist"])

        if not p and name in FORCE.get(dom, []):
            change = "added (Perm in SDTMIG 3.4; needed for a conformance fix)"
        elif not p and v.get("extra"):
            change = "added (--DY for the --DTC kept from the pilot)"
        elif not p:
            change = f"added ({v['core']} in SDTMIG 3.4)"
        elif v.get("extra"):
            change = "kept from pilot; allowed by SDTM but not in the SDTMIG 3.4 domain table"
        else:
            bits = []
            if old and old["label"] != v["label"]:
                bits.append(f"label '{old['label']}' -> '{v['label']}'")
            if old and old.get("core") != v["core"]:
                bits.append(f"core {old.get('core')} -> {v['core']}")
            change = "; ".join(bits) or "unchanged"
        change = "; ".join([change] + notes)

        length = p.get("length") or (8 if v["simpleDatatype"] == "Num" else NEW_LENGTH.get(name, 200))
        row = {
            "dataset": dom, "dataset_label": label,
            "structure": ds.get("datasetStructure", first.get("structure", "")),
            "order": order, "variable": name, "label": v["label"],
            "type": v["simpleDatatype"],
            "datatype": p.get("datatype") or ("integer" if v["simpleDatatype"] == "Num" else "text"),
            "length": length, "key": p.get("key", ""),
            "mandatory": "Yes" if v["core"] == "Req" else "No",
            "role": v.get("role", ""), "codelist": "|".join(cls),
            "origin": p.get("origin", ""),
            "comment": p.get("comment", "") if p else
                       ("Provisional length; set from data." if name not in NEW_LENGTH and v["simpleDatatype"] == "Char" else ""),
            "core": v["core"], "change": change,
        }
        spec.append(row)
        changes.append({"dataset": dom, "variable": name, "core": v["core"], "change": change})
    for name in pv:
        if name not in kept:  # none expected: every pilot variable is kept
            changes.append({"dataset": dom, "variable": name, "core": "",
                            "change": "in pilot but not a SDTMIG 3.4 variable of this domain"})

ct_rows = []
for code, (c, src) in sorted(used_cdisc.items(), key=lambda x: x[1][0]["submissionValue"]):
    for i, t in enumerate(c["terms"], 1):
        ct_rows.append({"codelist": c["submissionValue"], "code": code,
                        "extensible": str(c["extensible"]).lower(), "source": f"CDISC CT {src}",
                        "order": i, "term": t["submissionValue"], "decode": t.get("preferredTerm", "")})
for name in sorted(used_sponsor):
    for r in pilot_ct.get(name, []):
        ct_rows.append({**r, "source": "sponsor (from pilot define.xml)"})

out = ROOT / "specs"
for fname, rows in (("sdtm_spec.csv", spec), ("sdtm_ct.csv", ct_rows), ("sdtm_changes.csv", changes)):
    with open(out / fname, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"specs/{fname}: {len(rows)} rows")

"""Build specs/sdtm_spec.csv and specs/ct.csv from the CDISC pilot define.xml.

The pilot SDTM define.xml (define 1.0, SDTMIG 3.1.2) is the target metadata
for this repo's SDTM: variable order, label, type, length, origin, derivation
comment and codelist per variable, plus the codelists themselves.

Usage: python tools/define_to_specs.py [data/reference/sdtm/define.xml]
"""
import csv
import pathlib
import sys
import xml.etree.ElementTree as ET

NS = {
    "odm": "http://www.cdisc.org/ns/odm/v1.2",
    "def": "http://www.cdisc.org/ns/def/v1.0",
}
DEF = "{%s}" % NS["def"]
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"

root_dir = pathlib.Path(__file__).resolve().parent.parent
define = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else \
    root_dir / "data" / "reference" / "sdtm" / "define.xml"
mdv = ET.parse(define).getroot().find("odm:Study/odm:MetaDataVersion", NS)

items = {i.get("OID"): i for i in mdv.findall("odm:ItemDef", NS)}

# Variable-level spec: one row per dataset variable, in define order.
spec_rows = []
for grp in mdv.findall("odm:ItemGroupDef", NS):
    keys = [k.strip() for k in (grp.get(DEF + "DomainKeys") or "").split(",")]
    for ref in grp.findall("odm:ItemRef", NS):
        item = items[ref.get("ItemOID")]
        cl = item.find("odm:CodeListRef", NS)
        name = item.get("Name")
        spec_rows.append({
            "dataset": grp.get("Name"),
            "dataset_label": grp.get(DEF + "Label"),
            "structure": grp.get(DEF + "Structure"),
            "order": ref.get("OrderNumber"),
            "variable": name,
            "label": item.get(DEF + "Label"),
            "type": "Num" if item.get("DataType") in ("integer", "float") else "Char",
            "datatype": item.get("DataType"),
            "length": item.get("Length"),
            "key": keys.index(name) + 1 if name in keys else "",
            "mandatory": ref.get("Mandatory"),
            "role": ref.get("Role"),
            "codelist": cl.get("CodeListOID") if cl is not None else "",
            "origin": item.get("Origin"),
            "comment": (item.get("Comment") or "").strip(),
        })

# Codelists: one row per term.
ct_rows = []
for cl in mdv.findall("odm:CodeList", NS):
    for rank, term in enumerate(
            cl.findall("odm:CodeListItem", NS) + cl.findall("odm:EnumeratedItem", NS), 1):
        decode = term.find("odm:Decode/odm:TranslatedText", NS)
        ct_rows.append({
            "codelist": cl.get("OID"),
            "datatype": cl.get("DataType"),
            "order": term.get(DEF + "Rank") or rank,
            "term": term.get("CodedValue"),
            "decode": decode.text.strip() if decode is not None and decode.text else "",
        })

out = root_dir / "specs"
out.mkdir(exist_ok=True)
for fname, rows in (("sdtm_spec.csv", spec_rows), ("ct.csv", ct_rows)):
    with open(out / fname, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"specs/{fname}: {len(rows)} rows")

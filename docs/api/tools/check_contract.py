#!/usr/bin/env python3
"""Design-time checks for the PSA API contract drafts. Local only; reads files, writes nothing.

    python3 check_contract.py                 # check docs/api/openapi/*.openapi.yaml
    python3 check_contract.py --self-test     # prove the checks can fail (mutates an in-memory copy)

Needs: pyyaml, jsonschema, openapi-spec-validator (see docs/api/README.md). It validates the DESIGN, not an
implementation: nothing here talks to a server or a database.
"""
import copy
import re
import sys
from pathlib import Path

import yaml
from jsonschema import Draft4Validator
from openapi_spec_validator import validate as validate_openapi

ROOT = Path(__file__).resolve().parents[3]
SPEC = ROOT / "docs/api/openapi/identity-access.openapi.yaml"
DESIGN_DOC = ROOT / "docs/api/API_DESIGN_IDENTITY_ACCESS.md"
REQ_FILES = [ROOT / "docs/requirements/FUNCTIONAL_REQUIREMENTS.md",
             ROOT / "docs/requirements/NON_FUNCTIONAL_REQUIREMENTS.md",
             ROOT / "docs/requirements/USER_STORIES.md"]
MIGRATIONS = [ROOT / "database/migrations/V1__initial_schema.sql",
              ROOT / "database/migrations/V3__least_privilege_runtime_roles.sql"]

METHODS = ("get", "post", "put", "patch", "delete")
UNSAFE = ("post", "put", "patch", "delete")
# Citations that are not numbered requirements; defined in the design document section "Sources".
PSEUDO_SOURCES = {"S6-SEC", "S8-DEC1"}
RATE_CLASSES = {"AUTH_CHALLENGE", "AUTH_VERIFY", "STAFF_AUTH", "SESSION_MANAGEMENT", "ACCOUNT_READ", "ACCOUNT_WRITE"}
PUBLIC_OPERATIONS = {"startSignup", "completeSignup", "startLogin", "completeLogin", "refreshSession",
                     "startStaffLogin", "completeStaffFirstFactor"}
CHALLENGE_START = ("startSignup", "startLogin", "startStaffLogin", "startIdentifierAdd")
CHALLENGE_VERIFY = ("completeSignup", "completeLogin", "completeIdentifierAdd")
CREDENTIAL_SCHEMAS = {"SessionGranted", "StaffSession", "StaffPreMfaState"}
SECRET_QUERY_NAMES = re.compile(r"token|code|password|pin|secret", re.I)
LABELS = {"Explicitly required": "EXPLICIT",
          "Implied by approved architecture/security": "IMPLIED",
          "Requires a proposed requirement change": "CHANGE_REQUIRED",
          "Unsupported (removed)": "UNSUPPORTED"}
EXPECTED_AUDIT_ROWS = 26


def ops(spec):
    for path, item in spec["paths"].items():
        for method in METHODS:
            if method in item:
                yield path, method, item[method]


def refs(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "$ref":
                yield v
            else:
                yield from refs(v)
    elif isinstance(node, list):
        for v in node:
            yield from refs(v)


def resolve(spec, ref):
    node = spec
    for part in ref.lstrip("#/").split("/"):
        node = node[part]
    return node


def known_requirements():
    found = set()
    for f in REQ_FILES:
        found |= set(re.findall(r"\b((?:FR|NFR|US)-\d{3})\b", f.read_text()))
    return found


def sql_enums():
    v1 = MIGRATIONS[0].read_text()

    def check_values(column):
        m = re.search(column + r"\s+text[^,]*?CHECK \(" + column + r" IN \(([^)]*)\)", v1, re.S)
        return set(re.findall(r"'([A-Z_]+)'", m.group(1))) if m else None

    return {c: check_values(c) for c in ("account_status", "platform", "identifier_type")}


def audit_rows(design_text):
    """Rows of the requirement audit table: | `operationId` | <label> | ..."""
    rows = {}
    labels = "|".join(re.escape(label) for label in LABELS)
    for m in re.finditer(rf"^\| `(\w+)` \| ({labels}) \|", design_text, re.M):
        rows[m.group(1)] = LABELS[m.group(2)]
    return rows


def run_checks(spec, design_text):
    problems = []
    add = problems.append
    reqs = known_requirements()
    enums = sql_enums()

    try:
        validate_openapi(copy.deepcopy(spec))
    except Exception as e:  # noqa: BLE001 - report any validator failure as a finding
        add(f"OpenAPI structure invalid: {str(e)[:200]}")
        return problems

    # ---- requirement audit: the document and the contract must agree
    audit = audit_rows(design_text)
    if len(audit) != EXPECTED_AUDIT_ROWS:
        add(f"audit table has {len(audit)} operations, expected {EXPECTED_AUDIT_ROWS}")
    contract_ids = {op.get("operationId") for _, _, op in ops(spec)}
    kept = {o for o, label in audit.items() if label != "UNSUPPORTED"}
    removed = {o for o, label in audit.items() if label == "UNSUPPORTED"}
    if contract_ids != kept:
        add(f"contract operations differ from audited kept operations: only in contract "
            f"{sorted(contract_ids - kept)}, only in audit {sorted(kept - contract_ids)}")
    if removed & contract_ids:
        add(f"operations audited as unsupported are still in the contract: {sorted(removed & contract_ids)}")

    seen_ids = set()
    schemes = spec["components"]["securitySchemes"]
    cookie_schemes = {n for n, s in schemes.items() if s.get("in") == "cookie"}
    for path, method, op in ops(spec):
        oid = op.get("operationId")
        where = f"{method.upper()} {path}"
        if not oid or oid in seen_ids:
            add(f"{where}: operationId missing or duplicated")
        seen_ids.add(oid)
        for key in ("summary", "tags", "x-requirements", "x-rate-limit-class", "x-support"):
            if not op.get(key):
                add(f"{where}: missing {key}")
        if oid in audit and audit[oid] != op.get("x-support"):
            add(f"{where}: x-support {op.get('x-support')} differs from the audit label {audit[oid]}")
        cited = op.get("x-requirements", [])
        for r in cited:
            if r not in reqs and r not in PSEUDO_SOURCES:
                add(f"{where}: unknown requirement {r}")
        numbered = [r for r in cited if r in reqs]
        support = op.get("x-support")
        if support not in ("EXPLICIT", "IMPLIED", "CHANGE_REQUIRED"):
            add(f"{where}: x-support must be EXPLICIT, IMPLIED or CHANGE_REQUIRED, got {support}")
        if support == "EXPLICIT" and not any(r.startswith(("FR-", "NFR-")) for r in numbered):
            add(f"{where}: labelled EXPLICIT but cites no numbered FR or NFR")
        if support == "IMPLIED" and not cited:
            add(f"{where}: labelled IMPLIED but cites nothing")
        changes = op.get("x-requirement-change", [])
        if support == "CHANGE_REQUIRED" and not changes:
            add(f"{where}: labelled CHANGE_REQUIRED but names no requirement change")
        if support != "CHANGE_REQUIRED" and changes:
            add(f"{where}: names a requirement change but is not labelled CHANGE_REQUIRED")
        for rc in changes:
            if not re.search(rf"^\| {re.escape(rc)} \|", design_text, re.M):
                add(f"{where}: requirement change {rc} is not defined in the design document table")
        if op.get("x-rate-limit-class") not in RATE_CLASSES:
            add(f"{where}: unknown rate-limit class {op.get('x-rate-limit-class')}")
        codes = set(op.get("responses", {}))
        for c in ("429", "500", "503"):
            if c not in codes:
                add(f"{where}: no {c} response")
        if method in UNSAFE and op.get("requestBody"):
            for c in ("400", "413", "415"):
                if c not in codes:
                    add(f"{where}: request body but no {c} response")
        # authentication
        security = op.get("security", spec.get("security"))
        if security == [] and oid not in PUBLIC_OPERATIONS:
            add(f"{where}: unauthenticated but not on the public-operation allow-list")
        if oid in PUBLIC_OPERATIONS and security != []:
            add(f"{where}: on the public list but declares security")
        if security != [] and "401" not in codes:
            add(f"{where}: authenticated but no 401 response")
        for alt in security or []:
            if method in UNSAFE and any(n in cookie_schemes for n in alt) and "csrfToken" not in alt:
                add(f"{where}: cookie session on a state-changing operation without CSRF")
        if security and any(n in cookie_schemes for alt in security for n in alt) and "403" not in codes:
            add(f"{where}: cookie session operation has no 403 response")
        # anti-enumeration
        if oid in CHALLENGE_START:
            bad = codes & {"404", "409", "422"}
            if bad:
                add(f"{where}: challenge start must be uniform but declares {sorted(bad)}")
            if "202" not in codes:
                add(f"{where}: must answer 202")
        if oid in CHALLENGE_VERIFY:
            if codes & {"404", "409"}:
                add(f"{where}: verification must not distinguish unknown/used/conflict")
            if "422" not in codes:
                add(f"{where}: missing the uniform CHALLENGE_INVALID response")
        for prm in op.get("parameters", []):
            prm = resolve(spec, prm["$ref"]) if "$ref" in prm else prm
            if prm["in"] == "query" and SECRET_QUERY_NAMES.search(prm["name"]):
                add(f"{where}: secret-looking query parameter {prm['name']}")
        # decisions exist as headings in the design document
        for d in op.get("x-decision", []):
            if not re.search(rf"^###? {re.escape(d)}\b", design_text, re.M):
                add(f"{where}: {d} is not defined in the design document")
        if "x-database-function" in op:
            text = "\n".join(m.read_text() for m in MIGRATIONS)
            if not re.search(rf"CREATE (?:OR REPLACE )?FUNCTION {re.escape(op['x-database-function'])}\(", text):
                add(f"{where}: database function {op['x-database-function']} not found in V1/V3")
        # responses
        for code, resp in op["responses"].items():
            r = resolve(spec, resp["$ref"]) if "$ref" in resp else resp
            if code.startswith("2") and "X-Correlation-Id" not in r.get("headers", {}):
                add(f"{where} {code}: success response has no X-Correlation-Id header")
            schema = r.get("content", {}).get("application/json", {}).get("schema", {})
            used = schema.get("$ref", "").split("/")[-1]
            if used in CREDENTIAL_SCHEMAS and "Cache-Control" not in r.get("headers", {}):
                add(f"{where} {code}: credential-bearing response lacks Cache-Control: no-store")
            if code[0] in "45" and used != "ApiError":
                add(f"{where} {code}: error response is not ApiError")

    # ---- components
    all_refs = set(refs(spec))
    for kind in ("schemas", "responses", "parameters", "headers"):
        for name in spec["components"].get(kind, {}):
            if f"#/components/{kind}/{name}" not in all_refs:
                add(f"unused component {kind}/{name}")
    for r in all_refs:
        try:
            resolve(spec, r)
        except KeyError:
            add(f"unresolved $ref {r}")
    for name, sch in spec["components"]["schemas"].items():
        if name.endswith("Request"):
            if sch.get("additionalProperties") is not False:
                add(f"request schema {name} must set additionalProperties: false")
            for pname, p in sch.get("properties", {}).items():
                if p.get("type") == "string" and not (p.get("maxLength") or p.get("enum") or p.get("format")):
                    add(f"request schema {name}.{pname} is an unbounded string")
    codes_enum = set(spec["components"]["schemas"]["ApiError"]["properties"]["code"]["enum"])
    other_enum_values = set()

    def collect_enums(node):
        if isinstance(node, dict):
            if isinstance(node.get("enum"), list):
                other_enum_values.update(v for v in node["enum"] if isinstance(v, str))
            for v in node.values():
                collect_enums(v)
        elif isinstance(node, list):
            for v in node:
                collect_enums(v)

    collect_enums({k: v for k, v in spec["components"]["schemas"].items() if k != "ApiError"})
    for code in set(re.findall(r"`([A-Z][A-Z_]{3,})`", yaml.safe_dump(spec))):
        if code not in codes_enum and code not in other_enum_values:
            add(f"description mentions `{code}` which is not an ApiError code")
    # ---- alignment with the database CHECK lists
    sch = spec["components"]["schemas"]
    for col, api_values in (("platform", set(sch["DeviceInfo"]["properties"]["platform"]["enum"])),
                            ("identifier_type", set(sch["Identifier"]["properties"]["type"]["enum"]))):
        if enums[col] is None:
            add(f"could not read the {col} CHECK list from V1")
        elif api_values != enums[col]:
            add(f"enum drift for {col}: API {sorted(api_values)} vs database {sorted(enums[col])}")
    status = set(sch["CurrentUser"]["properties"]["accountStatus"]["enum"])
    if status != {"ACTIVE", "SUSPENDED"} or not status <= (enums["account_status"] or set()):
        add(f"CurrentUser.accountStatus must be exactly ACTIVE and SUSPENDED (people who may sign in), got {sorted(status)}")

    # ---- examples validate against their schemas
    def validate_example(example, schema, label):
        errs = list(Draft4Validator(inline(spec, schema)).iter_errors(example))
        if errs:
            add(f"example for {label} does not match its schema: {errs[0].message[:120]}")

    for path, method, op in ops(spec):
        rb = op.get("requestBody", {}).get("content", {}).get("application/json", {})
        if "example" in rb:
            validate_example(rb["example"], rb["schema"], f"{method.upper()} {path} request")
    for name, resp in spec["components"]["responses"].items():
        c = resp.get("content", {}).get("application/json", {})
        if "example" in c:
            validate_example(c["example"], c["schema"], f"response {name}")
    return problems


def inline(spec, node, depth=0):
    """Expand $refs so jsonschema (draft 4, close to OpenAPI 3.0 for what is used here) can validate."""
    if depth > 20:
        return {}
    if isinstance(node, dict):
        if "$ref" in node:
            return inline(spec, resolve(spec, node["$ref"]), depth + 1)
        out = {k: inline(spec, v, depth + 1) for k, v in node.items() if k != "nullable"}
        if node.get("nullable") and "type" in out:
            out["type"] = [out["type"], "null"]
        out.pop("format", None)  # format assertions are not part of this check
        return out
    if isinstance(node, list):
        return [inline(spec, v, depth + 1) for v in node]
    return node


# ---------------------------------------------------------------- negative controls

def mutations():
    def drop_429(s): del s["paths"]["/auth/login/challenges"]["post"]["responses"]["429"]
    def open_request(s): s["components"]["schemas"]["StartLoginRequest"]["additionalProperties"] = True
    def drop_csrf(s): s["paths"]["/staff/auth/logout"]["post"]["security"] = [{"staffSession": []}]
    def enumeration_oracle(s):
        s["paths"]["/auth/login/challenges"]["post"]["responses"]["409"] = {"$ref": "#/components/responses/BadRequest"}
    def unknown_requirement(s): s["paths"]["/me"]["get"]["x-requirements"] = ["FR-999"]
    def bad_example(s): s["paths"]["/auth/login/challenges"]["post"]["requestBody"]["content"]["application/json"]["example"] = {"identifier": {"type": "FAX", "value": "x"}}
    def drop_no_store(s): del s["paths"]["/auth/login/verifications"]["post"]["responses"]["200"]["headers"]["Cache-Control"]
    def missing_function(s): s["paths"]["/me"]["patch"]["x-database-function"] = "set_everything"
    def enum_drift(s): s["components"]["schemas"]["Identifier"]["properties"]["type"]["enum"] = ["PHONE", "EMAIL", "FAX"]
    def public_by_accident(s): s["paths"]["/me"]["get"]["security"] = []
    def secret_in_query(s):
        s["paths"]["/me/identifiers"]["get"]["parameters"] = [{"name": "token", "in": "query", "schema": {"type": "string"}}]
    def unbounded_string(s): del s["components"]["schemas"]["RefreshRequest"]["properties"]["refreshToken"]["maxLength"]
    def unknown_decision(s): s["paths"]["/me"]["patch"]["x-decision"] = ["TC-99"]
    def unused_component(s): s["components"]["schemas"]["Orphan"] = {"type": "object"}
    def error_not_apierror(s): s["components"]["responses"]["Forbidden"]["content"]["application/json"]["schema"] = {"type": "object"}
    def account_status_wider(s): s["components"]["schemas"]["CurrentUser"]["properties"]["accountStatus"]["enum"] = ["ACTIVE", "SUSPENDED", "DELETED"]
    def support_label_mismatch(s): s["paths"]["/me"]["get"]["x-support"] = "IMPLIED"
    def change_required_without_rc(s): s["paths"]["/me/identifiers/challenges"]["post"]["x-requirement-change"] = []
    def unknown_rc(s): s["paths"]["/me/identifiers/challenges"]["post"]["x-requirement-change"] = ["RC-99"]
    def direct_without_numbered(s): s["paths"]["/me"]["get"]["x-requirements"] = ["S6-SEC"]
    def removed_op_returns(s):
        s["paths"]["/me/sessions"] = {"get": copy.deepcopy(s["paths"]["/me/identifiers"]["get"])}
        s["paths"]["/me/sessions"]["get"]["operationId"] = "listSessions"
    def operation_not_audited(s):
        s["paths"]["/me/extra"] = {"get": copy.deepcopy(s["paths"]["/me/identifiers"]["get"])}
        s["paths"]["/me/extra"]["get"]["operationId"] = "extraOperation"
    return {k: v for k, v in locals().items() if callable(v)}


def self_test(spec, design_text):
    baseline = run_checks(spec, design_text)
    if baseline:
        print("baseline is not clean; fix it before the self-test:")
        for p in baseline:
            print("  -", p)
        return 1
    missed = []
    muts = mutations()
    for name, mutate in muts.items():
        copy_ = copy.deepcopy(spec)
        mutate(copy_)
        found = run_checks(copy_, design_text)
        status = "caught" if found else "MISSED"
        print(f"  {status:7} {name}" + (f"  -> {found[0][:90]}" if found else ""))
        if not found:
            missed.append(name)
    # mutate the document side too: an audit label that disagrees with the contract
    broken_doc = design_text.replace("| `getCurrentUser` | Explicitly required |",
                                     "| `getCurrentUser` | Implied by approved architecture/security |", 1)
    found = run_checks(spec, broken_doc)
    print(f"  {'caught' if found else 'MISSED':7} document_label_mismatch" + (f"  -> {found[0][:90]}" if found else ""))
    if not found:
        missed.append("document_label_mismatch")
    total = len(muts) + 1
    print(f"negative controls: {total - len(missed)} caught / {len(missed)} missed")
    return 1 if missed else 0


def main():
    spec = yaml.safe_load(SPEC.read_text())
    design_text = DESIGN_DOC.read_text()
    if "--self-test" in sys.argv:
        return self_test(spec, design_text)
    problems = run_checks(spec, design_text)
    n_ops = sum(1 for _ in ops(spec))
    if problems:
        print(f"FAIL: {len(problems)} problem(s) in {SPEC.name}")
        for p in problems:
            print("  -", p)
        return 1
    print(f"PASS: {SPEC.name}: valid OpenAPI, {n_ops} operations, audit table matches the contract, all design checks satisfied")
    return 0


if __name__ == "__main__":
    sys.exit(main())

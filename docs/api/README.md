# API design drafts

Local design drafts, not approved, not implemented. Part 1 (identity and access), revision 2:

- [`API_DESIGN_IDENTITY_ACCESS.md`](API_DESIGN_IDENTITY_ACCESS.md) - requirement audit of the operations, requirement changes needed, decisions (founder vs technical), gaps
- [`openapi/identity-access.openapi.yaml`](openapi/identity-access.openapi.yaml) - the contract draft (16 operations)
- [`tools/check_contract.py`](tools/check_contract.py) - design-time checks

## Running the checks

They read files only (no server, no database). Python 3 with `pyyaml`, `jsonschema` and `openapi-spec-validator`:

```
cd ~/dev/psa
python3 -m venv /tmp/apivenv && /tmp/apivenv/bin/pip install openapi-spec-validator==0.7.1 jsonschema==4.23.0 pyyaml
/tmp/apivenv/bin/python docs/api/tools/check_contract.py               # check the contract
/tmp/apivenv/bin/python docs/api/tools/check_contract.py --self-test   # prove the checks can fail
```

What they verify: the file is valid OpenAPI 3.0; the requirement-audit table in the design document and the contract list the same
operations with the same support label (directly / partially supported; unsupported ones must not be in the contract); each
operation has an id, requirement citations that exist (a directly supported one cites a numbered FR or NFR), a rate class,
authentication, the required error responses, and CSRF on cookie-based state changes; challenge operations stay uniform (nothing
that would reveal whether an account exists); request schemas reject unknown fields and bound every string; credential-bearing
responses are `no-store`; error responses use the one envelope; every `$ref` resolves and nothing is unused; the decisions named in
`x-decision` exist in the design document; API enums match the database `CHECK` lists; examples match their schemas. The
`--self-test` mode applies deliberate faults to an in-memory copy and requires every one to be caught.

What they do **not** verify: that the design is right, that the approved requirements are met beyond the citations, any
implementation, security of the authentication scheme, or that mobile and dashboard clients can use it.

Status of the revision-2 files: written but **not yet executed** (see `docs/HANDOFF.md` section 5).

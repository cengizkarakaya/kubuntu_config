# CI policy architecture

The former inline Python assertion block in `.github/workflows/qa.yml` is preserved in `tests/test-policy-legacy.py` (all 59 assert statements). This is a deliberately independent regression gate. `policy/invariants.toml` adds an inspectable declaration of package and bootstrap invariants checked by `scripts/check-policy.py`; it does not drive production installation. `tests/test-policy.py` exercises deliberate violations using temporary copies of manifests. Existing behavior tests are unchanged. Do not delete old assertions until equivalent independent behavioral coverage has been demonstrated. A change to policy alone must not silently relax the independent safety checks. The legacy text checks remain syntax-sensitive by design during migration.

```bash
python3 -B tests/test-policy-legacy.py
python3 -B scripts/check-policy.py
python3 -B tests/test-policy.py
```

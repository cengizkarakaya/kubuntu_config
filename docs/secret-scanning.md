# Repository secret scanning

CI scans the fetched Git history with Gitleaks, using a fixed official release asset verified against the SHA-256 published by the GitHub release API. The scan uses full redaction and does not upload reports or post PR comments. It fails on findings; never paste the detected secret into a public issue or log.

This is an additional check, not permission to stage private files. Review every launcher snapshot, Conda export and inventory before staging. Keep all personal backups outside the repository.

If a real secret is exposed, revoke or rotate it immediately. Removing it in a new commit does not erase Git history. Review history cleanup separately. If a false positive is confirmed, use a narrowly scoped, documented exception rather than disabling a rule globally.

To upgrade Gitleaks, review its official stable release and update the asset version and published SHA-256 together in `.github/workflows/qa.yml`. Run CI on a review branch before merging. The scan is not a guarantee that the repository contains no private information.

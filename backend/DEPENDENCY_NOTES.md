# Backend dependency alignment

Runtime: Node 22. The production firebase-admin dependency and Flutter packages are unchanged.

Development/test packages are pinned to Firebase JS 12.19.0 and @firebase/rules-unit-testing 5.0.2, which supports Node 22. The previous Firebase JS 13 / Rules SDK 6 tree required Node >=24.12.0.

The following transitive overrides remain intentional:
- @grpc/grpc-js: 1.14.7 for the security fixes.
- glob under rimraf: 14.0.2 with minimatch 11.0.1. This crosses glob's major boundary and is covered by test:dependencies.
- @firebase/app: 0.16.2; @firebase/app-compat: 0.5.18. These keep database-compat's peer resolution on the Node-22-compatible release family instead of resolving Node-24-only peers.

Validation in preparation: installation with --engine-strict under Node 22.23.4 succeeded, 10 permission tests and 2 dependency compatibility tests passed, npm audit reported zero vulnerabilities. Rules regression tests run only against a local demo Firestore Emulator. Run these checks on the development machine too before merging; mocked permission tests do not replace real booking/order acceptance testing.

Run from backend:

```sh
npx --yes --package=node@22 -c 'node -v && npm install --engine-strict && npm run test:permissions && npm run test:dependencies && npm audit'
```

Run the Rules regression test from the repository root:

```sh
firebase emulators:exec --only firestore --project demo-lumi-permissions "cd backend && npx --yes --package=node@22 -c 'npm run test:rules'"
```

Restart the backend under Node 22 after changing installed packages. Commit package.json, package-lock.json, dependency_compat_test.js and this note. Keep backups and credentials out of Git. Review/remove overrides once upstream dependencies adopt compatible patched versions.

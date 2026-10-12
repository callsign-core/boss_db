# Selected upstream pool and inflection fixes

- Tracking: https://github.com/qubit-asia/qcb/issues/889.
- Adapt pool configuration intent from upstream `528d5b945f2165573a93322d972a3be7d98b78fe`. Preserve defaults `size=200`, `max_overflow=50`, and the fixed pool/worker identity. Resolve explicit values once before passing them to Poolboy so duplicate options cannot reverse precedence.
- Adapt inflection correction from upstream `5c3439c834a4a3a4fd9f0e7bde48d7e414b59738`: irregular word rules match suffixes rather than text inside unrelated words.
- `legacy_pluralize/1` and `legacy_singularize/1` preserve the original algorithm for implicit table/collection/bucket names, table/module conversion, generated associations, cache watches and news topics. Existing schemas and identifiers are not renamed or migrated.
- Ordinary `pluralize/1` and `singularize/1` use corrected rules. Existing persistent names remain the default; explicitly configured model table names remain authoritative.
- Verify the complete QCB naming/model inventory against the pre-change source, pool limits/worker failure/recovery, notifications, Mnesia storage and HTTP/WebSocket authentication/session/hybi00 parity on gen8.
- No dependency updates, optional SQL backend behavior changes, production deployment or image publication are included.

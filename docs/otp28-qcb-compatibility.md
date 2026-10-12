# OTP 28 source preservation

- Base: `d203a5176169460fd32267fbebbe614b58ba94ee`. Tracking: https://github.com/qubit-asia/qcb/issues/884.
- Scope: Parameterized compiler/record getters, ambient Mnesia transactions and MongoDB crypto. Shared changes preserve the already validated QCB patch behavior.
- Existing record tuples, storage schemas, IDs and callback/transaction conventions remain intact.
- Supported verification lane: native amd64 Ubuntu 24.04, OTP 28.5.0.7, QCB's locked dependency graph. Legacy Travis matrices and optional database/language/backend adapters are not a claim of OTP 28 coverage.
- QCB-specific controller/request/WebSocket facades and its Cowboy 2/hybi00 TV runtime remain in QCB. This branch adds no QCB application dependency to the framework.
- Validation: source identity against the QCB patches, portable compiler/Mnesia and generic worker regression tests, and the QCB native/full-runtime acceptance lane. Final results are recorded by Issue #884 and the draft PR.
- Source branches are review candidates; existing tags and default branches remain unchanged. No production deployment, image publication or release is performed.

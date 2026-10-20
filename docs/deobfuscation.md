# Deobfuscation Analysis

Decoded Base64 string:

```text
import os; os.system('rm -rf /')
```

The script decodes this text and passes it to `exec`. If run with sufficient
permissions, it attempts to recursively delete files from the filesystem root,
which can destroy the operating system and user data. Base64 is only an
encoding; it does not make the payload safe.

## Mitigations

- Do not execute decoded or otherwise untrusted text with `exec` or `eval`.
- Review and statically analyze source code and decoded payloads before running
  them.
- Validate data against an explicit format instead of treating data as code.
- Run untrusted code only in a disposable, isolated environment with minimal
  privileges and no access to important data.

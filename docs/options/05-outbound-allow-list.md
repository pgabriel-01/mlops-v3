---
title: "5 - Outbound allow-list"
weight: 5
---

Scenario 3 only. The default allows `pypi.org`, `files.pythonhosted.org`, `*.anaconda.com` and `conda.anaconda.org`. Replace it with exactly what your environment needs:

```yaml
allowed_outbound_fqdns:
  - pypi.org
  - files.pythonhosted.org
  - internal-mirror.contoso.com
```

Fewer hosts is safer, but training jobs that install packages fail if a host is missing.

Back to [Options](_index.md).

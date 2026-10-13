# Security

Report vulnerabilities privately through the repository's "Report a vulnerability" (GitHub security advisories) option. Do not open a public issue.

Generated projects use OIDC, no stored secrets, Key Vault with RBAC and purge protection, and Entra-authenticated Terraform state. The deploy identity is broad by default (Contributor + RBAC Administrator at subscription scope); scope it down for production.

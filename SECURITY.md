# Security

## Reporting a vulnerability

Please report a security vulnerability privately.

Do not open a public GitHub issue, discussion, or pull request for a suspected vulnerability. Do not paste tokens, passwords, or private URLs into a public log.

If this repository is hosted on GitHub, use **Security → Report a vulnerability** so the report stays in a private advisory. If that flow is not available yet, contact the maintainers through a private channel they have published. Do not guess an email address from a commit.

Include:

- The affected area, such as auth storage, logging, or the CLI copy step.
- A description of the impact.
- Steps to reproduce, without live secrets.
- The version or commit you tested, if you know it.

The maintainers will investigate and coordinate a fix. Please give them time to respond before any public disclosure.

## What this project already protects

- Tokens are stored with Flutter Secure Storage. Passwords are not stored.
- `env/*.json`, keystores, `key.properties`, and `local.properties` are gitignored.
- `awesome create` does not copy local environment JSON, signing files, SDK path files, or crash logs into a new project.
- HTTP logs record the method, path, and status code. They omit headers, query parameters, and bodies.
- Example environment files ship with an empty `API_BASE_URL`.

Application security rules for contributors are in `.agent/rules/security.md`.

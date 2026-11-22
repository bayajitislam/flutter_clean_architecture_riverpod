# GoRouter and one Dio client

## Context

Auth needs a redirect, and HTTP needs one place for the base URL, the token header, and redacted logs.

## Decision

`GoRouter` owns routes and the auth redirect. Paths live in `RoutePaths`. One `Dio` from `dioProvider` sends requests. Interceptors attach the token and log the method, path, and status only.

## Alternatives considered

- `Navigator 1.0` with manual stacks. The auth redirect is easier to get wrong.
- The `http` package. It is smaller, and it would still need interceptors and cancellation that Dio already has.
- A Dio instance per feature. Tokens and logs would drift.

## Consequences

A new screen is a `GoRoute` plus a path constant. A new request uses the shared client and a typed model. Features do not configure their own Dio.

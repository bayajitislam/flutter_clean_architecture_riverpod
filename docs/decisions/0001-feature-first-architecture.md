# Feature-first architecture

## Context

A starter kit is copied into many apps. If every screen reaches into a shared API client and a global state object, later features become coupled and hard to delete.

## Decision

Each feature lives in `lib/features/<feature>` and is split into `data`, `domain`, and `presentation` only when those layers earn their place. Domain code does not import Flutter or Dio. Screens call use cases. Cross-feature widgets live in `lib/shared`. Infrastructure lives in `lib/core`.

`awesome validate` rejects imports that cross those boundaries.

## Alternatives considered

- A single `lib/screens` and `lib/services` layout. It is faster for a tiny app and harder to split later.
- A package per feature. That is more isolation than a starter needs, and it slows the generator.

## Consequences

New features follow one shape, so contributors can find the repository, the use case, and the screen. A presentation-only page is allowed, so a static screen does not grow empty layers. Features cannot share data sources by importing them. They share types through `lib/shared` or pass an id in the route.

# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Minerva Protocol defines the gRPC contract between a "server" (a plugin embedded in a
military simulation engine, e.g. Arma 3) and "clients" that read simulation state and
send commands to units/groups. It is protobuf-only: no generated code is committed to
this repo. Consumers (e.g. `minerva-server`) generate their own bindings, typically via
`buf generate` against the published BSR module.

## Layout

All `.proto` files live under `minerva/v1/`, package `minerva.v1`:

- `common.proto` — `Side`, `Position`, `Orientation`, `Velocity`, `Faction`.
- `unit.proto` — `Unit`, `UnitState`, `HealthState`, `UnitCategory`, `UnitService`.
- `group.proto` — `Group`, `GroupReadiness`, `GroupService`.
- `location.proto` — `Location`, `Capability`, `LocationService`.
- `simulation.proto` — `SimulationInfo`, `SimulationStateUpdate`, `SimulationService`.
- `commands.proto` — per-command messages (`MoveCommand`, `SearchAndDestroyCommand`, ...),
  `CommandService.SendCommand` (single RPC, oneof over command types).
- `waypoint.proto`, `weather.proto`, `loadout.proto` — supporting types.

Units: positions are in meters, `z` is altitude above sea level (ASL). Directions
(`Orientation.direction`) are compass degrees (0 = north, clockwise). Wind fields on
`Weather` are reported as-is from the simulation (radians from east, counterclockwise).

`Group` does not embed its units; `Unit.group_id` is the single source of truth for
membership, queried via `UnitService.ListUnits(group_id)`.

## Working with the protos

This repo uses [buf](https://buf.build) — there is no `protoc` step and no build script.

- `buf lint` — check style (config: `buf.yaml`, `STANDARD` lint rules).
- `buf format -w` — format in place; `buf format --diff --exit-code` to check only.
- `buf build` — verify the module compiles.
- `buf breaking --against '.git#branch=main'` — check for breaking changes against `main`.

Run all three (lint, format check, build) before opening a PR; CI (`bufbuild/buf-action`)
runs the same checks, plus a breaking-change check against the published BSR module on
pull requests.

## Publishing (BSR)

The module is `buf.build/voron-simulations/minerva`, public, default label `main`. CI
pushes a new commit to BSR automatically on every push to `main` (`buf push`, using the
`BUF_TOKEN` repository secret). Consumers pin a specific BSR commit in their
`buf.gen.yaml` input rather than tracking `main` directly, so protocol changes only take
effect downstream when they explicitly bump the pinned commit.

## Compatibility policy

- Prefer additive changes (new fields, new RPCs, new messages) — these are non-breaking
  and safe to publish directly to `main`.
- Breaking changes (removing/renaming fields or RPCs, changing field numbers or types)
  are allowed but must be called out explicitly in the PR description, since every
  downstream consumer (`minerva-server` and, transitively, `minerva-arma3`) has to bump
  its pinned commit and update accordingly.

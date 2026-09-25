# Minerva v1 contract

The protobuf definitions in [`minerva/v1`](../minerva/v1) are the wire contract.
This document records the units and current behavior of the Minerva server and
Arma 3 adapter where a field or stream message alone does not convey them.

## Coordinates and time

- `Position.x` and `Position.y` are map coordinates in meters relative to the
  map origin; `Position.z` is altitude in meters above sea level (ASL).
  `SimulationInfo.world_size` has `x_meters` and `y_meters` extents. The current
  Arma 3 adapter reports the same `worldSize` value for both axes.
- `Velocity` components and `Weather.wind_speed` are meters per second.
  `Orientation.direction` is a compass heading in degrees, clockwise from
  north. `Weather.wind_direction` is radians counterclockwise from east, as
  reported by the simulation.
- `simulation_start_sim_time` and `SimulationStateUpdate.simulation_time` are
  in-simulation Unix timestamps in seconds. `simulation_start_real_time` is a
  wall-clock Unix timestamp in seconds. The Arma 3 adapter converts its date
  array at minute precision. `time_acceleration` is the simulation-time rate
  relative to real time, as reported by the engine.

## Readiness and loadout

`GroupReadiness.fuel_state`, `ammo_state`, and `health_state` are fractions:
0 is depleted or destroyed and 1 is full or undamaged. The Arma 3 adapter
averages fuel over tracked vehicles and health over tracked units; an empty
set yields 1. It currently reports `ammo_state = 1` because it has no group
ammo model. `HealthState.health` is also 1 when undamaged and 0 when destroyed.

`LoadoutState` and `Weapon` remain in the schema for consumers, but the current
Arma 3 adapter does not populate `UnitState.loadout`. An absent loadout does
not mean that the unit has no weapons.

## Filters and membership

An omitted `side` filter means all sides. A present filter matches the
group's `side`, the location's `owner`, or, for `ListUnits`, the side of the
unit's cached group. `ListUnits.group_id` filters by exact group ID; when both
filters are present, both must match. A unit without a cached group does not
match a `side` filter. An unknown `side` enum value returns `INVALID_ARGUMENT`.
`Group` does not embed units; `Unit.group_id` is the membership source.

## Commands

`SendCommandRequest` selects one command. The server returns
`INVALID_ARGUMENT` for a missing command or required command data. A valid
command targeting an unknown group returns `COMMAND_RESULT_FAILURE` with a
reason. For a dispatched command, `COMMAND_RESULT_SUCCESS` means the engine
acknowledged the command; it does not promise that the resulting task has
finished. An engine rejection, timeout, or reset returns
`COMMAND_RESULT_FAILURE` with a reason. The Arma 3 adapter currently rejects
`DefendZone` and `Support` as unimplemented.

## Streams and reset

`SubscribeGroupUpdates` starts with one `upserted` message per cached group
matching the optional `side` filter, followed by changes. `upserted` replaces
the client's view of that group. `removed_id` means the client should stop
tracking that ID. Group removals are sent to all subscribers because the ID
does not carry a side. If a group changes side, the server sends a removal
for the old membership before an upsert for the new one. A client may receive
a removal for an ID it never tracked; it can ignore that removal. There is no
explicit end-of-snapshot marker.

`SubscribeSimulationUpdates` first sends the cached state if one exists,
then sends state changes. An absent `state` message signals a server reset and
clears the client's cached simulation state. On reset, the server also sends
`removed_id` for each cached group. New subscriptions after a reset have no
initial simulation state or groups until the server receives new data. Neither
stream has a reset generation or resumption cursor.

The current server silently skips events if a subscriber falls behind its
bounded broadcast buffer. It does not signal a gap or send a replacement
snapshot, so a client cannot rely on either stream for lossless recovery.
Detecting lag and restoring a consistent view requires a separate server
change; this schema change does not provide that behavior.

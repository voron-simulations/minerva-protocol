# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Minerva Protocol repository - a Protocol Buffers (protobuf) based communication protocol for military simulation systems. The project defines message schemas for coordinating military units, groups, zones, and commands in a distributed simulation environment.

## Architecture

The protocol is designed around "server" which is a plugin to a simulation engine (e.g. Arma 3, Digital Combat Simulator) and "client" which connects to the server to send commands and receive updates. The protocol supports real-time bidirectional communication using gRPC streaming.

Messages are sent asynchronously, allowing clients to send commands while receiving state updates. The protocol is extensible, allowing new message types to be added without breaking existing functionality.

## Message Types

The protocol defines several key message types:

- Request - message sent from client to server. Server is expected to respond with a response message.
- Command - message sent from client to server to give instructions to a group or unit.
- Response - message sent from server to client in response to a request.
- Update - message sent from server to client to update the state of the simulation.

## Build System

The project uses a simple bash-based build system:

- **Build all targets**: `./build.sh` - Generates C#, Java, and Python code from .proto files
- **Build command**: `protoc *.proto --csharp_out=out/csharp --java_out=out/java --python_out=out/python`
- **Output directories**: 
  - `out/csharp/` - C# generated code
  - `out/java/Minerva/Protocol/` - Java generated code  
  - `out/python/` - Python generated code

## Architecture

### Core Protocol Structure

The protocol is organized around several key .proto files:

1. **core.proto** - Central message routing and service definitions
   - `AnyServerToClientMessage` - Main message wrapper with transaction IDs and oneof message types
   - `MessageExchangeService` - Bidirectional streaming gRPC service
   - Imports and orchestrates all other message types

2. **common.proto** - Fundamental data types
   - `Position`, `Orientation`, `Velocity` - Spatial data structures
   - `Side`, `Faction` - Military organizational structures
   - `SimulationStateUpdate` - Global simulation state

3. **group.proto** - Military unit group management
   - `Group` - Container for multiple units with shared state
   - `GroupState` - Fuel, ammo, health status tracking
   - Group listing and state update messages

4. **commands.proto** - Military command messages
   - `MoveCommand` - Basic unit movement
   - `SearchAndDestroyCommand` - Combat missions
   - Additional commands: DefendZone, Patrol, Support

5. **unit.proto** and **zone.proto** - Individual unit and zone definitions
6. **loadout.proto** - Equipment and weapon system definitions

### Message Flow Pattern

All messages follow a request/response pattern and are wrapped in `AnyServerToClientMessage` for routing. The system supports:
- Real-time state updates (simulation, group, zone)
- Command execution (move, combat, support)
- Query operations (list groups/zones, get specific entities)

## Development Workflow

1. Modify .proto files to define new messages or services
1. Run `./build.sh` to ensure correctness and generate code
1. Ensure backward compatibility for existing message types

## Key Design Patterns

- **Transaction IDs**: All messages support optional transaction tracking
- **Oneof unions**: `AnyServerToClientMessage` uses protobuf oneof for type-safe message routing
- **Streaming RPC**: Core service uses bidirectional streaming for real-time communication
- **State management**: Separate state update messages for different entity types
- **Military modeling**: Hierarchical structure (sides → factions → groups → units)
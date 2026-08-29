# TNR — WorkspaceSerializer

<p align="center">
  <b>A lightweight Roblox Studio serializer for saving, exporting, and restoring Instance hierarchies.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Roblox%20Studio-Plugin-black?style=for-the-badge&logo=roblox&logoColor=white">
  <img src="https://img.shields.io/badge/Luau-2C2D72?style=for-the-badge">
  <img src="https://img.shields.io/badge/Status-Development-orange?style=for-the-badge">
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer">
  <img src="https://img.shields.io/github/forks/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer">
  <img src="https://img.shields.io/github/issues/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer">
</p>

<p align="center">
  <img src="https://img.shields.io/github/last-commit/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer?style=for-the-badge">
  <img src="https://img.shields.io/github/repo-size/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer?style=for-the-badge">
  <img src="https://img.shields.io/github/license/Bondpley/Tooling-Node-Runtime-WorkspaceSerializer>
</p>

---

## Overview

**WorkspaceSerializer** is a Roblox Studio utility designed to serialize `Instance` hierarchies into structured data and reconstruct them later.

Instead of treating a Workspace as a collection of individual objects, WorkspaceSerializer treats it as a **tree**:

Workspace
│
├── Map
│   ├── Buildings
│   │   ├── House
│   │   │   ├── Walls
│   │   │   └── Door
│   │   └── Shop
│   │
│   ├── Roads
│   └── Decorations
│
├── SpawnLocation
└── Environment

The serializer walks through this hierarchy, reads supported properties, converts Roblox-specific datatypes into a portable representation, and stores the result as ordinary Lua data.

The same data can then be passed through the deserializer to rebuild the hierarchy.

---

## Why?

Roblox `Instance` objects contain much more than just a name and class.

A single `Part` can contain properties such as:

```lua
CFrame
Size
Color
Material
Transparency
Anchored
CanCollide
CanTouch
CanQuery
CastShadow
CustomPhysicalProperties
```

Some of these values are also Roblox-specific datatypes:

```lua
Vector3
Vector2
Color3
CFrame
UDim2
BrickColor
NumberRange
PhysicalProperties
EnumItem
Rect
```

These values cannot simply be dumped into a basic table and expected to survive serialization.

WorkspaceSerializer solves this by converting them into tagged data.

For example:

```lua
Vector3.new(10, 20, 30)
```

becomes:

```lua
{
    "V3",
    10,
    20,
    30
}
```

and can later be reconstructed as:

```lua
Vector3.new(10, 20, 30)
```

---

# How It Works

At a high level, the process looks like this:

```text
             Roblox Workspace
                    │
                    ▼
             ┌──────────────┐
             │   Serializer │
             └──────┬───────┘
                    │
                    ▼
            Structured Lua Data
                    │
                    ▼
             ┌──────────────┐
             │   Storage    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │ Deserializer │
             └──────┬───────┘
                    │
                    ▼
             Reconstructed
               Instances
```

The important part is that the serializer does not attempt to store Roblox objects directly.

Instead, it creates a representation that can be safely manipulated, stored, exported, or transmitted.

---

# Example

Given a simple object:

```text
Workspace
└── TestPart
```

with:

```lua
TestPart.Position = Vector3.new(10, 5, 20)
TestPart.Size = Vector3.new(4, 2, 4)
TestPart.Color = Color3.fromRGB(255, 100, 50)
TestPart.Anchored = true
```

the resulting data can conceptually look like:

```lua
{
    ClassName = "Part",
    Name = "TestPart",

    Properties = {
        Position = {"V3", 10, 5, 20},
        Size = {"V3", 4, 2, 4},
        Color = {"C3", 1, 0.392, 0.196},
        Anchored = true,
    },

    Children = {}
}
```

The exact internal format can evolve, but the principle remains the same:

> Roblox objects → serializable data → Roblox objects

---

# Supported Datatypes

WorkspaceSerializer includes explicit serialization support for several Roblox datatypes.

| Roblox Type          | Tag      | Example                |
| -------------------- | -------- | ---------------------- |
| `Vector3`            | `V3`     | `{"V3", X, Y, Z}`      |
| `Vector2`            | `V2`     | `{"V2", X, Y}`         |
| `Color3`             | `C3`     | `{"C3", R, G, B}`      |
| `CFrame`             | `CF`     | Position + orientation |
| `UDim2`              | `UD2`    | Scale + Offset         |
| `BrickColor`         | `BC`     | BrickColor number      |
| `NumberRange`        | `NR`     | Minimum + Maximum      |
| `EnumItem`           | `EN`     | Enum type + name       |
| `Rect`               | `RECT`   | Min + Max              |
| `PhysicalProperties` | `PP`     | Physical parameters    |
| `Instance`           | —        | Instance reference     |
| Scripts              | `SCRIPT` | Script placeholder     |

---

# CFrame Serialization

`CFrame` deserves special handling because it contains both position and rotation.

WorkspaceSerializer stores:

```text
Position
LookVector
UpVector
```

For example:

```lua
{
    "CF",

    position.X,
    position.Y,
    position.Z,

    look.X,
    look.Y,
    look.Z,

    up.X,
    up.Y,
    up.Z
}
```

The value can then be reconstructed during deserialization.

This allows objects to retain their orientation instead of only saving their position.

---

# Enum Serialization

Roblox enums are represented by their enum type and item name.

For example:

```lua
Enum.Material.Neon
```

becomes:

```lua
{
    "EN",
    "Material",
    "Neon"
}
```

and is reconstructed using:

```lua
Enum.Material.Neon
```

This avoids depending on numeric enum values.

---

# Instance Hierarchies

WorkspaceSerializer is designed around the fact that Roblox is hierarchical.

For example:

```text
Model
├── Base
├── Walls
│   ├── Wall1
│   ├── Wall2
│   └── Wall3
└── Roof
```

The serializer preserves this parent-child relationship.

After restoration:

```text
Model
├── Base
├── Walls
│   ├── Wall1
│   ├── Wall2
│   └── Wall3
└── Roof
```

the hierarchy remains intact.

This is especially useful for maps, builds, prefabs, UI trees, and other structured collections of Instances.

---

# Roblox Studio

WorkspaceSerializer is built around the Roblox Studio data model.

The Studio Explorer represents objects as a parent-child hierarchy, with `Workspace` containing visible 3D content and other services holding different parts of the experience.

```text
Workspace
├── Camera
├── Terrain
├── SpawnLocation
├── Baseplate
└── Map
    ├── Buildings
    └── Decorations
```

That hierarchy is the foundation WorkspaceSerializer works with.

![Roblox Studio Explorer]([https://img.itch.zone/aW1nLzIwNjM3OTAzLnBuZw%3D%3D/original/1OXvkn.png](https://prod.docsiteassets.roblox.com/assets/studio/explorer/Parent-Child-Hierarchy.png.webp))

---

# Basic Usage

A typical serialization flow looks like:

```lua
local Serializer = require(path.To.Serializer)

local data = Serializer:Serialize(workspace.Map)
```

At this point, `data` contains the serialized representation of the selected hierarchy.

The data can then be stored or passed to another part of the application.

To restore it:

```lua
local restored = Serializer:Deserialize(data)

restored.Parent = workspace
```

---

# Example: Saving a Model

```lua
local model = workspace:FindFirstChild("Map")

if model then
    local data = Serializer:Serialize(model)

    print("Model serialized successfully")
end
```

The serializer can then process the model recursively:

```text
Map
├── Buildings
│   ├── House
│   └── Shop
├── Roads
└── Props
    ├── Tree
    ├── Bench
    └── Lamp
```

---

# Example: Restoring a Model

```lua
local data = savedData

local model = Serializer:Deserialize(data)

if model then
    model.Parent = workspace
end
```

The resulting hierarchy is reconstructed from the serialized representation.

---

# Serialization Pipeline

The internal pipeline can be summarized as:

```text
Instance
   │
   ├── ClassName
   ├── Name
   ├── Properties
   └── Children
          │
          ▼
      serializeValue()
          │
          ▼
    Tagged Lua values
          │
          ▼
      Serialized tree
```

Deserialization reverses the process:

```text
Serialized tree
      │
      ▼
deserializeValue()
      │
      ▼
Roblox datatypes
      │
      ▼
Instance creation
      │
      ▼
Property restoration
      │
      ▼
Child restoration
```

---

# Property Handling

WorkspaceSerializer uses a defined property list to determine which properties should be serialized.

Some examples include:

```lua
"CFrame"
"Position"
"Orientation"
"Size"
"Transparency"
"Color"
"BrickColor"
"Material"
"Anchored"
"CanCollide"
"CanTouch"
"CanQuery"
"CastShadow"
"Massless"
"Locked"
```

UI-related properties can also be handled:

```lua
"Text"
"TextColor3"
"TextSize"
"TextTransparency"
"TextWrapped"
"TextScaled"
"BackgroundColor3"
"BackgroundTransparency"
"Image"
"ImageTransparency"
"ImageColor3"
"Visible"
"Active"
"ZIndex"
```

and additional properties can be added as the serializer evolves.

---

# Script Handling

Scripts are treated differently from normal Roblox datatypes.

Currently, script instances are represented as placeholders:

```lua
{
    "SCRIPT",
    "MyScript"
}
```

When restored, the serializer creates a new script instance with the stored name.

The original source code is **not** serialized.

This is intentional and prevents the serializer from treating source code as ordinary instance data.

---

# Design Goals

WorkspaceSerializer is built around a few simple principles.

### Predictable

The serialized representation should be easy to inspect and understand.

### Extensible

Adding support for a new Roblox datatype should not require rewriting the entire serializer.

### Lightweight

The serializer should avoid unnecessary abstractions and keep the core implementation small.

### Roblox-focused

The format is designed specifically around Roblox's `Instance` and datatype system.

### Reversible

Whenever possible:

```text
Serialize → Deserialize
```

should produce an equivalent object hierarchy.

---

# Architecture

The project is centered around two primary operations:

```text
┌───────────────────────┐
│     Workspace         │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│      Serializer       │
│                       │
│  Instance → Data      │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│    Serialized Data    │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│     Deserializer      │
│                       │
│  Data → Instance      │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│   Restored Workspace  │
└───────────────────────┘
```

---

# Project Structure

A possible project layout:

```text
TNR-WorkspaceSerializer/
│
├── src/
│   ├── Serializer.lua
│   ├── Deserializer.lua
│   └── Types.lua
│
├── examples/
│   ├── SerializeModel.lua
│   └── RestoreModel.lua
│
├── docs/
│   └── format.md
│
├── README.md
├── LICENSE
└── CHANGELOG.md
```

The actual repository structure may change as the project develops.

---

# Performance

Serialization is recursive, meaning the amount of work increases with the number of instances being processed.

For example:

```text
10 Instances
    ↓
Small serialization

1,000 Instances
    ↓
Larger serialization

10,000+ Instances
    ↓
Significant amount of work
```

For large Workspace trees, it is recommended to serialize only the required container rather than the entire game hierarchy.

For example:

```lua
Serializer:Serialize(workspace.Map)
```

is generally preferable to processing unrelated services.

---

# What It Does Not Do

WorkspaceSerializer is **not** intended to be a complete replacement for Roblox place files.

It does not automatically guarantee support for:

* Every Roblox class
* Every Roblox property
* External assets
* Original script source
* Runtime-only state
* Services that cannot be recreated normally

The serializer focuses on a practical subset of the Roblox data model and can be extended over time.

---

# Roadmap

Possible future improvements:

```text
[ ] More Roblox datatypes
[ ] More Instance classes
[ ] Attribute serialization
[ ] Tag serialization
[ ] Improved CFrame handling
[ ] Better script handling
[ ] Binary serialization format
[ ] Compression
[ ] Versioned save format
[ ] Incremental serialization
[ ] Change detection
[ ] Studio plugin interface
[ ] Import / Export utilities
```

---

# TNR

## Tooling & Node Runtime

**TNR** is the tooling layer behind WorkspaceSerializer.

The name reflects the project's focus on working with Roblox's hierarchical instance tree:

```text
TNR
│
└── WorkspaceSerializer
    │
    ├── Serialization
    ├── Deserialization
    ├── Datatype conversion
    └── Instance reconstruction
```

The goal is to eventually provide a small collection of reusable utilities for Roblox development rather than a single standalone serializer.

---

# Example Data

A simplified serialized object might look like this:

```lua
{
    ClassName = "Part",

    Name = "ExamplePart",

    Properties = {
        CFrame = {
            "CF",
            0, 5, 0,
            0, 0, -1,
            0, 1, 0
        },

        Size = {
            "V3",
            4, 1, 4
        },

        Color = {
            "C3",
            1, 0, 0
        },

        Material = {
            "EN",
            "Material",
            "Neon"
        },

        Anchored = true
    },

    Children = {}
}
```

This representation contains everything required to recreate the basic object without storing the Roblox object itself.

---

# Before / After

### Original

```text
Workspace
└── Build
    ├── Floor
    ├── Wall
    ├── Wall
    └── Roof
```

### Serialized

```text
Workspace
      │
      ▼
 ┌────────────┐
 │ Serialize  │
 └─────┬──────┘
       ▼
  Structured Data
       │
       ▼
 ┌────────────┐
 │ Deserialize│
 └─────┬──────┘
       ▼
Workspace
└── Build
    ├── Floor
    ├── Wall
    ├── Wall
    └── Roof
```

The hierarchy survives the round trip.

---

# Contributing

Contributions are welcome.

When adding support for a new datatype, keep the format consistent with the existing tagged-value system.

For example:

```lua
if vType == "NewType" then
    return {"NT", ...}
end
```

and implement the corresponding deserialization logic:

```lua
if tag == "NT" then
    return ...
end
```

Keep changes focused and avoid introducing unnecessary dependencies.

---

# License

Distributed under the license included in this repository.

See [`LICENSE`](LICENSE) for more information.

---

<p align="center">
  <sub>TNR — Tooling & Node Runtime</sub>
  <br>
  <sub>WorkspaceSerializer • Roblox Studio</sub>
</p>

For the GitHub README, I'd use the **Roblox Studio Explorer screenshot** near the “Roblox Studio” section because it visually explains *what the serializer is actually working with*: the Instance hierarchy. Roblox's own documentation describes Explorer as the hierarchical view of the objects/services in a place, with `Workspace` representing the 3D world. ([d2gbj0c64xar4a.cloudfront.net][1])

[1]: https://d2gbj0c64xar4a.cloudfront.net/docs/studio/ui-overview?utm_source=chatgpt.com "Studio interface | Documentation - Roblox Creator Hub"

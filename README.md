# MARS Creator

**MARS Creator** is an iOS application for scanning, reconstructing, and organizing indoor 3D environments. It leverages Apple's **RoomPlan API**, **ARKit**, **SceneKit**, and **Metal** on LiDAR-equipped devices to produce AR-ready maps of buildings, floors, and rooms.

It is the setup and calibration tool for the companion library **MARS** (*Multiple Augmented Reality Sessions*), which localizes and navigates users through indoor spaces using augmented reality.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Requirements](#requirements)
- [Architecture](#architecture)
- [Data Model](#data-model)
- [Project Structure](#project-structure)
- [Core Modules](#core-modules)
- [Outputs](#outputs)
- [Dependencies](#dependencies)
- [Configuration](#configuration)
- [Getting Started](#getting-started)

---

## Overview

MARS Creator allows users to build a hierarchical map of an indoor environment structured as:

```
Building → Floor → Room
```

For each room, users can:
- Perform a LiDAR scan using the RoomPlan API
- Capture an ARWorldMap for device localization
- Place reference markers (image-based AR anchors) for calibration
- Define transition zones (stairs, escalators, elevators) and floor connections
- Position rooms relative to each other (automatically or manually) to assemble a full floor plan

The resulting data is consumed by the **MARS** library to localize and guide users in the real world through AR.

---

## Key Features

### Building & Space Management
- Create and manage multiple **buildings**, each with multiple **floors** and **rooms**
- Hierarchical navigation: Building → Floor → Room
- Rename, reorder, and delete entities at every level
- Persist all data locally in the device's Documents directory

### LiDAR Room Scanning
- Integrated with Apple's **RoomPlan API** for real-time LiDAR scanning
- Scan individual rooms or entire floors
- Export scans as `.usdz` 3D models
- Track scan progress (distance covered, feature points)

### ARWorldMap Capture
- Capture **ARWorldMap** per room for precise device localization
- Managed via a shared `ARSessionManager` singleton
- Used by the MARS library for real-time indoor positioning

### Room Positioning
- **Automatic positioning**: Aligns rooms on a floor plan using architectural features detected by RoomPlan (doors, windows, openings). An algorithm clusters features, finds compatible pairs between adjacent rooms, and computes the optimal 4×4 transformation matrix.
- **Manual positioning**: Interactive drag/rotate controls for fine-tuning room placement on the floor map.
- Positions stored as `RoomPositionMatrix` (translation + Y-axis rotation) in JSON.

### Reference Markers
- Attach image-based AR reference markers to each room
- Store marker coordinates (`simd_float3`) and physical width
- Used by the MARS library for precise AR anchor placement and localization

### Transition Zones & Floor Connections
- Define **transition zones** (stairs, escalators, elevators) within rooms
- Link transition zones across floors via `AdjacentFloorsConnection` or `ElevatorConnection`
- Store altitude values for multi-floor navigation

### 3D Visualization
- View room and floor scans in an interactive SceneKit 3D viewer
- Color-coded rooms for easy identification
- Camera controls for pan, zoom, and orbit

### Metal-Accelerated AR Rendering
- Custom Metal shaders for ARKit camera feed rendering
- Supports up to 64 simultaneous AR anchor instances
- YCbCr texture pipeline for efficient video frame processing

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| iOS | 17.0 |
| Xcode | 15.0 |
| Swift | 5.0 |
| Device | LiDAR-equipped iPhone or iPad |

**Supported LiDAR devices:** iPad Pro (2020+), iPhone 12 Pro / 13 Pro / 14 Pro / 15 Pro and later.

> The app does **not** support the iOS Simulator for scanning or AR features — a physical LiDAR device is required.

---

## Architecture

MARS Creator follows a **MVC + MVVM hybrid** pattern.

### Model
- `BuildingModel` — singleton data store; owns and publishes the full `Building → Floor → Room` hierarchy using Combine (`@Published`)
- Domain objects (`Building`, `Floor`, `Room`, `ReferenceMarker`, etc.) conform to `ObservableObject`, `Codable`, and `Identifiable`

### View
- All UI is built with **SwiftUI**, using `NavigationStack` for hierarchical navigation
- ARKit, SceneKit, and RoomPlan views are bridged via `UIViewRepresentable`

### Communication
- `ARSessionManager.shared` — shared AR session across views
- `NotificationCenter` for decoupled cross-component events (world map updates, tracking state changes)
- Combine `@Published` / `ObservedObject` for reactive UI binding

### Persistence
- File-based, under `Documents/ARLCreator/`
- JSON for metadata and position matrices; `.usdz` for 3D scans; images for reference markers

---

## Data Model

```
Building
  name: String
  floors: [Floor]

Floor
  name: String
  altitude: Double
  rooms: [Room]
  roomPositionMatrix: [String: RoomPositionMatrix]   // room name → transform
  planimetry: SCNScene?                               // assembled floor .usdz

Room
  name: String
  color: String
  referenceMarkers: [ReferenceMarker]
  transitionZones: [TransitionZone]
  connections: [Connection]
  scene: SCNScene?                                    // room .usdz

ReferenceMarker
  imageName: String
  physicalWidth: Float
  coordinates: simd_float3

TransitionZone
  name: String
  connections: [Connection]

Connection (AdjacentFloorsConnection | ElevatorConnection)
  targetFloor: String
  targetRoom: String
  altitude: Double
```

### File System Layout

```
Documents/ARLCreator/
└── [BuildingName]/
    └── [FloorName]/
        ├── [FloorName].json          ← room position matrices
        └── [RoomName]/
            ├── MapUsdz/
            │   └── [RoomName].usdz  ← RoomPlan scan
            ├── JsonMaps/
            ├── JsonParametric/
            ├── PlistMetadata/
            ├── ReferenceMarker/
            │   ├── [marker.jpg]
            │   └── Marker Data.json
            ├── TransitionZone/
            └── Connection.json
```

---

## Project Structure

```
MARS Creator/
├── AppDelegate.swift
├── ContentView.swift
├── ViewController.swift
├── LocationList.swift
├── Renderer.swift                    ← Metal AR rendering engine
├── Shaders.metal                     ← GPU shaders
├── ShaderTypes.h                     ← CPU/GPU shared uniform types
├── ScanBuild-Bridging-Header.h
│
├── Data/
│   ├── BuildingModel.swift           ← Singleton data store
│   ├── Beans/
│   │   ├── Building.swift
│   │   ├── Floor.swift
│   │   ├── Room.swift
│   │   ├── ReferenceMarker.swift
│   │   ├── TransitionZone.swift
│   │   ├── RoomPositionMatrix.swift
│   │   ├── Coordinates.swift
│   │   ├── Rectangle.swift
│   │   ├── NodeCluster.swift
│   │   ├── NamedURL.swift
│   │   └── Connection/
│   │       ├── Connection.swift
│   │       ├── AdjacentFloorsConnection.swift
│   │       └── ElevatorConnection.swift
│   └── Utils/
│       ├── AutoPositionUtility.swift ← Automatic room alignment algorithm
│       ├── ServerManager.swift       ← Backend API communication
│       ├── ServerCreateMatrix.swift
│       ├── SaveFile.swift
│       ├── MoveObject.swift
│       ├── MoveDimensionObject.swift
│       ├── Logger.swift
│       ├── Extension.swift           ← SwiftUI / SceneKit / SIMD extensions
│       ├── extensionNotificationName.swift
│       └── Utils.swift
│
└── View/
    ├── BuildingsView.swift           ← Root navigation
    ├── BuildingView.swift
    ├── FloorView.swift
    ├── RoomView.swift
    ├── Color.swift
    ├── FilePickerView.swift
    ├── DirPickerView.swift
    ├── AddBuildingView.swift
    ├── AddFloorView.swift
    ├── AddRoomView.swift
    ├── AddTransitionZoneView.swift
    ├── FloorAltitudeTabView.swift
    ├── AR/
    │   ├── ARSessionManager.swift
    │   ├── RoomCaptureViewContainer.swift
    │   ├── FloorCaptureViewContainer.swift
    │   ├── ExportRoomViewContainer.swift
    │   ├── VisualizeRoomViewContainer.swift
    │   ├── ARSCNViewContainer.swift
    │   └── SCNViewTransitionZone.swift
    ├── ScanningViews/
    │   ├── FloorScanningView.swift
    │   ├── RoomScanningView.swift
    │   └── RoomScanProgressView.swift
    ├── SCNView/
    │   ├── SCNViewContainer.swift
    │   ├── SCNViewMapContainer.swift
    │   ├── SCNViewUpdatePositionRoomContainer.swift
    │   └── ManageSceneView.swift
    ├── RoomTabViews/
    │   ├── RoomTabsView.swift
    │   ├── RoomPlanimetryTabView.swift
    │   ├── RoomPositionTabView.swift
    │   ├── RoomMarkerTabView.swift
    │   ├── RoomConnectionsTabView.swift
    │   └── RoomCameraRMView.swift
    ├── FloorTabViews/
    │   ├── FloorPlanimetryTabView.swift
    │   └── FloorRoomsListTabView.swift
    ├── RoomPositionViews/
    │   ├── AutomaticRoomPositionView.swift
    │   └── ManualRoomPositionView.swift
    ├── ConnectionViews/
    │   └── AddStairsConnectionView.swift
    └── Beans/
        ├── DefaultCardView.swift
        ├── ScanningCardView.swift
        ├── MatrixCardView.swift
        ├── MarkerCardView.swift
        ├── RoomCardView.swift
        ├── TransitionZoneCardView.swift
        ├── ConnectionCardView.swift
        ├── ListConnectionCardView.swift
        ├── ConnectedDotsView.swift
        └── MapControllerView.swift
```

---

## Core Modules

### `BuildingModel`
Central singleton (`BuildingModel.getInstance()`) that manages the full data hierarchy. Publishes `buildings: [Building]` via Combine. Handles file system operations for creating, renaming, and deleting buildings, floors, and rooms.

### `AutoPositionUtility`
Automatic room alignment algorithm:
1. Extracts architectural feature nodes (doors, windows, openings) from RoomPlan scans
2. Groups them into `NodeCluster` sets for source and target rooms
3. Iterates candidate rotation angles (Y-axis) and translations
4. Selects the transform that minimizes compatibility error and spatial distance
5. Returns a `RoomPositionMatrix` (4×4 translation + Y rotation)

### `ARSessionManager`
Shared singleton managing the `ARSession` lifecycle. Coordinates world map capture, tracking state notifications, and session reuse across scanning views.

### `Renderer`
Metal-based rendering engine for the AR camera feed:
- Manages `MTLCommandQueue` and render pipelines
- Handles YCbCr → RGB conversion for live camera textures
- Renders AR anchors (up to 64 instances) with transformation uniforms

### `ServerManager`
Handles communication with an optional backend server. Reads `SERVER_URL` and `SERVER_PASSWORD` from environment variables. Used for uploading and syncing scan data.

---

## Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| ARWorldMap | Binary (`.worldmap`) | Device localization in the MARS library |
| Room scan | `.usdz` | 3D model of individual room |
| Floor planimetry | `.usdz` (assembled) | Multi-room floor plan |
| Room position | JSON (`RoomPositionMatrix`) | Spatial alignment of rooms on a floor |
| Reference markers | JSON + image | AR anchor calibration data |
| Floor connections | JSON (`Connection`) | Multi-floor navigation graph |

---

## Dependencies

### Swift Package Manager

| Package | Source | Purpose |
|---------|--------|---------|
| [swift-numerics](https://github.com/apple/swift-numerics) | Apple | Advanced math for spatial data (`ComplexModule`, `Numerics`, `RealModule`) |
| [AlertToast](https://github.com/elai950/AlertToast) | elai950 | Toast-style notifications in SwiftUI |

### Apple Frameworks

| Framework | Usage |
|-----------|-------|
| ARKit | AR session, ARWorldMap, device tracking |
| RoomPlan | LiDAR-based room scanning and reconstruction |
| SceneKit | 3D scene graph, visualization, node transforms |
| RealityKit | Advanced AR rendering |
| Metal / MetalKit | GPU-accelerated shader rendering |
| CoreMotion | Gyroscope and accelerometer data |
| SwiftUI | Declarative UI framework |
| UIKit | Base iOS UI, `UIViewRepresentable` bridges |
| Combine | Reactive state management (`@Published`, `ObservableObject`) |
| Foundation | File management, JSON encoding/decoding, URLs |

---

## Configuration

- `SERVER_URL` and `SERVER_PASSWORD` — environment variables for optional backend sync (not committed to source)
- `ScanBuild-Bridging-Header.h` — Objective-C bridging header for interoperability
- Metal fast math is enabled in Release builds
- Whole-module optimization enabled in Release builds

---

## Getting Started

1. Clone the repository
2. Open `MARS Creator.xcodeproj` in Xcode 15 or later
3. Select a LiDAR-equipped physical device as the build target
4. Build and run (`Cmd+R`)
5. Create a **Building**, add a **Floor**, then add and scan **Rooms**
6. Use **Room Positioning** (automatic or manual) to assemble the floor plan
7. Add **Reference Markers** to each room for AR calibration
8. The generated ARWorldMap and SCNScene are consumed by the MARS library for indoor localization

> Note: Scanning and AR features require a physical LiDAR device. The iOS Simulator is not supported for these features.

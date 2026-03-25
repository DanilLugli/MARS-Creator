# MARS Creator — Project Context

## Overview

**MARS Creator** is an iOS app for creating AR-ready indoor maps using Apple's RoomPlan API and ARKit. It is a setup/calibration tool for the **MARS (Multiple Augmented Reality Sessions)** library, enabling users to scan indoor spaces and produce two key outputs:
- **ARWorldMap** — a tracking map for device localization
- **SCNScene** — a 2D/3D representation of scanned environments for AR apps

**Requirements:**
- iOS 17.0+ (Debug target: 17.5, Release: 17.0)
- iPhone or iPad with LiDAR (iPad Pro, iPhone 12/13/14/15 Pro)
- Xcode 15+, Swift 5.0

---

## Architecture

**MVC + MVVM hybrid:**
- **Model**: `BuildingModel` singleton (`Data/Beans/`) owns all app state
- **View**: SwiftUI views in `View/` (navigation via `NavigationStack`)
- **Bridge**: `UIViewRepresentable` wrappers for ARKit/SceneKit/RoomPlan in `View/AR/` and `View/SCNView/`

**State management:**
- `BuildingModel.getInstance()` — central data store, `@Published var buildings: [Building]`
- `ARSessionManager.shared` — shared AR session singleton
- Combine `@Published` / `ObservableObject` throughout
- `NotificationCenter` for cross-component events (see `Data/Utils/extensionNotificationName.swift`)

---

## Data Model Hierarchy

```
Building
 └── Floor (altitude, room position matrices, planimetry .usdz)
      └── Room (color, referenceMarkers, transitionZones, connections)
           ├── ReferenceMarker (image + simd_float3 coordinates)
           ├── TransitionZone (stairs/escalators/elevators)
           └── Connection → AdjacentFloorsConnection | ElevatorConnection
```

**Persistence:** File system under `Documents/ARLCreator/`. Each entity has its own directory; metadata is stored as JSON; 3D models as `.usdz`.

Room directory layout:
```
Room/
├── MapUsdz/[RoomName].usdz
├── JsonMaps/, JsonParametric/, PlistMetadata/
├── ReferenceMarker/
│   ├── [image.jpg|png]
│   └── Marker Data.json
├── TransitionZone/
└── Connection.json
```

Floor-level room positions are stored in `[FloorName].json` as `RoomPositionMatrix` (4×4 translation + rotation).

---

## Key Files

| File | Role |
|------|------|
| `Data/BuildingModel.swift` | Singleton data store, manages Building/Floor/Room lifecycle |
| `Data/Beans/Floor.swift` | Floor model; saves/loads room position matrices |
| `Data/Beans/Room.swift` | Room model; manages markers, transition zones, connections |
| `Data/Utils/AutoPositionUtility.swift` | Automatic room alignment algorithm |
| `Data/Utils/ServerManager.swift` | Backend API communication (SERVER_URL, SERVER_PASSWORD env vars) |
| `Data/Utils/SaveFile.swift` | File I/O helpers |
| `View/BuildingsView.swift` | Root navigation view |
| `View/AR/RoomCaptureViewContainer.swift` | RoomPlan scanning integration |
| `View/AR/FloorCaptureViewContainer.swift` | Floor-level RoomPlan scanning |
| `View/SCNView/SCNViewContainer.swift` | SceneKit 3D visualization |
| `View/RoomPositionViews/AutomaticRoomPositionView.swift` | UI for automatic positioning |
| `View/RoomPositionViews/ManualRoomPositionView.swift` | UI for manual positioning |
| `View/RoomTabViews/RoomTabsView.swift` | Tab interface for room details |
| `Renderer.swift` | Metal rendering engine for AR |
| `Shaders.metal` / `ShaderTypes.h` | GPU shaders for AR visualization |

---

## External Dependencies (SPM)

- **apple/swift-numerics** (`ComplexModule`, `Numerics`, `RealModule`) — spatial math
- **AlertToast** (`elai950/AlertToast`) — toast notifications

---

## Apple Frameworks Used

ARKit, RoomPlan, SceneKit, RealityKit, Metal, MetalKit, CoreMotion, UIKit, SwiftUI, Combine, Foundation

---

## Key Algorithms

### Automatic Room Positioning (`AutoPositionUtility`)
Aligns rooms using architectural features (doors, windows, openings from RoomPlan scan):
1. Clusters SCNNodes by feature type from source and target rooms
2. Finds compatible cluster pairs
3. Computes optimal rotation angle (Y-axis) and translation vector
4. Minimizes total compatibility + transformation error
5. Returns `RoomPositionMatrix` (translation + r_Y rotation)

### 3D Scene Rendering
- Loads USDZ files produced by RoomPlan API
- Filters helper nodes (`"Room"`, `"Geom"`, `"_grp"`)
- Applies room position matrices for multi-room floor assembly
- Uses Metal shaders for ARKit camera feed rendering

---

## Navigation Structure

```
ContentView
 └── BuildingsView
      └── BuildingView
           ├── FloorView
           │    ├── RoomView → RoomTabsView
           │    │              ├── RoomPlanimetryTabView
           │    │              ├── RoomMarkerTabView
           │    │              ├── RoomPositionTabView
           │    │              ├── RoomConnectionsTabView
           │    │              └── RoomCameraRMView
           │    └── FloorTabViews (FloorPlanimetryTabView, FloorRoomsListTabView)
           ├── RoomScanningView / FloorScanningView (RoomPlan)
           └── VisualizeRoomViewContainer (SceneKit)
```

---

## Git Branches

- **`testFloorScanView`** — main branch for PRs
- **`automatic_room_position_test`** — active development branch (automatic room alignment feature)

---

## Notes

- The app requires a physical LiDAR device; Simulator is not supported for AR/scanning features.
- `BuildingModel` is a singleton — pass it via `@EnvironmentObject` or access via `BuildingModel.getInstance()`.
- Room colors are stored as `String` (hex or named) in the Room model.
- `ServerManager` uses environment variables `SERVER_URL` and `SERVER_PASSWORD` — not committed to source.
- Metal bridging header: `ScanBuild-Bridging-Header.h`.

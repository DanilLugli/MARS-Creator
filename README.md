# ARL Creator

**ARL Creator** is an iOS application designed to provide an advanced 3D environment scanning experience using Apple’s **RoomPlan API**, **SceneKit**, and **RealityKit** on LiDAR-equipped devices. This app enables users to capture and reconstruct a detailed 3D model of an indoor space, which can be further analyzed and customized for various augmented reality (AR) applications.

**ARL Creator** serves as the setup tool for the companion libray **MARS**, where users are localized and navigated through indoor spaces using AR technologies. 

## Key Features

ARL Creator generates two primary outputs:

- **ARWorldMap**: A comprehensive tracking map of the environment, used to localize the device within the scanned space.
- **SCNScene**: A 2D representation of the scanned environment, created using Apple's **RoomPlan API**, which visually represents the layout of the space for further use in AR applications.

## Dependencies

ARL Creator relies on the following dependency:

- [swift-numerics](https://github.com/apple/swift-numerics): Provides advanced mathematical functionalities for the processing and handling of spatial data.

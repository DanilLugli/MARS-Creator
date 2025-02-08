//
//  RoomCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 19/08/24.
//

import SwiftUI

struct RoomCardView: View {
    @ObservedObject var room: Room
    
    var rowSize: Int
    var isSelected: Bool

    enum ActiveAlert {
        case none, position, planimetry
    }
    
    @State private var activeAlert: ActiveAlert = .none

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                
                HStack {
                    
                    VStack(alignment: .leading) {
                        Text(room.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.customBackground)

                        Text("Last modified \(dateFormatter.string(from: room.lastUpdate))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()

                HStack {
                    Spacer()
                    
                    if !room.hasPosition{
                        
                        ZStack {
                            Color.clear.frame(width: 10, height: 100)
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.red)
                                //.background(Color.yellow)
                                .font(.system(size: 35)).padding()
                        }
                        .onTapGesture {
                            print("Tapped on exclamation mark")
                            activeAlert = .position
                        }
                        
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color(room.color))
                            .font(.system(size: 30))
                            .frame(width: 70, height: 70)
                            //.padding(.trailing)
                    }
                    
                    if !room.hasValidScene() {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.system(size: 35))
                            .frame(width: 70, height: 70)
                            .contentShape(SwiftUI.Rectangle())
                            .onTapGesture {
                                activeAlert = .planimetry
                            }
                    }
                    
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { activeAlert != .none },
                set: { if !$0 { activeAlert = .none } }
            )) {
                switch activeAlert {
                case .position:
                    return Alert(
                        title: Text("ATTENTION"),
                        message: Text("\(room.name) has no position in its Floor.\nYou have to calculate it in Room Position page."),
                        dismissButton: .default(Text("OK"))
                    )
                case .planimetry:
                    return Alert(
                        title: Text("ATTENTION"),
                        message: Text("\(room.name) has no planimetry.\nYou need to create it in the Room Planimetry page."),
                        dismissButton: .default(Text("OK"))
                    )
                case .none:
                    return Alert(title: Text(""))
                }
            }
            .frame(width: geometry.size.width / CGFloat(rowSize), height: 80)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)

        }
    }
}


struct RoomCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRoom = Room(
            _name: "Room",
            _lastUpdate: Date(),
            _planimetry: SCNViewContainer(),
            _referenceMarkers: [],
            _transitionZones: [],
            _scene: nil,
            _sceneObjects: [],
            _roomURL: URL(fileURLWithPath: ""),
            parentFloor: nil
        )
        
        return RoomCardView(room: sampleRoom, rowSize: 1, isSelected: false)
    }
}

// 📆 Formattatore per le date
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

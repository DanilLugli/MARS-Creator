import SwiftUI

struct MapControllerView: View {

    @State private var scaleWidth: Double = 0
    @State private var timer: Timer? = nil // Timer per la pressione continua
    @State private var isPressed = false  // Stato per controllare il rilascio

    var moveObject: MoveObject
    
    var body: some View {
        HStack {
            
            VStack {
                Text("Rotate Anticlockwise:").foregroundColor(Color.customBackground)
                pressableButton(
                    action: { continuous in moveObject.rotateCounterClockwise() },
                    imageName: "arrow.counterclockwise"
                )
                
                Text("Rotate Clockwise:").foregroundColor(Color.customBackground)
                pressableButton(
                    action: { continuous in moveObject.rotateClockwise() },
                    imageName: "arrow.clockwise"
                )
            }
            
            if moveObject is MoveDimensionObject {
                VStack {
                    Slider(value: $scaleWidth, in: 0...1, step: 0.01) {
                        Text("Width")
                    }
                    .onChange(of: scaleWidth) { _, _ in
                        if let moveDimensionObject = moveObject as? MoveDimensionObject {
                            moveDimensionObject.incrementWidht(by: Int(scaleWidth * 100))
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
            }
            
            // Movimenti
            VStack {
                Text("Move along 4 axes: ").foregroundColor(Color.customBackground)
                
                // Bottone per muovere in alto (up)
                pressableButton(
                    action: { continuous in moveObject.moveUp(continuous: continuous) },
                    imageName: "arrow.up"
                )
                
                HStack(spacing: 20) {
                    // Bottone per muovere a sinistra
                    pressableButton(
                        action: { continuous in moveObject.moveLeft(continuous: continuous) },
                        imageName: "arrow.left"
                    )
                    
                    // Bottone per muovere a destra
                    pressableButton(
                        action: { continuous in moveObject.moveRight(continuous: continuous) },
                        imageName: "arrow.right"
                    )
                }
                
                // Bottone per muovere in basso (down)
                pressableButton(
                    action: { continuous in moveObject.moveDown(continuous: continuous) },
                    imageName: "arrow.down"
                )
            }
            .padding()
        }
    }

    // MARK: - Pressable Button Component
    private func pressableButton(action: @escaping (_ continuous: Bool) -> Void, imageName: String) -> some View {
        Button(action: {
            // Azione eseguita al tap singolo
            action(false)
        }) {
            Image(systemName: imageName)
                .bold()
                .foregroundColor(.white)
        }
        .buttonStyle(.bordered)
        .background(Color.blue.opacity(0.4))
        .cornerRadius(8)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded { _ in
                    startTimer(action: action)
                }
        )
        .onChange(of: isPressed) { newValue in
            if !newValue {
                stopTimer()
            }
        }
        .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
            isPressed = isPressing
        }, perform: {})
    }

    // Timer: ogni intervallo (0.1 secondi) chiama l'azione in modalità continua
    private func startTimer(action: @escaping (_ continuous: Bool) -> Void) {
        stopTimer() // Ferma eventuali timer esistenti
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            action(true)
        }
        timer?.fire()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct MapControllerView_Previews: PreviewProvider {
    static var previews: some View {
        MapControllerView(moveObject: MockMoveObject())
    }
}

// Mock implementation for preview
class MockMoveObject: MoveObject {
    func rotateClockwise() {
        print("Mock: rotateClockwise")
    }

    func rotateCounterClockwise() {
        print("Mock: rotateCounterClockwise")
    }

    func moveUp(continuous: Bool) {
        print("Mock: moveUp, continuous: \(continuous)")
    }

    func moveDown(continuous: Bool) {
        print("Mock: moveDown, continuous: \(continuous)")
    }

    func moveLeft(continuous: Bool) {
        print("Mock: moveLeft, continuous: \(continuous)")
    }

    func moveRight(continuous: Bool) {
        print("Mock: moveRight, continuous: \(continuous)")
    }
}

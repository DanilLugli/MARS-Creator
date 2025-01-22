import SwiftUI

struct MapControllerView: View {

    @State private var scaleWidth: Double = 0
    @State private var timer: Timer? = nil // Timer per la pressione continua
    @State private var isPressed = false  // Stato per controllare il rilascio

    var moveObject: MoveObject
    
    var body: some View {
        HStack {
            // Rotazione
            VStack {
                // Ruota in senso antiorario
                pressableButton(
                    action: { moveObject.rotateCounterClockwise() },
                    imageName: "arrow.counterclockwise"
                )
                
                // Ruota in senso orario
                pressableButton(
                    action: { moveObject.rotateClockwise() },
                    imageName: "arrow.clockwise"
                )
            }
            
            // Slider per modifica dimensione
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
                // Muovi in alto
                pressableButton(
                    action: { moveObject.moveUp() },
                    imageName: "arrow.up"
                )
                
                HStack(spacing: 20) {
                    // Muovi a sinistra
                    pressableButton(
                        action: { moveObject.moveLeft() },
                        imageName: "arrow.left"
                    )
                    
                    // Muovi a destra
                    pressableButton(
                        action: { moveObject.moveRight() },
                        imageName: "arrow.right"
                    )
                }
                
                // Muovi in basso
                pressableButton(
                    action: { moveObject.moveDown() },
                    imageName: "arrow.down"
                )
            }
        }
    }

    // MARK: - Pressable Button Component
    private func pressableButton(action: @escaping () -> Void, imageName: String) -> some View {
        Button(action: {
            action() // Esegui una sola volta al click singolo
        }) {
            Image(systemName: imageName)
                .bold()
                .foregroundColor(.white)
        }
        .buttonStyle(.bordered)
        .background(Color.blue.opacity(0.4))
        .cornerRadius(8)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2) // Pressione prolungata
                .onEnded { _ in
                    startTimer(action: action) // Avvia il timer dopo 0.2 secondi
                }
        )
        .onChange(of: isPressed) { newValue in
            if !newValue {
                stopTimer()
            }
        }
        .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
            isPressed = isPressing // Aggiorna lo stato del pulsante
        }, perform: {})
    }

    // MARK: - Timer Management
    private func startTimer(action: @escaping () -> Void) {
        stopTimer() // Ferma eventuali timer esistenti
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            action()
        }
        timer?.fire() 
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

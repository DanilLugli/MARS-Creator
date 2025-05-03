import SwiftUI

struct MapControllerView: View {

    @State private var scaleWidth: Double = 0
    @State private var timer: Timer? = nil // Timer per la pressione continua
    @State private var isPressed = false  // Stato per controllare il rilascio
    @State private var showAlert = false // Stato per mostrate un alert nel caso il posizionamento automatico fallisca

    var moveObject: MoveObject
    var needsAutoPositioning = false
    
    @Binding var isAutoPositioning: Bool  // Stato condiviso con la view padre per il posizionamento automatico
    
    var body: some View {
        HStack {
            VStack {
                Text("Rotate Left")
                    .multilineTextAlignment(TextAlignment.center)
                    .foregroundColor(Color.customBackground)
                pressableButton(
                    action: { continuous in moveObject.rotateCounterClockwise() },
                    imageName: "arrow.counterclockwise"
                )
                
                Spacer().frame(height: 20)
                
                Text("Rotate Right")
                    .multilineTextAlignment(TextAlignment.center)
                    .foregroundColor(Color.customBackground)
                pressableButton(
                    action: { continuous in moveObject.rotateClockwise() },
                    imageName: "arrow.clockwise"
                )
            }
            .frame(maxWidth: .infinity)
            
//            if moveObject is MoveDimensionObject {
//                VStack {
//                    Slider(value: $scaleWidth, in: 0...1, step: 0.01) {
//                        Text("Width")
//                    }
//                    .onChange(of: scaleWidth) { _, _ in
//                        if let moveDimensionObject = moveObject as? MoveDimensionObject {
//                            moveDimensionObject.incrementWidht(by: Int(scaleWidth * 100))
//                        }
//                    }
//                    .padding()
//                }
//            } else {
//                Spacer()
//            }
            
            // Movimenti
            VStack {
                Text("Move along 4 axes")
                    .multilineTextAlignment(TextAlignment.center)
                    .foregroundColor(Color.customBackground)
                
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
            .frame(maxWidth: .infinity)
            
            // Posizionamento automatico
            VStack {
                Text("Auto Align")
                    .multilineTextAlignment(TextAlignment.center)
                    .foregroundColor(Color.customBackground)
                pressableButton(
                    action: { _ in applyAutoPositioning() },
                    imageName: "scope"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(isAutoPositioning ? 0 : 1)
        .overlay {
            if isAutoPositioning {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.customBackground))
                        .scaleEffect(1.5)
                    
                    Text("Auto-positioning in progress...")
                        .foregroundColor(Color.customBackground)
                        .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if needsAutoPositioning {
                applyAutoPositioning()
            }
        }
        .alert("Auto-Positioning Failed", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to perform auto-positioning, manual positioning will be required to proceed.")
        }
    }

    // Applica il posizionamento automatico della stanza nel piano e mostra un alert in caso di fallimento.
    private func applyAutoPositioning() {
        Task {
            self.isAutoPositioning = true
            if !(await moveObject.applyAutoPositioning()) {
                self.showAlert = true
            }
            self.isAutoPositioning = false
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

import SwiftUI

struct MapControllerView: View {

    @State private var scaleWidth: Double = 0
    
    var moveObject: MoveObject
    
    var body: some View {
        HStack {
            VStack {
                Button(action: {
                    moveObject.rotateCounterClockwise()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .bold()
                        .foregroundColor(.white)
                }.buttonStyle(.bordered)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(8)
                
                
                Button(action: {
                    moveObject.rotateClockwise()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .bold()
                        .foregroundColor(.white)
                }.buttonStyle(.bordered)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(8)
                
            }
            
            if moveObject is MoveDimensionObject {
                VStack{
                    
                    Slider(value: $scaleWidth, in: 0...1, step: 0.01) {
                        Text("Width")
                    }.onChange(of: scaleWidth){
                        if let moveDimensionObject = moveObject as? MoveDimensionObject {
                            moveDimensionObject.incrementWidht(by: Int(scaleWidth*100))
                        }
                    }
                    .padding()
                }

            }
            else{
                Spacer()
            }
            
            VStack {
                Button(action: {
                    moveObject.moveUp()
                }) {
                    Image(systemName: "arrow.up")
                        .bold()
                        .foregroundColor(.white)
                }.buttonStyle(.bordered)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(8)
                
                
                HStack(spacing: 20) {
                    Button(action: {
                        moveObject.moveLeft()
                    }) {
                        Image(systemName: "arrow.left")
                            .bold()
                            .foregroundColor(.white)
                    }.buttonStyle(.bordered)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(8)
                    
                    Button(action: {
                        moveObject.moveRight()
                    }) {
                        Image(systemName: "arrow.right")
                            .bold()
                            .foregroundColor(.white)
                    }.buttonStyle(.bordered)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(8)
                    
                }
                
                Button(action: {
                    moveObject.moveDown()
                }) {
                    Image(systemName: "arrow.down")
                        .bold()
                        .foregroundColor(.white)
                }.buttonStyle(.bordered)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(8)
                
            }
        }
    }
}

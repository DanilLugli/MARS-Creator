import SwiftUI

struct MarkerCardView: View {
    
    var imageName: Image
    
    init(imageName: Image) {
        self.imageName = imageName
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
            
            imageName
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    MarkerCardView(imageName: Image("your_image_name_here")) // Replace "your_image_name_here" with the name of your image
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

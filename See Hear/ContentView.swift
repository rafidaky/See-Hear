import SwiftUI

struct ContentView: View {
    @State var detectedObject: String?
    var body: some View {
        NavigationView {
            VStack {
                Text("See Hear'a Hoş Geldiniz!")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.bottom, 20)
                    .foregroundColor(Color.purple)
                Image(systemName: "globe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.purple)
                Text("Görsel ve işitsel yardım için uygulamanız.")
                    .font(.title3)
                    .fontWeight(.regular)
                    .padding(.top, 20)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Spacer()
                NavigationLink(
                    destination: CameraView(detectedObject: $detectedObject),
                    label: {
                        Text("Başla")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    })
                NavigationLink(
                    destination: SettingsView(),
                    label: {
                        Text("Ayarlar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    })
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [.white, .purple.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

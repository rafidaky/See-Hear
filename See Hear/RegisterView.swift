import SwiftUI

struct RegisterView: View {
    @State private var kullaniciAdi: String = ""
    @State private var sifre: String = ""
    @State private var sifreyiOnayla: String = ""
    @State private var registrationMessage: String = ""
    @State private var detectedObject: String? = nil
    @State private var navigationTag: Int? = nil
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Text("Kayıt Ol")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                    .padding(.bottom, 20)

                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.purple)
                    .padding(.bottom, 20)

                TextField("Kullanıcı Adı", text: $kullaniciAdi)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                SecureField("Şifre", text: $sifre)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                SecureField("Şifreyi Onayla", text: $sifreyiOnayla)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                Text(registrationMessage)
                    .foregroundColor(registrationMessage.contains("Başarılı") ? .green : .red)
                    .padding(.bottom, 20)

                NavigationLink(destination: CameraView(detectedObject: $detectedObject), tag: 1, selection: $navigationTag) {
                    EmptyView()
                }

                Button(action: {
                    register()
                }) {
                    Text("Kayıt Ol")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .onTapGesture {
                    // Check for successful registration and navigate to CameraView
                    if registrationMessage.contains("Başarılı") {
                        navigationTag = 1
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [.white, .purple.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all))
            .background(
                NavigationLink(destination: CameraView(detectedObject: $detectedObject), tag: 1, selection: $navigationTag) {
                    EmptyView()
                }
            )
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    // Function to perform user registration
    func register() {
        guard let url = URL(string: "http://10.0.0.191:8080/api/users/register") else {
            registrationMessage = "Geçersiz URL"
            return
        }

        let registrationData = [
            "username": kullaniciAdi,
            "password": sifre,
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: registrationData, options: .prettyPrinted)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data {
                        if let responseString = String(data: data, encoding: .utf8) {
                            registrationMessage = responseString
                            navigationTag = 1
                        } else {
                            registrationMessage = "Geçersiz server cevabı"
                        }
                    } else if let error = error {
                        registrationMessage = "API Hatası: \(error.localizedDescription)"
                    }
                }
            }.resume()
        } catch {
            registrationMessage = "JSON verisi hazırlama hatası: \(error.localizedDescription)"
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var detectedObject: String? = nil
    @State private var navigationTag: Int? = nil

    var body: some View {
        if #available(iOS 16.0, *) {
            
                VStack {
                    Text("Giriş Yap")
                        .font(.largeTitle)
                        .foregroundColor(.purple)
                        .padding(.bottom, 20)
                    
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.purple)
                        .padding(.bottom, 20)
                    
                    TextField("Kullanıcı Adı", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    
                    SecureField("Şifre", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    
                    Button(action: {
                        login()
                    }, label: {
                        Text("Giriş Yap")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    })
                    .navigationBarHidden(true)
                    
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [.white, .purple.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all))
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text(showAlert ? (alertMessage.contains("Hata") ? "Hata" : "Başarılı") : ""),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("Tamam")))
                })
                .background(
                    NavigationLink(destination: CameraView(detectedObject: $detectedObject), tag: 1, selection: $navigationTag) {
                        EmptyView()
                    }
                )
            
        } else {
            // Fallback on earlier versions
        }
    }

    private func login() {
        guard let url = URL(string: "http://10.0.0.191:8080/api/users/login") else {
            showAlert = true
            alertMessage = "Geçersiz URL"
            return
        }

        let body: [String: String] = [
            "username": username,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle the response (success or failure)
            // Update UI on the main thread if needed
            if let error = error {
                showAlert = true
                alertMessage = "Hata: \(error.localizedDescription)"
            } else if let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    // Login successful, handle the response data
                    showAlert = true
                    alertMessage = "Giriş başarılı"
                    navigationTag = 1 // Set the tag to trigger NavigationLink
                } else {
                    // Login failed, handle the response data
                    showAlert = true
                    alertMessage = "Giriş başarısız"
                }
            }
        }.resume()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isRegistering: Bool = false

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .foregroundColor(.purple)
                .padding(.bottom, 20)

            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .foregroundColor(.purple)
                .padding(.bottom, 20)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            Button(action: {
                // Perform login action here (call your API)
                // You can use the values in 'username' and 'password' for authentication
            }) {
                Text("Login")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }

            Button(action: {
                isRegistering = true
            }) {
                Text("Hesabınız yok mu? Hesap oluşturun.")
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            .sheet(isPresented: $isRegistering, content: {
                // This is where you present the RegisterView
                RegisterView()
            })

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [.white, .purple.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

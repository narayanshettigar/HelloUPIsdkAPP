import SwiftUI

struct HomeScreen: View {
    @State private var environment = "Staging"
    @State private var language = ""
    @State private var email = ""
    @State private var bic = ""
    @State private var subscriptionKey = ""
    @Binding var showBottomSheet : Bool
    @State private var isEnvironmentPickerVisible = false
    @State private var isLanguagePickerVisible = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let environments = ["Staging", "Production"]
    let languages = ["English", "Spanish", "French", "German", "Chinese"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Environment Selection").bold().foregroundColor(.black.opacity(0.8))) {
                    Picker("Environment", selection: $environment) {
                        ForEach(environments, id: \.self) {
                            Text($0)
                                .foregroundColor(.black)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorMultiply(.blue.opacity(0.5)).colorInvert()
                    .colorMultiply(.white).colorInvert()
                    .padding(-15)
                }
                
                Section(header: Text("Language Selection").bold().foregroundColor(.black.opacity(0.8))) {
                    Button(action: {
                        isLanguagePickerVisible.toggle()
                        hideKeyboard()
                    }) {
                        HStack {
                            Text(language.isEmpty ? "Select Language" : language)
                                .foregroundColor(language.isEmpty ? .gray : .black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $isLanguagePickerVisible) {
                        VStack {
                            Text("Select Language")
                                .font(.headline)
                                .padding()
                            Divider()
                            ForEach(languages, id: \.self) { lang in
                                Button(action: {
                                    language = lang
                                    isLanguagePickerVisible.toggle()
                                }) {
                                    Text(lang)
                                        .foregroundColor(.blue)
                                        .padding()
                                }
                            }
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("BIC").bold().foregroundColor(.black.opacity(0.8))) {
                    TextField("Enter your BIC", text: $bic)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Subscription Key").bold().foregroundColor(.black.opacity(0.8))) {
                    TextField("Enter your Subscription Key", text: $subscriptionKey)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Email Address").bold().foregroundColor(.black.opacity(0.8))) {
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        // Validate fields before proceeding
                        if isValidForm() {
                            showBottomSheet.toggle()
                        } else {
                            showAlert = true
                        }
                    }) {
                        Text("Submit")
                            .fontWeight(.bold)
                            .frame(width: UIScreen.main.bounds.width - 100)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.5)]),
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                   // .disabled(environment.isEmpty || language.isEmpty || email.isEmpty)
                }
            }
            .navigationTitle("Hello UPI")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func isValidForm() -> Bool {
        // Validate environment
        if environment.isEmpty {
            alertMessage = "Please select an environment."
            return false
        }
        
        // Validate language
        if language.isEmpty {
            alertMessage = "Please select a language."
            return false
        }
        
        // Validate email
        if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address."
            return false
        }
        
        if email.isEmpty {
            alertMessage = "Please enter a valid email address."
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Simple email validation using regex
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview{
    HomeScreen(showBottomSheet: .constant(false))
}

struct ContentView: View {
    @StateObject private var contactsManager = ContactsManager()
    @State private var showBottomSheet = false
    @State private var dynamicContent: [String] = ["Item 1"]
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.1), Color.blue.opacity(0.6)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
            
            HomeScreen(showBottomSheet: $showBottomSheet)
            
            if showBottomSheet {
                BottomSheetView(isPresented: $showBottomSheet) {
                    VStack {
                        ContentViewContacts()
                        AudioRecorderContentView()
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .padding(.bottom, 40)
                }
                .ignoresSafeArea()
                //.transition(.move(edge: .bottom))
                .animation(.spring())
            }
        }
        .onAppear{
            self.contactsManager.requestContactsPermission { granted in
                if granted {
                    self.contactsManager.fetchContacts()
                }
            }
        }
    }
}

struct BottomSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background dimming view
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                // Bottom sheet content
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        HStack{
                            Image("img2")
                                .resizable()
                                .frame(width: 40, height: 30)
                                .onTapGesture {
                                    //                                    withAnimation {
                                    isPresented = false
                                    //                                    }
                                }
                            Image("img1")
                                .resizable()
                                .frame(width: 125, height: 40)
                            Spacer()
                            Image("img3")
                                .resizable()
                                .frame(width: 60, height: 25)
                        }
                        .padding()
                        Divider()
                        content()
                    }
                    .background(GeometryReader { geometry in
                        Color.white
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                            .shadow(radius: 10)
                            .frame(height: geometry.size.height)
                    })
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


#Preview {
    ContentView()
}

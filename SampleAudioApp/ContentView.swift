import SwiftUI
import SwiftUI
import AVFoundation
import Speech


struct HomeScreen: View {
    @State private var environment = ""
    @State private var language = ""
    @State private var email = ""
    @Binding var showBottomSheet : Bool
    @State private var isEnvironmentPickerVisible = false
    @State private var isLanguagePickerVisible = false
    
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
                
                //                Section(header: Text("Language Selection").bold().foregroundColor(.black.opacity(0.8))) {
                //                    Picker("Language", selection: $language) {
                //                        ForEach(languages, id: \.self) {
                //                            Text($0)
                //                        }
                //                    }
                //                }
                
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
                
                Section(header: Text("Email Address").bold().foregroundColor(.black.opacity(0.8))) {
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        //                withAnimation {
                        showBottomSheet.toggle()
                        //                }
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
                    .disabled(environment.isEmpty || language.isEmpty || email.isEmpty)
                }
            }
            .navigationTitle("Hello UPI Sample App")
        }
    }
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(showBottomSheet: .constant(false))
    }
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



class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var audioURL: URL?
    @Published var transcription = ""
    
    private var audioRecorder: AVAudioRecorder?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var lastSpeechTimestamp: Date?
    private let silenceTimeout: TimeInterval = 1.0
    private var silenceTimer: Timer?
    
    @Published var audioLevels: [CGFloat] = Array(repeating: 0.2, count: 30)
    private var levelUpdateTimer: Timer?
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
    }
    
    func reset() {
        stopRecording()
        
        // Cancel any ongoing tasks
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Stop and reset audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error resetting audio session: \(error)")
        }
        
        // Clear all published properties
        DispatchQueue.main.async {
            self.audioURL = nil
            self.transcription = ""
            self.isRecording = false
            self.isProcessing = false
        }
        
        // Invalidate and clear the silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Clear the last speech timestamp
        lastSpeechTimestamp = nil
        
        // Remove the audio file if it exists
        if let url = audioURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        print("AudioRecorder reset completed")
        
        // Reset audio levels
        DispatchQueue.main.async {
            self.audioLevels = Array(repeating: 0.2, count: 30)
        }
        
        print("AudioRecorder reset completed")
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    print("Speech recognition not authorized")
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    print("Microphone access not granted")
                }
            }
        }
    }
    
    func startRecording() {
        isProcessing = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            isProcessing = false
            return
        }
        
        startActualRecording()
    }
    
    private func startActualRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            isProcessing = false
            
            startSpeechRecognition()
            startAudioLevelUpdates()
            
        } catch {
            print("Failed to start recording: \(error)")
            isProcessing = false
        }
    }
    
    private func startAudioLevelUpdates() {
        levelUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevels()
        }
    }
    
    private func updateAudioLevels() {
        guard let audioRecorder = audioRecorder, audioRecorder.isRecording else { return }
        audioRecorder.updateMeters()
        let level = CGFloat(audioRecorder.averagePower(forChannel: 0))
        let normalizedLevel = min(max((level + 50) / 50, 0), 1) // Normalize the level to 0-1 range
        DispatchQueue.main.async {
            self.audioLevels.removeFirst()
            self.audioLevels.append(normalizedLevel)
        }
    }
    
    func startSpeechRecognition() {
        guard let recognitionRequest = try? SFSpeechAudioBufferRecognitionRequest() else {
            print("Unable to create recognition request")
            return
        }
        self.recognitionRequest = recognitionRequest
        
        recognitionRequest.shouldReportPartialResults = true
        
        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                
                if let result = result {
                    self?.transcription = result.bestTranscription.formattedString
                    self?.lastSpeechTimestamp = Date()
                    
                    if result.isFinal {
                        self?.stopRecording()
                    }
                }
                
                if error != nil {
                    print("error: \(String(describing: error?.localizedDescription))")
                }
            }
            
            // Start a timer to check for prolonged silence
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                
                if let lastSpeech = self.lastSpeechTimestamp,
                   Date().timeIntervalSince(lastSpeech) > self.silenceTimeout {
                    self.stopRecording()
                    timer.invalidate()
                }
            }
        } catch {
            print("Error setting up speech recognition: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        levelUpdateTimer?.invalidate()
        levelUpdateTimer = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.audioURL = self.audioRecorder?.url
            self.audioLevels = Array(repeating: 0.2, count: 30)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.recognitionTask?.cancel()
            self?.recognitionTask = nil
            self?.recognitionRequest = nil
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}


struct AudioRecorderContentView: View {
    @ObservedObject private var audioRecorder = AudioRecorder()
    @State private var isShowingTranscription = false
    
    var body: some View {
        ZStack {
            //            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
            //                           startPoint: .topLeading,
            //                           endPoint: .bottomTrailing)
            //            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 5) {
                
                
                if audioRecorder.isRecording {
                    VStack{
                        //                        Text("Listening...")
                        //                            .font(.footnote)
                        //                            .foregroundColor(.white)
                        //                            .padding(10)
                        //                            .background(Color.red.opacity(0.8))
                        //                            .clipShape(Capsule())
                        //                            .shadow(radius: 10)
                        
                        AudioWaveform(audioLevels: $audioRecorder.audioLevels)
                            .frame(width: 200, height: 20, alignment: .center)
                            .padding()
                            .shadow(radius: 5)
                    }
                } else {
                    Button(action: {
                        self.audioRecorder.startRecording()
                    }) {
                        Image(systemName: "mic")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .disabled(audioRecorder.isProcessing)
                }
                
                if let audioURL = audioRecorder.audioURL {
                    AudioPlayer(url: audioURL)
                }
                
                if !audioRecorder.transcription.isEmpty {
                    HStack{
                        Text("Transcription: ")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.green)
                            .cornerRadius(10)
                        
                        Text(audioRecorder.transcription)
                            .font(.footnote)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .transition(.scale)
                    }
                }
                
                HStack{
                    Spacer()
                    Button(action: {
                        self.audioRecorder.reset()
                    }) {
                        Text("Reset")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
                
            }
            .padding()
        }
        .onAppear {
            audioRecorder.requestPermissions()
        }
    }
}


struct AudioPlayer: View {
    let url: URL
    @State private var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession!
    
    init(url: URL) {
        self.url = url
        self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
        
        do {
            self.audioSession = AVAudioSession.sharedInstance()
            try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try self.audioSession.setActive(true)
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        Button(action: {
            if isPlaying {
                self.audioPlayer?.pause()
            } else {
                self.audioPlayer?.play()
            }
            isPlaying.toggle()
        }) {
            HStack {
                //                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                Image(systemName: "play.circle.fill")
                    .font(.footnote)
                //                Text(isPlaying ? "Pause" : "Play Recording")
                Text("Play Recording")
                    .font(.footnote)
                
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.orange)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }
}


struct AudioWaveView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                let wavelength: CGFloat = 20
                let amplitude: CGFloat = height / 4
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let angle = 2 * .pi * (x / wavelength) - phase
                    let y = midHeight + amplitude * sin(angle)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.black, lineWidth: 2)
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                withAnimation {
                    phase = 2 * .pi
                }
            }
        }
    }
}


struct AudioWaveform: View {
    @Binding var audioLevels: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<min(self.audioLevels.count, 30), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: (geometry.size.width - 120) / 30, height: self.audioLevels[index] * geometry.size.height)
                }
            }
        }
        .frame(height: 50)
    }
}

//
//  ContentView.swift
//  MacPlay
//
//  Created by Ronald on 24/7/21.
//


import SwiftUI
import AVFoundation

struct ContentView: View {
    
    private let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .front)
    
    @State private var selectedDeviceIndex: Int?
    
    @StateObject var camera = CameraModel()
    
    var body: some View {
        let devices = getDevices()
        ZStack {
            VStack {
                VStack {
                    if camera.isTaken {
                        CameraPreview(camera: camera)
                    } else {
                        Picker("Select Camera", selection: $selectedDeviceIndex){
                            ForEach(devices, id: \.self) { device in
                                Text(device.localizedName).tag(devices.firstIndex(of: device))
                            }
                        }
                        Button(action: {
                            self.camera.setUp(selectedIndex: selectedDeviceIndex!)
                            self.camera.isTaken.toggle()
                        }){
                            Text("Start Camera")
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height, alignment: .center)
        .background(Color.black)
    }
    
    func getDevices() -> [AVCaptureDevice] {
        let devices = discoverySession.devices
        
        guard !devices.isEmpty else { fatalError("Missing capture devices.")}
        
        return devices
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CameraPreview : NSViewRepresentable {
    
    @ObservedObject var camera : CameraModel
    
    func makeNSView(context: Context) -> some NSView {
        
        let view = NSView(frame: NSScreen.main!.frame)

        
        view.wantsLayer = true   // needed explicitly for NSView
        //let presOptions: NSApplication.PresentationOptions = ([.fullScreen,.autoHideMenuBar])
        //let optionsDictionary = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions: presOptions]
        //view.enterFullScreenMode(NSScreen.main!, withOptions: optionsDictionary)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer?.addSublayer(camera.preview)
        camera.preview.connection?.automaticallyAdjustsVideoMirroring = false
        camera.preview.connection?.isVideoMirrored = true
        
        camera.session.startRunning()
        
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
}


class CameraModel: ObservableObject {
    @Published var isTaken: Bool = false
    @Published var session = AVCaptureSession()
    @Published var alert : Bool = false
    
    
    //since we're going to read pic data
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    private let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .front)
    
    func setUp(selectedIndex: Int) {
        do {
            self.session.beginConfiguration()
            let devices = self.discoverySession.devices
            let device = devices[selectedIndex]
            
            let input = try AVCaptureDeviceInput(device: device)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

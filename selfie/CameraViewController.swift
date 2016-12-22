import Cocoa
import AVFoundation

protocol CameraViewDelegate {
    func showPreferenceWindow()
    func onFailedToConnectCamera()
    func onCaptureSizeDetected(size: NSSize)
    func onCaptured(image: Data, type: FileType)
}

class CameraViewController: NSViewController {
    @IBOutlet var cameraView: NSView!
    @IBOutlet var settingButton: NSButton!
    
    var session: AVCaptureSession?
    var input: AVCaptureInput?
    var output: AVCaptureStillImageOutput?
    var preference: Preference!
    
    var cameraEventDelegate: CameraViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer?.backgroundColor = CGColor.white
    }
    
    override func viewDidAppear() {
        let camera: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if let input = try? AVCaptureDeviceInput(device: camera) {
            self.session = AVCaptureSession()
            self.input = input
            self.session!.addInput(self.input!)
            
            if let dimension = self.input?.getDimension() {
                self.cameraEventDelegate?.onCaptureSizeDetected(size: NSSize(width: Int(dimension.width),
                                                                             height: Int(dimension.height)))
            }
            
            self.output = AVCaptureStillImageOutput()
            self.output!.outputSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
            self.session!.addOutput(self.output!)
            
            let videoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session!)
            videoLayer.frame = self.view.bounds
            videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            if (self.preference.flipX) {
                videoLayer.setAffineTransform(CGAffineTransform(scaleX: -1.0, y: 1.0))
            }
            self.cameraView.layer!.addSublayer(videoLayer)
            
            self.session!.startRunning()
        } else {
            self.cameraEventDelegate?.onFailedToConnectCamera()
        }
    }
    
    override func viewDidDisappear() {
        self.session?.stopRunning()
        self.session?.removeInput(self.input)
        self.session?.removeOutput(self.output)
        self.session = nil
        self.input = nil
        self.output = nil
    }
    
    func flash(completionHandler: @escaping () -> Void) {
        let first: (NSAnimationContext) -> Void = {(context) in
            context.duration = 0.2
            self.cameraView.animator().alphaValue = 0
        }
        
        let second: (NSAnimationContext) -> Void = {(context) in
            context.duration = 0.4
            self.cameraView.animator().alphaValue = 1
        }
        
        NSAnimationContext.runAnimationGroup(
            first,
            completionHandler: {() in
                NSAnimationContext.runAnimationGroup(second,
                                                     completionHandler: completionHandler)
            }
        )
    }
    
    @IBAction func settingButtonClicked(sender: NSButton) {
        self.cameraEventDelegate?.showPreferenceWindow()
    }
    
    @IBAction func captureButtonClicked(sender: NSButton) {
        // TODO Error handling & success/fail alert
        if let connection = self.output?.connection(withMediaType: AVMediaTypeVideo) {
            self.output?.captureStillImageAsynchronously(from: connection,
                                                         completionHandler: {(buffer, error) in
                                                            self.flash {
                                                                self.handleBuffer(buffer: buffer)
                                                            }})
        }
    }

    func handleBuffer(buffer: CMSampleBuffer?) {
        // convert CMSampleBuffer to CIImage
        guard let sampleBuffer: CMSampleBuffer = buffer else { return }
        guard let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)

        let imageWidth = Double(ciImage.extent.width)
        let imageHeight = Double(ciImage.extent.height)
        let targetWidth = Double(self.preference.width)
        let targetHeight = Double(self.preference.height)
        
        
        // resize image
        let scale = max(targetWidth / imageWidth, targetHeight / imageHeight)
        let flipX = self.preference.flipX ? -1.0 : 1.0
        let resizedImage: CIImage = ciImage.applying(CGAffineTransform(scaleX: CGFloat(scale * flipX),
                                                                       y: CGFloat(scale)))

        // convert CIImage to CGImage
        let context = CIContext(options: [:])
        guard let cgImage: CGImage = context.createCGImage(resizedImage,
                                                           from: resizedImage.extent) else { return }
        
        // crop image
        let cropRect = CGRect(x: Int(Double(cgImage.width) / 2 - targetWidth / 2),
                              y: Int(Double(cgImage.height) / 2 - targetHeight / 2),
                              width: Int(targetWidth),
                              height: Int(targetHeight))
        guard let croppedImage: CGImage = cgImage.cropping(to: cropRect) else { return }

        // convert CGImage to Data
        let type = self.preference.fileType
        let imageRep = NSBitmapImageRep(cgImage: croppedImage)
        if let image = imageRep.representation(using: type.representation,
                                               properties: [:]){
            self.cameraEventDelegate?.onCaptured(image: image, type: type)
        }
    }
}

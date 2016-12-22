import Cocoa
import AVFoundation

extension AVCaptureInput {
    func getDimension() -> CMVideoDimensions? {
        if let port = self.ports[0] as? AVCaptureInputPort {
            return Optional.some(CMVideoFormatDescriptionGetDimensions(port.formatDescription))
        } else {
            return Optional.none
        }
    }
}

import Foundation
import AVFoundation
import Photos
import UniformTypeIdentifiers

@MainActor
final class PermissionsManager: ObservableObject {
    @Published private(set) var microphoneAuthorized = false
    @Published private(set) var photoLibraryAuthorized = false
    @Published private(set) var cameraAuthorized = false
    
    func requestMicrophoneAccess() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            microphoneAuthorized = true
            return true
        case .denied:
            microphoneAuthorized = false
            return false
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            microphoneAuthorized = granted
            return granted
        @unknown default:
            return false
        }
    }
    
    func requestPhotoLibraryAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoLibraryAuthorized = status == .authorized
        return photoLibraryAuthorized
    }
    
    func requestCameraAccess() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        cameraAuthorized = status
        return cameraAuthorized
    }
}

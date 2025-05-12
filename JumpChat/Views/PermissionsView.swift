import SwiftUI
import AVFoundation
import Photos

struct PermissionsView: View {
    @StateObject private var permissionsManager = PermissionsManager()
    @Binding var showPermissions: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Jump Chat needs a few permissions to work its magic.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 24) {
                    PermissionButton(
                        title: "Microphone",
                        description: "For voice conversations",
                        systemImage: "mic.fill",
                        isAuthorized: permissionsManager.microphoneAuthorized
                    ) {
                        let granted = await permissionsManager.requestMicrophoneAccess()
                        if !granted {
                            // Could show an alert here explaining why mic is needed
                        }
                    }
                    
                    PermissionButton(
                        title: "Photo Library",
                        description: "To save and share images",
                        systemImage: "photo.fill",
                        isAuthorized: permissionsManager.photoLibraryAuthorized
                    ) {
                        let granted = await permissionsManager.requestPhotoLibraryAccess()
                        if !granted {
                            // Could show an alert here explaining why photos are needed
                        }
                    }
                    
                    PermissionButton(
                        title: "Camera",
                        description: "For capturing images",
                        systemImage: "camera.fill",
                        isAuthorized: permissionsManager.cameraAuthorized
                    ) {
                        let granted = await permissionsManager.requestCameraAccess()
                        if !granted {
                            // Could show an alert here explaining why camera is needed
                        }
                    }
                }
                .padding(.horizontal)
                
                Button {
                    Task {
                        await requestAllPermissions()
                    }
                } label: {
                    Text("Enable All")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button {
                    showPermissions = false
                } label: {
                    Text("Continue")
                        .font(.headline)
                }
                .padding(.top)
            }
            .padding(.vertical, 32)
            .navigationTitle("Jump Chat")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func requestAllPermissions() async {
        var allGranted = true
        
        // Request each permission and track results
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { return await permissionsManager.requestMicrophoneAccess() }
            group.addTask { return await permissionsManager.requestPhotoLibraryAccess() }
            group.addTask { return await permissionsManager.requestCameraAccess() }
            
            for await result in group {
                if !result {
                    allGranted = false
                }
            }
        }
        
        // If all permissions granted, we can auto-dismiss
        if allGranted {
            showPermissions = false
        }
    }
}

struct PermissionButton: View {
    let title: String
    let description: String
    let systemImage: String
    let isAuthorized: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isAuthorized ? .green : .secondary)
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PermissionsView(showPermissions: .constant(true))
}

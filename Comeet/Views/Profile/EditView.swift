//
//  EditView.swift
//  Comeet
//
//  Created by Michael Ross on 4/15/21.
//  Copyright © 2021 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct EditView: View {
    @Environment(UserService.self) var userService: UserService
    @State private var isShowPhotoLibrary = false
    @State private var imageAlertShown = false
    @State var imageCache = SDImageCache.shared
    
    var user: User
    
    var body: some View {
        VStack {
                ProfileEditView(user: user)
        }.sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(isShown: $isShowPhotoLibrary, alertShown: $imageAlertShown)
        }.alert(isPresented: $imageAlertShown) {
            Alert(title: Text("Image Saved"),
            message: Text("You may need to close the app for the new image to take effect"))
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(user: User())
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(UserService.self) private var userService
    
    @Binding var isShown: Bool
    
    @Binding var alertShown: Bool
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
    
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = true
                
        return imagePicker
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(userService: userService, isShown: $isShown, alertShown: $alertShown)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    final class Coordinator : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let userService: UserService
        @Binding var isShown: Bool
        @Binding var alertShown: Bool
        
        init(userService: UserService, isShown: Binding<Bool>, alertShown: Binding<Bool>) {
            self.userService = userService
            _isShown = isShown
            _alertShown = alertShown
        }
        
        var image: Image?
        var imageURL: NSURL?
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                
                print("DEBUG: Image loaded")
                
                Task { @MainActor in
                    guard let data = image.jpegData(compressionQuality: 0.8) else { return }
                    do {
                        try await userService.uploadNewImage(data: data)
                        SDImageCache.shared.clearMemory()
                        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                            SDImageCache.shared.clearDisk(onCompletion: { continuation.resume() })
                        }
                        isShown = false
                        alertShown = true
                    } catch {
                        SessionStore.shared.handle(error)
                        let alert = UIAlertController(title: "Could not upload photo", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        picker.present(alert, animated: true)
                    }
                }

                print("DEBUG: Alert shown? \(alertShown)")
            }
                       
        }
        //Image selection got cancel
        func imagePickerControllerDidCancel(_ picker:      UIImagePickerController) {
            isShown = false
        }
        
    }
}

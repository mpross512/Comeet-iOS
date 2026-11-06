//
//  EditView.swift
//  Comeet
//
//  Created by Michael Ross on 4/15/21.
//  Copyright © 2021 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct EditView: View {
    let user: User

    var body: some View {
        ProfileEditView(user: user)
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(user: User())
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(SessionStore.self) private var session
    
    @Binding var isShown: Bool
    
    @Binding var alertShown: Bool
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
    
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = true
                
        return imagePicker
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, isShown: $isShown, alertShown: $alertShown)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    final class Coordinator : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let session: SessionStore
        @Binding var isShown: Bool
        @Binding var alertShown: Bool
        
        init(session: SessionStore, isShown: Binding<Bool>, alertShown: Binding<Bool>) {
            self.session = session
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
                        try await session.uploadPhoto(data)
                        isShown = false
                        alertShown = true
                    } catch {
                        session.handle(error)
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

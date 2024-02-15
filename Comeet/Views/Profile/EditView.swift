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
    
    @Binding var isShown: Bool
    
    @Binding var alertShown: Bool
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
    
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = true
                
        return imagePicker
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShown: $isShown, alertShown: $alertShown)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    final class Coordinator : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Environment(UserService.self) var userService: UserService
        @Binding var isShown: Bool
        @Binding var alertShown: Bool
        
        init(isShown: Binding<Bool>, alertShown: Binding<Bool>) {
            _isShown = isShown
            _alertShown = alertShown
        }
        
        var image: Image?
        var imageURL: NSURL?
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                
                print("DEBUG: Image loaded")
                
                userService.uploadNewImage(data: image.jpegData(compressionQuality: 1.0)!)
                isShown = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.alertShown = true
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

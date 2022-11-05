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

    @State private var isShowPhotoLibrary = false
    @State var imageCache = SDImageCache.shared
    
    @State var bio: String = "\(UserHandler.getUserHandler().user.getBio())"

    var body: some View {
        VStack {
            
            WebImage(url: UserHandler.getUserHandler().getImageURL())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 175, height: 175)
                .clipShape(Circle())

            Button(action: {
                self.isShowPhotoLibrary = true
            }) {
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 20))

                    Text("Photo library")
                        .font(.headline)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.horizontal)
            }
            
            TextField("Bio", text: $bio)
                .foregroundColor(.black)
                .padding(.leading)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25).fill(Color.white)
                )
                .padding(.horizontal)
        }.sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(isShown: $isShowPhotoLibrary)
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    
    @Binding var isShown: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
    
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = true
                
        return imagePicker
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShown: $isShown)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    
    
    final class Coordinator : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        @Binding var isShown: Bool
        
        init(isShown: Binding<Bool>) {
            _isShown = isShown
        }
        
        var image: Image?
        var imageURL: NSURL?
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                
                UserHandler.getUserHandler().uploadNewImage(data: image.jpegData(compressionQuality: 1.0)!)
                isShown = false

            }
                       
        }
        //Image selection got cancel
        func imagePickerControllerDidCancel(_ picker:      UIImagePickerController) {
            isShown = false
        }
        
    }
}

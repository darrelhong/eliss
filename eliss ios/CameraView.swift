//
//  CameraView.swift
//  eliss ios
//
//  Created by ByteDance on 8/4/23.
//

import SwiftUI

struct CameraView: View {
    @Binding var image: Image?
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .statusBar(hidden: true)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(image: .constant(Image(systemName: "pencil")))
    }
}


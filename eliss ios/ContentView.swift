//
//  ContentView.swift
//  eliss ios
//
//  Created by darrelhong on 7/4/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = DataModel()

    var body: some View {
        CameraView(image: $model.viewfinderImage)
            .overlay(alignment: .top) {
                HStack(spacing: 60) {
                    Spacer()
                    Button {
                        model.camera.switchCaptureDevice()
                    } label: {
                        Label("Switch camera", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                }
                .padding()
                .background(.black.opacity(0.65))
            }
            .task {
                await model.camera.start()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

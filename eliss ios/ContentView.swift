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
                    Text("Angle: \(Int($model.situpAngle.wrappedValue ?? 0))")
                    Spacer()
                    Button {
                        model.camera.switchCaptureDevice()
                    } label: {
                        Label("Switch camera", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                }
                .font(.system(size: 16))
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

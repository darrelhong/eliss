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
        CameraPreviewController(dataModel: model)
            .overlay(alignment: .top) {
                HStack(spacing: 10) {
                    Text("Angle: \($model.debouncedAngle.wrappedValue == nil ? "nil" : String(Int($model.debouncedAngle.wrappedValue!)))")
                    Text("State: \($model.repPosition.wrappedValue.rawValue)")
                    Text("Reps: \($model.reps.wrappedValue)")
                    Spacer()
                    Button {
                        model.cameraController.switchCamera()
                    } label: {
                        Label("Switch camera", systemImage: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                }
                .padding()
                .font(.system(size: 16))
                .background(.black.opacity(0.65))
            }
            .ignoresSafeArea()
            .statusBar(hidden: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

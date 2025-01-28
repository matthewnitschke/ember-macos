//
//  PresetEntry.swift
//  EmberMate
//
//  Created by Matthew Nitschke on 1/27/25.
//

import SwiftUI

struct PresetEntry: View {
    var images: [String] = [
        "mug.fill",
        "cup.and.saucer.fill",
        "drop.fill",
        "leaf.fill",
        "star.fill",
        "flame.fill"
    ]
    
    @Binding var preset: Preset
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onDelete) {
                Image(systemName: "trash")
            }.buttonStyle(.plain)

            TextField("Name", text: $preset.name)
                .labelsHidden()

            TemperatureInput(value: $preset.temperature)

            Picker(
                selection: $preset.icon,
                label: Text("Icon")
            ) {
                ForEach(images, id: \.self) { image in
                    Image(systemName: image)
                        .tag(image)
                }
            }.frame(width: 45).labelsHidden()
        }
    }
}

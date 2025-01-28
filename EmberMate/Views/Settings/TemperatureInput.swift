//
//  TemperatureInput.swift
//  EmberMate
//
//  Created by Matthew Nitschke on 1/26/25.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications

struct TemperatureInput: View {
    @EnvironmentObject private var emberMug: EmberMug
    
    @Binding var value: Double

    var body: some View {
        TextField(
            "Temperature",
            text: Binding(
                get: {
                    if emberMug.temperatureUnit == .celcius {
                        String(format: "%.0f", value)
                    } else {
                        String(format: "%.0f", (value * 9/5) + 32)
                    }
                },
                set: {
                    if emberMug.temperatureUnit == .celcius {
                        value = Double($0)!
                    } else {
                        value = (Double($0)! - 32) * 5/9
                    }
                }
            )
        )
            .labelsHidden()
            .multilineTextAlignment(.trailing)
        
    }
}

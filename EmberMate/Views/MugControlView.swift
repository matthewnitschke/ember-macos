//
//  MugControlView.swift
//  EmberMate
//
//  Created by Matthew Nitschke on 12/5/23.
//

import Foundation
import SwiftUI
import UserNotifications

struct MugControlView: View {
    @EnvironmentObject private var emberMug: EmberMug
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text(emberMug.peripheral?.name ?? "")
                    .font(.caption)
                Spacer()
                Image(systemName: getBatteryIcon(emberMug.batteryLevel, isCharging: emberMug.isCharging))
            }

            HStack {
                Button(action: {
                    setTemperature(delta: -0.5)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .frame(width: 30, height: 100)
                        .background(Color.black.opacity(0.29))
                }.buttonStyle(PlainButtonStyle()).cornerRadius(9)

                Spacer()

                VStack {
                    Text(
                        emberMug.liquidState == LiquidState.empty
                            ? "Empty"
                            : getFormattedTemperature(emberMug.currentTemp, unit: emberMug.temperatureUnit)
                    ).font(.largeTitle)

                    Text("Target: \(getFormattedTemperature(emberMug.targetTemp, unit: emberMug.temperatureUnit))")
                }

                Spacer()

                Button(action: {
                    setTemperature(delta: 0.5)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .frame(width: 30, height: 100)
                        .background(Color.black.opacity(0.29))
                }.buttonStyle(PlainButtonStyle()).cornerRadius(9)
            }

            HStack {
                ForEach(appState.presets, id: \.id) { preset in
                    TemperaturePresetButton(
                        preset: preset,
                        temperatureUnit: emberMug.temperatureUnit,
                        isSelected: appState.selectedPreset?.id == preset.id,
                        onSelect: {
                            appState.selectedPreset = preset
                            emberMug.setTargetTemp(temp: $0)
                        }
                    )
                }
            }

            if !appState.timers.isEmpty {
                TimerView()
            }

        }.padding(10).background(LinearGradient(
            colors: getBackgroundGradientForMugState(),
            startPoint: .top,
            endPoint: .bottom
        ))
        .environment(\.colorScheme, .dark) // Ignore OS level light mode, UI is designed for "dark" mode
    }

    private func setTemperature(delta: Double) {
        appState.selectedPreset = nil

        let nextTemp = round((self.emberMug.targetTemp + delta) * 2) / 2
        self.emberMug.setTargetTemp(temp: nextTemp)
    }

    private func emptyBackgroundGradient() -> [Color] {
        return [getColor(212, 212, 212), getColor(69, 69, 69)]
    }

    private func getBackgroundGradientForMugState() -> [Color] {
        if (emberMug.liquidState == LiquidState.empty) {
            return [getColor(212, 212, 212), getColor(69, 69, 69)]
        }

        let currentTemp = emberMug.currentTemp

        var val = 0.0
        if (currentTemp <= 50) {
            val = 0.0
        } else if (currentTemp >= 63) {
            val = 1.0
        } else {
            val = Double(currentTemp - 50)
        }

        return getBackgroundGradient(val)
    }
}

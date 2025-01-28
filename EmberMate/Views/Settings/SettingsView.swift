//
//  SettingsView.swift
//  EmberMate
//
//  Created by Matthew Nitschke on 12/10/23.
//

import Foundation
import SwiftUI
import AppKit
import LaunchAtLogin
import UserNotifications

struct SettingsView: View {
    @State var internalTime: String?

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            PresetsSettingsView()
                .tabItem { Label("Presets", systemImage: "square.and.arrow.down") }
        }
        .navigationTitle("Settings")
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject private var emberMug: EmberMug
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Form {
            Section {
                HStack {
                    if (bluetoothManager.state == .disconnected) {
                        Image(systemName: "mug")
                            .font(.largeTitle)
                        Text("No Device Connected")
                    } else {
                        Image(systemName: "mug.fill")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(emberMug.peripheral?.name ?? "Unknown Device")
                            HStack(spacing: 3) {
                                Image(systemName: getBatteryIcon(emberMug.batteryLevel, isCharging: emberMug.isCharging))
                                Text("\(emberMug.batteryLevel)%")
                            }.foregroundColor(.gray)
                        }
                        Spacer()
                        Button("Disconnect") {
                            bluetoothManager.disconnect()
                        }
                    }
                }
            }
            
            Section {
                Picker("Measurement Unit", selection: $emberMug.temperatureUnit) {
                    Text("℉").tag(TemperatureUnit.fahrenheit)
                    Text("℃").tag(TemperatureUnit.celcius)
                }
                LaunchAtLogin.Toggle()
            }
            
            Section {
                if appState.notificationsDisabled {
                    LabeledContent {
                        Button("System Settings") {
                            self.openURL(.notificationSettings)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Notifications are disabled")
                        }
                    }
                }
                
                Toggle(isOn: appState.$notifyOnTemperatureReached) {
                    Text("Notify when temperature is reached")
                        .opacity(appState.notificationsDisabled ? 0.5 : 1)
                }
                .disabled(appState.notificationsDisabled)
                
                Toggle(isOn: appState.$notifyOnLowBattery) {
                    Text("Notify on low battery (15%)")
                        .opacity(appState.notificationsDisabled ? 0.5 : 1)
                }
                    .disabled(appState.notificationsDisabled)
            }
        
            
            
        }
        .formStyle(.grouped)
        .task {
            await appState.updateNotificationsDisabled()
        }
    }
}

struct PresetsSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var emberMug: EmberMug

    var body: some View {
        Form {
            Section {
                ForEach($appState.presets, id: \.id) { preset in
                    PresetEntry(
                        preset: preset,
                        onDelete: { appState.presets.removeAll(where: { $0.id == preset.id }) }
                    )
                }
            } header: {
                Text("Temperature")
            } footer: {
                HStack {
                    Spacer()
                    Button("+") {
                        appState.presets.append(Preset())
                    }
                }
            }

            Section {
                if (!appState.timers.isEmpty) {
                    ForEach(appState.timers.indices, id: \.self) { index in
                        HStack {
                            Button(action: {
                                appState.timers.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                            }.buttonStyle(.plain)

                            TextField("Duration", text: Binding(
                                get: {
                                    // zombie child render issue, ensure that [index] always referes to a value
                                    if (appState.timers.count - 1 < index) {
                                        return ""
                                    }
                                    return appState.timers[index]
                                },
                                set: { newValue in
                                    appState.timers[index] = newValue
                                }
                            )).labelsHidden()
                        }
                    }
                }
            } header: {
                Text("Timer")
            } footer: {
                HStack {
                    Spacer()
                    Button("+") {
                        appState.timers.append("4:00")
                    }
                }
            }

        }
        .formStyle(.grouped)
    }
}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension URL {
    static let notificationSettings: URL = {
        let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!
        
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return url
        }
        
        return url.appending(queryItems: [
            .init(name: "id", value: bundleId)
        ])
    }()
}

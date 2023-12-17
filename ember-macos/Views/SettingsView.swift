//
//  SettingsView.swift
//  ember-macos
//
//  Created by Matthew Nitschke on 12/10/23.
//

import Foundation
import SwiftUI
import AppKit
import LaunchAtLogin

struct SettingsView: View {
    var appState: AppState
    var emberMug: EmberMug
    var bluetoothManager: BluetoothManager
    
    @State var internalTime: String?
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                emberMug: emberMug,
                appState: appState,
                bluetoothManager: bluetoothManager
            )
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            PresetsSettingsView(appState: appState)
                .tabItem {
                    Label("Presets", systemImage: "square.and.arrow.down")
                }
        }
        .navigationTitle("Settings")
        
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var emberMug: EmberMug
    @ObservedObject var appState: AppState
    @ObservedObject var bluetoothManager: BluetoothManager
    
    @AppStorage("notifyTemperatureReached") var notifyTemperatureReached: Bool = true
    
    var body: some View {
        Form {
            Section {
                HStack {
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
                
                Section {
                    LaunchAtLogin.Toggle()
                    Toggle("Notify when temperature is reached", isOn: appState.$notifyOnTemperatureReached)
                }
            }
        }.formStyle(.grouped)
    }
}

struct PresetsSettingsView: View {
    @ObservedObject var appState: AppState
    
    var images: [String] = [
        "mug.fill",
        "cup.and.saucer.fill",
        "drop.fill",
        "leaf.fill",
        "star.fill",
        "flame.fill"
    ]
    
    var body: some View {
        Form {
            Section {
                ForEach($appState.presets, id: \.id) { preset in
                    HStack {
                        Button(action: {
                            appState.presets.removeAll(where: { $0.id == preset.id })
                        }) {
                            Image(systemName: "trash")
                        }.buttonStyle(.plain)
                        
                        TextField("Name", text: preset.name)
                            .labelsHidden()
                        
                        TextField("Temperature", value: preset.temperature, format: .number)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                        
                        Picker(
                            selection: preset.icon,
                            label: Text("Icon")
                        ) {
                            ForEach(images, id: \.self) { image in
                                Image(systemName: image)
                                    .tag(image)
                            }
                        }.frame(width: 45).labelsHidden()
                    }
                }
            } header: {
                Text("Temperature")
            } footer: {
                Button("+") {
                    appState.presets.append(Preset())
                }
            }
            
            Section {
                ForEach(appState.timers.indices, id: \.self) { index in
                    HStack {
                        Button(action: {
                            appState.timers.remove(at: index)
                        }) {
                            Image(systemName: "trash")
                        }.buttonStyle(.plain)
                        
                        TextField("Duration", text: Binding(
                            get: {
                                // zombie child render issue, mod the response so the requests are always in bounds
                                appState.timers[index % appState.timers.count]
                            },
                            set: { newValue in
                                appState.timers[index] = newValue
                            }
                        )).labelsHidden()
                    }
                }
            } header: {
                Text("Timer")
            } footer: {
                Button("+") {
                    appState.timers.append("4:00")
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
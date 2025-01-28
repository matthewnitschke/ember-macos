//
//  AppView.swift
//  EmberMate
//
//  Created by Matthew Nitschke on 12/3/23.
//

import Foundation
import SwiftUI

struct AppView: View {
    @EnvironmentObject private var bluetoothManager: BluetoothManager

    var body: some View {
        switch bluetoothManager.state {
        case .connected: MugControlView()
        case .disconnected, .connecting: ConnectMugView()
        case .reConnecting: Text("Device Lost, Searching...").padding()
        }
    }
}

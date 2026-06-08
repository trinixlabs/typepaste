//
//  TypePasteApp.swift
//  TypePaste
//
//  Created by Tim Haselaars on 03/02/2026.
//

import SwiftUI

@main
struct TypePasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            TypePasteMenuBarView(appDelegate: appDelegate)
        } label: {
            Image(systemName: "number.square")
        }
        .menuBarExtraStyle(.window)

        Settings {
            ContentView()
        }
    }
}

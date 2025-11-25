//
//  DesktopSettings.swift
//  boringNotch
//
//  Desktop configuration settings
//

import SwiftUI
import Defaults

struct DesktopSettings: View {
    @ObservedObject var desktopManager = DesktopManager.shared
    @Default(.showDesktopName) var showDesktopName
    @Default(.desktopNames) var desktopNames
    @Default(.desktopNameAutoExpandOnNotch) var autoExpandOnNotch
    @Default(.desktopNameAutoHideDelay) var autoHideDelay

    @State private var editingSpaceID: String? = nil
    @State private var editingName: String = ""
    @State private var showAddSheet = false
    @State private var newSpaceID: String = ""
    @State private var newSpaceName: String = ""

    var body: some View {
        Form {
            Section {
                Toggle("Show Desktop Name", isOn: $showDesktopName)
                    .help("Display the current desktop name in the notch")
            }

            Section(header: Text("Auto-Expand on Notched Screens")) {
                Toggle("Auto-expand when switching desktops", isOn: $autoExpandOnNotch)
                    .help("On screens with a notch, briefly expand the notch to show the desktop name when switching")
                    .disabled(!showDesktopName)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Auto-hide delay:")
                        Spacer()
                        Text(String(format: "%.1f seconds", autoHideDelay))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $autoHideDelay, in: 0.5...5.0, step: 0.5)
                }
                .disabled(!showDesktopName || !autoExpandOnNotch)
                .help("How long to keep the notch expanded after switching desktops")
            }

            Section(header: Text("Current Desktop")) {
                HStack {
                    Text("Space ID:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(desktopManager.currentSpaceID))
                        .foregroundColor(.primary)
                }

                HStack {
                    Text("Name:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(desktopManager.currentSpaceName)
                        .foregroundColor(.primary)
                }

                Button("Set Name for Current Desktop") {
                    editingSpaceID = String(desktopManager.currentSpaceID)
                    editingName = desktopManager.currentSpaceName
                }
            }

            Section(header: Text("Desktop Names")) {
                if desktopNames.isEmpty {
                    Text("No custom desktop names configured")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(desktopNames.keys.sorted()), id: \.self) { spaceID in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(desktopNames[spaceID] ?? "")
                                    .font(.body)
                                Text("Space ID: \(spaceID)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if spaceID == String(desktopManager.currentSpaceID) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .help("Current desktop")
                            }
                            Button(action: {
                                editingSpaceID = spaceID
                                editingName = desktopNames[spaceID] ?? ""
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Edit name")

                            Button(action: {
                                if let spaceID = UInt64(spaceID) {
                                    desktopManager.removeDesktopName(forSpaceID: spaceID)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Remove name")
                        }
                        .padding(.vertical, 4)
                    }
                }

                Button(action: {
                    showAddSheet = true
                }) {
                    Label("Add Desktop Name", systemImage: "plus")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Use")
                        .font(.headline)
                    Text("1. Enable 'Show Desktop Name' to display the name in the notch")
                    Text("2. Click 'Set Name for Current Desktop' to quickly name the desktop you're on")
                    Text("3. Switch to different desktops to add names for each one")
                    Text("4. Desktop names will update automatically when you switch between them")
                    Text("")
                    Text("Note: On screens with a notch, enable 'Auto-expand' to briefly show the desktop name when switching (the notch will automatically close after the configured delay)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(minWidth: 500, minHeight: 500)
        .sheet(isPresented: Binding(
            get: { editingSpaceID != nil },
            set: { if !$0 { editingSpaceID = nil } }
        )) {
            if let spaceID = editingSpaceID {
                VStack(spacing: 16) {
                    Text("Edit Desktop Name")
                        .font(.headline)

                    Text("Space ID: \(spaceID)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Desktop Name", text: $editingName)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Cancel") {
                            editingSpaceID = nil
                            editingName = ""
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Save") {
                            if let spaceIDNum = UInt64(spaceID), !editingName.isEmpty {
                                desktopManager.setDesktopName(editingName, forSpaceID: spaceIDNum)
                            }
                            editingSpaceID = nil
                            editingName = ""
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(editingName.isEmpty)
                    }
                }
                .padding()
                .frame(width: 300)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VStack(spacing: 16) {
                Text("Add Desktop Name")
                    .font(.headline)

                TextField("Space ID", text: $newSpaceID)
                    .textFieldStyle(.roundedBorder)

                TextField("Desktop Name", text: $newSpaceName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Cancel") {
                        showAddSheet = false
                        newSpaceID = ""
                        newSpaceName = ""
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Add") {
                        if let spaceIDNum = UInt64(newSpaceID), !newSpaceName.isEmpty {
                            desktopManager.setDesktopName(newSpaceName, forSpaceID: spaceIDNum)
                        }
                        showAddSheet = false
                        newSpaceID = ""
                        newSpaceName = ""
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newSpaceID.isEmpty || newSpaceName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}

#Preview {
    DesktopSettings()
}

//
//  DesktopNameView.swift
//  boringNotch
//
//  Desktop name display component
//

import SwiftUI
import Defaults

struct DesktopNameView: View {
    @ObservedObject var desktopManager = DesktopManager.shared
    @Default(.showDesktopName) var showDesktopName

    var body: some View {
        if showDesktopName {
            // Simple text, no background
            Text(desktopManager.currentSpaceName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .id(desktopManager.currentSpaceID)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: desktopManager.currentSpaceID)
        }
    }
}

#Preview {
    DesktopNameView()
        .padding()
        .background(Color.gray)
}

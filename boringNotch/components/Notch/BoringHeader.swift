//
//  BoringHeader.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Defaults
import SwiftUI

struct BoringHeader: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @StateObject var tvm = TrayDrop.shared

    var body: some View {
        let hasNotch = NSScreen.screens
            .first(where: { $0.localizedName == coordinator.selectedScreen })?.safeAreaInsets.top ?? 0 > 0

        Group {
            if vm.notchState == .peek && hasNotch {
                // PEEK MODE on notched screens - just desktop name on left, vertically centered
                HStack {
                    DesktopNameView()
                        .padding(.leading, 30)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                // NORMAL MODE - original layout with desktop name on left when open+notched
                normalLayout(hasNotch: hasNotch)
            }
        }
        .foregroundColor(.gray)
        .environmentObject(vm)
    }

    @ViewBuilder
    private func normalLayout(hasNotch: Bool) -> some View {
        HStack(spacing: 0) {
            // LEFT SECTION
            HStack {
                if vm.notchState == .open && hasNotch {
                    // Show desktop name on left when open on notched screens
                    DesktopNameView()
                        .padding(.leading, 8)
                } else if (!tvm.isEmpty || coordinator.alwaysShowTabs) && Defaults[.boringShelf] {
                    TabSelectionView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(vm.notchState == .closed ? 0 : 1)
            .blur(radius: vm.notchState == .closed ? 20 : 0)
            .animation(.smooth.delay(0.1), value: vm.notchState)
            .zIndex(2)

            // CENTER SECTION
            VStack(spacing: 4) {
                // Only show desktop name in center when not on notched screen in open mode
                if (vm.notchState == .peek && !hasNotch) || (vm.notchState == .open && !hasNotch) {
                    DesktopNameView()
                }

                if vm.notchState == .open {
                    Rectangle()
                        .fill(hasNotch ? .black : .clear)
                        .frame(width: vm.closedNotchSize.width)
                        .mask {
                            NotchShape()
                        }
                }
            }

            // RIGHT SECTION
            HStack(spacing: 4) {
                if vm.notchState == .open {
                    if Defaults[.showMirror] {
                        Button(action: {
                            vm.toggleCameraPreview()
                        }) {
                            Capsule()
                                .fill(.black)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "web.camera")
                                        .foregroundColor(.white)
                                        .padding()
                                        .imageScale(.medium)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    if Defaults[.settingsIconInNotch] {
                        Button(action: {
                            SettingsWindowController.shared.showWindow()
                        }) {
                            Capsule()
                                .fill(.black)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                        .padding()
                                        .imageScale(.medium)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    if Defaults[.showBatteryIndicator] {
                        BoringBatteryView(
                            batteryWidth: 30,
                            isCharging: batteryModel.isCharging,
                            isInLowPowerMode: batteryModel.isInLowPowerMode,
                            isPluggedIn: batteryModel.isPluggedIn,
                            levelBattery: batteryModel.levelBattery,
                            maxCapacity: batteryModel.maxCapacity,
                            timeToFullCharge: batteryModel.timeToFullCharge,
                            isForNotification: false
                        )
                    }
                }
            }
            .font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(vm.notchState == .closed ? 0 : 1)
            .blur(radius: vm.notchState == .closed ? 20 : 0)
            .animation(.smooth.delay(0.1), value: vm.notchState)
            .zIndex(2)
        }
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel())
}

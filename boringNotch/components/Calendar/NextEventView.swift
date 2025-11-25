//
//  NextEventView.swift
//  boringNotch
//
//  Displays the next upcoming event in the notch when closed
//

import SwiftUI
import Defaults

struct NextEventView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    @EnvironmentObject var vm: BoringViewModel
    @State private var isHovering: Bool = false

    var body: some View {
        if let event = calendarManager.nextUpcomingEvent {
            HStack(spacing: 4) {
                // Calendar color indicator
                HStack {
                    Rectangle()
                        .fill(Color(event.calendar.color))
                        .frame(width: 3)
                        .cornerRadius(1.5)
                        .frame(
                            height: max(0, vm.effectiveClosedNotchHeight - 12))
                }
                .frame(
                    width: max(0, vm.effectiveClosedNotchHeight - (isHovering ? 0 : 12)),
                    height: max(0, vm.effectiveClosedNotchHeight - (isHovering ? 0 : 12)))

                // Event details
                Rectangle()
                    .fill(.black)
                    .overlay(
                        HStack(spacing: 8) {
                            // Event title
                            Text(event.title)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundStyle(.white)
                                .font(.callout)

                            Spacer(minLength: vm.closedNotchSize.width)

                            // Event time
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(event.start, style: .time)
                                    .font(.caption)
                            }
                            .foregroundStyle(.gray)
                        }
                        .padding(.horizontal, 8)
                    )
                    .frame(width: vm.closedNotchSize.width + (isHovering ? 8 : 0))

                // Spacer on the right
                HStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(
                            width: max(0, vm.effectiveClosedNotchHeight - 12),
                            height: max(0, vm.effectiveClosedNotchHeight - 12))
                }
                .frame(
                    width: max(0, vm.effectiveClosedNotchHeight - (isHovering ? 0 : 12)),
                    height: max(0, vm.effectiveClosedNotchHeight - (isHovering ? 0 : 12)))
            }
            .frame(height: vm.effectiveClosedNotchHeight + (isHovering ? 8 : 0), alignment: .center)
            .onHover { hovering in
                withAnimation(.smooth) {
                    isHovering = hovering
                }
            }
        }
    }
}

#Preview {
    NextEventView()
        .environmentObject(BoringViewModel())
        .padding()
        .background(Color.gray)
}

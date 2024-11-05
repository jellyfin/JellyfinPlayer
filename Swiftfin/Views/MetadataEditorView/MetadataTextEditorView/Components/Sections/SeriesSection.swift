//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension MetadataTextEditorView {
    struct SeriesSection: View {
        @Binding
        var item: BaseItemDto

        @State
        private var tempTimeInterval: TimeInterval = 0
        @State
        private var tempRunTime: Int?

        // MARK: - Initializer

        init(item: Binding<BaseItemDto>) {
            self._item = Binding(projectedValue: item)
            self.tempRunTime = Int(ServerTicks(item.wrappedValue.runTimeTicks ?? 0).minutes)
        }

        // MARK: - Body

        var body: some View {

            Section(L10n.series) {
                seriesStatusView
            }

            Section(L10n.episodes) {
                airTimeView

                runTimeView
            }

            Section(L10n.dayOfWeek) {
                airDaysView
            }
        }

        // MARK: - Series Status View

        @ViewBuilder
        private var seriesStatusView: some View {
            Picker(L10n.status, selection: Binding(get: {
                SeriesStatus(rawValue: item.status ?? "") ?? .continuing
            }, set: {
                item.status = $0.rawValue
            })) {
                ForEach(SeriesStatus.allCases, id: \.self) { status in
                    Text(status.displayTitle).tag(status)
                }
            }
        }

        // MARK: - Air Time View

        @ViewBuilder
        private var airTimeView: some View {
            DatePicker(
                L10n.airTime,
                selection: Binding<Date>(
                    get: { parseAirTimeToDate(item.airTime) },
                    set: { date in
                        item.airTime = formatDateToString(date)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
        }

        // MARK: - Air Days View

        @ViewBuilder
        private var airDaysView: some View {
            ForEach(DayOfWeek.allCases, id: \.self) { field in
                Toggle(field.displayTitle ?? L10n.unknown, isOn: Binding(
                    get: { item.airDays?.contains(field) ?? false },
                    set: { isSelected in
                        if isSelected {
                            item.airDays?.append(field)
                        } else {
                            item.airDays?.removeAll { $0 == field }
                        }
                    }
                ))
            }
        }

        // MARK: - Run Time View

        @ViewBuilder
        private var runTimeView: some View {
            ChevronAlertButton(
                L10n.runTime,
                subtitle: ServerTicks(item.runTimeTicks ?? 0)
                    .seconds.formatted(.hourMinute),
                description: L10n.episodeRuntimeDescription
            ) {
                TextField(
                    L10n.minutes,
                    value: $tempRunTime,
                    format: .number
                )
                .keyboardType(.numberPad)
            } onSave: {
                if let tempRunTime = tempRunTime, tempRunTime != 0 {
                    item.runTimeTicks = ServerTicks(minutes: tempRunTime).ticks
                } else {
                    item.runTimeTicks = nil
                }
            } onCancel: {
                if let originalRunTime = item.runTimeTicks {
                    tempRunTime = Int(ServerTicks(originalRunTime).minutes)
                } else {
                    tempRunTime = nil
                }
            }
        }

        // MARK: - Parse AirTime to Date

        private func parseAirTimeToDate(_ airTime: String?) -> Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            if let airTime = airTime, let date = dateFormatter.date(from: airTime) {
                return date
            }
            return dateFormatter.date(from: "00:00") ?? Date()
        }

        // MARK: - Format Date to String

        private func formatDateToString(_ date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        }
    }
}

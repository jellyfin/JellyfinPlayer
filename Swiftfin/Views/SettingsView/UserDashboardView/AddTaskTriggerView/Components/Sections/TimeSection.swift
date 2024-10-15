//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddTaskTriggerView {

    struct TimeSection: View {

        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        var body: some View {
            if taskTriggerInfo.type == TaskTriggerType.daily.rawValue || taskTriggerInfo.type == TaskTriggerType.weekly.rawValue {
                DatePicker(
                    L10n.time,
                    selection: Binding<Date>(
                        get: {
                            ServerTicks(
                                ticks: taskTriggerInfo.timeOfDayTicks ?? defaultTimeOfDayTicks
                            ).date
                        },
                        set: { date in
                            taskTriggerInfo.timeOfDayTicks = ServerTicks(date: date).ticks
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }
}

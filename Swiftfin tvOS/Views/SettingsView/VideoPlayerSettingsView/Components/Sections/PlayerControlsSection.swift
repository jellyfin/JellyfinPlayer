//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {
    struct PlayerControlsSection: View {
        @Default(.VideoPlayer.jumpBackwardLength)
        private var jumpBackwardLength
        @Default(.VideoPlayer.jumpForwardLength)
        private var jumpForwardLength

        @EnvironmentObject
        private var router: VideoPlayerSettingsCoordinator.Router

        var body: some View {
            Section {
                // Gestures have been removes as tvOS does not have touch gestures

                InlineEnumToggle(title: L10n.jumpBackwardLength, selection: $jumpBackwardLength)

                InlineEnumToggle(title: L10n.jumpForwardLength, selection: $jumpForwardLength)
            } header: {
                L10n.playerControls.text
            } footer: {
                L10n.playerControlsDescription.text
            }
        }
    }
}

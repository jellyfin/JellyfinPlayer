//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct AutoPlay: View {

        @Default(.VideoPlayer.autoPlayEnabled)
        private var isAutoPlayEnabled
        
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var systemImage: String {
            if isAutoPlayEnabled {
                "play.circle.fill"
            } else {
                "stop.circle"
            }
        }

        var body: some View {
            Button(
                "Autoplay",
                systemImage: systemImage
            ) {
                isAutoPlayEnabled.toggle()
            }
            .transition(.scale.combined(with: .opacity).animation(.snappy))
            .id(isAutoPlayEnabled)
            .disabled(manager.queue == nil)
        }
    }
}
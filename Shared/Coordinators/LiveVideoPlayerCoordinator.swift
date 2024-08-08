//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import PreferencesView
import Stinsen
import SwiftUI

final class LiveVideoPlayerCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \LiveVideoPlayerCoordinator.start)

    @Root
    var start = makeStart

    let videoPlayerManager: LiveVideoPlayerManager

    init(manager: LiveVideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    // TODO: remove after iOS 15 support removed

    @ViewBuilder
    private func containerView<Content: View>(_ content: @escaping () -> Content) -> some View {
        iOS15View {
            iOS15LandscapeView(content: content)
        } content: {
            PreferencesView(content: content)
        }
    }

    @ViewBuilder
    func makeStart() -> some View {
        #if os(iOS)

        containerView {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    LiveVideoPlayer(manager: self.videoPlayerManager)
                } else {
                    LiveNativeVideoPlayer(manager: self.videoPlayerManager)
                }
            }
            .preferredColorScheme(.dark)
            .supportedOrientations(UIDevice.isPhone ? .landscape : .allButUpsideDown)
        }
        .ignoresSafeArea()
        .backport
        .persistentSystemOverlays(.hidden)

        #else

        PreferencesView {
            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                LiveVideoPlayer(manager: self.videoPlayerManager)
            } else {
                LiveNativeVideoPlayer(manager: self.videoPlayerManager)
            }
        }
        .ignoresSafeArea()

        #endif
    }
}

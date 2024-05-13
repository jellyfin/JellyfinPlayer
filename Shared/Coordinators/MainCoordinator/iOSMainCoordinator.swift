//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Nuke
import Stinsen
import SwiftUI

final class MainCoordinator: NavigationCoordinatable {

    @Injected(LogManager.service)
    private var logger

    var stack: Stinsen.NavigationStack<MainCoordinator>

    @Root
    var mainTab = makeMainTab
    @Root
    var selectUser = makeSelectUser
    @Root
    var serverCheck = makeServerCheck

    @Route(.fullScreen)
    var liveVideoPlayer = makeLiveVideoPlayer
    @Route(.modal)
    var settings = makeSettings
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer

    init() {

        if Container.userSession() != nil, !Defaults[.signOutOnClose] {
            stack = NavigationStack(initial: \.serverCheck)
        } else {
            stack = NavigationStack(initial: \MainCoordinator.selectUser)
        }

        // TODO: move these to the App instead?

        ImageCache.shared.costLimit = 1000 * 1024 * 1024 // 125MB

        // Notification setup for state
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
        Notifications[.processDeepLink].subscribe(self, selector: #selector(processDeepLink(_:)))
        Notifications[.didChangeCurrentServerURL].subscribe(self, selector: #selector(didChangeCurrentServerURL(_:)))
    }

    @objc
    func didSignIn() {
        logger.info("Signed in")

        withAnimation(.linear(duration: 0.1)) {
            let _ = root(\.serverCheck)
        }
    }

    @objc
    func didSignOut() {
        logger.info("Signed out")

        withAnimation(.linear(duration: 0.1)) {
            let _ = root(\.selectUser)
        }
    }

    @objc
    func processDeepLink(_ notification: Notification) {
        guard let deepLink = notification.object as? DeepLink else { return }
        if let coordinator = hasRoot(\.mainTab) {
            switch deepLink {
            case let .item(item):
                coordinator.focusFirst(\.home)
                    .child
                    .popToRoot()
                    .route(to: \.item, item)
            }
        }
    }

    @objc
    func didChangeCurrentServerURL(_ notification: Notification) {

        guard Container.userSession() != nil else { return }

        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(SettingsCoordinator())
    }

    func makeMainTab() -> MainTabCoordinator {
        MainTabCoordinator()
    }

    func makeSelectUser() -> NavigationViewCoordinator<SelectUserCoordinator> {
        NavigationViewCoordinator(SelectUserCoordinator())
    }

    func makeServerCheck() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ServerCheckView()
        }
    }

    func makeVideoPlayer(manager: VideoPlayerManager) -> VideoPlayerCoordinator {
        VideoPlayerCoordinator(manager: manager)
    }

    func makeLiveVideoPlayer(manager: LiveVideoPlayerManager) -> LiveVideoPlayerCoordinator {
        LiveVideoPlayerCoordinator(manager: manager)
    }
}

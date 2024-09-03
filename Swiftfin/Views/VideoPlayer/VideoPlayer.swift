//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MediaPlayer
import Stinsen
import SwiftUI
import VLCUI

// TODO: organize
// TODO: localization necessary for toast text?
// TODO: entire gesture layer should be separate

enum NothingConfiguration {

    static var vlcConfiguration: VLCVideoPlayer.Configuration {
        let configuration = VLCVideoPlayer.Configuration(url: URL(string: "http://localhost/nothing.mp4")!)
        configuration.autoPlay = false
        return configuration
    }
}

struct VideoPlayer: View {

    // TODO: remove settings from here and only have in gesture handler
    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength

    @Default(.VideoPlayer.Gesture.horizontalPanGesture)
    private var horizontalPanGesture
    @Default(.VideoPlayer.Gesture.horizontalSwipeGesture)
    private var horizontalSwipeGesture
    @Default(.VideoPlayer.Gesture.longPressGesture)
    private var longPressGesture
    @Default(.VideoPlayer.Gesture.multiTapGesture)
    private var multiTapGesture
    @Default(.VideoPlayer.Gesture.doubleTouchGesture)
    private var doubleTouchGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanGestureLeft)
    private var verticalGestureLeft
    @Default(.VideoPlayer.Gesture.verticalPanGestureRight)
    private var verticalGestureRight

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @State
    private var audioOffset: Int = 0
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isGestureLocked: Bool = false
    @State
    private var isPresentingOverlay: Bool = true
    @State
    private var isScrubbing: Bool = false
    @State
    private var playbackSpeed: Double = 1
    @State
    private var subtitleOffset: Int = 0
    @State
    private var safeAreaInsets: EdgeInsets = .zero
    @State
    private var contentSize: CGSize = .zero

    @StateObject
    private var scrubbedProgress: ProgressBox = .init()

    @StateObject
    private var manager: VideoPlayerManager
    @StateObject
    private var vlcUIProxy: VLCVideoPlayer.Proxy

    private let gestureStateHandler: GestureStateHandler = .init()

    // TODO: create general toast manager and inject into environment
    private let updateViewProxy: UpdateViewProxy = .init()

    // MARK: playerView

    @ViewBuilder
    private var playerView: some View {
        ZStack {

            Color.black

//            if let playbackitem = manager.playbackItem {
//                VLCVideoPlayer(configuration: playbackitem.vlcConfiguration)
//                    .proxy(vlcUIProxy)
//                    .onTicksUpdated { ticks, _ in
//
//                        guard manager.state != .initial || manager.state != .loadingItem else { return }
//
//                        let newSeconds = ticks / 1000
//                        let newProgress = CGFloat(newSeconds) / CGFloat(manager.item.runTimeSeconds)
//
//                        // set scrubbed seconds instead, which will be communicated
//                        // to the manager elsewhere if not scrubbing
//
//                        if !isScrubbing {
//                            scrubbedProgress.seconds = newSeconds
//                            scrubbedProgress.progress = newProgress
//                        }
//                    }
//                    .onStateUpdated { state, _ in
//                        switch state {
//                        case .buffering, .esAdded, .opening:
//                            manager.send(.buffer)
//                        case .ended, .stopped:
//                            manager.send(.ended)
//                        case .error:
//                            // TODO: localize
//                            manager.send(.error(.init("Unable to perform playback")))
//                        case .playing:
//                            manager.send(.play)
//                        case .paused:
//                            manager.send(.pause)
//                        }
//                    }
//            }
//                .debugOverlay()

            VideoPlayer.Overlay()
                .environment(\.safeAreaInsets, $safeAreaInsets)
        }
        .videoPlayerKeyCommands(
            gestureStateHandler: gestureStateHandler,
            updateViewProxy: updateViewProxy
        )
        .environmentObject(manager)
        .environmentObject(scrubbedProgress)
        .environmentObject(vlcUIProxy)
        .environment(\.aspectFilled, $isAspectFilled)
        .environment(\.isPresentingOverlay, $isPresentingOverlay)
        .environment(\.isScrubbing, $isScrubbing)
        .environment(\.playbackSpeed, $playbackSpeed)
    }

    // MARK: body

    var body: some View {

        let _ = Self._printChanges()

        playerView
            .navigationBarHidden()
            .statusBarHidden()
            .ignoresSafeArea()
            .onChange(of: audioOffset) { newValue in
                vlcUIProxy.setAudioDelay(.ticks(newValue))
            }
            .onChange(of: isAspectFilled) { newValue in
                UIView.animate(withDuration: 0.2) {
                    vlcUIProxy.aspectFill(newValue ? 1 : 0)
                }
            }
//        .onChange(of: isGestureLocked) { newValue in
//            if newValue {
//                updateViewProxy.present(systemName: "lock.fill", title: "Gestures Locked")
//            } else {
//                updateViewProxy.present(systemName: "lock.open.fill", title: "Gestures Unlocked")
//            }
//        }
            .onChange(of: isScrubbing) { isScrubbing in
                guard !isScrubbing else { return }

                vlcUIProxy.setTime(.seconds(scrubbedProgress.seconds))
            }
            .onChange(of: scrubbedProgress.progress) { progress in
                guard !isScrubbing else { return }

                scrubbedProgress.seconds = Int(progress * CGFloat(manager.item.runTimeSeconds))
            }
            .onChange(of: subtitleColor) { newValue in
                vlcUIProxy.setSubtitleColor(.absolute(newValue.uiColor))
            }
            .onChange(of: subtitleFontName) { newValue in
                vlcUIProxy.setSubtitleFont(newValue)
            }
            .onChange(of: subtitleOffset) { newValue in
                vlcUIProxy.setSubtitleDelay(.ticks(newValue))
            }
            .onChange(of: subtitleSize) { newValue in
                vlcUIProxy.setSubtitleSize(.absolute(24 - newValue))
            }
            .onReceive(manager.events) { @MainActor event in
                switch event {
                case .playbackStopped:
                    vlcUIProxy.stop()
                    router.dismissCoordinator()
                case let .playNew(playbackItem: item):
                    isAspectFilled = false
                    audioOffset = 0
                    subtitleOffset = 0

                    let seconds: Int

                    switch item.vlcConfiguration.startTime {
                    case let .ticks(value):
                        seconds = value / 1000
                    case let .seconds(value):
                        seconds = value
                    }

                    let progress = CGFloat(seconds) / CGFloat(item.baseItem.runTimeSeconds)

                    scrubbedProgress.progress = progress
                    scrubbedProgress.seconds = seconds

                    vlcUIProxy.playNewMedia(item.vlcConfiguration)
                }
            }
            .trackingSize($contentSize, $safeAreaInsets)
            .onChange(of: safeAreaInsets) { _ in
                print("top -", safeAreaInsets)
            }
    }
}

// MARK: init

extension VideoPlayer {

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {

        let manager = VideoPlayerManager(item: item, mediaSource: mediaSource)
        let videoPlayerProxy = VLCVideoPlayerProxy()
        let vlcUIProxy = VLCVideoPlayer.Proxy()

        videoPlayerProxy.vlcUIProxy = vlcUIProxy
        manager.proxy = videoPlayerProxy

        self.init(
            manager: manager,
            vlcUIProxy: vlcUIProxy
        )
    }

    init(item: VideoPlayerPlaybackItem) {
        let manager = VideoPlayerManager(playbackItem: item)
        let videoPlayerProxy = VLCVideoPlayerProxy()
        let vlcUIProxy = VLCVideoPlayer.Proxy()

        videoPlayerProxy.vlcUIProxy = vlcUIProxy
        manager.proxy = videoPlayerProxy

        self.init(
            manager: manager,
            vlcUIProxy: vlcUIProxy
        )
    }
}

#Preview {
    VideoPlayer(
        item: .init(
            baseItem: .init(name: "Top Gun Maverick"),
            mediaSource: .init(),
            playSessionID: "",
            url: URL(string: "/")!
        )
    )
}

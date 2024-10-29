//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: bar color default to style
// TODO: remove compact buttons?
// TODO: capsule scale on editing
// TODO: possible issue with runTimeSeconds == 0
// TODO: live tv
// TODO: scrubbing with preview view
//       - move to overlay instead?
//       - size
//       - location
//       - enabled

extension VideoPlayer.Overlay {

    struct PlaybackProgress: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.Overlay.sliderColor)
        private var sliderColor
        @Default(.VideoPlayer.Overlay.sliderType)
        private var sliderType

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.scrubbedSeconds)
        @Binding
        private var scrubbedSeconds: TimeInterval

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var capsuleSliderSize = CGSize.zero
        @State
        private var sliderFrame: CGRect = .zero
        
        private var progress: Double {
            scrubbedSeconds / manager.item.runTimeSeconds
        }
        
        private var previewXOffset: CGFloat {
            let p = sliderFrame.width * progress
            return clamp(p, min: 100, max: sliderFrame.width - 100)
        }

        @ViewBuilder
        private var capsuleSlider: some View {
            AlternateLayoutView {
                EmptyHitTestView()
                    .frame(height: 10)
                    .trackingSize($capsuleSliderSize)
            } content: {
                CapsuleSlider(
                    value: _scrubbedSeconds.wrappedValue,
                    total: manager.item.runTimeSeconds
                )
                .gesturePadding(30)
                .onEditingChanged { newValue in
                    isScrubbing = newValue
                }
                .foregroundStyle(sliderColor)
                .frame(maxWidth: isScrubbing ? nil : max(0, capsuleSliderSize.width - 30))
                .frame(height: isScrubbing ? 20 : 10)
                .trackingFrame($sliderFrame)
            }
            .animation(.linear(duration: 0.05), value: scrubbedSeconds)
            .frame(height: 10)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(
                value: _scrubbedSeconds.wrappedValue,
                total: manager.item.runTimeSeconds
            )
            .onEditingChanged { newValue in
                isScrubbing = newValue
            }
            .frame(height: 20)
        }

        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                switch sliderType {
                case .capsule: capsuleSlider
                case .thumb: thumbSlider
                }

                SplitTimeStamp()
                    .if(sliderType == .capsule) { view in
                        view.offset(y: isScrubbing ? 5 : 0)
                            .frame(maxWidth: isScrubbing ? nil : max(0, capsuleSliderSize.width - 30))
                    }
            }
            .disabled(manager.state == .loadingItem)
            .onChange(of: scrubbedSeconds) { newValue in
                if newValue == 0 || newValue == manager.item.runTimeSeconds {
                    UIDevice.impact(.light)
                }
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.5))
                    .aspectRatio(1.77, contentMode: .fill)
                    .frame(width: 200)
                    .position(x: previewXOffset, y: -75)
                    .isVisible(isScrubbing)
            }
            .animation(.bouncy(duration: 0.4, extraBounce: 0.1), value: isScrubbing)
        }
    }
}
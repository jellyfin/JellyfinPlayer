//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ScalingButtonStyle: ButtonStyle {

    private let animation: Animation
    private let scale: CGFloat

    init(scale: CGFloat = 0.8, animation: Animation = .linear(duration: 0.1)) {
        self.animation = animation
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .animation(.linear(duration: 0.4), value: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .background {
                Circle()
                    .foregroundStyle(Color.white)
                    .opacity(configuration.isPressed ? 0.5 : 0)
                    .frame(width: 100)
            }
            .animation(animation, value: configuration.isPressed)
    }
}

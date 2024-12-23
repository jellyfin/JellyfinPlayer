//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import Nuke
import SwiftUI

struct UserProfileImage: View {

    // MARK: - Inject Logger

    @Injected(\.logService)
    private var logger

    // MARK: - User Variables

    private let userId: String?
    private let source: ImageSource
    private let pipeline: ImagePipeline
    private let placeholder: any View

    // MARK: - Initializer

    init(
        userId: String?,
        source: ImageSource,
        pipeline: ImagePipeline = .Swiftfin.default,
        placeholder: any View = SystemImageContentView(systemName: "person.fill", ratio: 0.5)
    ) {
        self.userId = userId
        self.source = source
        self.pipeline = pipeline
        self.placeholder = placeholder
    }

    // MARK: - Body

    var body: some View {
        RedrawOnNotificationView(
            .didChangeUserProfile,
            filter: {
                $0 == userId
            }
        ) {
            ImageView(source)
                .pipeline(pipeline)
                .image {
                    $0.posterBorder(ratio: 1 / 2, of: \.width)
                }
                .placeholder { _ in
                    placeholder
                }
                .failure {
                    placeholder
                }
                .posterShadow()
                .aspectRatio(1, contentMode: .fill)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .onNotification(.didChangeUserProfile) { notificationUser in
            if notificationUser == userId {
                let imageURL = source.url

                guard let imageURL else {
                    logger.info("No user profile image URL found")
                    return
                }

                let request = ImageRequest(url: imageURL)

                pipeline.cache[request] = nil
                pipeline.configuration.dataCache?.removeData(for: imageURL.absoluteString)
                logger.info("Image removed from cache: \(imageURL.absoluteString)")
            }
        }
    }
}

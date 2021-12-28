/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Introspect
import JellyfinAPI
import SwiftUI

// Intermediary view for ItemView to set navigation bar settings
struct ItemNavigationView: View {
    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    var body: some View {
        ItemView(item: item)
            .navigationBarTitle("", displayMode: .inline)
    }
}

private struct ItemView: View {
    @EnvironmentObject var itemRouter: ItemCoordinator.Router

    @State private var orientation: UIDeviceOrientation = .unknown
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    private let viewModel: ItemViewModel

    init(item: BaseItemDto) {
        switch item.itemType {
        case .movie:
            self.viewModel = MovieItemViewModel(item: item)
        case .season:
            self.viewModel = SeasonItemViewModel(item: item)
        case .episode:
            self.viewModel = EpisodeItemViewModel(item: item)
        case .series:
            self.viewModel = SeriesItemViewModel(item: item)
        default:
            self.viewModel = ItemViewModel(item: item)
        }
    }

    @ViewBuilder
    var toolbarItemContent: some View {
        switch viewModel.item.itemType {
        case .season:
            Menu {
                Button {
                    (viewModel as? SeasonItemViewModel)?.routeToSeriesItem()
                } label: {
                    Label("Show Series", systemImage: "text.below.photo")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
            }
        case .episode:
            Menu {
                Button {
                    (viewModel as? EpisodeItemViewModel)?.routeToSeriesItem()
                } label: {
                    Label("Show Series", systemImage: "text.below.photo")
                }
                Button {
                    (viewModel as? EpisodeItemViewModel)?.routeToSeasonItem()
                } label: {
                    Label("Show Season", systemImage: "square.fill.text.grid.1x2")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
            }
        default:
            EmptyView()
        }
    }

    var body: some View {
        Group {
            if hSizeClass == .compact && vSizeClass == .regular {
                ItemPortraitMainView()
                    .environmentObject(viewModel)
            } else {
                ItemLandscapeMainView()
                    .environmentObject(viewModel)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarItemContent
            }
        }
    }
}

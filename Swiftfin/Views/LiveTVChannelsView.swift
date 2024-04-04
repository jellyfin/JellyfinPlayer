//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Foundation
import JellyfinAPI
import SwiftUI

typealias LiveTVChannelViewProgram = (timeDisplay: String, title: String)

struct LiveTVChannelsView: View {

    @EnvironmentObject
    private var liveTVRouter: LiveTVCoordinator.Router
    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @StateObject
    var viewModel = LiveTVChannelsViewModel()

    @ViewBuilder
    private func channelCell(for channelProgram: LiveTVChannelProgram) -> some View {
        let channel = channelProgram.channel
        let currentProgramDisplayText = channelProgram.currentProgram?
            .programDisplayText(timeFormatter: viewModel.timeFormatter) ?? LiveTVChannelViewProgram(timeDisplay: "", title: "")
        let nextItems = channelProgram.programs.filter { program in
            guard let start = program.startDate else {
                return false
            }
            guard let currentStart = channelProgram.currentProgram?.startDate else {
                return false
            }
            return start > currentStart
        }

        LiveTVChannelItemWideElement(
            channel: channel,
            currentProgram: channelProgram.currentProgram,
            currentProgramText: currentProgramDisplayText,
            nextProgramsText: nextProgramsDisplayText(
                nextItems: nextItems,
                timeFormatter: viewModel.timeFormatter
            ),
            onSelect: { _ in
                guard let mediaSource = channel.mediaSources?.first else {
                    return
                }
                viewModel.stopScheduleCheckTimer()
                mainRouter.route(to: \.liveVideoPlayer, LiveVideoPlayerManager(item: channel, mediaSource: mediaSource))
            }
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.channelPrograms.isNotEmpty {
                CollectionVGrid(
                    viewModel.channelPrograms,
                    layout: .minWidth(250, itemSpacing: 16, lineSpacing: 4)
                ) { program in
                    channelCell(for: program)
                }
                .onAppear {
                    viewModel.startScheduleCheckTimer()
                }
                .onDisappear {
                    viewModel.stopScheduleCheckTimer()
                }
            } else {
                VStack {
                    Text(L10n.noResults)
                    Button {
                        viewModel.getChannels()
                    } label: {
                        Text(L10n.reload)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func nextProgramsDisplayText(nextItems: [BaseItemDto], timeFormatter: DateFormatter) -> [LiveTVChannelViewProgram] {
        var programsDisplayText: [LiveTVChannelViewProgram] = []
        for item in nextItems {
            programsDisplayText.append(item.programDisplayText(timeFormatter: timeFormatter))
        }
        return programsDisplayText
    }
}

private extension BaseItemDto {
    func programDisplayText(timeFormatter: DateFormatter) -> LiveTVChannelViewProgram {
        var timeText = ""
        if let start = self.startDate {
            timeText.append(timeFormatter.string(from: start) + " ")
        }
        var displayText = ""
        if let season = self.parentIndexNumber,
           let episode = self.indexNumber
        {
            displayText.append("\(season)x\(episode) ")
        } else if let episode = self.indexNumber {
            displayText.append("\(episode) ")
        }
        if let name = self.name {
            displayText.append("\(name) ")
        }
        if let title = self.episodeTitle {
            displayText.append("\(title) ")
        }
        if let year = self.productionYear {
            displayText.append("\(year) ")
        }
        if let rating = self.officialRating {
            displayText.append("\(rating)")
        }

        return LiveTVChannelViewProgram(timeDisplay: timeText, title: displayText)
    }
}

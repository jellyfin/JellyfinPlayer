//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import UIKit

final class HomeViewModel: ViewModel {
    
    @Injected(Container.userSession)
    private var userSession

    @Published
    var resumeItems: [BaseItemDto] = []
    @Published
    var hasNextUp: Bool = false
    @Published
    var hasRecentlyAdded: Bool = false
    @Published
    var librariesShowRecentlyAddedIDs: [String] = []
    @Published
    var libraries: [BaseItemDto] = []

    override init() {
        super.init()
        refresh()

        // Nov. 6, 2021
        // This is a workaround since Stinsen doesn't have the ability to rebuild a root at the time of writing.
        // See ServerDetailViewModel.swift for feature request issue
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
    }

    @objc
    private func didSignIn() {
//        for cancellable in cancellables {
//            cancellable.cancel()
//        }

        librariesShowRecentlyAddedIDs = []
        libraries = []
        resumeItems = []

        refresh()
    }

    @objc
    private func didSignOut() {
//        for cancellable in cancellables {
//            cancellable.cancel()
//        }
//
//        cancellables.removeAll()
    }

    @objc
    func refresh() {
        logger.debug("Refresh called.")

        refreshLibrariesLatest()
        refreshLatestAddedItems()
        refreshResumeItems()
        refreshNextUpItems()
    }

    // MARK: Libraries Latest Items

    private func refreshLibrariesLatest() {
        Task {
            let userViewsPath = Paths.getUserViews(userID: userSession.user.id)
            let response = try? await userSession.client.send(userViewsPath)
            
            guard let allLibraries = response?.value.items else {
                await MainActor.run {
                    self.libraries = []
                }
                
                return
            }
            
            let excludedLibraryIDs = await self.getExcludedLibraries()
            
            let libraries = allLibraries
                .filter({ $0.collectionType == "movies" || $0.collectionType == "tvshows" })
                .filter { library in
                    !excludedLibraryIDs.contains(where: { $0 == library.id ?? "" })
                }
            
            await MainActor.run {
                self.libraries = libraries
            }
        }
    }
    
    private func getExcludedLibraries() async -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try? await userSession.client.send(currentUserPath)
        
        return response?.value.configuration?.latestItemsExcludes ?? []
    }

    // MARK: Recently Added Items

    private func refreshLatestAddedItems() {
//        UserLibraryAPI.getLatestMedia(
//            userId: "123abc",
//            includeItemTypes: [.movie, .series],
//            limit: 1
//        )
//        .sink { completion in
//            switch completion {
//            case .finished: ()
//            case .failure:
//                self.hasRecentlyAdded = false
//                self.handleAPIRequestError(completion: completion)
//            }
//        } receiveValue: { items in
//            self.hasRecentlyAdded = items.count > 0
//        }
//        .store(in: &cancellables)
    }

    // MARK: Resume Items

    private func refreshResumeItems() {
        Task {
            let resumeParameters = Paths.GetResumeItemsParameters(
                limit: 20,
                fields: ItemFields.minimumCases,
                enableUserData: true
            )
            
            let request = Paths.getResumeItems(userID: userSession.user.id, parameters: resumeParameters)
            let response = try await userSession.client.send(request)
            
            guard let items = response.value.items else { return }
            
            await MainActor.run {
                self.resumeItems = items
            }
        }
        
//        ItemsAPI.getResumeItems(
//            userId: "123abc",
//            limit: 20,
////            fields: [
////                .primaryImageAspectRatio,
////                .seriesPrimaryImage,
////                .seasonUserData,
////                .overview,
////                .genres,
////                .people,
////                .chapters,
////            ],
//            enableUserData: true
//        )
//        .trackActivity(loading)
//        .sink(receiveCompletion: { completion in
//            switch completion {
//            case .finished: ()
//            case .failure:
//                self.resumeItems = []
//                self.handleAPIRequestError(completion: completion)
//            }
//        }, receiveValue: { response in
//            self.logger.debug("Retrieved \(String(response.items!.count)) resume items")
//
//            self.resumeItems = response.items ?? []
//        })
//        .store(in: &cancellables)
    }

    func markItemUnplayed(_ item: BaseItemDto) {
//        guard let itemID = item.id, resumeItems.contains(where: { $0.id == itemID }) else { return }
//
//        PlaystateAPI.markUnplayedItem(
//            userId: "123abc",
//            itemId: item.id!
//        )
//        .sink(receiveCompletion: { [weak self] completion in
//            self?.handleAPIRequestError(completion: completion)
//        }, receiveValue: { _ in
//            self.refreshResumeItems()
//            self.refreshNextUpItems()
//        })
//        .store(in: &cancellables)
    }
    
    func markItemPlayed(_ item: BaseItemDto) {
//        guard let itemID = item.id, resumeItems.contains(where: { $0.id == itemID }) else { return }
//
//        PlaystateAPI.markPlayedItem(
//            userId: "123abc",
//            itemId: itemID
//        )
//        .sink(receiveCompletion: { [weak self] completion in
//            self?.handleAPIRequestError(completion: completion)
//        }, receiveValue: { _ in
//            self.refreshResumeItems()
//            self.refreshNextUpItems()
//        })
//        .store(in: &cancellables)
    }

    // MARK: Next Up Items

    private func refreshNextUpItems() {
//        TvShowsAPI.getNextUp(
//            userId: "123abc",
//            limit: 1
//        )
//        .trackActivity(loading)
//        .sink(receiveCompletion: { completion in
//            switch completion {
//            case .finished: ()
//            case .failure:
//                self.hasNextUp = false
//                self.handleAPIRequestError(completion: completion)
//            }
//        }, receiveValue: { response in
//            self.hasNextUp = (response.items ?? []).count > 0
//        })
//        .store(in: &cancellables)
    }
}

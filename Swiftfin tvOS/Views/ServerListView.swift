//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreStore
import SwiftUI

struct ServerListView: View {

    @EnvironmentObject
    private var router: ServerListCoordinator.Router
    @ObservedObject
    var viewModel: ServerListViewModel

    @ViewBuilder
    private var listView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.servers, id: \.id) { server in
                    ServerButton(server: server)
                        .onSelect {
                            router.route(to: \.userList, server)
                        }
                        .padding(.horizontal, 100)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.remove(server: server)
                            } label: {
                                Label(L10n.remove, systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.top, 50)
        }
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private var connectToServerButton: some View {
        Button {
            router.route(to: \.connectToServer)
        } label: {
            L10n.connect.text
                .bold()
                .font(.callout)
                .frame(width: 300, height: 100)
                .background(Color.jellyfinPurple)
        }
        .buttonStyle(CardButtonStyle())
    }

    @ViewBuilder
    private var noServerView: some View {
        VStack(spacing: 50) {
            L10n.connectToJellyfinServerStart.text
                .frame(minWidth: 50, maxWidth: 500)
                .multilineTextAlignment(.center)
                .font(.body)

            connectToServerButton
        }
    }

    @ViewBuilder
    private var innerBody: some View {
        if viewModel.servers.isEmpty {
            noServerView
                .offset(y: -50)
        } else {
            listView
        }
    }

    var body: some View {
        innerBody
            .navigationTitle(L10n.servers)
            .if(!viewModel.servers.isEmpty) { view in
                view.toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            router.route(to: \.connectToServer)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .contextMenu {
                            Button {
                                router.route(to: \.basicAppSettings)
                            } label: {
                                L10n.settings.text
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchServers()
            }
    }
}

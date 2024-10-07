//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// TODO: refactor with socket implementation

final class ServerTaskObserver: ViewModel, Stateful, Identifiable {

    enum Action: Equatable {
        case start
        case stop
        case stopObserving
        case addTrigger(TaskTriggerInfo)
        case removeTrigger(TaskTriggerInfo)
    }

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
        case running
        case updated
    }

    @Published
    final var state: State = .initial
    @Published
    private(set) var task: TaskInfo

    private var progressCancellable: AnyCancellable?
    private var cancelCancellable: AnyCancellable?

    var id: String? { task.id }

    init(task: TaskInfo) {
        self.task = task
    }

    func respond(to action: Action) -> State {
        switch action {
        case .start:
            if case .running = state {
                return state
            }

            progressCancellable = Task {
                do {
                    try await start()

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .running
        case .stop:
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            cancelCancellable = Task {
                do {
                    try await stop()

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        case .stopObserving:
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            return .initial
        case let .addTrigger(trigger):
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            cancelCancellable = Task {
                do {
                    try await addTrigger(newTrigger: trigger)
                    await MainActor.run {
                        self.state = .updated
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .updated
        case let .removeTrigger(trigger):
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            cancelCancellable = Task {
                do {
                    try await removeTrigger(deleteTrigger: trigger)
                    await MainActor.run {
                        self.state = .updated
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .updated
        }
    }

    private func start() async throws {
        guard let id = task.id else { return }

        let request = Paths.startTask(taskID: id)
        try await userSession.client.send(request)

        try await pollTaskProgress(id: id)
    }

    private func pollTaskProgress(id: String) async throws {
        while true {
            let request = Paths.getTask(taskID: id)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                self.task = response.value
            }

            guard response.value.state == .running || response.value.state == .cancelling else {
                break
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    private func stop() async throws {
        guard let id = task.id else { return }

        let request = Paths.stopTask(taskID: id)
        try await userSession.client.send(request)
    }

    private func addTrigger(newTrigger: TaskTriggerInfo) async throws {
        var updatedTriggers = task.triggers ?? []
        updatedTriggers.append(newTrigger)
        try await updateTriggers(updatedTriggers)
    }

    private func removeTrigger(deleteTrigger: TaskTriggerInfo) async throws {
        var updatedTriggers = task.triggers ?? []
        updatedTriggers.removeAll { $0 == deleteTrigger }
        try await updateTriggers(updatedTriggers)
    }

    private func updateTriggers(_ updatedTriggers: [TaskTriggerInfo]) async throws {
        guard let id = task.id else { return }
        let updateRequest = Paths.updateTask(taskID: id, updatedTriggers)
        try await userSession.client.send(updateRequest)

        let getTaskRequest = Paths.getTask(taskID: id)
        let response = try await userSession.client.send(getTaskRequest)

        await MainActor.run {
            self.task = response.value
        }
    }
}

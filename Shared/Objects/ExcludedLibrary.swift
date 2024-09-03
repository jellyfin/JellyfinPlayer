//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

struct ExcludedLibrary: Hashable, Identifiable, Storable {

    let id: String
    let name: String

    init(
        id: String,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}
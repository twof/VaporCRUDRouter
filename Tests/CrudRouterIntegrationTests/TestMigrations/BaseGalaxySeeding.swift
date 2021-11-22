//
//  File.swift
//  
//
//  Created by fnord on 12/29/19.
//

import FluentKit
import Foundation

struct BaseGalaxySeeding: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return BaseGalaxySeeding.galaxies.map {
            $0.save(on: database).transform(to: ())
        }.flatten(on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return BaseGalaxySeeding.galaxies.map {
            $0.delete(on: database).transform(to: ())
        }.flatten(on: database.eventLoop)
    }

    static let milkyWayId = UUID()
    static let galaxies = [Galaxy(id: milkyWayId, name: "Milky Way")]
}

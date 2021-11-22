//
//  File.swift
//  
//
//  Created by fnord on 12/29/19.
//

import FluentKit
import Foundation

struct ChildSeeding: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return ChildSeeding.planets.map { planet in
            planet
                .save(on: database)
                .transform(to: ())
        }.flatten(on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return ChildSeeding.planets.map {
            $0.delete(on: database).transform(to: ())
        }.flatten(on: database.eventLoop)
    }

    static let earthId = UUID()
    static var planets: [Planet] {
        [Planet(id: earthId, name: "Earth", galaxyID: BaseGalaxySeeding.milkyWayId)]
    }
}

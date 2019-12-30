//
//  File.swift
//  
//
//  Created by fnord on 12/29/19.
//

import FluentKit

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
    
    static let planets = [Planet(id: 1, name: "Earth", galaxyID: 1)]
}

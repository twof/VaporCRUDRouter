//
//  File.swift
//  
//
//  Created by fnord on 12/29/19.
//

import FluentSQLiteDriver
import Fluent
import XCTVapor

struct TestSeeding: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return TestSeeding.galaxies.map {
            $0.save(on: database).transform(to: ())
        }.flatten(on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return TestSeeding.galaxies.map {
            $0.delete(on: database).transform(to: ())
        }.flatten(on: database.eventLoop)
    }
    
    static let galaxies = [Galaxy(name: "Milky Way")]
}

func configure(_ app: Application) throws {
    // Serves files from `Public/` directory
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure SQLite database
    app.databases.use(.sqlite(file: "db.sqlite"), as: .sqlite)

    // Configure migrations
    app.migrations.add(GalaxyMigration())
    app.migrations.add(PlanetMigration())
    app.migrations.add(PlanetTagMigration())
    app.migrations.add(TagMigration())
    app.migrations.add(TestSeeding())
}

final class CrudRouteResponseTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        app = Application()
        try! configure(app)
    }
    
    func testBase() throws {
        app.crud(register: Galaxy.self)
        
        do {
            try app.testable().test(.GET, "/galaxy", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Galaxy].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Milky Way")
                XCTAssert(decoded[0].id == 1)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }

    static var allTests = [
        ("testPublicable", testPublicable),
    ]
}

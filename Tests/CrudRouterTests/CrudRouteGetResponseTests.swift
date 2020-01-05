//
//  File.swift
//  
//
//  Created by fnord on 12/29/19.
//

import FluentSQLiteDriver
import Fluent
import XCTVapor

final class CrudRouteGetResponseTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        app = Application()
        try! configure(app)
        
        try! app.migrator.setupIfNeeded().wait()
        try! app.migrator.prepareBatch().wait()
    }
    
    override func tearDown() {
        super.tearDown()
        
        try! app.migrator.revertAllBatches().wait()
    }
    
    func testGetBase() throws {
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
    
    func testGetChildren() throws {
        app.crud(register: Galaxy.self) { (controller) in
            controller.crud(children: \.$planets)
        }
        
        do {
            try app.testable().test(.GET, "/galaxy", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Galaxy].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Milky Way")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.GET, "/galaxy/1/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testGetParents() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(parent: \.$galaxy)
        }
        
        do {
            try app.testable().test(.GET, "/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.GET, "/planet/1/galaxy", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Galaxy.self, from: bodyBuffer)
                
                XCTAssert(decoded.name == "Milky Way")
                XCTAssert(decoded.id == 1)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testGetSiblings() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(siblings: \.$tags)
        }
        
        app.crud(register: Tag.self) { controller in
            controller.crud(siblings: \.$planets)
        }
        
        do {
            try app.testable().test(.GET, "/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.GET, "/tag", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Tag].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Life-Supporting")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.GET, "/planet/1/tag", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Tag].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Life-Supporting")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.GET, "/tag/1/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    private func configure(_ app: Application) throws {
        // Serves files from `Public/` directory
        // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        // Configure SQLite database
        app.databases.use(.sqlite(), as: .sqlite)

        // Configure migrations
        app.migrations.add(GalaxyMigration())
        app.migrations.add(PlanetMigration())
        app.migrations.add(PlanetTagMigration())
        app.migrations.add(TagMigration())
       
        app.migrations.add(BaseGalaxySeeding())
        app.migrations.add(ChildSeeding())
        app.migrations.add(SiblingSeeding())
    }

    static var allTests = [
        ("testPublicable", testGetBase),
    ]
}

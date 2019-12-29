import XCTest
@testable import CrudRouter
import Vapor
import FluentSQLiteDriver
import Fluent
import XCTVapor

extension PathComponent {
    var stringComponent: String {
        switch self {
        case .constant(let val):
            return val
        case .parameter(let val):
            return ":\(val)"
        default:
            return "all"
        }
    }
}

//extension Array where Element: Model {
//    func save(on conn: Database) -> EventLoopFuture<[Element]> {
//
//        return conn.transaction(on: conn) { (dbConn) -> EventLoopFuture<[Element]> in
//            return self.map { $0.save(on: dbConn) }.flatten(on: dbConn)
//        }
//    }
//
//    func delete(on conn: Element.Database.Connection) -> EventLoopFuture<[Element]> {
//        let databaseIdentifier = Element.defaultDatabase!
//
//        return conn.transaction(on: databaseIdentifier) { (dbConn) -> EventLoopFuture<[Element]> in
//            return self.map { element in
//                return element.delete(on: dbConn).transform(to: element)
//                }.flatten(on: dbConn)
//        }
//    }
//
//    func create(on conn: Element.Database.Connection) -> EventLoopFuture<[Element]> {
//        let databaseIdentifier = Element.defaultDatabase!
//
//        return conn.transaction(on: databaseIdentifier) { (dbConn) -> EventLoopEventLoopFuture<[Element]> in
//            return self.map { $0.create(on: dbConn) }.flatten(on: dbConn)
//        }
//    }
//}


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

func configure(_ app: inout Application) throws {
    app.provider(FluentProvider())

    // Register middleware
    app.register(extension: MiddlewareConfiguration.self) { middlewares, app in
        // Serves files from `Public/` directory
        // middlewares.use(app.make(FileMiddleware.self))
    }
    
    app.databases.sqlite(
        configuration: .init(storage: .connection(.memory)),
        threadPool: app.make(),
        poolConfiguration: app.make(),
        logger: app.make(),
        on: app.make()
    )
    
    app.register(Migrations.self) { c in
        var migrations = Migrations()
        migrations.add(GalaxyMigration(), to: .sqlite)
        migrations.add(TestSeeding(), to: .sqlite)
        migrations.add(PlanetMigration(), to: .sqlite)
        migrations.add(PlanetTagMigration(), to: .sqlite)
        migrations.add(TagMigration(), to: .sqlite)
        return migrations
    }
    
    let migrator = app.make(Migrator.self)
    try migrator.setupIfNeeded().wait()
    try migrator.prepareBatch().wait()
}

func routes(_ router: RoutesBuilder) throws {
    router.crud(register: Galaxy.self) { controller in
        controller.crud(children: \.$planets)
    }
    router.crud(register: Planet.self) { controller in
        controller.crud(parent: \.$galaxy)
        controller.crud(siblings: \.$tags)
    }
    router.crud(register: Tag.self) { controller in
        controller.crud(siblings: \.$planets)
    }
}

extension Application {
//    static func testable(envArgs: [String]? = nil) throws -> Application {
//        let environment = Environment(name: "testing")
//        var app = Application(environment: environment)
//        try configure(&app)
//
//        return app
//    }

    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil) throws -> Response where T: Content {
        let responder = self.make(Responder.self)
        let request = Request(application: self, method: method, url: URI(path: path), on: self.make())
        return try responder.respond(to: request).wait()
    }

    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init()) throws -> Response {
        let emptyContent: EmptyContent? = nil
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
    }

    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: C? = nil, decodeTo type: T.Type) throws -> T where C: Content, T: Decodable {
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: data)
        return try response.content.decode(type)
    }

    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type) throws -> T where T: Content {
        let emptyContent: EmptyContent? = nil
        return try self.getResponse(to: path, method: method, headers: headers, data: emptyContent, decodeTo: type)
    }

    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders, data: T) throws where T: Content {
        _ = try self.sendRequest(to: path, method: method, headers: headers, body: data)
    }
}

struct EmptyContent: Content {}

final class CrudRouterTests: XCTestCase {

    func testBaseCrudRegistrationWithRouteName() throws {
        Application.
        
        app.crud("planets", register: Planet.self)

        XCTAssert(app.routes.all.isEmpty == false)
        XCTAssert(app.routes.all.count == 5)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planets"] })
        XCTAssert(paths.contains { $0 == ["GET", "planets", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planets"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planets", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planets", ":planetsID"] })
    }

    func testBaseCrudRegistrationWithDefaultRoute() throws {
        app.crud(register: Planet.self)

        XCTAssert(app.routes.all.isEmpty == false)
        XCTAssert(app.routes.all.count == 5)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })
    }

    func testPublicable() throws {
        app.crud(register: Galaxy.self)
        do {
            let resp = try app.sendRequest(to: "/galaxy", method: .GET)
            let decoded = try resp.content.decode([Galaxy].self)
            XCTAssert(decoded.count == 1)
            //            XCTAssert(resp.count == 1)
            //            XCTAssert(resp[0].nameAndId == "Milky Way 0")
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }

    static var allTests = [
        ("testBaseCrudRegistrationWithRouteName", testBaseCrudRegistrationWithRouteName),
        ("testBaseCrudRegistrationWithDefaultRoute", testBaseCrudRegistrationWithDefaultRoute),
        ("testPublicable", testPublicable),
    ]
}

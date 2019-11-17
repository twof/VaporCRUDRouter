import XCTest
@testable import CrudRouter
import Vapor
import FluentSQLite

extension PathComponent {
    var stringComponent: String {
        switch self {
        case .constant(let val), .parameter(let val):
            return val
        default:
            return "all"
        }
    }
}

extension Array where Element: Model, Element.Database: TransactionSupporting {
    func save(on conn: Element.Database.Connection) -> EventLoopFuture<[Element]> {
        let databaseIdentifier = Element.defaultDatabase!

        return conn.transaction(on: databaseIdentifier) { (dbConn) -> EventLoopEventLoopFuture<[Element]> in
            return self.map { $0.save(on: dbConn) }.flatten(on: dbConn)
        }
    }

    func delete(on conn: Element.Database.Connection) -> EventLoopFuture<[Element]> {
        let databaseIdentifier = Element.defaultDatabase!

        return conn.transaction(on: databaseIdentifier) { (dbConn) -> EventLoopEventLoopFuture<[Element]> in
            return self.map { element in
                return element.delete(on: dbConn).transform(to: element)
                }.flatten(on: dbConn)
        }
    }

    func create(on conn: Element.Database.Connection) -> EventLoopFuture<[Element]> {
        let databaseIdentifier = Element.defaultDatabase!

        return conn.transaction(on: databaseIdentifier) { (dbConn) -> EventLoopEventLoopFuture<[Element]> in
            return self.map { $0.create(on: dbConn) }.flatten(on: dbConn)
        }
    }
}


struct TestSeeding: SQLiteMigration {
    static let galaxies = [Galaxy(name: "Milky Way")]

    static func prepare(on conn: SQLiteConnection) -> EventLoopEventLoopFuture<Void> {
        return TestSeeding.galaxies.create(on: conn).transform(to: ())
    }

    static func revert(on conn: SQLiteConnection) -> EventLoopEventLoopFuture<Void> {
        return TestSeeding.galaxies.delete(on: conn).transform(to: ())
    }
}

func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Galaxy.self, database: .sqlite)
    migrations.add(model: Planet.self, database: .sqlite)
    migrations.add(model: PlanetTag.self, database: .sqlite)
    migrations.add(model: Tag.self, database: .sqlite)
    migrations.add(migration: TestSeeding.self, database: .sqlite)
    migrations.prepareCache(for: .sqlite)
    services.register(migrations)
}

func routes(_ router: Router) throws {
    router.crud(register: Galaxy.self) { controller in
        controller.crud(children: \.planets)
    }
    router.crud(register: Planet.self) { controller in
        controller.crud(parent: \.galaxy)
        controller.crud(siblings: \.tags)
    }
    router.crud(register: Tag.self) { controller in
        controller.crud(siblings: \.planets)
    }
}

func boot(_ app: Application) throws { }

extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing

        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }

        try configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)

        try boot(app)
        return app
    }

    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil) throws -> Response where T: Content {
        let headers = headers
        let responder = try self.make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        return try responder.respond(to: wrappedRequest).wait()
    }

    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init()) throws -> Response {
        let emptyContent: EmptyContent? = nil
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
    }

    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: C? = nil, decodeTo type: T.Type) throws -> T where C: Content, T: Decodable {
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: data)
        return try response.content.decode(type).wait()
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

    var app: Application!

    override func setUp() {
        //        try! Application.reset()
        app = try! Application.testable()
    }

    func testBaseCrudRegistrationWithRouteName() throws {
        let router = EngineRouter.default()

        router.crud("planets", register: Planet.self)

        XCTAssert(router.routes.isEmpty == false)
        XCTAssert(router.routes.count == 5)
        let paths = router.routes.map { $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planets"] })
        XCTAssert(paths.contains { $0 == ["GET", "planets", "int"] })
        XCTAssert(paths.contains { $0 == ["POST", "planets"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planets", "int"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planets", "int"] })
    }

    func testBaseCrudRegistrationWithDefaultRoute() throws {
        let router = EngineRouter.default()

        router.crud(register: Planet.self)

        XCTAssert(router.routes.isEmpty == false)
        XCTAssert(router.routes.count == 5)
        let paths = router.routes.map { $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", "int"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", "int"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", "int"] })
    }

    func testPublicable() throws {
        do {
            //            let resp = try app.getResponse(to: "/galaxy", method: .GET, decodeTo: [Galaxy.PublicGalaxy].self)
            let resp = try app.sendRequest(to: "/galaxy", method: .GET)
            XCTAssert(try resp.content.syncDecode([Galaxy].self).count == 1)
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

import FluentSQLite

struct PlanetTag: SQLitePivot {
    typealias Left = Planet
    typealias Right = Tag

    static var leftIDKey: LeftIDKey = \.planetID
    static var rightIDKey: RightIDKey = \.tagID

    var id: Int?
    var planetID: Int
    var tagID: Int
}

extension PlanetTag: ModifiablePivot {
    init(_ planet: Planet, _ tag: Tag) throws {
        planetID = try planet.requireID()
        tagID = try tag.requireID()
    }
}

extension PlanetTag: Migration { }

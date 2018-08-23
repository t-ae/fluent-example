import FluentSQLite
import FluentMySQL

public struct Message: SQLiteModel, Migration {
    public static let entity = "messages"
    
    public var id: Int?
    
    public var from_person_id: Int
    public var to_person_id: Int
    
    public var body: String
    
    public init(id: Int? = nil,
                from_person_id: Int,
                to_person_id: Int,
                body: String) {
        self.id = id
        self.from_person_id = from_person_id
        self.to_person_id = to_person_id
        self.body = body
    }
}

public struct MessageMySQL: MySQLModel, Migration {
    public static let entity = "messages"
    
    public var id: Int?
    
    public var from_person_id: Int
    public var to_person_id: Int
    
    public var body: String
    
    public init(id: Int? = nil,
                from_person_id: Int,
                to_person_id: Int,
                body: String) {
        self.id = id
        self.from_person_id = from_person_id
        self.to_person_id = to_person_id
        self.body = body
    }
}

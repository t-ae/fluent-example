import App
import Vapor
import FluentSQLite
import FluentMySQL
import XCTest

final class AppTests: XCTestCase {
    func testSQLite() throws {
        var config = Config.default()
        var env = try Environment.detect()
        var services = Services.default()
        try configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        
        let req = Request(using: app)
        
        var future = req.future()
        
        // Insert persons
        var person1 = Person(name: "Person 1")
        var person2 = Person(name: "Person 2")
        future = future.flatMap {
            map(to: Void.self,
                person1.save(on: req).map { person1 = $0 },
                person2.save(on: req).map { person2 = $0 }) { _,_ in
                    return
            }
        }
        
        // Insert message
        future = future.flatMap {
            let message = try Message(from_person_id: person1.requireID(), to_person_id: person2.requireID(), body: "body")
            return message.save(on: req).transform(to: $0)
        }
        
        // Create new decodable which has aliased fields.
        struct FromPerson: Decodable {
            var from_id: Int
            var from_name: String
        }
        
        // Fetch
        future = future.flatMap {_ in 
            req.databaseConnection(to: .sqlite).flatMap { (conn: SQLiteConnection) in
                // use column name aliases for from_persons
                conn.raw("""
                    SELECT messages.*,
                        from_persons.id AS "from_id",
                        from_persons.name AS "from_name",
                        to_persons.*
                    FROM messages
                    JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
                    JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
                    """).all().map { rows in
                        try rows.map { row -> (Message, FromPerson, Person) in
                            let msg = try conn.decode(Message.self, from: row, table: "messages")
                            let from = try conn.decode(FromPerson.self, from: row, table: "persons") // has original table name
                            let to = try conn.decode(Person.self, from: row, table: "persons") // has original table name
                            return (msg, from, to)
                        }
                }
                }
                .map { print($0) }
        }
        
        try future.wait()
    }
    
    func testMySQL() throws {
        var config = Config.default()
        var env = try Environment.detect()
        var services = Services.default()
        try configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        
        let req = Request(using: app)
        
        var future = req.future()
        
        // Insert persons
        var person1 = PersonMySQL(name: "Person 1")
        var person2 = PersonMySQL(name: "Person 2")
        future = future.flatMap {
            map(to: Void.self,
                person1.save(on: req).map { person1 = $0 },
                person2.save(on: req).map { person2 = $0 }) { _,_ in
                    return
            }
        }
        
        // Insert message
        future = future.flatMap {
            let message = try MessageMySQL(from_person_id: person1.requireID(), to_person_id: person2.requireID(), body: "body")
            return message.save(on: req).transform(to: $0)
        }
        
        future = future.flatMap {
            MessageMySQL.query(on: req).all().map { print($0) }
        }
        
        // Fetch
        future = future.flatMap {_ in
            req.databaseConnection(to: .mysql).flatMap { (conn: MySQLConnection) in
                conn.raw("""
                    SELECT * FROM messages
                    JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
                    JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
                    """).all().map { rows in
                        try rows.map { row -> (MessageMySQL, PersonMySQL, PersonMySQL) in
                            let msg = try conn.decode(MessageMySQL.self, from: row, table: "messages")
                            let from = try conn.decode(PersonMySQL.self, from: row, table: "from_persons")
                            let to = try conn.decode(PersonMySQL.self, from: row, table: "to_persons")
                            return (msg, from, to)
                        }
                }
                }
                .map { print($0) }
        }
        
        try future.wait()
    }
}

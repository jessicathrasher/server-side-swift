import CouchDB
import Foundation
import HeliumLogger
import Kitura
import LoggerAPI
import SwiftyJSON
import KituraCORS

HeliumLogger.use()

let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false)
let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database("polls")

let router = Router()

//let options = Options(allowedOrigin: .origin("http://localhost:3000"), methods: ["GET","PUT"], allowedHeaders: ["Content-Type"], maxAge: 5)

let cors = CORS(options: Options())

//router.all("/cors", middleware: cors) // This didn't work although it was on the docs, the next line did
router.all(middleware: cors)


router.post("/polls/create", middleware: BodyParser())

// routes here
router.get("/polls/list") {
    request, response, next in
    defer { next() }
    
    // looks async but is sync
    database.retrieveAll(includeDocuments: true) { docs, error in
        if let error = error {
            let errorMessage = error.localizedDescription
            
            let status = ["status": "error", "message": errorMessage]
            let result = ["result": status]

            let json = JSON(result)
            response.status(.internalServerError).send(json: json)
        } else {
            
            let status = ["status": "ok"]
            var polls = [[String: Any]]()
            
            if let docs = docs {
                for document in docs["rows"].arrayValue {
                    var poll = [String: Any]()
                    poll["id"] = document["id"].stringValue
                    poll["title"] = document["doc"]["title"].stringValue
                    
                    poll["option1"] = document["doc"]["option1"].stringValue
                    poll["option2"] = document["doc"]["option2"].stringValue

                    poll["votes1"] = document["doc"]["votes1"].intValue
                    poll["votes2"] = document["doc"]["votes2"].intValue
                    
                    polls.append(poll)
                }
            }
            
            let result: [String: Any] = ["result": status, "polls": polls]
            let json = JSON(result)
            
            response.status(.OK).send(json: json)
        }
    }
}

router.post("/polls/delete/:pollid") {
    request, response, next in
    defer { next() }

    guard let poll = request.parameters["pollid"] else {
        try response.status(.badRequest).end()
        return
    }
    
    database.retrieve(poll) { doc, error in
        
        if let error = error {
            let errorMessage = error.localizedDescription
            
            let status = ["status": "error", "message": errorMessage]
            let result = ["result": status]
            
            let json = JSON(result)
            response.status(.forbidden).send(json: json) // can be something other than forbidden
        } else if let doc = doc {
            
            let rev = doc["_rev"].stringValue
            
            database.delete(poll, rev: rev, failOnNotFound: false) { error in
                let status = ["status": "ok"]
                let result = ["result": status]
                let json = JSON(result)
                response.status(.OK).send(json: json)
            }
        }
    }
}

router.post("/polls/create") {
    request, response, next in
    defer { next() }
    
    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .urlEncoded(let body) = values else {
        try response.status(.badRequest).end()
        return
    }

    let fields = ["title", "option1", "option2"]
    var poll = [String: Any]()
    
    for field in fields {
        
        if let value = body[field]?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if value.characters.count > 0 {
                poll[field] = value
                continue
            }
        }
        try response.status(.badRequest).end()
        return
    }

    poll["votes1"] = 0
    poll["votes2"] = 0
    let json = JSON(poll)
    
    // looks async but really isn't (callback confusing name) - id, rev#, the new doc, error
    database.create(json) { id, rev, doc, error in
        if let id = id {
            let status = ["status": "ok", "id":id]
            let result = ["result": status]
            let json = JSON(result)
            response.status(.OK).send(json: json)
        } else {
            let errorMessage = error?.localizedDescription ?? "Unknown error" // nil coalescing 
            let status = ["status": "error", "errorMessage": errorMessage]
            let result = ["result": status]
            let json = JSON(result)
            response.status(.internalServerError).send(json: json)
        }
    }
}

router.post("/polls/vote/:pollid/:option") {
    request, response, next in
    defer { next() }
    
    guard let poll = request.parameters["pollid"], let option = request.parameters["option"] else {
        try response.status(.badRequest).end()
        return
    }
    
    database.retrieve(poll) { doc, error in
        
        if let error = error {
            let errorMessage = error.localizedDescription
            
            let status = ["status": "error", "message": errorMessage]
            let result = ["result": status]
            
            let json = JSON(result)
            response.status(.forbidden).send(json: json) // can be something other than forbidden
        } else if let doc = doc {
            
            let id = doc["_id"].stringValue
            let rev = doc["_rev"].stringValue
            
            var newDocument = doc
            
            if option == "1" {
                newDocument["votes1"].intValue += 1
            } else {
                newDocument["votes2"].intValue += 1
            }
            
            database.update(id, rev: rev, document: newDocument) { rev, doc, error in
                if let error = error {
                    let status = ["status": "error"]
                    let result = ["result": status]
                    let json = JSON(result)
                    
                    response.status(.conflict).send(json: json)
                } else {
                    let status = ["status": "ok"]
                    let result = ["result": status]
                    let json = JSON(result)
                    response.status(.OK).send(json: json)
                }
            }
        }
    }
}


Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

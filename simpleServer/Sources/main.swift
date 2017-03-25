import HeliumLogger
import Kitura

HeliumLogger.use()

let router = Router()

router.post("/employees/add", middleware: BodyParser())
router.post("/employees/edit", middleware: BodyParser())

router.post("/employees/add") {
    request, response, next in
    
    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .urlEncoded(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    
    guard let name = body["name"] else { return }
    response.send("Adding new employee \(name)")
    next()
}

router.get("/platforms") {
    request, response, next in
    
    guard let name = request.queryParameters["name"] else {
        try response.status(.badRequest).end()
        return
    }
    
    response.send("Loading the \(name) platform...")
    next()
}

router.post("/employees/edit") {
    request, response, next in

    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .json(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    
    if let name = body["name"].string {
        response.send("Edited employee \(name)")
    }
    
    next()
}

router.get("/games/:name") {
    request, response, next in
    defer { next() }
    
    guard let name = request.parameters["name"] else { return }
    
    response.send("Let's play the \(name) game")
}

router.route("/test")
    .get() {
        request, response, next in
        defer { next() }
        response.send("Hello")
    }.post() {
        request, response, next in
        defer { next() }
        response.send("World")
    }


//router.get("/search/([0-9]+)/([A-Za-z]+)") {
// name the parameters, then can be accessed the same way
//}

Kitura.addHTTPServer(onPort: 8091, with: router)
Kitura.run()

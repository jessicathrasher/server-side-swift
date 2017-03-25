import HeliumLogger
import Kitura
import KituraStencil
import LoggerAPI


let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())
HeliumLogger.use()

let bios = [
    "kirk": "My name is James Kirk and I love snakes.",
    "picard": "My name is Jean-Luc and I love fish.",
    "archer": "My name is Jonathan and I love beagles.",
    "janeway": "My name is Katherine and I want to hug every hamster"
]

router.all("/static", middleware: StaticFileServer())


router.get("/") {
    request, response, next in
    defer { next() }
    try response.render("home", context: [:])
}

router.get("/staff") {
    request, response, next in
    defer { next() }
    
    var context = [String: Any]()

    context["people"] = bios.keys.sorted()
    
    try response.render("staff", context: context)
}


router.get("/staff/:name") {
    request, response, next in
    defer { next() }
    
    guard let name = request.parameters["name"] else { return }
    
    var context = [String: Any]()
    
    if let bio = bios[name] {
        context["name"] = name
        context["bio"] = bio
    }
    
    context["people"] = bios.keys.sorted()
    
    try response.render("staff", context: context)
}

router.get("/contact") {
    request, response, next in
    defer { next() }
    try response.render("contact", context: [:])
}

Kitura.addHTTPServer(onPort: 8091, with: router)
Kitura.run() // Never returns, keeps running until we kill it

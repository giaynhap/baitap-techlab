 
enum NewsElementTextStyle {
  case normal
  case bold
  case italic
  case tn
  case note
  case boldItalic
}

enum NewsElementType {
  case text
  case image
  case video
  case table
  case br
  case webview
  case group
  
}

 // html element
protocol NewsHtmlElementProtocol {
  var endTextNode: Bool {get}
  var textNode: Bool {get}
  var text: String {get}
  var tag: String {get}
  var elementChildren: [NewsHtmlElementProtocol] {get }
}

// display element
protocol NewsContentElementProtocol {
  var index: Int {get set}
  init?(_ element : Any , parentStyle: NewsElementTextStyle? )
  var type: NewsElementType {get}
}
 protocol NewsContentTextElementProtocol {
  var content: String? {get set}
  var style: NewsElementTextStyle {get set}
 }
 
 protocol NewsContentGroupElementProtocol {
  var attr: NSAttributedString? {get set}
  var children: [NewsContentElementProtocol]? {get set}
 }

 
 protocol NewsContentImageElementProtocol {
  var image: Any? {get set}
  var url: String? {get set}
  var width: CGFloat {get set}
  var height: CGFloat {get set}
 }
 
 protocol NewsContentTableElementProtocol {
  var attr: NSAttributedString? {get set}
 }
 
 protocol NewsContentVideoElementProtocol : NewsContentImageElementProtocol {
  
 }
 

 

 // display element - html
protocol NewsContentHtmlElementProtocol {
  var tag: String? {get}
}

 //strategy
protocol NewsContentParserProtocol {
  func parse( _ data: String)
  var result:[NewsContentElementProtocol]? {get set}
}

  
 extension TFHppleElement: NewsHtmlElementProtocol {
   
   var endTextNode: Bool {
     return self.children.count <= 1 || self.isTextNode()
   }
   
   var textNode: Bool {
     return self.isTextNode()
   }
   
   var text: String {
     return (self.isTextNode() ? self.content : self.text()) ?? ""
   }
   
   var tag: String {
     return self.tagName ?? ""
   }
   
   var elementChildren: [NewsHtmlElementProtocol] {
     return self.children.map { (m) -> NewsHtmlElementProtocol in
       return m as! NewsHtmlElementProtocol
     }
   }
 }

  
 
struct NewParserException: Error, LocalizedError {
     let errorDescription: String?

     init(_ description: String) {
         errorDescription = description
     }
 }

 //test
 protocol NewsContentParserOuputProtocol {
  func getResult<T>(elements: [NewsContentElementProtocol]) -> T
 }

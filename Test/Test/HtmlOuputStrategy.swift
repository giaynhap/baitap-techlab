//
//  HtmlOuputStrategy.swift
//  Test
//
//  Created by NuocLoc on 06/06/2021.
//

import Foundation

class TextHtmlElementFactory {
  class func getHtmlBy(element: NewsContentTextElementProtocol) -> String {
    switch element.style {
    case .bold:
      return String(format:"<b>%@</b>",element.content ?? "")
    case .italic:
      return String(format:"<i>%@</i>",element.content ?? "")
    case .boldItalic:
      return String(format:"<b><i>%@</i></b>",element.content ?? "")
    default:
      return element.content ?? ""
    }
  }
}

class HtmlOutputStrategy: NewsContentParserOuputProtocol {
  func getResult<String>(elements: [NewsContentElementProtocol]) -> String {
    var output = ""
    
    for element in elements {
      if let textElement = element as? NewsContentTextElementProtocol {
        output += Swift.String(format:"<p>%@</p>", TextHtmlElementFactory.getHtmlBy(element: textElement))
       
      } else if let groupElement = element as? NewsContentGroupElementProtocol  , let children = groupElement.children {
        output += "<p>"
        for e in children {
          output += " "+TextHtmlElementFactory.getHtmlBy(element: e as! NewsContentTextElementProtocol)
        }
        output += "</p>"
      } else if let imageElement = element as? NewsContentImageElementProtocol {
        output += "<img src=\""+(imageElement.url ?? "")+"\"/>"
      } else if let videoElement = element as? NewsContentVideoElementProtocol {
        output += "<video src=\""+(videoElement.url ?? "")+"\"/>"
      }
      
    }
    return output as! String
  }
  
  
}

//
//  NewsPaserContent.swift
//  Test
//
//  Created by NuocLoc on 06/06/2021.
//

import Foundation


class TextTagElement: NewsContentElementProtocol, NewsContentTextElementProtocol , NewsContentHtmlElementProtocol {
  var type: NewsElementType = .text
  var index: Int  = 0
  var content: String?
  var style: NewsElementTextStyle = .normal
  var tag: String?
  
  var isEmpty : Bool {
    return content?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != true
  }
  required init?(_ element: Any, parentStyle: NewsElementTextStyle?) {
    guard  let elm = element as? NewsHtmlElementProtocol else {
      return
    }
    if !elm.endTextNode {
      return nil
    } 
    
    self.tag = elm.tag
  
    let text = elm.text
    if elm.textNode  && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
      
      return nil
    }
    
    self.tag = elm.tag
    self.content = text
    var style: NewsElementTextStyle = .normal
    style = NewsHtmlParseUtils.mergeStyle(style1: parentStyle ?? .normal, style2: NewsHtmlParseUtils.tagToStyle(elm.tag)) ?? .normal
    self.style = style
  }
  
  init(index: Int, tag: String, content: String, style: NewsElementTextStyle) {
    self.index = index
    self.content = content
    self.style = style
    self.tag = tag
  }
  
}
 
class ImageTagElement: NewsContentElementProtocol, NewsContentImageElementProtocol ,  NewsContentHtmlElementProtocol {
  var tag: String?
  var type: NewsElementType = .image
  var index: Int  = 0
  var image: Any?
  var url: String?
  var width: CGFloat = 0
  var height: CGFloat = 0
   
  required init?(_ element: Any, parentStyle: NewsElementTextStyle?) {
    /*
     ....
     */
  }
}
 
class VideoTagElement: NewsContentElementProtocol, NewsContentVideoElementProtocol , NewsContentHtmlElementProtocol {
  var tag: String?
  var type: NewsElementType = .video
  var index: Int  = 0
  var image: Any?
  var url: String?
  var width: CGFloat = 0
  var height: CGFloat = 0
  
  required init?(_ element: Any, parentStyle: NewsElementTextStyle?) {
    /*
     ....
     */
  }
}
  
class TableTagElement: NewsContentElementProtocol, NewsContentTableElementProtocol, NewsContentHtmlElementProtocol {
  var tag: String? 
  var type: NewsElementType = .table
  var index: Int  = 0
  var raw: String?
  var attr: NSAttributedString?
  
  required init?(_ element: Any, parentStyle: NewsElementTextStyle?) {
    /*
     ....
     */
  }
  
}
 
class GroupTagElement: NewsContentElementProtocol,NewsContentGroupElementProtocol, NewsContentHtmlElementProtocol {
  var tag: String?
  var type: NewsElementType = .group
  var index: Int  = 0
  var attr: NSAttributedString?
  var children: [NewsContentElementProtocol]?
  var raw: String {
    return children?.reduce("", { (result, m) -> String in
      guard let m2 = m as? TextTagElement else {
        return result
      }
      return result + " " + (m2.content ?? "")
    }) ?? ""
     
  }
  required init?(_ element: Any, parentStyle: NewsElementTextStyle?) {
    return nil
  }
  
  init(index: Int) {
    self.index = index
  }
  
}

class EmptyTagElement: NewsContentElementProtocol, NewsContentHtmlElementProtocol {
  var index: Int = 0
  var tag: String?
  var type: NewsElementType = .br
 
  required init?(_ element: Any, parentStyle: NewsElementTextStyle?) {
    return nil
  }
  
  init (type: NewsElementType = .br, tag: String = "br") {
    self.type  = type
    self.tag = tag
  }
  
}
 

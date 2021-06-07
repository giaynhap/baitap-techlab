//
//  NewsParser.swift
//  Test
//
//  Created by NuocLoc on 06/06/2021.
//

import Foundation
 
import AVKit
import AVFoundation

class NewsContentHtmlParser: NewsContentParserProtocol {
  var result: [NewsContentElementProtocol]?
  var factory = NewsContentElementFactory()
  
  func parse(_ data: String) {
    let content = String(format:"<div>%@</div>",data )
    nativeHtmlParse(content)
  }
  
  func nativeHtmlParse( _ data: String) {
    self.result =  [NewsContentElementProtocol]()
    let buff = data.data(using: .utf8)
    let doc:TFHpple = TFHpple(htmlData: buff)
   
    if let elements = doc.search(withXPathQuery: "//div" ), let element =  elements.first as? TFHppleElement {
      self.parseContent(element: element)
    }
    if let result = self.result{
      self.result = self.mergeElement(result)
    }
     
  }
  
  func parseContent(element: NewsHtmlElementProtocol, parentStyle: NewsElementTextStyle = .normal) {
     
    let tag = element.tag
    if let element = factory.getElement(element, parentStyle: parentStyle) {
      self.result?.append(element)
    } 
    let computedStyle = NewsHtmlParseUtils.mergeStyle(style1: NewsHtmlParseUtils.tagToStyle(tag), style2: parentStyle) ?? .normal
    
    if !element.endTextNode {
      
      let children = element.elementChildren
      for newChild in children {
        self.parseContent(element: newChild, parentStyle: computedStyle)
      }
      
    } else if let firstElement = element.elementChildren.first,  !firstElement.textNode {
      parseContent(element: firstElement, parentStyle: computedStyle)
    }
    
    if NewsHtmlParseUtils.isBlockTag(tag) {
      result?.append(factory.getBlockTagEnd(tag))
    }
  }
   
  public func checkGroupTag(_ element: GroupTagElement?) -> NewsContentElementProtocol? {
    guard let element = element, var children = element.children else {
      return nil
    }
    
    // loc bỏ breakLine và thẻ dữ liệu rỗng
    children = children.filter({ (m) -> Bool in
      guard let textNode = m as? TextTagElement else {
        return false
      }
      return textNode.type == .br || textNode.isEmpty
    })
     
    // group rỗng
    if children.count == 0 {
      return nil
    }
    
    // group chỉ có 1 phần tử?
    if children.count == 1, let first = children.first {
      return first
    }
    
    var elementStyle : NewsElementTextStyle?
    var isSingleStyle = true
    // kiểm tra xem group có đồng nhất style ko
    for child in children {
      guard let textNode = child as? TextTagElement else {
        continue
      }
      let style = textNode.style
      
      if elementStyle != nil && elementStyle != style  {
        isSingleStyle = false
        break
      }
      elementStyle = style
    }
    
    if !isSingleStyle {
      return element
    } else {
      // gộp dữ liệu lại thành 1 element nếu chỉ chứ đồng nhất 1 kiểu style
      let text = children.reduce("") { (result, content) -> String in
        guard let textNode = content as? TextTagElement else {
          return result
        }
        
        if result.isEmpty {
          return textNode.content ?? ""
        } else {
          return result + " " + (textNode.content ?? "")
        }
        
        return result
      }
      // tạo thẻ mới gộp
      let index = children.first?.index ?? 0
      let element = TextTagElement(index: index, tag: "group", content:text , style: elementStyle ?? .normal)
      return element
    }
  }
  
  
  public func mergeElement(_ elements: [NewsContentElementProtocol]) -> [NewsContentElementProtocol] {
    var result =  [NewsContentElementProtocol]()
    var newsItem: GroupTagElement?
   
    if let input =  self.result {
      print("[ x ] ===== input ====")
      for x in input{
        if let x2 = x as? TextTagElement {
          print(" [\(x2.tag!)] \(x2.content ?? "")  - \(x2.style)")
        }
      }
    }
    
    for element in elements {
      guard let htmlElm = element as? NewsContentHtmlElementProtocol else {
        print("error")
        continue
      }
      
      let tag = htmlElm.tag ?? ""
       
      // tạo thành element khi gặp thẻ đóng
      if NewsHtmlParseUtils.isBreakLineTag(tag)
      || NewsHtmlParseUtils.isBlockTag(tag)
      || NewsHtmlParseUtils.isImageTag(tag)
      || NewsHtmlParseUtils.isVideoTag(tag)
      {
       
        if let item = checkGroupTag(newsItem) {
          result.append(item)
        }
        
        // chỉ đưa vào các thẻ có dữ liệu và không phải là dữ liệu xuống dòng
        // ngoại trừ thẻ xuống dòng
        
        if let text = element as? TextTagElement {
          if !text.isEmpty {
            result.append(element)
          }
        } else if NewsHtmlParseUtils.isBreakLineTag(tag) {
          result.append(element)
        } else {
          result.append(element)
        }
        
        newsItem = nil
        continue
      }
      
      // kiểm tra thêm vào group
      if newsItem == nil {
        newsItem = GroupTagElement(index: 0)
        newsItem?.children = [NewsContentElementProtocol]()
      }
     
      newsItem?.children?.append(element)
    }
    
    if let item = checkGroupTag(newsItem) {
      result.append(item)
    }
   
    print("[ x ] ===== output ====")
    for x in result{
      
      if let x2 = x as? TextTagElement {
        print(" [\(x2.tag!)] \(x2.content ?? "")  - \(x2.style)")
      } else if let x2 = x as? GroupTagElement {
        print(" [group] \(x2.raw)  ")
      }
    }
    
    return result
  }
}
  

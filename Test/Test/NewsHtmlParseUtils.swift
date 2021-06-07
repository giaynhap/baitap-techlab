//
//  NewsHtmlParseUtils.swift
//  MediaNews
//
//  Created by NuocLoc on 12/05/2021.
//

import Foundation



class NewsHtmlParseUtils {
  
 
  static let textTags = ["text","div","h4","h3","h2","h6","h5","h1","p","tn","strong","em","tn", "i" ,"b","br", "dd", "dt", "p", "h1", "h2", "h3", "h4", "h5", "span","ol"]
  static let skipTags = ["td","tr","tbody","thead"]
  static let boldTags = ["h1","h2","h3","h4","h5","b","strong"]
  static let noticTag = ["em"]
  static let blockTags = ["div","dd", "dt", "p", "h1", "h2", "h3", "h4", "h5","ol","h6","em"]
  
  static let webviewTags = ["iframe"]
  
  class func isTextTag(_ tag: String) -> Bool {
    return textTags.contains(tag)
  }
  
  class func isImageTag( _ tag: String) -> Bool {
    return tag == "img"
  }
  
  class func isVideoTag( _ tag: String) -> Bool {
    return tag == "video"
  }
  
  class func isTableTag( _ tag: String) -> Bool {
    return tag == "table"
  }
  
  class func isSkipTag( _ tag: String) -> Bool {
    return skipTags.contains(tag)
  }
  
  class func isBreakLineTag( _ tag: String) -> Bool {
    return tag == "br"
  }
  
  class func isBlockTag( _ tag: String) -> Bool {
    return blockTags.contains(tag) ||
    NewsHtmlParseUtils.isTableTag(tag) ||
      NewsHtmlParseUtils.isWebViewTag( tag )
  }
  
  class func isWebViewTag( _ tag: String ) -> Bool {
    return webviewTags.contains(tag)
  }
  
  class func tagToStyle( _ tag: String) -> NewsElementTextStyle {
    if boldTags.contains(tag) {
      return .bold
    }
    
    if tag == "i" {
      return .italic
    }
    
    if tag == "dd" {
      return .italic
    }
    
    if noticTag.contains(tag) {
      return .note
    }
    
    if tag == "tn" {
      return .tn
    }

    return .normal
    
  }
  
  class func mergeStyle(style1 : NewsElementTextStyle?, style2: NewsElementTextStyle?) -> NewsElementTextStyle? {
   
    guard let style1 = style1 else {
      return style2
    }
    
    guard let style2 = style2 else {
      return style1
    }
    
    if style1 == .normal {
      return style2
    }
    
    if style2 == .normal {
      return style1
    }
    
    if (style1 == .bold  && style2 == .italic) ||  style2 == .bold  && style1 == .italic {
      return .boldItalic
    }
        
    if style2 == .boldItalic || style1 == .boldItalic {
      return .boldItalic
    }
    
    // ưu tiên style mới
    return style2
    
  }
  
}

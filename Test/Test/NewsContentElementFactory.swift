//
//  NewsContentElementFactory.swift
//  Test
//
//  Created by NuocLoc on 06/06/2021.
//

import Foundation


class NewsContentElementFactory {
  
  func getElement(_ element: NewsHtmlElementProtocol, parentStyle: NewsElementTextStyle) -> NewsContentElementProtocol?{
    
    if NewsHtmlParseUtils.isTextTag(element.tag) {
     return TextTagElement(element, parentStyle: parentStyle)
    }
    
    if NewsHtmlParseUtils.isImageTag(element.tag) {
     return ImageTagElement(element, parentStyle: parentStyle)
    }
    
    if NewsHtmlParseUtils.isVideoTag(element.tag) {
     return VideoTagElement(element, parentStyle: parentStyle)
    }
    
    if NewsHtmlParseUtils.isTableTag(element.tag) {
     return TableTagElement(element, parentStyle: parentStyle)
    }
    
    /* 
     ....
     */
    
    
    return nil
    
  }
  
  func getBlockTagEnd( _ tag: String) -> NewsContentElementProtocol {
    return EmptyTagElement(type: .br, tag: tag)
  }
}

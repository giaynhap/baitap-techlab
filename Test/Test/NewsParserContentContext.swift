//
//  NewsContentContext.swift
//  Test
//
//  Created by NuocLoc on 06/06/2021.
//

import Foundation



class NewsParserContentContext {
 var parser: NewsContentParserProtocol?
 var onComplete: ( () -> Void)? = nil
  
  //test
  var output: NewsContentParserOuputProtocol?
 
 var result: [NewsContentElementProtocol]? {
   get {
     return parser?.result
   }
 }
 
 func parse( _ data: String, sync: Bool = false) throws {
  
  if parser == nil {
    throw NewParserException("Chưa chọn parser")
  }
  
  if sync {
     parser?.parse(data)
     onComplete?()
   } else {
     DispatchQueue.global(qos: .background).async { [weak self] in
       self?.parser?.parse(data)
       guard  let strongSelf = self else {
         return
       }
       strongSelf.onComplete?()
     }
   }
  
 }
  
  //test
  func getOuput<T>() -> T? {
    if let result = self.result {
      return output?.getResult(elements: result)
    } else {
      return nil
    }
  }
}

//
//  test.swift
//  TestCode
//
//  Created by NuocLoc on 06/06/2021.
//


import Foundation
import Kingfisher
import AVKit
import AVFoundation
import GoogleMobileAds
enum NewsElementTextStyle {
  case normal
  case bold
  case italic
  case tn
  case note
  case boldItalic
}

enum  NewsElementType {
  case text  (content: String, style: NewsElementTextStyle)
  case image (url: String, alt: String )
  case video (url: String, alt: String)
  case admob
  case sponsored
  case table(raw: String)
  case group
  case breakLine
  case webview(src: String)
}

class  NewsContentElementModel  {
  var index: Int = 0
  var tag: String = "p"
  var type: NewsElementType?
  var raw: String?
  var child: [NewsContentElementModel]?
  // custom
  var ad: AdsNativeViewModel?
  var sp: SponsoredModel?
  private var attrs: NSAttributedString?
  private var fontSize = 0
  fileprivate var isLoadResource = false
  fileprivate weak var _applyForView: NewsContentReloadCell?
  init(index: Int, type: NewsElementType){
    self.index = index
    self.type = type
    if NewsContentParser.isLoadMediaContent {
      if NewsContentParser.isAsyncLoadMediaContent {
        DispatchQueue.background.async { [weak self] in
          self?.checkLoadResource()
        }
      } else {
        self.checkLoadResource()
      }
    }
  }
   
  var resource: NewsContentResource?
  
  fileprivate func checkLoadResource(){
    switch type {
    case .image(let url, _):
      loadImageResource(url: url)
    case .video( let url, _):
      loadVideoResource(url: url)
    default:
      return
    }
  }
  
  func isTextNodeEmpty() -> Bool{
    if case .text(let content, _) = self.type {
      return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    return false
  }
  
  
  func isBreakLine() -> Bool {
    if case .breakLine = self.type {
      return true
    }
    return false
  }
  
  func loadImageResource(url: String, applyFor: NewsContentReloadCell? = nil ) {
    
    _applyForView = applyFor
    if isLoadResource {
      return
    }
    resource = NewsContentResource(thumb: nil, thumbUrl: url, width: 400, height: 300)
    isLoadResource = true
    if let image = loadImageFromUrl(url: url) {
      resource?.thumb = image
      resource?.width = image.size.width
      resource?.height = image.size.height
      if _applyForView != nil {
        DispatchQueue.main.async {
          self._applyForView?.reloadView()
        }
      }
    }
  }
  
  func loadVideoResource(url: String, applyFor: NewsContentReloadCell? = nil ) {
    _applyForView = applyFor
    if isLoadResource {
      return
    }
    isLoadResource = true
    resource  = NewsContentResource(thumb: nil, thumbUrl: url, width: 400, height: 300)
    
    if let image = loadImageFromVideoUrl(url: url) {
      resource?.thumb = image
      resource?.width = image.size.width
      resource?.height = image.size.height
    }
    print("video height \(resource?.width ?? 0)  \(resource?.height ?? 0)")
  }
  
  
  func loadImageFromUrl(url: String) -> UIImage? {
   
    let semaphore = DispatchSemaphore(value: 0)
    var image: UIImage? = nil
  
    url.loadImage { (result) in
      image = result
      semaphore.signal()
    }
    semaphore.wait()
    return image
  }
  
  func loadImageFromVideoUrl(url:String) -> UIImage? {
    
    guard let urlObj = URL(string: url) else {
      return nil
    }
    
    let asset:AVURLAsset! = AVURLAsset(url: urlObj, options:nil)
    let generate:AVAssetImageGenerator! = AVAssetImageGenerator(asset:asset)
    generate.appliesPreferredTrackTransform = true
    asset.resourceLoader.setDelegate(nil, queue: .main)
    
    do{
      let time = CMTime(value: 2, timescale: 1)
      let imgRef = try generate.copyCGImage(at: time, actualTime: nil)
      let image = UIImage(cgImage:imgRef)
      return image
    }catch (let e) {
      print("load \(url) error \(e)")
    }
    return nil
  }
  

  func getGroupTextRender(_ fontSize: Int) -> NSAttributedString? {
    
    if let attrs = self.attrs, fontSize == self.fontSize {
      return attrs
    }
    
    guard let children = self.child else {
      return nil
    }
    
    var isFirst = false
    let result = NSMutableAttributedString(string: "", attributes: nil)
    for child in children {
      if case .text(let content, let style) = child.type {
        var ops = [NSAttributedString.Key : Any]()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.25
        ops[.paragraphStyle] = paragraphStyle
        
        switch style {
        case .bold:
          ops [.font] = UIFont.appFontBold(ofSize: CGFloat(fontSize))
        case .italic:
          ops [.font] = UIFont.appFontItalic(ofSize: CGFloat(fontSize))
        case .tn:
          ops [.font] = UIFont.appFontItalic(ofSize: CGFloat(fontSize))
        case .boldItalic:
          ops [.font] = UIFont.appFontBoldItalic(ofSize: CGFloat(fontSize))
        default:
          ops [.font] = UIFont.appFontRegular(ofSize: CGFloat(fontSize))
        }
        
        if !isFirst {
          let attr = NSAttributedString(string:" \(content)", attributes: ops)
          result.append(attr)
        } else {
          isFirst = false
          let attr =  NSAttributedString(string:content, attributes: ops)
          result.append(attr)
        }
      }
    }
    
    self.attrs = result
    self.fontSize = fontSize

    return self.attrs
  }
  
}
struct NewsContentResource {
  var thumb: UIImage?
  var thumbUrl: String?
  var width: CGFloat
  var height: CGFloat
  
}


class NewsContentParser {
  var elementIndex = 0
  var elements: [NewsContentElementModel]!
  static var isLoadMediaContent = false
  static var isAsyncLoadMediaContent = false
  private init(){
    elements = [NewsContentElementModel]()
  }
  
  class func parse(html: String, completed: ( (NewsContentParser) -> Void )?){
    let parser = NewsContentParser()
    parser.parseContentNative(content: html){
      DispatchQueue.main.async {
        completed?(parser)
      }
    }
  }
  
  func parseContentNative(content str:String, success: @escaping () -> Void ) {
   
    if NewsRemoteConfig.shared.isUseBackupHtmlParser {
      print("[NewsContentElementModel] warning use v1 html parser" )
      parseContentNativeBackup(content: str, success: success)
      return
    }
    
    DispatchQueue.global(qos: .background).async {
      let data = str.data(using: .utf8)
      let doc:TFHpple = TFHpple(htmlData: data)
      self.elementIndex = 0
      self.elements.removeAll()
      if let elements = doc.search(withXPathQuery: "//div" ), let element =  elements.first as? TFHppleElement {
        self.parseContentElement(element)
      }
      self.elements = self.mergeElement(self.elements)
      success()
    }
  }
  
  
  func parseContentElement(_ child:TFHppleElement , parentStyle: NewsElementTextStyle? = nil) {
    //Parsed TEXT content
   // print("tag \(child.tagName)")
    let tag = child.tagName ?? ""
    if  NewsHtmlParseUtils.isTextTag(tag)
    {
      /*(1) khi gặp content thì mới parse ko thì tiếp tục nhảy phân tích bên trong*/
      if child.children.count <= 1 || child.isTextNode() {
       // print("tag \(child.tagName) - count \(child.children.count )")
        if let newElement =  parseText(element: child , index: elementIndex, parentStyle: parentStyle ) {
          newElement.tag = tag
          self.elements.append(newElement)
          elementIndex += 1
        }
      }
    }
    else if NewsHtmlParseUtils.isImageTag(tag)
    {
      if let newElement = self.parseImage(element: child, index: elementIndex) {
        newElement.tag = tag
        self.elements.append(newElement)
        elementIndex += 1
      }
    }
    else if NewsHtmlParseUtils.isVideoTag(tag)
    {
      if let newElement = parseVideo(element: child, index: elementIndex) {
        newElement.tag = tag
        self.elements.append(newElement)
        elementIndex += 1
      }
    }
    else if NewsHtmlParseUtils.isTableTag(tag)
    {
      let item = NewsContentElementModel.init(index: elementIndex, type: .table(raw: child.raw))
      item.tag = tag
      self.elements.append(item)
      elementIndex += 1
      return
    } else if NewsHtmlParseUtils.isBreakLineTag(tag)  {
      let item = NewsContentElementModel.init(index: elementIndex, type: .breakLine)
      item.tag = tag
      self.elements.append(item)
      elementIndex += 1
    }
    else if NewsHtmlParseUtils.isWebViewTag(tag)  {
      if let url = child.object(forKey: "src") {
        let item = NewsContentElementModel.init(index: elementIndex, type: .webview(src: url))
        item.tag = tag
        self.elements.append(item)
        elementIndex += 1
      }
      return
    }
    else if NewsHtmlParseUtils.isSkipTag(tag)  {
      return
    }
    
    /*(2) chỉ parse các node có 2 child trở về vì các node có 1 child là text node đã đươc parse ở 1*/
    if !child.isTextNode() && child.children.count > 1 {
      
      let backupStyle = mergeStyle(style1: NewsHtmlParseUtils.tagToStyle(tag), style2: parentStyle) ?? .normal
      
      for newChild in child.children {
        guard let element = newChild as? TFHppleElement else {
          continue
        }
        self.parseContentElement(element, parentStyle: backupStyle)
      }
    }
    /*(3)*/
    else if let element = child.children.first as? TFHppleElement , !element.isTextNode() {
      // trường hợp nếu không phải là text node thì mới parse vì có trường hợp thẻ <p><img/></p> ko có textnode nào nên chỉ có 1 element
      // nếu là text node vậy đã được parse từ vị trí (1)
      let backupStyle = mergeStyle(style1: NewsHtmlParseUtils.tagToStyle(tag), style2: parentStyle) ?? .normal
      self.parseContentElement(element, parentStyle: backupStyle)
    }
    
    if NewsHtmlParseUtils.isBlockTag(tag) {
      let item = NewsContentElementModel.init(index: elementIndex, type: .breakLine)
      item.tag = tag
      self.elements.append(item)
      elementIndex += 1
    }
    
  }
  
  func parseVideo(element child: TFHppleElement, index: Int) -> NewsContentElementModel? {
    
    if let url =  child.object(forKey: "db24h_src") {
      return NewsContentElementModel(index: index, type: .video(url: url, alt: ""))
    } else if let url =  child.object(forKey: "db24h_api") {
      if (url.count <= 0) {
        return nil
      }
      guard let requestUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) , let urlObj = URL(string: requestUrl) else {
        return nil
      }
      do {
        let jsonData =  try Data(contentsOf: urlObj)
        let videoUrl =  String(data: jsonData, encoding: .utf8) ?? ""
        return NewsContentElementModel(index: index, type: .video(url: videoUrl, alt: ""))
      } catch {
        return nil
      }
    }
    
    return nil
  }
  
  func parseImage(element child: TFHppleElement, index: Int) -> NewsContentElementModel? {
    if let url = child.object(forKey: "src") {
      let alt = child.object(forKey: "alt") ?? ""
      return NewsContentElementModel(index: index, type: .image(url: url, alt: alt))
    }
    return nil
  }
  
  func parseText(element child: TFHppleElement, index: Int, parentStyle: NewsElementTextStyle?) -> NewsContentElementModel? {
  
    var text = (child.isTextNode() ? child.content : child.text()) ?? ""
    //if text.count > 0 {
      text =  text.trimmingCharacters(in: .whitespacesAndNewlines)
      
     /* if text.count < 1 {
        return nil
      }
      */
      var style: NewsElementTextStyle = .normal
      
      style = mergeStyle(style1: parentStyle, style2: NewsHtmlParseUtils.tagToStyle(child.tagName)) ?? .normal
    
      let model =  NewsContentElementModel(index: index, type:.text(content: text, style: style))
      
      model.raw = child.raw
      return model
    /*}
    return nil*/
  }
  
  // hàm kiểm tra nội dung group
  public func checkGroupTag(_ element: NewsContentElementModel?) -> NewsContentElementModel? {
    
    // khử null
    guard let element = element, var children = element.child else {
      return nil
    }
    
    // loc bỏ breakLine và thẻ dữ liệu rỗng
    children = children.filter({ (m) -> Bool in
      if case .breakLine = m.type {
        return false
      }
      if m.isTextNodeEmpty() {
        return false
      } else {
        return true
      }
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
      if case .text(_, let style) = child.type {
        if elementStyle != nil && elementStyle != style  {
          isSingleStyle = false
          break
        }
        elementStyle = style
      }
    }
    
    if !isSingleStyle {
      return element
    } else {
      // gộp dữ liệu lại thành 1 element nếu chỉ chứ đồng nhất 1 kiểu style
      let text = children.reduce("") { (result, content) -> String in
        if case .text( let content, _) = content.type {
          if result.isEmpty {
            return content
          } else {
            return result + " " + content
          }
        }
        return result
      }
      // tạo thẻ mới gộp
      let index = children.first?.index ?? 0
      let element =  NewsContentElementModel(index: index, type: .text(content: text, style: elementStyle ?? .normal))
      element.tag = "group"
      return element
    }
  }
  
  public func mergeElement(_ elements: [NewsContentElementModel]) -> [NewsContentElementModel] {
    var result =  [NewsContentElementModel]()
    var newsItem: NewsContentElementModel?
    
    for element in elements {
      // tạo thành element khi gặp thẻ đóng
      if NewsHtmlParseUtils.isBreakLineTag(element.tag)
      || NewsHtmlParseUtils.isBlockTag(element.tag)
      || NewsHtmlParseUtils.isImageTag(element.tag)
      || NewsHtmlParseUtils.isVideoTag(element.tag)
      {
         
        if let item = checkGroupTag(newsItem) {
          result.append(item)
        }
        
        // chỉ đưa vào các thẻ có dữ liệu và không phải là dữ liệu xuống dòng
        // ngoại trừ thẻ xuống dòng
        if ( !element.isTextNodeEmpty() && !element.isBreakLine() )
            || NewsHtmlParseUtils.isBreakLineTag(element.tag)
        {
          result.append(element)
        }
        
        newsItem = nil
        continue
      }
      
      // kiểm tra thêm vào group
      if !element.isTextNodeEmpty() {
        if newsItem == nil {
          newsItem = NewsContentElementModel(index: 0, type: .group)
          newsItem?.child = [NewsContentElementModel]()
        }
        newsItem?.child?.append(element)
      }
    }
    
    if let item = checkGroupTag(newsItem) {
      result.append(item)
    }
     
    #if DEV
    print("[debug - tag] =======result=======")
    
    for element in result {
      if case .group = element.type {
        guard let childs = element.child else {
          print("[debug - tag] out  errror group")
          continue
        }
        for x in childs {
          print("[debug - tag] out child \(x.tag)")
        }
      } else {
        print("[debug - tag] out  \(element.tag)  \(element.type)")
      }
      
    }
    print("[debug - tag] =================")
    #endif
    
    return result
  }
  
  // hàm nối style
  func mergeStyle(style1 : NewsElementTextStyle?, style2: NewsElementTextStyle?) -> NewsElementTextStyle? {
   
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

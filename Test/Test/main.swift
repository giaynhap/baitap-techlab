//
//  main.swift
//  Test
//
//  Created by NuocLoc on 06/06/2021.
//

import Foundation
import Cocoa


var content = "<div><p>cong hoa <span>xa hoi chu nghia</span> <b>viet nam</b> </p></div><div>chu thuong<b>chu dam</b><i> chu nghien</i><p><b>chu dam trong p</b></p><p><b>chu dam trong p</b><i>chu nghiem p</i>chu thuong</p> <b><i>chu dam va nghien</i></b> <b> chu dam <i>chu dam va nghien</i></b> <p>123<p></p></p> <p></p><p></p></div>11111<div><p><p></p></p>a</div>"

let context = NewsParserContentContext()
context.parser = NewsContentHtmlParser() // parser Strategy
context.output = HtmlOutputStrategy() // hmtloutput Strategy
context.onComplete = {
  print("[Parser]  complete")
}

try context.parse(content,sync: true)

var output: String? = context.getOuput()
 
if let outputPath = Process().currentDirectoryURL?.appendingPathComponent("test-output.html") {
  print ("output -- \(outputPath.absoluteString)")
  try output?.write(to: outputPath, atomically: true, encoding: String.Encoding.utf8)
  
  NSWorkspace.shared.open(outputPath)
}

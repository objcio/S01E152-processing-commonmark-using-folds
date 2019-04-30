//
//  SwiftAST.swift
//  CommonMark
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import Ccmark

/// The type of a list in Markdown, represented by `Block.List`.
public enum ListType {
    case Unordered
    case Ordered
}

/// An inline element in a Markdown abstract syntax tree.
public enum Inline {
    case text(text: String)
    case link(children: [Inline], title: String?, url: String?)
}

extension Inline: ExpressibleByStringLiteral {
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(stringLiteral: StringLiteralType) {
        self = Inline.text(text: stringLiteral)
    }
}

/// A block-level element in a Markdown abstract syntax tree.
public enum Block {
    case paragraph(children: [Inline])
    case heading(children: [Inline], level: Int)
    case document(children: [Block])
}

extension Inline {
    public init(_ node: Node) {
        let inlineChildren = { node.children.map(Inline.init) }
        switch node.type {
        case CMARK_NODE_TEXT:
            self = .text(text: node.literal!)
        case CMARK_NODE_LINK:
            self = .link(children: inlineChildren(), title: node.title, url: node.urlString)
        default:
            fatalError("Unrecognized node: \(node.typeString)")
        }
    }
}

extension Block {
    public init(_ node: Node) {
        let parseInlineChildren = { node.children.map(Inline.init) }
        let parseBlockChildren = { node.children.map(Block.init) }
        switch node.type {
        case CMARK_NODE_PARAGRAPH:
            self = .paragraph(children: parseInlineChildren())
        case CMARK_NODE_HEADING:
            self = .heading(children: parseInlineChildren(), level: node.headerLevel)
        default:
            fatalError("Unrecognized node: \(node.typeString)")
        }
    }
}

extension Node {
    var listItem: [Block] {
        switch type {
        case CMARK_NODE_ITEM:
            return children.map(Block.init)
        default:
            fatalError("Unrecognized node \(typeString), expected a list item")
        }
    }

}

extension Node {
    convenience init(type: cmark_node_type, children: [Node] = []) {
        self.init(node: cmark_node_new(type))
        for child in children {
            cmark_node_append_child(node, child.node)
        }
    }
}

extension Node {
    convenience init(type: cmark_node_type, literal: String) {
        self.init(type: type)
        self.literal = literal
    }
//    convenience init(type: cmark_node_type, blocks: [Block]) {
//        self.init(type: type, children: blocks.map(Node.init))
//    }
//    convenience init(type: cmark_node_type, elements: [Inline]) {
//        self.init(type: type, children: elements.map(Node.init))
//    }
}

extension Node {
//    public convenience init(blocks: [Block]) {
//        self.init(type: CMARK_NODE_DOCUMENT, blocks: blocks)
//    }
}

extension Node {
    /// The abstract syntax tree representation of a Markdown document.
    /// - returns: an array of block-level elements.
    public var block: Block {
        return Block.document(children: children.map(Block.init))
    }
}

func tableOfContents(document: String) -> [Block] {
    let blocks = Node(markdown: document)?.children.map(Block.init) ?? []
    return blocks.filter {
        switch $0 {
        case .heading(_, let level) where level < 3: return true
        default: return false
        }
    }
}

//extension Node {
//    convenience init(element: Inline) {
//        switch element {
//        case .text(let text):
//            self.init(type: CMARK_NODE_TEXT, literal: text)
//        case .emphasis(let children):
//            self.init(type: CMARK_NODE_EMPH, elements: children)
//        case .code(let text):
//            self.init(type: CMARK_NODE_CODE, literal: text)
//        case .strong(let children):
//            self.init(type: CMARK_NODE_STRONG, elements: children)
//        case .html(let text):
//            self.init(type: CMARK_NODE_HTML_INLINE, literal: text)
//        case .custom(let literal):
//            self.init(type: CMARK_NODE_CUSTOM_INLINE, literal: literal)
//        case let .link(children, title, url):
//            self.init(type: CMARK_NODE_LINK, elements: children)
//            self.title = title
//            self.urlString = url
//        case let .image(children, title, url):
//            self.init(type: CMARK_NODE_IMAGE, elements: children)
//            self.title = title
//            urlString = url
//        case .softBreak:
//            self.init(type: CMARK_NODE_SOFTBREAK)
//        case .lineBreak:
//            self.init(type: CMARK_NODE_LINEBREAK)
//        }
//    }
//}
//
//extension Node {
//    convenience init(block: Block) {
//        switch block {
//        case .paragraph(let children):
//            self.init(type: CMARK_NODE_PARAGRAPH, elements: children)
//        case let .list(items, type):
//            let listItems = items.map { Node(type: CMARK_NODE_ITEM, blocks: $0) }
//            self.init(type: CMARK_NODE_LIST, children: listItems)
//            listType = type == .Unordered ? CMARK_BULLET_LIST : CMARK_ORDERED_LIST
//        case .blockQuote(let items):
//            self.init(type: CMARK_NODE_BLOCK_QUOTE, blocks: items)
//        case let .codeBlock(text, language):
//            self.init(type: CMARK_NODE_CODE_BLOCK, literal: text)
//            fenceInfo = language
//        case .html(let text):
//            self.init(type: CMARK_NODE_HTML_BLOCK, literal: text)
//        case .custom(let literal):
//            self.init(type: CMARK_NODE_CUSTOM_BLOCK, literal: literal)
//        case let .heading(text, level):
//            self.init(type: CMARK_NODE_HEADING, elements: text)
//            headerLevel = level
//        case .thematicBreak:
//            self.init(type: CMARK_NODE_THEMATIC_BREAK)
//        }
//    }
//}

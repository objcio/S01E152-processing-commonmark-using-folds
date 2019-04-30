import Foundation

let sample =
  """
  Hello

  This is a [link](https://www.objc.io)

  # Heading 1

  Test

  ## Another heading
  """

let node = Node(markdown: sample)!
print(node.block)

extension Inline {
    func fold<R>(_ cases: InlineCases<R>) -> R {
        switch self {
        case .text(let text):
            return cases.textCase(text)
        case .link(let children, let title, let url):
            return cases.linkCase(children.map { $0.fold(cases) }, title, url)
        @unknown default:
            fatalError()
        }
    }
}

struct InlineCases<R> {
    var textCase: (String) -> R
    var linkCase: ([R], _ title: String?, _ url: String?) -> R
}

struct BlockCases<R> {
    var inlineCases: InlineCases<R>
    var paragraphCase: ([R]) -> R
    var headingCase: ([R], Int) -> R
    var documentCase: ([R]) -> R
}

extension Block {
    func fold<R>(_ cases: BlockCases<R>) -> R {
        switch self {
        case .paragraph(let children):
            return cases.paragraphCase(children.map { $0.fold(cases.inlineCases) })
        case .heading(let children, let level):
            return cases.headingCase(children.map { $0.fold(cases.inlineCases)}, level)
        case .document(let children):
            return cases.documentCase(children.map { $0.fold(cases) })
        @unknown default:
            fatalError()
        }
    }
}


func flatten<El>(_ array: [[El]]) -> [El] {
    return array.flatMap { $0 }
}

func flatten<El: Monoid>(_ array: [El]) -> El {
    return array.reduce(.zero, +)
}

protocol Monoid {
    static var zero: Self { get }
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Array: Monoid {
    static var zero: [Element] { return [] }
}

extension String: Monoid {
    static let zero = ""
}

func crush<M: Monoid>() -> BlockCases<M> {
    return BlockCases<M>(
        inlineCases: InlineCases(
            textCase: { _ in .zero },
            linkCase: { children, title, url in flatten(children) }
        ),
        paragraphCase: { urls in flatten(urls) },
        headingCase: { children, _ in flatten(children) },
        documentCase: { flatten($0) }
    )
}

var collectLinks: BlockCases<[String]> = crush()
collectLinks.inlineCases.linkCase = { _, _, url in url.map { [$0] } ?? [] }

var collectText: BlockCases<String> = crush()
collectText.inlineCases.textCase = { $0 }

print(node.block.fold(collectText))

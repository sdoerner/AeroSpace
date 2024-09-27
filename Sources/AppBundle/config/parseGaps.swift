import Common
import TOMLKit

struct Gaps: Copyable, Equatable {
    var inner: Inner
    var outer: Outer

    struct Inner: Copyable, Equatable {
        var vertical: DynamicConfigValue<Int>
        var horizontal: DynamicConfigValue<Int>

        static var zero = Inner(vertical: 0, horizontal: 0)

        init(vertical: Int, horizontal: Int) {
            self.vertical = .constant(vertical)
            self.horizontal = .constant(horizontal)
        }

        init(vertical: DynamicConfigValue<Int>, horizontal: DynamicConfigValue<Int>) {
            self.vertical = vertical
            self.horizontal = horizontal
        }
    }

    struct Outer: Copyable, Equatable {
        var left: DynamicConfigValue<Int>
        var bottom: DynamicConfigValue<Int>
        var top: DynamicConfigValue<Int>
        var right: DynamicConfigValue<Int>
        var maxWidth: DynamicConfigValue<Int>

        static var zero = Outer(left: 0, bottom: 0, top: 0, right: 0, maxWidth: Int.max)

        init(left: Int, bottom: Int, top: Int, right: Int, maxWidth: Int) {
            self.left = .constant(left)
            self.bottom = .constant(bottom)
            self.top = .constant(top)
            self.right = .constant(right)
            self.maxWidth = .constant(maxWidth)
        }

        init(left: DynamicConfigValue<Int>, bottom: DynamicConfigValue<Int>, top: DynamicConfigValue<Int>, right: DynamicConfigValue<Int>, maxWidth: DynamicConfigValue<Int>) {
            self.left = left
            self.bottom = bottom
            self.top = top
            self.right = right
            self.maxWidth = maxWidth
        }
    }

    static var zero = Gaps(inner: .zero, outer: .zero)
}

struct ResolvedGaps {
    let inner: Inner
    let outer: Outer

    struct Inner {
        let vertical: Int
        let horizontal: Int

        func get(_ orientation: Orientation) -> Int {
            orientation == .h ? horizontal : vertical
        }
    }

    struct Outer {
        let left: Int
        let bottom: Int
        let top: Int
        let right: Int
    }

    init(gaps: Gaps, monitor: any Monitor, useSingleWindowGaps: Bool) {
        inner = .init(
            vertical: gaps.inner.vertical.getValue(for: monitor),
            horizontal: gaps.inner.horizontal.getValue(for: monitor)
        )

        var leftGap =  gaps.outer.left.getValue(for: monitor)
        var rightGap =  gaps.outer.right.getValue(for: monitor)

        if useSingleWindowGaps {
            let actualWidth = Int(monitor.width) - leftGap - rightGap
            let maxWidth = gaps.outer.maxWidth.getValue(for: monitor)
            if (actualWidth > maxWidth) {
              let diff = actualWidth - maxWidth
              let leftDiff = diff / 2
              let rightDiff = diff - leftDiff
              leftGap += leftDiff
              rightGap += rightDiff
            }
        }
        outer = .init(
                    left: leftGap,
                    bottom: gaps.outer.bottom.getValue(for: monitor),
                    top: gaps.outer.top.getValue(for: monitor),
                    right: rightGap
                )
    }
}

private let gapsParser: [String: any ParserProtocol<Gaps>] = [
    "inner": Parser(\.inner, parseInner),
    "outer": Parser(\.outer, parseOuter),
]

private let innerParser: [String: any ParserProtocol<Gaps.Inner>] = [
    "vertical": Parser(\.vertical) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
    "horizontal": Parser(\.horizontal) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
]

private let outerParser: [String: any ParserProtocol<Gaps.Outer>] = [
    "left": Parser(\.left) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
    "bottom": Parser(\.bottom) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
    "top": Parser(\.top) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
    "right": Parser(\.right) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
    "maxWidth": Parser(\.maxWidth) { value, backtrace, errors in parseDynamicValue(value, Int.self, 0, backtrace, &errors) },
]

func parseGaps(_ raw: TOMLValueConvertible, _ backtrace: TomlBacktrace, _ errors: inout [TomlParseError]) -> Gaps {
    parseTable(raw, .zero, gapsParser, backtrace, &errors)
}

func parseInner(_ raw: TOMLValueConvertible, _ backtrace: TomlBacktrace, _ errors: inout [TomlParseError]) -> Gaps.Inner {
    parseTable(raw, Gaps.Inner.zero, innerParser, backtrace, &errors)
}

func parseOuter(_ raw: TOMLValueConvertible, _ backtrace: TomlBacktrace, _ errors: inout [TomlParseError]) -> Gaps.Outer {
    parseTable(raw, Gaps.Outer.zero, outerParser, backtrace, &errors)
}

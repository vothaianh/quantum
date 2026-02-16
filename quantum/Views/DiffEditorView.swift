import SwiftUI
import WebKit

struct DiffEditorView: NSViewRepresentable {
    let original: String
    let modified: String
    let fileExtension: String
    let zoom: Double

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "ready")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        let baseURL = Bundle.main.resourceURL
        webView.loadHTMLString(Self.diffHTML, baseURL: baseURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let c = context.coordinator
        c.parent = self
        guard c.isReady else { return }

        let fontSize = 11.0 * zoom
        if c.lastOriginal != original || c.lastModified != modified || c.lastFontSize != fontSize {
            c.loadDiff()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: DiffEditorView
        weak var webView: WKWebView?
        var isReady = false
        var lastOriginal = ""
        var lastModified = ""
        var lastFontSize: Double = 0

        init(_ parent: DiffEditorView) { self.parent = parent }

        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            // Wait for JS ready message
        }

        func userContentController(_ uc: WKUserContentController, didReceive msg: WKScriptMessage) {
            if msg.name == "ready" {
                isReady = true
                loadDiff()
            }
        }

        func loadDiff() {
            let mode = CodeEditorWebView.cmMode(for: parent.fileExtension)
            let fontSize = 11.0 * parent.zoom
            lastOriginal = parent.original
            lastModified = parent.modified
            lastFontSize = fontSize

            let origJSON = jsonEscape(parent.original)
            let modJSON = jsonEscape(parent.modified)
            let js = "loadDiff(\(origJSON), \(modJSON), \"\(mode)\", \(fontSize))"
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }

        private func jsonEscape(_ string: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [string]),
                  let json = String(data: data, encoding: .utf8) else { return "\"\"" }
            return String(json.dropFirst(1).dropLast(1))
        }
    }

    // MARK: - HTML

    static let diffHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/codemirror.min.css">
    <style>
    @font-face{font-family:'JetBrains Mono';font-weight:400;font-style:normal;src:url('JetBrainsMono-Regular.woff2') format('woff2')}
    @font-face{font-family:'JetBrains Mono';font-weight:700;font-style:normal;src:url('JetBrainsMono-Bold.woff2') format('woff2')}
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{height:100%;overflow:hidden;background:#191919}
    #container{display:flex;height:100%;width:100%}
    .pane{flex:1;display:flex;flex-direction:column;overflow:hidden;min-width:0}
    .pane-header{
        padding:6px 12px;font-size:11px;font-family:-apple-system,BlinkMacSystemFont,sans-serif;
        font-weight:600;color:#6B8B7A;background:#1E1E1E;border-bottom:1px solid #232323;
        flex-shrink:0;
    }
    .pane-header span.label{color:#D8E8DF;font-weight:500}
    .divider{width:1px;background:#232323;flex-shrink:0}
    .editor-wrap{flex:1;overflow:hidden}
    .CodeMirror{
        height:100%;font-family:'JetBrains Mono',Menlo,monospace;
        background:#191919;color:#D8E8DF;line-height:1.6;
    }
    .CodeMirror-gutters{background:#141414;border-right:1px solid #232323}
    .CodeMirror-linenumber{color:#3E5649;padding:0 8px 0 4px}
    .CodeMirror-cursor{border-left:2px solid #00DC82}
    .CodeMirror-selected{background:rgba(0,220,130,.14)!important}
    .CodeMirror-activeline-background{background:rgba(0,220,130,.04)}
    .CodeMirror-matchingbracket{color:#00DC82!important;text-decoration:underline}
    .CodeMirror-code span[class^="cm-"]{color:#D8E8DF}
    .cm-keyword{color:#00DC82!important}
    .cm-string,.cm-string-2{color:#B8E986!important}
    .cm-comment{color:#4B6357!important;font-style:italic}
    .cm-number{color:#E5C07B!important}
    .cm-def{color:#82AAFF!important}
    .cm-variable{color:#D8E8DF!important}
    .cm-variable-2{color:#89DDFF!important}
    .cm-variable-3,.cm-type{color:#C792EA!important}
    .cm-property{color:#F07178!important}
    .cm-operator{color:#89DDCC!important}
    .cm-atom{color:#69F0AE!important}
    .cm-builtin{color:#7EE8C7!important}
    .cm-attribute{color:#FFCB6B!important}
    .cm-tag{color:#F07178!important}
    .cm-meta{color:#80CBC4!important}
    .cm-qualifier{color:#56D4C0!important}
    .cm-bracket{color:#5C7A6E!important}
    .cm-header{color:#00DC82!important;font-weight:bold}
    .cm-link{color:#82AAFF!important;text-decoration:underline}
    .cm-hr{color:#4B6357!important}
    .cm-error{color:#FF5555!important}
    .diff-removed{background:rgba(255,85,85,0.10)!important}
    .diff-removed-gutter{background:rgba(255,85,85,0.20)!important}
    .diff-added{background:rgba(0,220,130,0.10)!important}
    .diff-added-gutter{background:rgba(0,220,130,0.20)!important}
    .diff-spacer{background:rgba(0,220,130,0.02)!important}
    ::-webkit-scrollbar{width:8px;height:8px}
    ::-webkit-scrollbar-track{background:transparent}
    ::-webkit-scrollbar-thumb{background:rgba(0,220,130,.18);border-radius:4px}
    ::-webkit-scrollbar-thumb:hover{background:rgba(0,220,130,.30)}
    ::-webkit-scrollbar-corner{background:transparent}
    </style>
    </head>
    <body>
    <div id="container">
        <div class="pane" id="left-pane">
            <div class="pane-header"><span class="label">Original</span> (HEAD)</div>
            <div class="editor-wrap" id="left-editor"></div>
        </div>
        <div class="divider"></div>
        <div class="pane" id="right-pane">
            <div class="pane-header"><span class="label">Modified</span> (Working Copy)</div>
            <div class="editor-wrap" id="right-editor"></div>
        </div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/codemirror.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/swift/swift.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/javascript/javascript.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/python/python.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/clike/clike.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/htmlmixed/htmlmixed.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/css/css.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/xml/xml.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/shell/shell.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/go/go.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/rust/rust.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/ruby/ruby.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/sql/sql.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/yaml/yaml.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/markdown/markdown.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/php/php.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/lua/lua.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/addon/edit/matchbrackets.min.js"></script>
    <script>
    var leftCM, rightCM, syncing = false;

    // Myers diff — returns list of ops: {op:'equal'|'delete'|'insert', lines:[...]}
    function myersDiff(a, b) {
        var n = a.length, m = b.length;
        if (n === 0 && m === 0) return [{op:'equal',lines:[]}];
        if (n === 0) return [{op:'insert',lines:b}];
        if (m === 0) return [{op:'delete',lines:a}];

        var max = n + m;
        var v = new Int32Array(2 * max + 1);
        var offset = max;
        var trace = [];

        outer:
        for (var d = 0; d <= max; d++) {
            var vSnap = new Int32Array(v);
            trace.push(vSnap);
            for (var k = -d; k <= d; k += 2) {
                var x;
                if (k === -d || (k !== d && v[k - 1 + offset] < v[k + 1 + offset])) {
                    x = v[k + 1 + offset];
                } else {
                    x = v[k - 1 + offset] + 1;
                }
                var y = x - k;
                while (x < n && y < m && a[x] === b[y]) { x++; y++; }
                v[k + offset] = x;
                if (x >= n && y >= m) break outer;
            }
        }

        // Backtrack
        var ops = [];
        var x = n, y = m;
        for (var d = trace.length - 1; d > 0; d--) {
            var vPrev = trace[d];
            var k = x - y;
            var prevK;
            if (k === -d || (k !== d && vPrev[k - 1 + offset] < vPrev[k + 1 + offset])) {
                prevK = k + 1;
            } else {
                prevK = k - 1;
            }
            var prevX = vPrev[prevK + offset];
            var prevY = prevX - prevK;

            // Diagonal (equal)
            while (x > prevX && y > prevY) {
                x--; y--;
                ops.unshift({op:'equal',line:a[x]});
            }
            if (d > 0) {
                if (x === prevX) {
                    ops.unshift({op:'insert',line:b[y-1]});
                    y--;
                } else {
                    ops.unshift({op:'delete',line:a[x-1]});
                    x--;
                }
            }
        }
        // Remaining diagonal at d=0
        while (x > 0 && y > 0) {
            x--; y--;
            ops.unshift({op:'equal',line:a[x]});
        }

        // Group consecutive ops
        var grouped = [];
        for (var i = 0; i < ops.length; i++) {
            var o = ops[i];
            if (grouped.length > 0 && grouped[grouped.length-1].op === o.op) {
                grouped[grouped.length-1].lines.push(o.line);
            } else {
                grouped.push({op:o.op, lines:[o.line]});
            }
        }
        return grouped;
    }

    // Build aligned side-by-side content with padding lines
    function buildAligned(diffOps) {
        var leftLines = [], rightLines = [];
        var leftHighlight = [], rightHighlight = []; // line indices to highlight

        for (var i = 0; i < diffOps.length; i++) {
            var op = diffOps[i];
            if (op.op === 'equal') {
                for (var j = 0; j < op.lines.length; j++) {
                    leftLines.push(op.lines[j]);
                    rightLines.push(op.lines[j]);
                }
            } else if (op.op === 'delete') {
                // Check if next op is insert (changed block)
                var nextOp = (i + 1 < diffOps.length) ? diffOps[i + 1] : null;
                if (nextOp && nextOp.op === 'insert') {
                    // Changed block — pair them up
                    var delCount = op.lines.length;
                    var insCount = nextOp.lines.length;
                    var maxCount = Math.max(delCount, insCount);
                    for (var j = 0; j < maxCount; j++) {
                        if (j < delCount) {
                            leftHighlight.push(leftLines.length);
                            leftLines.push(op.lines[j]);
                        } else {
                            leftHighlight.push(leftLines.length);
                            leftLines.push('');
                        }
                        if (j < insCount) {
                            rightHighlight.push(rightLines.length);
                            rightLines.push(nextOp.lines[j]);
                        } else {
                            rightHighlight.push(rightLines.length);
                            rightLines.push('');
                        }
                    }
                    i++; // skip the insert op
                } else {
                    // Pure deletion — pad right side
                    for (var j = 0; j < op.lines.length; j++) {
                        leftHighlight.push(leftLines.length);
                        leftLines.push(op.lines[j]);
                        rightHighlight.push(rightLines.length);
                        rightLines.push('');
                    }
                }
            } else if (op.op === 'insert') {
                // Pure insertion — pad left side
                for (var j = 0; j < op.lines.length; j++) {
                    leftHighlight.push(leftLines.length);
                    leftLines.push('');
                    rightHighlight.push(rightLines.length);
                    rightLines.push(op.lines[j]);
                }
            }
        }

        return {
            leftText: leftLines.join('\\n'),
            rightText: rightLines.join('\\n'),
            leftHighlight: leftHighlight,
            rightHighlight: rightHighlight
        };
    }

    function loadDiff(original, modified, mode, fontSize) {
        var origLines = original.split('\\n');
        var modLines = modified.split('\\n');

        var diffOps = myersDiff(origLines, modLines);
        var aligned = buildAligned(diffOps);

        var opts = {
            mode: mode,
            lineNumbers: true,
            readOnly: true,
            matchBrackets: true,
            lineWrapping: false,
            cursorBlinkRate: -1
        };

        // Clear existing
        document.getElementById('left-editor').innerHTML = '';
        document.getElementById('right-editor').innerHTML = '';

        leftCM = CodeMirror(document.getElementById('left-editor'), Object.assign({value: aligned.leftText}, opts));
        rightCM = CodeMirror(document.getElementById('right-editor'), Object.assign({value: aligned.rightText}, opts));

        // Apply font size
        var cms = document.querySelectorAll('.CodeMirror');
        for (var i = 0; i < cms.length; i++) {
            cms[i].style.fontSize = fontSize + 'px';
        }

        // Highlight changed lines — left side (deletions in red)
        for (var i = 0; i < aligned.leftHighlight.length; i++) {
            var ln = aligned.leftHighlight[i];
            leftCM.addLineClass(ln, 'background', 'diff-removed');
            leftCM.addLineClass(ln, 'gutter', 'diff-removed-gutter');
        }

        // Highlight changed lines — right side (additions in green)
        for (var i = 0; i < aligned.rightHighlight.length; i++) {
            var ln = aligned.rightHighlight[i];
            rightCM.addLineClass(ln, 'background', 'diff-added');
            rightCM.addLineClass(ln, 'gutter', 'diff-added-gutter');
        }

        // Mark spacer lines (empty padding) with a subtle background
        for (var i = 0; i < aligned.leftHighlight.length; i++) {
            var ln = aligned.leftHighlight[i];
            if (leftCM.getLine(ln) === '') {
                leftCM.removeLineClass(ln, 'background', 'diff-removed');
                leftCM.addLineClass(ln, 'background', 'diff-spacer');
            }
        }
        for (var i = 0; i < aligned.rightHighlight.length; i++) {
            var ln = aligned.rightHighlight[i];
            if (rightCM.getLine(ln) === '') {
                rightCM.removeLineClass(ln, 'background', 'diff-added');
                rightCM.addLineClass(ln, 'background', 'diff-spacer');
            }
        }

        // Synchronized scrolling
        leftCM.on('scroll', function() {
            if (syncing) return;
            syncing = true;
            var info = leftCM.getScrollInfo();
            rightCM.scrollTo(info.left, info.top);
            syncing = false;
        });
        rightCM.on('scroll', function() {
            if (syncing) return;
            syncing = true;
            var info = rightCM.getScrollInfo();
            leftCM.scrollTo(info.left, info.top);
            syncing = false;
        });

        leftCM.refresh();
        rightCM.refresh();
    }

    window.webkit.messageHandlers.ready.postMessage('');
    </script>
    </body>
    </html>
    """
}

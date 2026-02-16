import SwiftUI
import WebKit

struct EditableCodeView: View {
    @Binding var content: String
    @Binding var isModified: Bool
    let fileExtension: String
    let zoom: Double
    let fileURL: URL
    var goToLine: Int?
    var searchQuery: String?
    var onDidGoToLine: (() -> Void)?

    @State private var aiEditRequest: AIEditRequest?
    @State private var showAIPopup = false
    @State private var showRevertBar = false
    @State private var pendingAIRange: (fromLine: Int, fromCh: Int, toLine: Int, toCh: Int)?
    @State private var coordinatorRef: CodeEditorWebView.Coordinator?

    var body: some View {
        ZStack(alignment: .top) {
            CodeEditorWebView(
                content: $content,
                isModified: $isModified,
                fileExtension: fileExtension,
                zoom: zoom,
                fileURL: fileURL,
                goToLine: goToLine,
                searchQuery: searchQuery,
                onAIEditRequest: { request in
                    aiEditRequest = request
                    showAIPopup = true
                },
                onRevertAvailable: { available in
                    showRevertBar = available
                },
                onDidGoToLine: onDidGoToLine,
                coordinatorRef: $coordinatorRef
            )

            // AI Edit Popup overlay
            if showAIPopup, let request = aiEditRequest {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showAIPopup = false }

                AIEditPopupView(
                    request: request,
                    onSubmit: { modelID, result in
                        showAIPopup = false
                        applyAIResult(result, request: request)
                    },
                    onCancel: { showAIPopup = false }
                )
                .padding(.top, 60)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Revert bar
            if showRevertBar {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent)
                    Text("AI edit applied")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        coordinatorRef?.eval("revertAIEdit()")
                        showRevertBar = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10, weight: .medium))
                            Text("Revert")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        coordinatorRef?.eval("acceptAIEdit()")
                        showRevertBar = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .medium))
                            Text("Accept")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.termGreen.opacity(0.8))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.bgHeader)
                .overlay(
                    Rectangle().fill(Theme.border).frame(height: 1),
                    alignment: .bottom
                )
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showAIPopup)
        .animation(.easeInOut(duration: 0.15), value: showRevertBar)
    }

    private func applyAIResult(_ result: String, request: AIEditRequest) {
        let escaped = CodeEditorWebView.Coordinator.jsonEscape(result)
        let js = "applyAIEdit(\(escaped), \(request.fromLine), \(request.fromCh), \(request.toLine), \(request.toCh))"
        coordinatorRef?.eval(js)
        showRevertBar = true
    }
}

// MARK: - WKWebView + CodeMirror 5

struct CodeEditorWebView: NSViewRepresentable {
    @Binding var content: String
    @Binding var isModified: Bool
    let fileExtension: String
    let zoom: Double
    let fileURL: URL
    var goToLine: Int?
    var searchQuery: String?
    let onAIEditRequest: (AIEditRequest) -> Void
    let onRevertAvailable: (Bool) -> Void
    var onDidGoToLine: (() -> Void)?
    @Binding var coordinatorRef: Coordinator?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "contentChanged")
        config.userContentController.add(context.coordinator, name: "saveFile")
        config.userContentController.add(context.coordinator, name: "ready")
        config.userContentController.add(context.coordinator, name: "aiEdit")
        config.userContentController.add(context.coordinator, name: "aiRevertDone")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView

        DispatchQueue.main.async {
            self.coordinatorRef = context.coordinator
        }

        webView.loadHTMLString(Self.editorHTML, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let c = context.coordinator
        c.parent = self

        guard c.isReady, !c.isInternalUpdate else { return }

        // Content changed externally (file switch)
        if c.lastContent != content {
            c.setContent(content, mode: Self.cmMode(for: fileExtension, fileName: fileURL.lastPathComponent))
        }

        // Zoom changed
        let fontSize = 11.0 * zoom
        if c.lastFontSize != fontSize {
            c.lastFontSize = fontSize
            c.eval("setFontSize(\(fontSize))")
        }

        // Go to line + highlight keyword
        if let line = goToLine, line != c.lastGoToLine {
            c.lastGoToLine = line
            if let query = searchQuery, !query.isEmpty {
                let escaped = Coordinator.jsonEscape(query)
                c.eval("goToLine(\(line - 1), \(escaped))")
            } else {
                c.eval("goToLine(\(line - 1), null)")
            }
            DispatchQueue.main.async { onDidGoToLine?() }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: CodeEditorWebView
        weak var webView: WKWebView?
        var isReady = false
        var isInternalUpdate = false
        var lastContent = ""
        var lastFontSize: Double = 0
        var lastGoToLine: Int?

        init(_ parent: CodeEditorWebView) {
            self.parent = parent
            self.lastContent = parent.content
        }

        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            let mode = CodeEditorWebView.cmMode(for: parent.fileExtension, fileName: parent.fileURL.lastPathComponent)
            let fontSize = 11.0 * parent.zoom
            lastFontSize = fontSize
            let json = Self.jsonEscape(parent.content)
            eval("initEditor(\(json), \"\(mode)\", \(fontSize))")
        }

        func userContentController(_ uc: WKUserContentController, didReceive msg: WKScriptMessage) {
            switch msg.name {
            case "ready":
                isReady = true
                // Execute pending goToLine after editor is ready
                if let line = parent.goToLine {
                    lastGoToLine = line
                    if let query = parent.searchQuery, !query.isEmpty {
                        let escaped = Self.jsonEscape(query)
                        eval("setTimeout(function(){goToLine(\(line - 1), \(escaped))},50)")
                    } else {
                        eval("setTimeout(function(){goToLine(\(line - 1), null)},50)")
                    }
                    DispatchQueue.main.async { self.parent.onDidGoToLine?() }
                }
            case "contentChanged":
                guard let text = msg.body as? String else { return }
                isInternalUpdate = true
                parent.content = text
                lastContent = text
                if !parent.isModified { parent.isModified = true }
                isInternalUpdate = false
            case "saveFile":
                guard let text = msg.body as? String else { return }
                isInternalUpdate = true
                parent.content = text
                lastContent = text
                do {
                    try text.write(to: parent.fileURL, atomically: true, encoding: .utf8)
                    parent.isModified = false
                } catch {
                    print("Save failed: \(error)")
                }
                isInternalUpdate = false
            case "aiEdit":
                guard let body = msg.body as? String,
                      let data = body.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                let request = AIEditRequest(
                    selectedText: json["selectedText"] as? String ?? "",
                    fullContent: json["fullContent"] as? String ?? "",
                    fromLine: json["fromLine"] as? Int ?? 0,
                    fromCh: json["fromCh"] as? Int ?? 0,
                    toLine: json["toLine"] as? Int ?? 0,
                    toCh: json["toCh"] as? Int ?? 0,
                    fileExtension: parent.fileExtension
                )
                parent.onAIEditRequest(request)
            case "aiRevertDone":
                parent.onRevertAvailable(false)
            default: break
            }
        }

        func setContent(_ content: String, mode: String) {
            lastContent = content
            let json = Self.jsonEscape(content)
            eval("setContent(\(json), \"\(mode)\")")
        }

        func eval(_ js: String) {
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }

        static func jsonEscape(_ string: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [string]),
                  let json = String(data: data, encoding: .utf8) else { return "\"\"" }
            // json is ["escaped string"] — strip the array brackets
            return String(json.dropFirst(1).dropLast(1))
        }
    }

    // MARK: - Mode Mapping

    static func cmMode(for ext: String, fileName: String = "") -> String {
        // Check filename first for .env files (.env, .env.example, .env.local, etc.)
        let lower = fileName.lowercased()
        if lower == ".env" || lower.hasPrefix(".env.") {
            return "shell"
        }

        switch ext.lowercased() {
        case "swift":                       return "swift"
        case "js", "jsx", "mjs", "cjs":    return "javascript"
        case "ts", "tsx":                   return "text/typescript"
        case "py":                          return "python"
        case "rb":                          return "ruby"
        case "go":                          return "go"
        case "rs":                          return "rust"
        case "c", "h":                      return "text/x-csrc"
        case "cpp", "cc", "cxx", "hpp", "mm": return "text/x-c++src"
        case "java":                        return "text/x-java"
        case "kt", "kts":                   return "text/x-kotlin"
        case "cs":                          return "text/x-csharp"
        case "html", "htm":                 return "htmlmixed"
        case "css", "scss", "less":         return "css"
        case "json":                        return "application/json"
        case "xml", "plist":                return "xml"
        case "yaml", "yml":                 return "yaml"
        case "md", "markdown":              return "markdown"
        case "sh", "bash", "zsh", "fish":   return "shell"
        case "sql":                         return "sql"
        case "php":                         return "php"
        case "lua":                         return "lua"
        case "env":                         return "shell"
        case "properties", "ini", "cfg", "conf": return "properties"
        default:                            return "text/plain"
        }
    }

    // MARK: - HTML + CodeMirror

    static let editorHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/codemirror.min.css">
    <style>
    html,body{margin:0;padding:0;height:100%;overflow:hidden;background:#181B21;box-sizing:border-box}
    #editor{height:100%;padding:8px 0 0 8px}
    .CodeMirror{
        height:100%;font-family:Menlo,monospace;
        background:#181B21;color:#D8DCE4;line-height:1.6;
    }
    .CodeMirror-gutters{background:#151820;border-right:1px solid #252932}
    .CodeMirror-linenumber{color:#4E5663;padding:0 8px 0 4px}
    .CodeMirror pre.CodeMirror-line,
    .CodeMirror pre.CodeMirror-line-like{padding-left:12px!important}
    .CodeMirror-cursor{border-left:1.5px solid #fff}
    .CodeMirror-selected{background:rgba(255,255,255,.12)!important}
    .CodeMirror-activeline-background{background:rgba(255,255,255,.04)}
    .CodeMirror-matchingbracket{color:#FFD700!important;text-decoration:underline}
    .CodeMirror-scrollbar-filler,.CodeMirror-gutter-filler{background:transparent}
    .CodeMirror-code span[class^="cm-"]{color:#D8DCE4}
    .cm-keyword{color:#C586C0!important}
    .cm-string,.cm-string-2{color:#CE9178!important}
    .cm-comment{color:#6A9955!important;font-style:italic}
    .cm-number{color:#B5CEA8!important}
    .cm-def{color:#79B8FF!important}
    .cm-variable{color:#D4D4D4!important}
    .cm-variable-2{color:#9CDCFE!important}
    .cm-variable-3,.cm-type{color:#4EC9B0!important}
    .cm-property{color:#9CDCFE!important}
    .cm-operator{color:#D4D4D4!important}
    .cm-atom{color:#9CDCFE!important}
    .cm-builtin{color:#DCDCAA!important}
    .cm-attribute{color:#9CDCFE!important}
    .cm-tag{color:#79B8FF!important}
    .cm-meta{color:#C586C0!important}
    .cm-qualifier{color:#4EC9B0!important}
    .cm-bracket{color:#D4D4D4!important}
    .cm-header{color:#79B8FF!important;font-weight:bold}
    .cm-link{color:#9CDCFE!important;text-decoration:underline}
    .cm-hr{color:#4E5663!important}
    .cm-error{color:#F44747!important}
    .ai-edit-highlight{background:rgba(86,205,122,0.12)!important}
    .ai-edit-gutter{background:rgba(86,205,122,0.3)!important}
    ::-webkit-scrollbar{width:8px;height:8px}
    ::-webkit-scrollbar-track{background:transparent}
    ::-webkit-scrollbar-thumb{background:rgba(255,255,255,.2);border-radius:4px}
    ::-webkit-scrollbar-thumb:hover{background:rgba(255,255,255,.3)}
    ::-webkit-scrollbar-corner{background:transparent}
    </style>
    </head>
    <body>
    <div id="editor"></div>
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
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/addon/edit/closebrackets.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/addon/edit/matchbrackets.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/addon/selection/active-line.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/mode/properties/properties.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.18/addon/search/searchcursor.min.js"></script>
    <script>
    var editor, changeTimer, saveTimer, isUpdating=false, dirty=false;
    var aiOriginalContent=null, aiOriginalFrom=null, aiOriginalTo=null, aiMarks=[];

    function initEditor(content, mode, fontSize) {
        editor = CodeMirror(document.getElementById('editor'), {
            value: content,
            mode: mode,
            lineNumbers: true,
            autoCloseBrackets: true,
            matchBrackets: true,
            styleActiveLine: true,
            indentUnit: 4,
            tabSize: 4,
            indentWithTabs: false,
            lineWrapping: false,
            extraKeys: {
                'Cmd-S': function() {
                    clearTimeout(saveTimer);
                    dirty = false;
                    window.webkit.messageHandlers.saveFile.postMessage(editor.getValue());
                },
                'Tab': function(cm) {
                    if (cm.somethingSelected()) cm.indentSelection('add');
                    else cm.replaceSelection('    ', 'end');
                },
                'Shift-Tab': function(cm) { cm.indentSelection('subtract'); },
                'Cmd-K': function(cm) {
                    var sel = cm.getSelection();
                    if (!sel) return;
                    var from = cm.getCursor('from');
                    var to = cm.getCursor('to');
                    window.webkit.messageHandlers.aiEdit.postMessage(JSON.stringify({
                        selectedText: sel,
                        fromLine: from.line, fromCh: from.ch,
                        toLine: to.line, toCh: to.ch,
                        fullContent: cm.getValue()
                    }));
                },
                'Cmd-D': function(cm) {
                    var text = cm.getSelection();
                    if (!text) {
                        var word = cm.findWordAt(cm.getCursor());
                        cm.setSelection(word.anchor, word.head);
                        return;
                    }
                    var cur = cm.getSearchCursor(text, {line:0,ch:0}, {caseFold:false});
                    var ranges = [];
                    while (cur.findNext()) {
                        ranges.push({anchor:cur.from(), head:cur.to()});
                    }
                    if (ranges.length > 0) cm.setSelections(ranges);
                }
            }
        });
        document.querySelector('.CodeMirror').style.fontSize = fontSize + 'px';
        setTimeout(function(){ editor.refresh(); }, 10);
        editor.on('changes', function() {
            if (isUpdating) return;
            dirty = true;
            clearTimeout(changeTimer);
            clearTimeout(saveTimer);
            changeTimer = setTimeout(function() {
                window.webkit.messageHandlers.contentChanged.postMessage(editor.getValue());
            }, 100);
            saveTimer = setTimeout(function() {
                if (!dirty) return;
                var val = editor.getValue();
                if (val.length === 0) return;
                dirty = false;
                window.webkit.messageHandlers.saveFile.postMessage(val);
            }, 1500);
        });
        window.webkit.messageHandlers.ready.postMessage('');
    }

    function setContent(content, mode) {
        if (!editor) return;
        clearTimeout(saveTimer);
        dirty = false;
        isUpdating = true;
        editor.setValue(content);
        if (mode) editor.setOption('mode', mode);
        editor.clearHistory();
        isUpdating = false;
        clearAIMarks();
    }

    function setFontSize(size) {
        var el = document.querySelector('.CodeMirror');
        if (el) { el.style.fontSize = size + 'px'; if (editor) editor.refresh(); }
    }

    function clearAIMarks() {
        for (var i = 0; i < aiMarks.length; i++) {
            aiMarks[i].clear();
        }
        aiMarks = [];
    }

    function applyAIEdit(text, fromLine, fromCh, toLine, toCh) {
        if (!editor) return;
        // Save original state for revert
        aiOriginalContent = editor.getValue();
        aiOriginalFrom = {line: fromLine, ch: fromCh};
        aiOriginalTo = {line: toLine, ch: toCh};
        clearAIMarks();

        // Replace the selected range
        editor.replaceRange(text, {line: fromLine, ch: fromCh}, {line: toLine, ch: toCh});

        // Calculate new end position
        var newLines = text.split('\\n');
        var endLine = fromLine + newLines.length - 1;
        var endCh = newLines.length === 1
            ? fromCh + newLines[0].length
            : newLines[newLines.length - 1].length;

        // Highlight the replaced range with green background
        var mark = editor.markText(
            {line: fromLine, ch: fromCh},
            {line: endLine, ch: endCh},
            {className: 'ai-edit-highlight'}
        );
        aiMarks.push(mark);

        // Also highlight gutter for changed lines
        for (var l = fromLine; l <= endLine; l++) {
            editor.addLineClass(l, 'gutter', 'ai-edit-gutter');
        }
    }

    function revertAIEdit() {
        if (!editor || aiOriginalContent === null) return;
        isUpdating = true;
        editor.setValue(aiOriginalContent);
        isUpdating = false;
        clearAIMarks();
        aiOriginalContent = null;
        window.webkit.messageHandlers.contentChanged.postMessage(editor.getValue());
        window.webkit.messageHandlers.aiRevertDone.postMessage('');
    }

    function acceptAIEdit() {
        clearAIMarks();
        // Remove gutter classes from all lines
        if (editor) {
            var lineCount = editor.lineCount();
            for (var i = 0; i < lineCount; i++) {
                editor.removeLineClass(i, 'gutter', 'ai-edit-gutter');
            }
        }
        aiOriginalContent = null;
    }

    var searchMark = null;
    function goToLine(line, query) {
        if (!editor) return;
        // Clear previous search highlight
        if (searchMark) { searchMark.clear(); searchMark = null; }
        // Scroll to line and set cursor
        editor.setCursor({line: line, ch: 0});
        editor.scrollIntoView({line: line, ch: 0}, 200);
        // Highlight the keyword on that line if provided
        if (query) {
            var lineText = editor.getLine(line);
            if (lineText) {
                var idx = lineText.toLowerCase().indexOf(query.toLowerCase());
                if (idx >= 0) {
                    var from = {line: line, ch: idx};
                    var to = {line: line, ch: idx + query.length};
                    editor.setSelection(from, to);
                    editor.scrollIntoView(from, 200);
                }
            }
        }
    }
    </script>
    </body>
    </html>
    """
}

import Foundation
import AppKit

struct FileItem: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?
}

// MARK: - File Icon Resolver

enum FileIconResolver {
    private static var cache: [String: NSImage] = [:]

    static func icon(for item: FileItem, expanded: Bool = false) -> NSImage {
        let key = iconName(for: item, expanded: expanded)

        if let cached = cache[key] { return cached }

        if let img = loadSVG(named: key) {
            cache[key] = img
            return img
        }

        // Fallback
        let fallback = item.isDirectory ? "default_folder" : "default_file"
        if let img = cache[fallback] ?? loadSVG(named: fallback) {
            cache[fallback] = img
            return img
        }

        return NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
    }

    private static func loadSVG(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg") else {
            return nil
        }
        guard let img = NSImage(contentsOf: url) else { return nil }
        img.isTemplate = false
        return img
    }

    private static func iconName(for item: FileItem, expanded: Bool) -> String {
        if item.isDirectory {
            let folderName = item.name.lowercased()
            if let specific = folderNames[folderName] {
                return expanded ? "\(specific)_opened" : specific
            }
            return expanded ? "default_folder_opened" : "default_folder"
        }

        let ext = item.url.pathExtension.lowercased()
        let filename = item.name.lowercased()

        // Check exact filename first
        if let specific = fileNames[filename] {
            return specific
        }

        // Check extension
        if let specific = extensions[ext] {
            return specific
        }

        return "default_file"
    }

    private static let extensions: [String: String] = [
        // Apple
        "swift": "file_type_swift",
        "m": "file_type_objectivec",
        "mm": "file_type_objectivecpp",
        "h": "file_type_c",
        "metal": "file_type_metal",
        "storyboard": "file_type_storyboard",
        "xib": "file_type_storyboard",
        "xcodeproj": "file_type_xcode",
        "xcworkspace": "file_type_xcode",
        "entitlements": "file_type_xml",
        "pbxproj": "file_type_xcode",
        // Web
        "js": "file_type_js",
        "mjs": "file_type_js",
        "cjs": "file_type_js",
        "jsx": "file_type_reactjs",
        "ts": "file_type_typescript",
        "mts": "file_type_typescript",
        "cts": "file_type_typescript",
        "tsx": "file_type_reactts",
        "html": "file_type_html",
        "htm": "file_type_html",
        "css": "file_type_css",
        "scss": "file_type_scss",
        "sass": "file_type_sass",
        "less": "file_type_less",
        "postcss": "file_type_postcss",
        "vue": "file_type_vue",
        "svelte": "file_type_svelte",
        "astro": "file_type_astro",
        "mdx": "file_type_mdx",
        "pug": "file_type_pug",
        "ejs": "file_type_ejs",
        "hbs": "file_type_handlebars",
        "mustache": "file_type_handlebars",
        "erb": "file_type_erb",
        // Data
        "json": "file_type_json",
        "jsonc": "file_type_json",
        "json5": "file_type_json",
        "xml": "file_type_xml",
        "yaml": "file_type_yaml",
        "yml": "file_type_yaml",
        "toml": "file_type_toml",
        "csv": "file_type_text",
        "plist": "file_type_xml",
        "graphql": "file_type_graphql",
        "gql": "file_type_graphql",
        "proto": "file_type_protobuf",
        "prisma": "file_type_prisma",
        // Languages
        "py": "file_type_python",
        "pyw": "file_type_python",
        "pyi": "file_type_python",
        "rb": "file_type_ruby",
        "rs": "file_type_rust",
        "go": "file_type_go",
        "java": "file_type_java",
        "kt": "file_type_kotlin",
        "kts": "file_type_kotlin",
        "cs": "file_type_csharp",
        "fs": "file_type_fsharp",
        "fsx": "file_type_fsharp",
        "cpp": "file_type_cpp",
        "cc": "file_type_cpp",
        "cxx": "file_type_cpp",
        "c": "file_type_c",
        "php": "file_type_php",
        "r": "file_type_r",
        "lua": "file_type_lua",
        "pl": "file_type_perl",
        "pm": "file_type_perl",
        "sql": "file_type_sql",
        "dart": "file_type_dartlang",
        "scala": "file_type_scala",
        "sc": "file_type_scala",
        "ex": "file_type_elixir",
        "exs": "file_type_elixir",
        "erl": "file_type_erlang",
        "hrl": "file_type_erlang",
        "hs": "file_type_haskell",
        "lhs": "file_type_haskell",
        "clj": "file_type_clojure",
        "cljs": "file_type_clojure",
        "cljc": "file_type_clojure",
        "jl": "file_type_julia",
        "zig": "file_type_zig",
        "nim": "file_type_nim",
        "ml": "file_type_ocaml",
        "mli": "file_type_ocaml",
        "groovy": "file_type_groovy",
        "gvy": "file_type_groovy",
        "sol": "file_type_solidity",
        "elm": "file_type_elm",
        "cr": "file_type_crystal",
        "coffee": "file_type_coffeescript",
        "vb": "file_type_config",
        "gleam": "file_type_gleam",
        "re": "file_type_reason",
        "res": "file_type_rescript",
        "wasm": "file_type_wasm",
        "wat": "file_type_wasm",
        "nix": "file_type_nix",
        "cu": "file_type_cuda",
        "cuh": "file_type_cuda",
        "glsl": "file_type_glsl",
        "vert": "file_type_glsl",
        "frag": "file_type_glsl",
        "hlsl": "file_type_glsl",
        "tf": "file_type_terraform",
        "tfvars": "file_type_terraform",
        // Shell
        "sh": "file_type_shell",
        "bash": "file_type_shell",
        "zsh": "file_type_shell",
        "fish": "file_type_shell",
        "ps1": "file_type_powershell",
        "psm1": "file_type_powershell",
        "psd1": "file_type_powershell",
        "bat": "file_type_bat",
        "cmd": "file_type_bat",
        // Docs
        "md": "file_type_markdown",
        "markdown": "file_type_markdown",
        "txt": "file_type_text",
        "pdf": "file_type_pdf",
        "log": "file_type_log",
        "tex": "file_type_tex",
        "latex": "file_type_tex",
        "ipynb": "file_type_jupyter",
        // Images
        "png": "file_type_image",
        "jpg": "file_type_image",
        "jpeg": "file_type_image",
        "gif": "file_type_image",
        "bmp": "file_type_image",
        "ico": "file_type_image",
        "webp": "file_type_image",
        "svg": "file_type_svg",
        "psd": "file_type_photoshop",
        // Media
        "mp4": "file_type_video",
        "mov": "file_type_video",
        "avi": "file_type_video",
        "webm": "file_type_video",
        "mp3": "file_type_audio",
        "wav": "file_type_audio",
        "flac": "file_type_audio",
        // Fonts
        "ttf": "file_type_font",
        "otf": "file_type_font",
        "woff": "file_type_font",
        "woff2": "file_type_font",
        // Archives
        "zip": "file_type_zip",
        "tar": "file_type_zip",
        "gz": "file_type_zip",
        "rar": "file_type_zip",
        "7z": "file_type_zip",
        "tgz": "file_type_zip",
        // Config
        "env": "file_type_dotenv",
        "ini": "file_type_ini",
        "cfg": "file_type_config",
        "conf": "file_type_config",
        "editorconfig": "file_type_editorconfig",
        // Build
        "gradle": "file_type_gradle",
        "cmake": "file_type_cmake",
        // Database
        "db": "file_type_db",
        "sqlite": "file_type_sqlite",
        "sqlite3": "file_type_sqlite",
        // Security
        "pem": "file_type_cert",
        "crt": "file_type_cert",
        "cer": "file_type_cert",
        "key": "file_type_key",
        "pub": "file_type_key",
        // Diff/Patch
        "diff": "file_type_diff",
        "patch": "file_type_patch",
        // Office
        "xlsx": "file_type_excel",
        "xls": "file_type_excel",
        "docx": "file_type_word",
        "doc": "file_type_word",
        // Binary
        "exe": "file_type_binary",
        "dll": "file_type_binary",
        "so": "file_type_binary",
        "dylib": "file_type_binary",
        "bin": "file_type_binary",
        "o": "file_type_binary",
        "a": "file_type_binary",
    ]

    private static let fileNames: [String: String] = [
        // Docker
        "dockerfile": "file_type_docker",
        "docker-compose.yml": "file_type_docker2",
        "docker-compose.yaml": "file_type_docker2",
        "compose.yml": "file_type_docker2",
        "compose.yaml": "file_type_docker2",
        // Git
        ".gitignore": "file_type_git",
        ".gitattributes": "file_type_git",
        ".gitmodules": "file_type_git",
        ".gitkeep": "file_type_git",
        // License
        "license": "file_type_license",
        "license.md": "file_type_license",
        "license.txt": "file_type_license",
        "licence": "file_type_license",
        "licence.md": "file_type_license",
        // Build
        "makefile": "file_type_cmake",
        "cmakelists.txt": "file_type_cmake",
        "cargo.toml": "file_type_cargo",
        "cargo.lock": "file_type_cargo",
        // Env
        ".env": "file_type_dotenv",
        ".env.local": "file_type_dotenv",
        ".env.development": "file_type_dotenv",
        ".env.production": "file_type_dotenv",
        ".env.staging": "file_type_dotenv",
        ".env.test": "file_type_dotenv",
        ".env.example": "file_type_dotenv",
        // JS/TS Config
        "package.json": "file_type_npm",
        "package-lock.json": "file_type_npm",
        ".npmrc": "file_type_npm",
        "yarn.lock": "file_type_yarn",
        ".yarnrc": "file_type_yarn",
        ".yarnrc.yml": "file_type_yarn",
        "pnpm-lock.yaml": "file_type_pnpm",
        "pnpm-workspace.yaml": "file_type_pnpm",
        ".pnpmfile.cjs": "file_type_pnpm",
        "bun.lockb": "file_type_bun",
        "bunfig.toml": "file_type_bun",
        "deno.json": "file_type_deno",
        "deno.jsonc": "file_type_deno",
        "deno.lock": "file_type_deno",
        "tsconfig.json": "file_type_tsconfig",
        "jsconfig.json": "file_type_tsconfig",
        "webpack.config.js": "file_type_webpack",
        "webpack.config.ts": "file_type_webpack",
        "vite.config.js": "file_type_vite",
        "vite.config.ts": "file_type_vite",
        "vite.config.mjs": "file_type_vite",
        "vite.config.mts": "file_type_vite",
        "rollup.config.js": "file_type_rollup",
        "rollup.config.ts": "file_type_rollup",
        "rollup.config.mjs": "file_type_rollup",
        ".babelrc": "file_type_babel",
        "babel.config.js": "file_type_babel",
        "babel.config.json": "file_type_babel",
        // Linters/Formatters
        ".eslintrc": "file_type_eslint",
        ".eslintrc.js": "file_type_eslint",
        ".eslintrc.json": "file_type_eslint",
        ".eslintrc.yml": "file_type_eslint",
        "eslint.config.js": "file_type_eslint",
        "eslint.config.mjs": "file_type_eslint",
        "eslint.config.ts": "file_type_eslint",
        ".prettierrc": "file_type_prettier",
        ".prettierrc.js": "file_type_prettier",
        ".prettierrc.json": "file_type_prettier",
        ".prettierrc.yml": "file_type_prettier",
        "prettier.config.js": "file_type_prettier",
        ".prettierignore": "file_type_prettier",
        ".stylelintrc": "file_type_stylelint",
        ".stylelintrc.json": "file_type_stylelint",
        ".editorconfig": "file_type_editorconfig",
        ".nodemon.json": "file_type_nodemon",
        "nodemon.json": "file_type_nodemon",
        // Testing
        "jest.config.js": "file_type_jest",
        "jest.config.ts": "file_type_jest",
        "jest.config.mjs": "file_type_jest",
        "cypress.config.js": "file_type_cypress",
        "cypress.config.ts": "file_type_cypress",
        "playwright.config.js": "file_type_playwright",
        "playwright.config.ts": "file_type_playwright",
        "vitest.config.js": "file_type_vitest",
        "vitest.config.ts": "file_type_vitest",
        // Next.js
        "next.config.js": "file_type_next",
        "next.config.mjs": "file_type_next",
        "next.config.ts": "file_type_next",
        // Nuxt
        "nuxt.config.js": "file_type_nuxt",
        "nuxt.config.ts": "file_type_nuxt",
        // Tailwind
        "tailwind.config.js": "file_type_tailwind",
        "tailwind.config.ts": "file_type_tailwind",
        "tailwind.config.mjs": "file_type_tailwind",
        // Svelte
        "svelte.config.js": "file_type_svelte",
        "svelte.config.ts": "file_type_svelte",
        // Astro
        "astro.config.js": "file_type_astro",
        "astro.config.ts": "file_type_astro",
        "astro.config.mjs": "file_type_astro",
        // Firebase
        "firebase.json": "file_type_firebase",
        ".firebaserc": "file_type_firebase",
        "firestore.rules": "file_type_firebase",
        // Vercel
        "vercel.json": "file_type_vercel",
        ".vercelignore": "file_type_vercel",
        // Terraform
        "terraform.tfvars": "file_type_terraform",
        // Prisma
        "schema.prisma": "file_type_prisma",
        // Nginx
        "nginx.conf": "file_type_nginx",
        // Claude
        "claude.md": "file_type_claude",
        ".clauderc": "file_type_claude",
        // Gulp
        "gulpfile.js": "file_type_gulp",
        "gulpfile.ts": "file_type_gulp",
        // Storybook
        ".storybook": "file_type_storybook",
        // Flutter
        "pubspec.yaml": "file_type_flutter",
        "pubspec.lock": "file_type_flutter",
        // NestJS
        "nest-cli.json": "file_type_nestjs",
        // Swagger
        "swagger.json": "file_type_swagger",
        "swagger.yaml": "file_type_swagger",
        "openapi.json": "file_type_swagger",
        "openapi.yaml": "file_type_swagger",
        // CI/CD
        "bitbucket-pipelines.yml": "file_type_bitbucketpipeline",
        "bitbucket-pipelines.yaml": "file_type_bitbucketpipeline",
        ".travis.yml": "file_type_travis",
        ".travis.yaml": "file_type_travis",
        ".circleci/config.yml": "file_type_circleci",
        ".gitlab-ci.yml": "file_type_gitlab",
        ".gitlab-ci.yaml": "file_type_gitlab",
        "jenkinsfile": "file_type_jenkins",
        "vagrantfile": "file_type_vagrant",
        // Monorepo / Build
        "turbo.json": "file_type_turbo",
        "nx.json": "file_type_nx",
        "project.json": "file_type_nx",
        "workspace.json": "file_type_nx",
        "build.gradle": "file_type_gradle",
        "build.gradle.kts": "file_type_gradle",
        "settings.gradle": "file_type_gradle",
        "settings.gradle.kts": "file_type_gradle",
        "pom.xml": "file_type_maven",
        "build.bazel": "file_type_bazel",
        "workspace.bazel": "file_type_bazel",
        "bazel": "file_type_bazel",
        // Ruby
        "gemfile": "file_type_ruby",
        "gemfile.lock": "file_type_ruby",
        "rakefile": "file_type_rake",
        ".ruby-version": "file_type_ruby",
        ".ruby-gemset": "file_type_ruby",
        // Python
        "requirements.txt": "file_type_python",
        "setup.py": "file_type_python",
        "setup.cfg": "file_type_python",
        "pyproject.toml": "file_type_python",
        "pipfile": "file_type_python",
        "pipfile.lock": "file_type_python",
        "poetry.lock": "file_type_python",
        ".python-version": "file_type_python",
        // Go
        "go.mod": "file_type_go",
        "go.sum": "file_type_go",
        // Rust
        "rust-toolchain": "file_type_rust",
        "rust-toolchain.toml": "file_type_rust",
        // Elixir
        "mix.exs": "file_type_elixir",
        "mix.lock": "file_type_elixir",
        // Git hooks & tooling
        ".huskyrc": "file_type_husky",
        ".huskyrc.js": "file_type_husky",
        ".huskyrc.json": "file_type_husky",
        ".lintstagedrc": "file_type_lintstagedrc",
        ".lintstagedrc.js": "file_type_lintstagedrc",
        ".lintstagedrc.json": "file_type_lintstagedrc",
        "lint-staged.config.js": "file_type_lintstagedrc",
        "lint-staged.config.mjs": "file_type_lintstagedrc",
        "commitlint.config.js": "file_type_commitlint",
        "commitlint.config.ts": "file_type_commitlint",
        ".commitlintrc": "file_type_commitlint",
        ".commitlintrc.json": "file_type_commitlint",
        // Dependabot / Renovate
        "renovate.json": "file_type_renovate",
        "renovate.json5": "file_type_renovate",
        ".renovaterc": "file_type_renovate",
        ".renovaterc.json": "file_type_renovate",
        "dependabot.yml": "file_type_dependabot",
        "dependabot.yaml": "file_type_dependabot",
        // Misc special files
        "procfile": "file_type_procfile",
        ".browserslistrc": "file_type_browserslist",
        ".watchmanconfig": "file_type_watchmanconfig",
        ".sentryclirc": "file_type_sentry",
        "sentry.properties": "file_type_sentry",
        "todo.md": "file_type_todo",
        "todo.txt": "file_type_todo",
        "todo": "file_type_todo",
        "robots.txt": "file_type_robots",
        // Ignore files
        ".dockerignore": "file_type_docker",
        ".gitignore_global": "file_type_git",
        ".npmignore": "file_type_npm",
        ".eslintignore": "file_type_eslint",
        ".stylelintignore": "file_type_stylelint",
        // Node
        ".nvmrc": "file_type_node",
        ".node-version": "file_type_node",
    ]

    private static let folderNames: [String: String] = [
        ".git": "default_folder",
    ]
}

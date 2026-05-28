// アプリアイコン(1024×1024 PNG)を生成するスクリプト。
// 使い方: swift generate_app_icon.swift <出力PNGパス>
// 深いインディゴのグラデーション背景に白い「¥」を描く。
// iOS の App アイコンはアルファチャンネル不可のため、最後に RGB へフラット化する。
import AppKit
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

// --- 1. RGBA bitmap に描画(NSGraphicsContext はアルファ必須) ---
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("failed to create bitmap rep") }

guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("failed to create graphics context")
}
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

// 背景: 縦方向のインディゴグラデーション
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(srgbRed: 0.34, green: 0.41, blue: 0.56, alpha: 1),
        CGColor(srgbRed: 0.21, green: 0.26, blue: 0.39, alpha: 1),
    ] as CFArray,
    locations: [0, 1]
)!
cg.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// 中央に白い「¥」
let glyph = "¥" as NSString
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 600, weight: .bold),
    .foregroundColor: NSColor.white,
]
let glyphSize = glyph.size(withAttributes: attrs)
glyph.draw(
    at: NSPoint(x: (size - glyphSize.width) / 2, y: (size - glyphSize.height) / 2),
    withAttributes: attrs
)
NSGraphicsContext.current = nil

// --- 2. アルファを除去して RGB へフラット化 ---
guard let rgbaImage = rep.cgImage else { fatalError("no cgImage") }
guard let rgbContext = CGContext(
    data: nil,
    width: Int(size), height: Int(size),
    bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("failed to create RGB context") }
rgbContext.draw(rgbaImage, in: CGRect(x: 0, y: 0, width: size, height: size))
guard let rgbImage = rgbContext.makeImage() else { fatalError("failed to flatten") }

// --- 3. PNG として書き出し ---
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(
    url as CFURL, UTType.png.identifier as CFString, 1, nil
) else { fatalError("failed to create PNG destination") }
CGImageDestinationAddImage(dest, rgbImage, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("failed to write PNG") }
print("written: \(outputPath)")

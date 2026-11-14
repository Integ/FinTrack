// Usage: render_svg <in.svg> <out.png> [size] [opaque]
// Pass "opaque" for the main app icon: the App Store rejects icons with an alpha channel.
import AppKit
let args = CommandLine.arguments
let size = args.count > 3 ? Int(args[3]) ?? 1024 : 1024
let opaque = args.count > 4 && args[4] == "opaque"
guard let image = NSImage(contentsOf: URL(fileURLWithPath: args[1])) else { fatalError("cannot load \(args[1])") }
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.imageInterpolation = .high
image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.restoreGraphicsState()
// AppKit does not reliably draw SVGs into a three-channel bitmap context.
// Render into RGBA first, then strip alpha only after rendering.
var output = rep
if opaque {
    let rgb = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    for y in 0..<size {
        for x in 0..<size {
            let source = rep.bitmapData! + y * rep.bytesPerRow + x * 4
            precondition(source[3] == 255, "opaque export requires a fully filled SVG background")
            let target = rgb.bitmapData! + y * rgb.bytesPerRow + x * 3
            target[0] = source[0]
            target[1] = source[1]
            target[2] = source[2]
        }
    }
    output = rgb
}
try! output.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))

// Usage: render_svg <in.svg> <out.png> [size] [opaque]
// Pass "opaque" for the main app icon: the App Store rejects icons with an alpha channel.
import AppKit
let args = CommandLine.arguments
let size = args.count > 3 ? Int(args[3]) ?? 1024 : 1024
let opaque = args.count > 4 && args[4] == "opaque"
guard let image = NSImage(contentsOf: URL(fileURLWithPath: args[1])) else { fatalError("cannot load \(args[1])") }
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: opaque ? 3 : 4, hasAlpha: !opaque, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.imageInterpolation = .high
image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))

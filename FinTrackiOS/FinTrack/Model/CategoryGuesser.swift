import Foundation

/// Guesses an item category from a free-text name such as "Apple Magic keyboard" or "戴森V10".
/// Rules are checked in order; the first match wins, so more specific groups come first.
enum CategoryGuesser {
    private static let rules: [(category: String, keywords: [String])] = [
        ("小家电", ["dyson", "戴森", "vacuum", "吸尘", "咖啡机", "空气净化"]),
        ("计算器", ["计算器", "calculator", "ti-84", "ti84", "ti-89", "ti 36", "ti-36", "10bii", "hp 11c", "casio fx"]),
        ("游戏", ["ps4", "ps5", "ps3", "playstation", "xbox", "switch", "nintendo", "游戏", "光盘", "g29", "g25", "g920", "手柄", "方向盘"]),
        ("相机摄影", ["相机", "camera", "镜头", "lens", "闪光灯", "canon", "佳能", "nikon", "尼康", "pentax", "宾得",
                   "tamron", "sigma", "olympus", "gopro", "dji", "om-1", "ae-1", "美能达", "minolta", "takumar", "fujifilm"]),
        ("智能家居", ["alexa", "echo", "fire tv", "firetv", "apple tv", "chromecast", "google tv", "nest", "homepod",
                   "portal", "智能", "awair", "smart tag", "ring "]),
        ("键盘鼠标", ["keyboard", "mouse", "键盘", "鼠标", "键鼠", "trackpad", "touchpad", "g502", "k380", "pebble",
                   "deathadder", "mx ergo", "mx master", "m720", "keys to go"]),
        ("电源充电", ["电源", "power supply", "power adapter", "magsafe", "charger", "充电", "适配器"]),
        ("笔记本电脑", ["laptop", "macbook", "笔记本", "thinkpad", "chromebook", "surface", "上网本", "游戏本", "vivobook",
                    "xps", "rog ", "rog笔记本", "notebook", "nitro", "ideapad", "zenbook"]),
        ("手机平板", ["iphone", "ipad", " phone", "smartphone", "手机", "平板", "kindle", "watch", "ipod", "pencil", "galaxy tab"]),
        ("耳机音箱", ["耳机", "音箱", "音响", "headphone", "earphone", "earbuds", "airpods", "earpods", "bose", "jbl", "sonos",
                   "marshall", "soundcore", "回音壁", "speaker", "soundlink", "beyerdynamic", "拜亚", "森海", "sennheiser",
                   "铁三角", "m50x", "麦克风", "rode", "h2n", "漫步者", "edifier", "edifer", "monster", "b&w", "监听", "beats"]),
        ("显示器电视", ["显示器", "monitor", "电视", " tv", "tv "]),
        ("台式机", ["台式机", "pc", "imac", "机箱", "desktop", "mac mini", "mac pro"]),
        ("电脑配件", ["内存", "ddr", "硬盘", "hdd", "ssd", "显卡", "nvidia", "gtx", "rtx", "amd", "intel", "i7", "i5",
                   "声卡", "软盘", "cf 卡", "cf卡", "存储卡", "sd卡", "hub", "转接头", "adapter", "路由器", "router",
                   "usb", "webcam", "1tb", "2tb", "500g"]),
        ("乐器", ["guitar", "吉他", "ukulele", "尤克里里", "fender", "钢琴", "电子琴"]),
    ]

    static func guess(_ name: String) -> String {
        let text = " " + name.lowercased() + " "
        for rule in rules where rule.keywords.contains(where: text.contains) {
            return rule.category
        }
        return Defaults.otherCategory
    }
}

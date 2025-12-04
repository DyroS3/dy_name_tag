Config = {}

-- General Settings
Config.Debug = false
Config.Locale = 'zh-cn'
Config.Framework = 'esx' -- 使用的框架: standalone / esx / qb

Config.StreamDistance = 10 -- 显示距离
Config.NewPlayerIcon = "🆕" -- 新玩家图标
Config.NewPlayerMode = 2 -- 新玩家判定模式: 1=ESX游戏时长, 2=数据库created_at时间
Config.NewPlayerHours = 72 -- 新玩家判定阈值 (单位: 小时)

-- 渲染与流控配置
Config.Render = {
    HeadOffsetZ = 0.9,     -- 头顶文字的 Z 偏移
    StreamerBusyMs = 1500, -- 有可见对象时主循环间隔
    StreamerIdleMs = 2000, -- 无可见对象时主循环间隔
}

Config.DisPlaySetting = { -- 名字显示相关配置
    default = {           -- 默认样式 (可以在这里调整全局的默认颜色和坐标)
        scale = 1.0,
        fontId = 42,
        color = {         -- 颜色配置
            nameTitle = { -- 名字标题颜色 ([ID:x] 玩家名)
                r = 255,
                g = 255,
                b = 255,
            },
            jobTitle = { -- 职业-职称颜色
                r = 255,
                g = 255,
                b = 255,
            },
        },
        pos = {                         -- 文本在屏幕上的偏移坐标 (相对玩家头顶)
            nameTitle  = { 0, -0.010 }, -- 名字标题位置 { x, y }, x 左负右正, y 上负下正
            jobTitle   = { 0, -0.035 }, -- 职业-职称位置 { x, y }, 默认在名字上方一行
            vipTitle   = { 0, -0.060 }, -- VIP 标识位置 { x, y }, 默认在名字上方两行
            superTitle = { 0, -0.085 }, -- 超级标签位置 { x, y }，默认在 VIP 上方一行
        }
    },
}

Config.JobColors = {       -- 不同职业对应的名字颜色 (十六进制字符串, 支持带 Alpha)
    mu = "#fff67a",
    zero = "#f4cccc",      --古城
    bld = "#FFD700",       --伯林顿
    heart = "#00ffff",     --三青
    hld = "#FFD700",       --惠灵顿
    cardealer = "#ff0000", --二手车
    mechanic = "#EEAEEE",  --
    off_mechanic = "#EEAEEE",
    taxi = "#ffd966",
    off_taxi = "#ffd966",
    police = "#3399ff",
    off_police = "#6CB7D6",
    sheriff = "#33bcff",
    off_sheriff = "#00FF00",
    dunhuang = "#00ff40",
    club = "#ffc700",
    xingxin = "#f5d742",
    customs = '#f542e3',
    gucheng = "#1fd13d",
    kylin = '#ffff00',
    qingzhou = '#f069af',
    ['jiuwu'] = "#782222",
    ['juyi'] = "#944AD5",
    ['fz'] = "#d42c2c",
    ['kunlun'] = "#4acf69",
    ['ambulance'] = "#ff3251",
    ['off_ambulance'] = "#ff329c",
    ['barber'] = "#FF0000",
    ['black'] = "#FF0000",
    ['king'] = "#CA890A",
    ['poxiao'] = "#e874b8",
    ['casino'] = "#e00d0d",
    ['longhu'] = "#ECF029",
    ['k14'] = "#DA919B",
    ['linyuan'] = "#121111",
    ['heitao'] = "#ff3718",
    ['lisheng'] = "#3399ff",
    ['unemployed'] = '#00ffff',

}

Config.HideZone = { -- 头显隐藏区域配置: 本地玩家进入这些区域时, 不显示任何头顶文字
    -- { pos = vec(-3035.0010, 1738.8862, 0.0), radius = 100.0 },
}

Config.VipTags = { -- 特定玩家的自定义头顶标签与颜色配置
    { identifier = "char1:f7bc828a8e7ab5374031b85b26cf38f57868fc4b", tag = "SVIP Pro Max+", color = "#FFD700" }, --一行一个
    { identifier = "char1:a30028d22d601e2b6820a2bafce9b797f0a40390", tag = "睾处不胜含", color = "#ff75a3" }, --一行一个
    -- {identifier="char1:265573604fb77c6fc0ce7ae1ffb85f84679f9826",tag="很内向坐出租车都是坐后备箱",color="#bd0015"},--一行一个
    -- {identifier="char1:5d10ee90cd8ff5f4b043c8d133242f44ca0056e1",tag="鸡冠希",color="##41ff33"},--一行一个
    { identifier = "char1:26bbd920651f1c974f28f2b5e5a17ae7912341f3", tag = "功名半纸 风雪千山", color = "#FFFF00" },
    { identifier = "char1:918baf24e9045e2a8a70c724a7b0dab3c46c4093", tag = "除了我全世界都是🐷", color = "#7B68EE" },
    { identifier = "char1:ff08d3c7c93b18b956177d99cded413719d41549", tag = "Gai溜子团伙", color = "#007FFF" }, --迦哥
    { identifier = "char1:3067a8dcb4b52bc458fd2ecae71383ce039742b6", tag = "🦋正义之眼看得穿邪恶之心🦋", color = "#CC91FA" },
    -- {identifier="char1:515fb937469e746d7a3e3c4b2a5980722b12381b",tag="律回岁晚冰霜少 春到入间草木知",color="#ef9ba1"},
    { identifier = "char1:322bc3cd920ccc047b3b29bdf4c450b914681b29", tag = "Neverland", color = "#ef9ba1" },
    { identifier = "char1:418dbcb9f2331e5b0579eff1d6dd7cac7be6e845", tag = "他时若遂凌云志，敢笑黄巢不丈夫", color = "#ef9ba1" },
    { identifier = "char1:56e229d92fb21b592f60476af45ccd36f1fe2641", tag = "MISTERK", color = "#ef9ba1" },
    { identifier = "char1:4278d229944362a7b018b55fad586f288eaa825c", tag = "打不过也不能跪下", color = "#f5b767" },
    { identifier = "char1:3d0c6dcefe76536d3e382aa47193a05d6c3cca2c", tag = "毕业于情爱的教室却从未找到过教堂", color = "#f567c5" },
    { identifier = "char1:813220ef04aef23527a6d8710f60cf23c8240cbe", tag = "光照在黑暗里，黑暗却不接受光", color = "#356ef2" },
    { identifier = "char1:cd65cea78f0419d3a7a9b9ea26c60c507ce7e9bd", tag = "城堡为爱守着秘密", color = "#f235ec" },
    { identifier = "char1:cf1aea2fef44298dfd5e5cde94101fa8bea5994d", tag = "💜Your King☁️", color = "#ED8CA1" },
    { identifier = "char1:2fb302d221e5839e54539374d5e868e03e3e28c8", tag = "💞天下兴亡匹夫责💞爱国情怀炽如火💞", color = "#f235ec" },
    { identifier = "char1:3a1c90ac20ec74b565bb8a6c665f7c54e3c06b22", tag = "手握日月摘星辰，世间无我这般人", color = "#3597f2" },
    { identifier = "char1:0244937dbeec437eecf7bb93ca30d6838c5e3bf2", tag = "高，还没富，但帅", color = "#f235ec" },
    { identifier = "char1:76bc84588e6bd788836a0b9d29b5aa8b17dfa47b", tag = "湾仔领导", color = "#35b0f2" },
    { identifier = "char1:5223d917928d8db35a7b590c488366ef2227b497", tag = "一言九鼎", color = "#a635f2" },
    { identifier = "char1:a73092285da0f5cd438104ce31d887df81afbac2", tag = "贪局", color = "#262625" },
    { identifier = "char1:14ae3051c056161c85a2331b77c87a67e102b549", tag = "🌸姑娘一句春不晚，痴儿留在真江南🌸", color = "#ed4ea3" },
    { identifier = "char1:10f14d9e89501206c62f835fd5694cd263bd74b9", tag = "Leo", color = "#FF60AF" },
    { identifier = "char1:99ef06d365649c5181bc5dd7f706caf49a28dd0b", tag = "街头智慧", color = "#60ff7a" },
    { identifier = "char1:b57cf92f2d94229861d5c8c29eac503f6aae33d1", tag = "左手哥", color = "#ed807e" },
    { identifier = "char1:ef7fe573f5d1cb4214ec32126d27b78e31c604c1", tag = "晚风轻拂过, 心间起涟漪", color = "#ed7ea7" },
    { identifier = "char1:242fb071ec311cb501723070c50ae510e046c940", tag = "❓", color = "#ebeae8" },
    { identifier = "char1:f8dfabeca747d2d14b519736e56bb05188e7c743", tag = "黑脸包公", color = "#ebeae8" },
    { identifier = "char1:083a11ad65cf2a292862c33e1f4939906f5479c3", tag = "✨ 派头全球资本  ✨", color = "#dba642" },
    { identifier = "char1:c45f4901500bf79607a84258784d16fb4d335d6c", tag = "💗 洛熙的主人 💗", color = "#ed5cac" },
    { identifier = "char1:3f2938906181b94f5cf11bbf764f3c4388f9dfa3", tag = "曰水火木金土此五行本乎数", color = "#e32d46" },
    { identifier = "char1:022000f5ccf44109666e3f76603dd12d1b75bcad", tag = "😍曙光赌神😍", color = "#dd2e2e" },
    { identifier = "char1:bda202a81f6131719e826d457cf455b8e013f868", tag = "🙂你骂我是你有病，我骂你还是你有病🙂", color = "#dce314" },
    { identifier = "char1:2502d17b95d8e686454a739f74dc8a307d1b32d5", tag = "恋爱要跟印度人谈 他们画的饼会飞", color = "#f23551" },
    { identifier = "char1:91c66eb8fad59e7fb7d32b2831f3673603fa07bf", tag = "🌙", color = "#f23551" },
    { identifier = "char1:e12e93651d5a3e007832e18605b47e37122ffd58", tag = "曙光第一双花红棍", color = "#f23551" },
    { identifier = "char1:07a730e51e18f4efd1d9f368c5a0c000fbbcbc32", tag = "🍂镜子点燃黑洞 列车驶进深空🍂", color = "#f04646" },
    { identifier = "char1:8626cfdaffaac32fb5109189a1a09d9331398b06", tag = "🚫禁止爆头🚫", color = "#FFD700" },
    { identifier = "char1:45c444870f2866bfbd31f0a14cfa75ce10e17da4", tag = "🤡", color = "#dd862e" },
    { identifier = "char1:96d03dcf7fe762ff0ca1aaaa5e9282f546288456", tag = "🐾街南绿树春绕絮🦋雪满游春路🐾", color = "#ed8d2d" },
    { identifier = "char1:73a878b87c25db80ef0a66894c6ceb95a54248d2", tag = "🧸", color = "#ed8d2d" },
    { identifier = "char1:583f66fcea099b25e980899ceb11ab46e4319a44", tag = "⛔切勿幻想⛔", color = "#161616" },
    { identifier = "char1:7474eab91ee53f8b812d6c16e746f3a11c1d63b8", tag = "✨君埋泉下泥销骨 我寄人间雪满头✨", color = "#8e27e8" },
    { identifier = "char1:39749888b33b18e82b99d6c31ff92db45b9dde3b", tag = "唯有爱在蔓延", color = "#66A3D4" },
    { identifier = "char1:9b3f6df3bd84614805e99401c8e2fbdac24cf47f", tag = "回忆终止雨落", color = "#66A3D4" },
    { identifier = "char1:0017acee321a3c6de4ebc0e877d7bc709dc0ad86", tag = "❄️❄️❄️❄️❄️❄️❄️", color = "#FFB6C1" },
    { identifier = "char1:a3a8a9762dfdd27411b8f803e422c8fd71fd0cce", tag = "🌸南风知我意 吹梦到西洲🌸", color = "#D3D3D3" },
    { identifier = "char1:ad2b852204ff0a1e05c8b340181deeb6f3f94dea", tag = "💞温文尔雅💞", color = "#BBD65B" },
    { identifier = "char1:bda202a81f6131719e826d457cf455b8e013f868", tag = "🙂你骂我是你有病，我骂你还是你有病🙂", color = "#d6b35c" },
    { identifier = "char1:741a164218933621fb5b948c3c9211340aae1979", tag = "这个杀手不太冷", color = "#800080" },
    { identifier = "char1:d01cb28bcbbf73886f75d260198b7fc8b6f2e4ba", tag = "黑警头子", color = "#0f0f0f" },
    { identifier = "char1:4099af25dafc16ecfee304295fd82e946ba655ef", tag = "✨人生若只如初见❤️何事悲风秋画扇🌙", color = "#F78A9D" },
    { identifier = "char1:07df9724b0ec195c596ce3e52388088eebd7bd34", tag = "请一边努力，一边快乐✨", color = "#FFFF00" },
    { identifier = "char1:400fe18442d684d416869992f21b8a15860f7df2", tag = "曙光第一变态", color = "#ff0000" },
    { identifier = "char1:4bf0b57a1bc26c8bbf6d019f004d70a382ccce4e", tag = "✨派头全球资本✨", color = "#C5C922" },
    { identifier = "char1:d80aa8a8333492d81d8c9bf1317706c01eaad1f4", tag = "手哥最温柔", color = "#f64444" },
    { identifier = "char1:71376a2368564046ebaced30b8721c6cfdd50361", tag = "💫红尘焉有忘机语🍓梦醒愿为无羡人💫", color = "#7AC3FE" },
    { identifier = "char1:8c7797559a44e74a0afd466e139ee30bd8f76e11", tag = "原谅我一生放荡不羁爱自由", color = "#E03A3A" },
    { identifier = "char1:0106d88535f009862138838614d6b6508224f605", tag = "🌊 ⛅ 行到水穷处 坐看云起时 ⛅ 🌊", color = "#CEF5D2" },
    { identifier = "char1:15e0278cd8869b29c89f1f302d175faa7b2fe6b7", tag = "🔥Life Is Only Thing We Need🔥", color = "#2E60A0" },
    { identifier = "char1:66afe5b348aebe46542411a8486cb6c1ba87fa66", tag = "💖 金山西见烟尘飞 💖", color = "#F29D9D" },
    { identifier = "char1:1b64e89d3d3b45176b85f4c80bc106f7c19f45ac", tag = "💓💓💓💓💓 打架带我一个 💞💞💞💞💞", color = "#FF8B5C" },
    { identifier = "char1:2936c5e189f0782047472be52d85a9c597fbf20d", tag = "❄️", color = "#fffefc" },
    { identifier = "char1:086fc3b64f0bd2a3dcc6ad58bce46b55c6633a48", tag = "💕循环的圆 不循环的缘💕", color = "#66A3D4" },
    { identifier = "char1:985d81d7ff93cb0e38bf79222ab13b52daa1fbd5", tag = "裤子不会自己掉 屁股不会自己翘", color = "#66A3D4" },
    { identifier = "char1:8eb4040dc4eb50814cf034ac2e890ea235bad6a7", tag = "🦩酆都山🦩", color = "#F644A5" },
    { identifier = "char1:28a962d978b47b3377dbb0dc8d8ea229a19e9214", tag = "人物模型找我", color = "#FE7AC3" },
    { identifier = "char1:cdc81def568cf1caae59956ce2b7cfc5701ebe50", tag = "离别秋无意 相逢人有心🍁", color = "#F644A5" },
    { identifier = "char1:9061a0a9773ce4c2f09699452fd5226d3ff84378", tag = "所爱隔山海，山海不可平", color = "#F644A5" },
    { identifier = "char1:8365405df0dbb0a6dcf25e82894a180434aff196", tag = "⚔️🗡️残缺的玉叫作王 王加三笔叫做狂⚔️🗡️", color = "#F644A5" },
    { identifier = "char1:77127b7037161bf270fa02d52fa82a6e909fd5de", tag = "小陆资本", color = "#A854F2" },
    { identifier = "char1:85a5d8c97d244a38adaf14de9bc3e8ef78d288d1", tag = "定格的一秒钟", color = "#ED8CA1" },
    { identifier = "char1:b47881387d8a8ecc2f7dd4b26810225b48cdf53c", tag = "💥山不让尘 川不辞盈💥", color = "#70A8AE" },
    { identifier = "char1:9bfefe213dcd221d9a85d31376770eb0a4489053", tag = "杀戮之王", color = "#70A8AE" },
    { identifier = "char1:b1dddcf16612727a729a3f7e8bff6fc9f2f1fab5", tag = "她朝若是同淋雪 此生也算共白头", color = "#ED8CA1" },
    { identifier = "char1:324793af8e0b0617e2709be36f6f56c5f7c4052f", tag = "鱼大善人哇哇哇娃哇哇哇", color = "#70A8AE" },
    { identifier = "char1:b3275950307273143b75481e71a54f17fdccb286", tag = "🦋临崖立马收缰晚 船到江心补漏迟🦋", color = "#D0D324" },
    { identifier = "char1:134d539f4f2faffe9fa33394304edf7a556410ab", tag = "左眼月读 读不尽人性贪婪 右眼天照 照不亮心路迷茫", color = "#FE7AC3" },
    { identifier = "char1:da5c320bc1b6499a64d7940d6b81d4d23508f364", tag = "人生在世 猖狂二字", color = "#E03A3A" },
    { identifier = "char1:c4f68f5b721721b38989200b6c45856904ceb644", tag = "白衣踏雪傲群雄，冰心一剑破苍穹", color = "#F644A5" },
    { identifier = "char1:4ec52ab5d3ddd51118fadc711d77087877d88428", tag = "忧郁小美女", color = "#ED8CA1" },
    { identifier = "char1:319bac9a974c3c05a5271441690bfe1a918544c9", tag = "朝云叆叇, 行露未晞", color = "#E78D9A" },
}

Config.AdminGroup = { -- 使用 Config.BeltAdminCommand 管理员权限
    'group=admin',    -- 默认管理员权限
    -- 'job=police', -- 普通职业权限
    -- 'jobwithgrade=police_4', -- 带有等级的职业权限
    'identifier=char1:3e2346bf4a20ba983cc360e08c9a535ff7d38dff', -- 指定玩家ID权限
    "identifier=char1:5d10ee90cd8ff5f4b043c8d133242f44ca0056e1",
    "identifier=char1:b3bde9053b488b1cba02022d70c7025759a687aa",
    "identifier=char1:a30028d22d601e2b6820a2bafce9b797f0a40390",
    "identifier=char1:80d7f3b7b4419830503e3520dc59bd67bb4b9091",
    "identifier=char1:228d1c585aac09f1d62100037cdc08b03bed72c9",
    "identifier=char1:3d0c6dcefe76536d3e382aa47193a05d6c3cca2c",
    "identifier=char1:1b64e89d3d3b45176b85f4c80bc106f7c19f45ac",
    "identifier=char1:39749888b33b18e82b99d6c31ff92db45b9dde3b",
    "identifier=char1:4ec52ab5d3ddd51118fadc711d77087877d88428",
    "identifier=char1:8eb4040dc4eb50814cf034ac2e890ea235bad6a7",
}

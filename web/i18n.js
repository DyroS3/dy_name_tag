(function (global) {
  const messages = {
    // Player view (Name Tag Control)
    'app.player.title': '头显控制',
    'app.player.subtitle': '管理你的头顶显示与超级头显状态',
    'app.player.adminButton': '管理超级标签',

    'card.global.title': '全局显示',
    'card.global.badge': '所有玩家',
    'card.global.description': '控制当前服务器中所有玩家的头顶标签是否显示.',

    'card.self.title': '我的显示',
    'card.self.badge': '自己',
    'card.self.description': '只控制你自己头顶的标签开关, 不影响其他玩家.',

    'card.super.title': '超级头显',
    'card.super.description.has': '你拥有超级头显, 可以在这里刷新你的显示效果.',
    'card.super.description.none': '暂未拥有超级头显, 解锁后可在此更新显示.',
    'card.super.selectLabel': '选择一个超级头显：',
    'card.super.applyButton': '应用选择',

    'toggle.global.label': '显示全部头顶标签',
    'toggle.self.label': '显示我的头顶标签',

    'status.global.label': '全局显示：',
    'status.self.label': '我的显示：',
    'status.super.label': '超级头显：',
    'status.on': '开启',
    'status.off': '关闭',
    'status.super.owned': '已拥有',
    'status.super.notOwned': '未拥有',

    // Admin view (Super Tag Admin)
    'admin.title': '超级标签控制',
    'admin.subtitle': '管理玩家的超级标签列表与当前选中项',
    'admin.backToPlayer': '返回玩家界面',

    'admin.identifier.cardTitle': '玩家标识',
    'admin.identifier.hint': '输入要管理的玩家唯一标识, 或从下方在线列表中点选填入.',
    'admin.identifier.placeholder': 'identifier...',
    'admin.identifier.loadButton': '加载玩家',

    'admin.online.label': '在线玩家：',
    'admin.online.searchPlaceholder': '搜索 ID / 名称 / 标识...',

    'admin.tags.cardTitle': '标签列表',
    'admin.tags.badgePrefix': '标签数：',
    'admin.tags.empty': '暂无标签, 可在右侧添加.',
    'admin.tags.setCurrent': '设为当前',
    'admin.tags.delete': '删除',
    'admin.tags.toggleEditor.show': '新增 / 颜色',
    'admin.tags.toggleEditor.hide': '收起编辑',

    'admin.editor.title': '新增与颜色',
    'admin.editor.description': '为该 identifier 添加新的超级标签, 或调整颜色.',
    'admin.editor.close': '关闭',
    'admin.editor.newTitlePlaceholder': '新的超级标签',
    'admin.editor.addTitleButton': '添加标题',
    'admin.editor.colorPlaceholder': '#FFFFFF',
    'admin.editor.applyColorButton': '设置颜色',

    'admin.mockPlayerNamePrefix': '测试玩家',
  };

  const api = {
    messages,
    t(key) {
      return Object.prototype.hasOwnProperty.call(messages, key) ? messages[key] : key;
    },
  };

  global.DY_I18N = api;
})(typeof window !== 'undefined' ? window : globalThis);

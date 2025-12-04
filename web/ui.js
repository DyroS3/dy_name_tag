const { createApp, reactive, computed, ref, watch } = Vue;

const I18N = (typeof window !== 'undefined' && window.DY_I18N) ? window.DY_I18N : {
  t(key) {
    return key;
  },
};

function createStore() {
  const state = reactive({
    visible: false,
    mode: 'player', // 保留字段，当前仅用于兼容
    // 是否为管理员，由服务端回调 dy_name_tag:getAdminContext 决定
    isAdmin: false,
    player: {
      showAllHeadtags: true,
      showSelfHeadtag: true,
      hasSuperTag: false,
      superTagMeta: null,
    },
    // 管理端相关状态：当前正在操作的 identifier、该 identifier 的档案、在线玩家列表
    admin: {
      identifier: '',
      entry: null,
      players: [],
    },
  });

  function applyOpenPayload(payload) {
    if (!payload) return;
    if (typeof payload.showAllHeadtags === 'boolean') state.player.showAllHeadtags = payload.showAllHeadtags;
    if (typeof payload.showSelfHeadtag === 'boolean') state.player.showSelfHeadtag = payload.showSelfHeadtag;
    if (typeof payload.hasSuperTag === 'boolean') state.player.hasSuperTag = payload.hasSuperTag;
    if (payload.superTagMeta !== undefined) state.player.superTagMeta = payload.superTagMeta;
    // 来自客户端 Lua 的管理员上下文：是否管理员 + 管理端 payload
    if (typeof payload.isAdmin === 'boolean') state.isAdmin = payload.isAdmin;
    if (payload.admin) {
      const a = payload.admin;
      if (typeof a.identifier === 'string') state.admin.identifier = a.identifier;
      if (a.entry !== undefined) state.admin.entry = a.entry;
      if (Array.isArray(a.players)) state.admin.players = a.players;
    }
  }

  function handleMessage(event) {
    const data = event.data || {};
    if (!data || !data.type) return;

    if (data.type === 'open') {
      state.visible = true;
      state.mode = 'player';
      applyOpenPayload(data.payload || {});
    } else if (data.type === 'update_state') {
      applyOpenPayload(data.payload || {});
    } else if (data.type === 'close') {
      state.visible = false;
      state.admin.identifier = '';
      state.admin.entry = null;
      state.admin.players = [];
    }
  }

  if (typeof window !== 'undefined') {
    window.addEventListener('message', handleMessage);
  }

  function sendMessage(payload) {
    // Placeholder: integrate with FiveM via RegisterNUICallback later.
    // This stub is kept side-effect free for now.
    try {
      if (typeof GetParentResourceName === 'function' && payload && payload.type) {
        fetch(`https://${GetParentResourceName()}/${payload.type}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: JSON.stringify(payload),
        });
      }
    } catch (e) {
      console.error('NUI fetch error', e);
    }
  }

  return { state, sendMessage };
}

const PlayerMenuView = {
  props: ['state', 'sendMessage', 'onToggleAdmin'],
  setup(props) {
    const t = I18N.t.bind(I18N);

    const statusText = computed(() => {
      return {
        global: props.state.player.showAllHeadtags ? t('status.on') : t('status.off'),
        self: props.state.player.showSelfHeadtag ? t('status.on') : t('status.off'),
        super: props.state.player.hasSuperTag ? t('status.super.owned') : t('status.super.notOwned'),
      };
    });

    const selectedTitle = ref(
      (props.state.player.superTagMeta && props.state.player.superTagMeta.selected) || ''
    );
    const selectOpen = ref(false);

    watch(
      () => props.state.player.superTagMeta && props.state.player.superTagMeta.selected,
      (val) => {
        selectedTitle.value = val || '';
      }
    );

    function toggleGlobal() {
      props.state.player.showAllHeadtags = !props.state.player.showAllHeadtags;
      props.sendMessage({ type: 'toggle_global', value: props.state.player.showAllHeadtags });
    }

    function toggleSelf() {
      props.state.player.showSelfHeadtag = !props.state.player.showSelfHeadtag;
      props.sendMessage({ type: 'toggle_self', value: props.state.player.showSelfHeadtag });
    }

    function updateSuperTag() {
      if (!selectedTitle.value) return;
      props.state.player.hasSuperTag = true;
      if (!props.state.player.superTagMeta) {
        props.state.player.superTagMeta = {};
      }
      props.state.player.superTagMeta.selected = selectedTitle.value;
      props.sendMessage({ type: 'set_super_title', title: selectedTitle.value });
    }

    function toggleSelectOpen() {
      if (!props.state.player.superTagMeta || !props.state.player.superTagMeta.list || !props.state.player.superTagMeta.list.length) return;
      selectOpen.value = !selectOpen.value;
    }

    function selectTitle(title) {
      selectedTitle.value = title;
      selectOpen.value = false;
    }

    return { t, statusText, selectedTitle, selectOpen, toggleGlobal, toggleSelf, updateSuperTag, toggleSelectOpen, selectTitle };
  },
  template: `
    <div>
      <header>
        <div style="display: flex; align-items: center; justify-content: space-between; gap: 12px;">
          <div>
            <h1 class="app-title">{{ t('app.player.title') }}</h1>
            <p class="app-subtitle">{{ t('app.player.subtitle') }}</p>
          </div>
          <!-- 仅管理员可见：打开/收起管理面板的按钮 -->
          <button
            v-if="state.isAdmin"
            class="neo-btn"
            style="width: 180px; height: 40px; font-size: 0.8rem; background: var(--accent-blue); color: #fff;"
            @click="onToggleAdmin && onToggleAdmin()"
          >
            {{ t('app.player.adminButton') }}
          </button>
        </div>
      </header>

      <section class="card-grid">
        <article class="neo-card">
          <div class="card-header">
            <h2 class="card-title">{{ t('card.global.title') }}</h2>
            <span class="badge-pill">{{ t('card.global.badge') }}</span>
          </div>
          <p class="neo-description">{{ t('card.global.description') }}</p>
          <div class="toggle-row">
            <span class="toggle-label">{{ t('toggle.global.label') }}</span>
            <div
              class="toggle-switch"
              :class="{ 'toggle-track-on': state.player.showAllHeadtags }"
              @click="toggleGlobal"
            >
              <div class="toggle-thumb" :class="{ 'toggle-thumb-on': state.player.showAllHeadtags }"></div>
            </div>
          </div>
        </article>

        <article class="neo-card">
          <div class="card-header">
            <h2 class="card-title">{{ t('card.self.title') }}</h2>
            <span class="badge-pill">{{ t('card.self.badge') }}</span>
          </div>
          <p class="neo-description">{{ t('card.self.description') }}</p>
          <div class="toggle-row">
            <span class="toggle-label">{{ t('toggle.self.label') }}</span>
            <div
              class="toggle-switch"
              :class="{ 'toggle-track-on': state.player.showSelfHeadtag }"
              @click="toggleSelf"
            >
              <div class="toggle-thumb" :class="{ 'toggle-thumb-on': state.player.showSelfHeadtag }"></div>
            </div>
          </div>
        </article>

        <article class="neo-card">
          <div class="card-header">
            <h2 class="card-title">{{ t('card.super.title') }}</h2>
            <span class="badge-pill" :class="{ warn: !state.player.hasSuperTag }">
              {{ state.player.hasSuperTag ? t('status.super.owned') : t('status.super.notOwned') }}
            </span>
          </div>
          <p class="neo-description">
            {{ state.player.hasSuperTag
              ? t('card.super.description.has')
              : t('card.super.description.none') }}
          </p>
          <div
            v-if="state.player.superTagMeta && state.player.superTagMeta.list && state.player.superTagMeta.list.length"
            style="margin-top: 8px; position: relative;"
          >
            <label class="neo-description" style="display: block; margin-bottom: 4px;">
              {{ t('card.super.selectLabel') }}
            </label>
            <div class="neo-select-wrapper" @click="toggleSelectOpen">
              <div class="neo-select-display">
                <span>{{ selectedTitle || state.player.superTagMeta.selected || state.player.superTagMeta.list[0] }}</span>
              </div>
              <div class="neo-select-arrow">▼</div>
              <ul v-if="selectOpen" class="neo-select-menu">
                <li
                  v-for="title in state.player.superTagMeta.list"
                  :key="title"
                  class="neo-select-item"
                  :class="{ active: title === selectedTitle }"
                  @click.stop="selectTitle(title)"
                >
                  {{ title }}
                </li>
              </ul>
            </div>
          </div>
          <button class="neo-btn neo-btn-primary" @click="updateSuperTag">
            {{ t('card.super.applyButton') }}
          </button>
        </article>
      </section>

      <footer class="footer-info">
        <div class="info-pill">
          <span class="dot" :class="{ off: !state.player.showAllHeadtags }"></span>
          <span>{{ t('status.global.label') }}{{ statusText.global }}</span>
        </div>
        <div class="info-pill">
          <span class="dot" :class="{ off: !state.player.showSelfHeadtag }"></span>
          <span>{{ t('status.self.label') }}{{ statusText.self }}</span>
        </div>
        <div class="info-pill">
          <span class="dot" :class="{ off: !state.player.hasSuperTag }"></span>
          <span>{{ t('status.super.label') }}{{ statusText.super }}</span>
        </div>
      </footer>
    </div>
  `,
};

const AdminPanelView = {
  props: ['state', 'sendMessage', 'onToggleAdmin'],
  setup(props) {
    const t = I18N.t.bind(I18N);
    const identifier = ref(props.state.admin.identifier || '');
    const entry = computed(() => props.state.admin.entry || null);
    // 在线玩家：仅来自服务端的真实在线玩家列表
    const onlinePlayers = computed(() => props.state.admin.players || []);

    const playerSearch = ref('');

    const filteredPlayers = computed(() => {
      const q = playerSearch.value.trim().toLowerCase();
      const list = onlinePlayers.value || [];
      if (!q) return list;

      return list.filter((p) => {
        const idStr = String(p.id || '').toLowerCase();
        const nameStr = String(p.name || '').toLowerCase();
        const identStr = String(p.identifier || '').toLowerCase();
        return (
          idStr.includes(q) ||
          nameStr.includes(q) ||
          identStr.includes(q)
        );
      });
    });

    watch(
      () => props.state.admin.identifier,
      (val) => {
        identifier.value = val || '';
      }
    );

    const newTitle = ref('');
    const colorInput = ref('');
    const editorVisible = ref(false);

    watch(
      entry,
      (val) => {
        if (val && val.color) {
          colorInput.value = val.color;
        }
      },
      { immediate: true }
    );

    function loadEntry() {
      if (!identifier.value) return;
      props.sendMessage({ type: 'admin_load_entry', identifier: identifier.value });
    }

    function addTitle() {
      if (!identifier.value || !newTitle.value) return;
      props.sendMessage({ type: 'admin_add_title', identifier: identifier.value, title: newTitle.value });
      newTitle.value = '';
    }

    function removeTitle(title) {
      if (!identifier.value || !title) return;
      props.sendMessage({ type: 'admin_remove_title', identifier: identifier.value, title });
    }

    function setCurrent(title) {
      if (!identifier.value || !title) return;
      props.sendMessage({ type: 'admin_set_title', identifier: identifier.value, title });
    }

    function applyColor() {
      if (!identifier.value || !colorInput.value) return;
      props.sendMessage({ type: 'admin_set_color', identifier: identifier.value, color: colorInput.value });
    }

    function toggleEditor() {
      editorVisible.value = !editorVisible.value;
    }

    return {
      t,
      identifier,
      entry,
      onlinePlayers,
      playerSearch,
      filteredPlayers,
      newTitle,
      colorInput,
      editorVisible,
      loadEntry,
      addTitle,
      removeTitle,
      setCurrent,
      applyColor,
      toggleEditor,
      onToggleAdmin: props.onToggleAdmin,
    };
  },
  template: `
    <div>
      <header>
        <div style="display: flex; align-items: center; justify-content: space-between; gap: 12px;">
          <div>
            <h1 class="app-title">{{ t('admin.title') }}</h1>
            <p class="app-subtitle">{{ t('admin.subtitle') }}</p>
          </div>
          <button
            class="neo-btn"
            style="width: 160px; height: 40px; font-size: 0.8rem; background: var(--accent-blue); color: #fff;"
            @click="onToggleAdmin && onToggleAdmin()"
          >
            {{ t('admin.backToPlayer') }}
          </button>
        </div>
      </header>

      <section class="neo-card admin-id-card" style="margin-bottom: 24px;">
        <div class="card-header admin-id-header">
          <h2 class="card-title">{{ t('admin.identifier.cardTitle') }}</h2>
          <p class="neo-description admin-id-hint">{{ t('admin.identifier.hint') }}</p>
        </div>
        <div class="admin-id-row">
          <input
            v-model="identifier"
            type="text"
            :placeholder="t('admin.identifier.placeholder')"
            class="admin-id-input"
          />
          <button class="neo-btn neo-btn-primary admin-id-btn" @click="loadEntry">
            {{ t('admin.identifier.loadButton') }}
          </button>
        </div>
        <div v-if="onlinePlayers.length" class="admin-online-list tag-list">
          <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 4px;">
            <p class="neo-description">{{ t('admin.online.label') }}</p>
            <input
              v-model="playerSearch"
              type="text"
              :placeholder="t('admin.online.searchPlaceholder')"
              class="admin-search-input"
            />
          </div>
          <div
            v-for="p in filteredPlayers"
            :key="p.id"
            class="admin-online-item tag-row"
            @click="identifier = p.identifier"
          >
            <span class="admin-online-name">[{{ p.id }}] {{ p.name }}</span>
            <span class="admin-online-id">{{ p.identifier }}</span>
          </div>
        </div>
      </section>

      <section v-if="entry" class="admin-grid">
        <article class="neo-card">
          <div class="card-header">
            <div style="display: flex; align-items: center; gap: 8px;">
              <h2 class="card-title">{{ t('admin.tags.cardTitle') }}</h2>
              <span class="badge-pill admin-info-pill">
                {{ t('admin.tags.badgePrefix') }}{{ (entry.list && entry.list.length) || 0 }}
              </span>
            </div>
            <button class="neo-btn-sm admin-editor-toggle" @click="toggleEditor">
              {{ editorVisible ? t('admin.tags.toggleEditor.hide') : t('admin.tags.toggleEditor.show') }}
            </button>
          </div>
          <p v-if="!entry.list || !entry.list.length" class="neo-description">{{ t('admin.tags.empty') }}</p>
          <div v-else class="tag-list">
            <div
              v-for="(title, idx) in entry.list"
              :key="title"
              class="tag-row"
            >
              <span class="tag-index">{{ idx + 1 }}</span>
              <span class="tag-text">{{ title }}</span>
              <div class="tag-actions">
                <button class="neo-btn-sm" @click="setCurrent(title)">
                  {{ t('admin.tags.setCurrent') }}
                </button>
                <button
                  class="neo-btn-sm tag-btn-danger"
                  @click="removeTitle(title)"
                >
                  {{ t('admin.tags.delete') }}
                </button>
              </div>
            </div>
          </div>
        </article>
      </section>

      <transition name="fade-scale">
        <div v-if="entry && editorVisible" class="admin-editor-overlay">
          <div class="neo-card admin-editor-modal">
            <div class="card-header">
              <h2 class="card-title">{{ t('admin.editor.title') }}</h2>
              <button class="neo-btn-sm admin-editor-close" @click="toggleEditor">
                {{ t('admin.editor.close') }}
              </button>
            </div>
            <p class="neo-description">{{ t('admin.editor.description') }}</p>
            <div style="margin-top: 8px; display: flex; gap: 8px;">
              <input
                v-model="newTitle"
                type="text"
                :placeholder="t('admin.editor.newTitlePlaceholder')"
                style="flex: 1; padding: 8px 10px; border-radius: 12px; border: 2px solid var(--border-color);"
              />
              <button class="neo-btn neo-btn-primary" style="width: 120px;" @click="addTitle">
                {{ t('admin.editor.addTitleButton') }}
              </button>
            </div>
            <div style="margin-top: 12px; display: flex; gap: 8px; align-items: center;">
              <input
                v-model="colorInput"
                type="text"
                :placeholder="t('admin.editor.colorPlaceholder')"
                style="flex: 1; padding: 8px 10px; border-radius: 12px; border: 2px solid var(--border-color);"
              />
              <input
                v-model="colorInput"
                type="color"
                class="admin-color-picker"
              />
              <button class="neo-btn" style="width: 120px; background: var(--accent-blue); color: #fff;" @click="applyColor">
                {{ t('admin.editor.applyColorButton') }}
              </button>
            </div>
          </div>
        </div>
      </transition>
    </div>
  `,
};

const AppRoot = {
  setup() {
    const store = createStore();
    // 是否展开管理面板，由玩家端右上角按钮控制
    const adminPanelVisible = ref(false);

    function toggleAdminPanel() {
      if (adminPanelVisible.value) {
        // 从管理界面返回玩家界面时，清空前端缓存的管理目标
        store.state.admin.identifier = '';
        store.state.admin.entry = null;
      }
      adminPanelVisible.value = !adminPanelVisible.value;
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' || e.key === 'Esc' || e.keyCode === 27) {
          if (!store.state.visible) return;
          e.preventDefault();
          adminPanelVisible.value = false;
          store.state.visible = false;
          store.state.admin.identifier = '';
          store.state.admin.entry = null;
          store.state.admin.players = [];
          store.sendMessage({ type: 'close_menu' });
        }
      });
    }

    return { store, adminPanelVisible, toggleAdminPanel };
  },
  components: { PlayerMenuView, AdminPanelView },
  template: `
    <div>
      <transition name="fade-scale">
        <div v-if="store.state.visible" class="neo-main-card">
          <transition name="mode-switch" mode="out-in">
            <PlayerMenuView
              v-if="!adminPanelVisible"
              :state="store.state"
              :sendMessage="store.sendMessage"
              :onToggleAdmin="toggleAdminPanel"
            />
            <AdminPanelView
              v-else
              :state="store.state"
              :sendMessage="store.sendMessage"
              :onToggleAdmin="toggleAdminPanel"
            />
          </transition>
        </div>
      </transition>
    </div>
  `,
};

createApp(AppRoot).mount('#app');

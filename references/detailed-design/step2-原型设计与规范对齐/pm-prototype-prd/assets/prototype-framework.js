/**
 * 高保真原型注释引擎 (Annotated Prototype Engine)
 * 类似墨刀/Axure的页面标注系统 + 框选迭代工具
 * 
 * 用法: 在生成的 HTML 原型中引入本脚本，通过 window.__PrototypeAnnotations API 添加注释
 *
 * @version 1.2 — 新增版本管理与回退：框选确认修改自动升版 + 本地版本台账 +
 *                 快照导出/回退（工具条「📜 版本」）。存储不可用时自动降级为会话内存
 */

(function () {
  'use strict';

  // ============================================================
  // 核心数据结构
  // ============================================================
  const CONFIG = {
    annotationColor: {
      interaction: '#1677ff', // 交互说明
      business: '#fa8c16', // 业务逻辑
      edgecase: '#ff4d4f', // 边界条件/异常
      permission: '#52c41a', // 权限规则
      note: '#722ed1', // 通用备注
    },
    annotationLabel: {
      interaction: '交互说明',
      business: '业务逻辑',
      edgecase: '边界异常',
      permission: '权限规则',
      note: '备注',
    },
  };

  // 存储所有注释
  let _annotations = [];
  let _selectionActive = false;
  let _addAnnotationActive = false;
  let _panelVisible = true;
  // ⚠️ Bug Fix: 多页面原型注释分组 - 当前活跃页面 ID
  let _activePage = null;
  // 多屏并排展示模式：多个页面同时可见（如登录+注册并排），注释面板按页面分组
  let _multiScreenMode = false;
  let _pageFilter = 'all'; // 'all' 或具体 pageId
  let _pageLabels = {}; // { pageId: '显示标签' }

  // ============================================================
  // 版本管理（v1.2 新增）— 框架代管版本号，消除“忘记升版本号/记台账”的遗忘点
  // 规则：框选确认修改 = 一次版本迭代。确认时框架自动升版（V1.0→V1.1…）、
  // 记录版本台账、保存“确认当下页面”快照；工具条「📜 版本」提供台账查看、
  // 快照导出文件、回退（有快照 → 新标签打开快照；无快照 → 生成回退指令给 AI）。
  // 安全设计：localStorage 不可用（file:// 协议下常见）时自动降级为会话内存；
  // 所有存储/快照操作均 try/catch 包裹，任何失败都不影响既有交互与原型内容。
  // ============================================================
  var _ver = {
    current: null,       // 当前版本号（如 '1.0'）；启动时由页面 aptVersion 标注与台账对账取最高
    history: [],         // 版本台账 [{ version, date, changes:[desc], snap:bool }]
    storageOk: false,    // 本地存储可用性（启动时探测）
    fp: null,            // 页面指纹：file:// 下多个原型共享同一存储域，用“标题+哈希”隔离
    snapMax: 6,          // 快照最多保留数（超出删除最旧）
    snapMaxLen: 450000,  // 单快照最大字符数（超出不落盘，仅保留台账，仍可导出当前页面）
    historyMax: 30,      // 台账最多保留条数
  };
  var _verPrefix = '原型 '; // aptVersion 标注的前缀（保留页面原有的 “原型 V” / “原型 ” 写法）

  function _verFingerprint() {
    if (_ver.fp) return _ver.fp;
    var base = document.title || (location.pathname.split('/').pop()) || 'unnamed';
    var h = 5381;
    for (var i = 0; i < base.length; i++) { h = ((h << 5) + h + base.charCodeAt(i)) | 0; }
    _ver.fp = base + '-' + (h >>> 0).toString(16);
    return _ver.fp;
  }
  function _verKey(k) { return 'apt-ver-' + _verFingerprint() + '-' + k; }

  // 探测 localStorage 可用性（file://、隐私模式下可能抛异常）
  function _verStorage() {
    if (_ver.storageOk) return true;
    try {
      var k = '__apt_ver_probe__';
      localStorage.setItem(k, '1');
      localStorage.removeItem(k);
      _ver.storageOk = true;
    } catch (e) { _ver.storageOk = false; }
    return _ver.storageOk;
  }

  // 从页面 aptVersion 标注读取文件侧版本号（如 “原型 V1.0”），并记住前缀写法
  function _verReadSpan() {
    try {
      var el = document.getElementById('aptVersion');
      if (!el) return null;
      var txt = String(el.textContent || '');
      var m = txt.match(/原型\s*(V)?\s*(\d+\.\d+)/i);
      if (m) { if (m[1]) _verPrefix = '原型 V'; else _verPrefix = '原型 '; return m[2]; }
      var m2 = txt.match(/(\d+\.\d+)/);
      return m2 ? m2[1] : null;
    } catch (e) { return null; }
  }
  function _verNum(v) {
    var m = String(v || '').match(/^(\d+)\.(\d+)$/);
    return m ? (+m[1]) * 1000 + (+m[2]) : -1;
  }
  function _verBumpText(v) {
    var p = String(v || '1.0').match(/^(\d+)\.(\d+)$/);
    var major = p ? +p[1] : 1;
    var minor = p ? +p[2] : 0;
    minor++;
    if (minor >= 100) { major++; minor = 0; }
    return major + '.' + minor;
  }
  function _verSyncSpan() {
    try {
      var el = document.getElementById('aptVersion');
      if (el && _ver.current) el.textContent = _verPrefix + _ver.current;
    } catch (e) {}
  }

  // 启动加载：页面 aptVersion 标注（文件侧事实版本）与台账（浏览器侧记忆）对账，取最高
  function _verLoad() {
    var ledger = null;
    if (_verStorage()) {
      try {
        var raw = localStorage.getItem(_verKey('ledger'));
        if (raw) ledger = JSON.parse(raw);
      } catch (e) { console.warn('[apt] 版本台账读取失败:', e); }
    }
    if (ledger && ledger.current) _ver.current = ledger.current;
    if (ledger && ledger.history) _ver.history = ledger.history;
    var spanV = _verReadSpan();
    if (spanV && _verNum(spanV) > _verNum(_ver.current)) _ver.current = spanV;
    if (!_ver.current) _ver.current = '1.0';
    _verReconcile();
  }

  // 台账与快照对账：为有快照但无条目的版本补“基线快照”条目，并校正 snap 标记
  function _verReconcile() {
    var have = {};
    _ver.history.forEach(function (e) { have[e.version] = true; });
    var keys = _verSnapKeys();
    for (var i = 0; i < keys.length; i++) {
      var v = _verSnapKeyVersion(keys[i]);
      if (!v) continue;
      if (!have[v]) { _ver.history.push({ version: v, date: '', changes: [], snap: true }); have[v] = true; }
      else {
        _ver.history.forEach(function (e) { if (e.version === v) e.snap = true; });
      }
    }
    _ver.history.sort(function (a, b) { return _verNum(a.version) - _verNum(b.version); });
  }

  // 框选确认 = 升版 + 记录台账 + 保存“上一版本”快照（确认当下 DOM 即上一版本内容，作为回退基线）
  function _verBump(desc) {
    var prev = _ver.current || '1.0';
    var next = _verBumpText(prev);
    var e0 = _verFind(prev);
    if (!e0) {
      _ver.history.push({ version: prev, date: '', changes: [], snap: _verSaveSnapshot(prev) });
    } else if (!e0.snap) {
      e0.snap = _verSaveSnapshot(prev);
    }
    var d = new Date();
    var dateStr = d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
    _ver.current = next;
    _ver.history.push({ version: next, date: dateStr, changes: [String(desc || '').trim()], snap: false });
    if (_ver.history.length > _ver.historyMax) _ver.history = _ver.history.slice(-_ver.historyMax);
    _verReconcile();
    _verSyncSpan();
    appendVersionBarEntry(next, desc);
    _verPersist();
    return next;
  }
  function _verFind(v) {
    for (var i = 0; i < _ver.history.length; i++) if (_ver.history[i].version === v) return _ver.history[i];
    return null;
  }
  function _verPersist() {
    if (!_verStorage()) return;
    try {
      localStorage.setItem(_verKey('ledger'), JSON.stringify({
        current: _ver.current,
        history: _ver.history.map(function (e) { return { version: e.version, date: e.date, changes: e.changes, snap: !!e.snap }; })
      }));
    } catch (e) { console.warn('[apt] 版本台账写入失败:', e); }
  }

  // 快照：序列化“干净原型”（剔除框架运行时注入的工具栏/面板/标注层容器，重新加载时框架会重建）
  function _verCapturedHTML() {
    try {
      var clone = document.documentElement.cloneNode(true);
      clone.querySelectorAll('.apt-toolbar, .apt-panel, #aptMarkerContainer, .apt-selector-overlay, .apt-selector-popup, #aptFloatTip, #aptModifyPanel, #aptAnnotatePopup').forEach(function (n) { n.remove(); });
      if (clone.body) clone.body.style.marginRight = '';
      return '<!DOCTYPE html>\n' + clone.outerHTML;
    } catch (e) { return null; }
  }
  function _verSaveSnapshot(version) {
    if (!_verStorage()) return false;
    var html = _verCapturedHTML();
    if (!html || html.length > _ver.snapMaxLen) return false;
    var key = _verKey('snap-' + String(version).replace('.', '_'));
    try {
      localStorage.setItem(key, html);
      _verEvictSnapshots(false);
      return true;
    } catch (e) {
      // 配额不足：删除最旧快照后重试一次
      var removed = _verEvictSnapshots(true);
      if (removed > 0) {
        try { localStorage.setItem(key, html); _verEvictSnapshots(false); return true; } catch (e2) { return false; }
      }
      return false;
    }
  }
  function _verSnapKeys() {
    var keys = [];
    if (!_verStorage()) return keys;
    try {
      var prefix = _verKey('snap-');
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        if (k && k.indexOf(prefix) === 0) keys.push(k);
      }
    } catch (e) {}
    return keys;
  }
  function _verSnapKeyVersion(key) {
    var m = String(key || '').match(/snap-(\d+)_(\d+)$/);
    return m ? m[1] + '.' + m[2] : null;
  }
  // 按版本号数值排序后删除最旧快照；force=true 时至少删 1 个（配额不足重试用）
  function _verEvictSnapshots(force) {
    var removed = 0;
    if (!_verStorage()) return removed;
    try {
      var list = _verSnapKeys().map(function (k) {
        var m = String(k).match(/snap-(\d+)_(\d+)$/);
        return { k: k, mj: m ? +m[1] : 0, mn: m ? +m[2] : 0 };
      }).sort(function (a, b) { return (a.mj - b.mj) || (a.mn - b.mn); });
      var target = force ? Math.max(0, list.length - 1) : Math.max(0, list.length - _ver.snapMax);
      for (var i = 0; i < target; i++) { localStorage.removeItem(list[i].k); removed++; }
    } catch (e) {}
    return removed;
  }
  function _verSnapGet(version) {
    if (!_verStorage()) return null;
    try { return localStorage.getItem(_verKey('snap-' + String(version).replace('.', '_'))); } catch (e) { return null; }
  }

  // 版本标注栏追加：原型按规范用 id="aptVersionBar"（或 data-apt-version-bar）声明容器
  function appendVersionBarEntry(version, desc) {
    try {
      var bar = document.getElementById('aptVersionBar') || document.querySelector('[data-apt-version-bar]');
      if (!bar) return;
      var d = new Date();
      var dateStr = d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
      var item = document.createElement('span');
      item.style.cssText = 'display:inline-block;margin:2px 10px 2px 0;padding:1px 10px;font-size:12px;border:1px solid #d9d9d9;border-radius:10px;background:#ffffff;color:#595959;white-space:nowrap;';
      var b = document.createElement('b');
      b.style.cssText = 'color:#1677ff;margin-right:6px;';
      b.textContent = 'v' + version + ' · ' + dateStr;
      item.appendChild(b);
      item.appendChild(document.createTextNode(String(desc || '').slice(0, 40)));
      bar.appendChild(item);
    } catch (e) {}
  }

  // 导出与回退
  function _verDownloadHTML(filename, html) {
    try {
      var blob = new Blob([html], { type: 'text/html;charset=utf-8' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(function () { URL.revokeObjectURL(url); }, 10000);
      return true;
    } catch (e) { return false; }
  }
  function _verSaveToFile(filename, html) {
    // Chrome/Edge：弹出系统保存位置选择，可直接存进产品库「详细设计/原型/」（过程文件夹）随项目留档；
    // 其他浏览器 / 用户取消 / 权限失败：回退为下载到浏览器下载目录（仍可对页面 Ctrl+S 另存为任意路径）
    if (window.showSaveFilePicker) {
      try {
        window.showSaveFilePicker({
          suggestedName: filename,
          types: [{ description: 'HTML 原型文件', accept: { 'text/html': ['.html'] } }],
        }).then(function (handle) {
          return handle.createWritable().then(function (writer) {
            return writer.write(html).then(function () { return writer.close(); });
          });
        }).then(function () {
          showFloatingTip('✅ 快照已保存到所选位置（建议与产品库「详细设计/原型/」过程文件夹一并留档）');
        }).catch(function (err) {
          if (!err || err.name !== 'AbortError') _verDownloadHTML(filename, html); // 用户取消则静默；其余失败回退下载
        });
        return;
      } catch (e) { /* 回退下载 */ }
    }
    if (!_verDownloadHTML(filename, html)) alert('导出失败（浏览器可能限制下载，可改用 Ctrl+S 保存，或用 Chrome/Edge 直选保存位置）');
  }
  function _verExportCurrent() {
    var html = _verCapturedHTML();
    if (!html) { alert('无法序列化当前页面'); return; }
    var name = (document.title || 'prototype').replace(/[\\/:*?"<>|]/g, '_') + '-current.html';
    _verSaveToFile(name, html);
  }
  function _verExportSnapshot(version) {
    var html = _verSnapGet(version);
    if (!html) { alert('该版本没有本地快照（可能因页面过大或存储不可用未落盘），请改用“回退指令”'); return; }
    var name = (document.title || 'prototype').replace(/[\\/:*?"<>|]/g, '_') + '-v' + version + '.html';
    _verSaveToFile(name, html);
  }
  function _verRollback(version) {
    var html = _verSnapGet(version);
    if (html) {
      if (!confirm('回退到 v' + version + '？将打开该版本快照（原文件不受影响；如需替换，请在快照页 Ctrl+S 另存为同名文件）。')) return;
      try {
        var url = URL.createObjectURL(new Blob([html], { type: 'text/html;charset=utf-8' }));
        var w = window.open(url, '_blank');
        if (!w) location.href = url; // 弹窗被拦截时同标签页打开
        setTimeout(function () { URL.revokeObjectURL(url); }, 60000);
        return;
      } catch (e) { /* 快照打开失败，降级为回退指令 */ }
    }
    _verRollbackInstruction(version);
  }
  // 无快照时的降级回退：把“该版本之后的变更记录”格式化成回退指令，复制给 AI 让它改回文件
  function _verRollbackInstruction(version) {
    var entry = _verFind(version);
    var lines = [
      '【原型版本回退指令】',
      '请把当前原型文件回退到 v' + version + ' 的状态：',
      '恢复要点（v' + version + ' 之后的变更，需要逐一撤销）：'
    ];
    var after = _ver.history.filter(function (e) { return _verNum(e.version) > _verNum(version); });
    if (after.length === 0) lines.push('（无已记录的后继变更，请对照该版本快照/标注手工核对）');
    after.forEach(function (e) {
      lines.push('- v' + e.version + '（' + (e.date || '?') + '）：' + ((e.changes || []).join('；') || '（无描述）'));
    });
    lines.push('回退后请同步版本标注栏为 v' + version + '，并逐项核对交互。');
    var text = lines.join('\n');
    function fallbackCopy() {
      try {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed'; ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        alert('该版本无本地快照。已复制回退指令到剪贴板，粘贴给 AI 即可让 AI 把文件改回 v' + version + '。');
      } catch (e2) {
        alert('该版本无本地快照，且自动复制失败，请手动把下方回退指令复制给 AI：\n\n' + text);
      }
    }
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function () {
          alert('该版本无本地快照，已生成回退指令并复制到剪贴板 —— 粘贴到对话框发送给 AI，即可让 AI 把文件改回 v' + version + '。');
        }, fallbackCopy);
        return text;
      }
    } catch (e) {}
    fallbackCopy();
    return text;
  }

  // 「📜 版本」面板：台账列表 + 每版导出/回退 + 当前页导出 + 存储状态提示
  function toggleVersionPanel() {
    var panel = document.getElementById('aptVersionPanel');
    if (!panel) panel = buildVersionPanel();
    if (!panel) return;
    if (panel.style.display !== 'none') { panel.style.display = 'none'; return; }
    renderVersionPanel(panel);
    panel.style.display = 'block';
  }
  function buildVersionPanel() {
    var panel = document.createElement('div');
    panel.id = 'aptVersionPanel';
    panel.style.cssText = 'position:fixed;top:64px;left:50%;transform:translateX(-50%);z-index:99999;width:440px;max-width:92vw;max-height:60vh;overflow-y:auto;background:#ffffff;border:1px solid #e8e8e8;border-radius:10px;box-shadow:0 8px 32px rgba(0,0,0,0.18);font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif;';
    panel.innerHTML = ''
      + '<div style="display:flex;align-items:center;gap:8px;padding:12px 16px;border-bottom:1px solid #f0f0f0;">'
      + '<span style="font-size:14px;font-weight:600;color:#262626;">📜 版本历史</span>'
      + '<span id="aptVerCurrent" style="font-size:12px;color:#8c8c8c;flex:1;"></span>'
      + '<button id="aptVerClose" style="width:24px;height:24px;border:none;background:transparent;cursor:pointer;font-size:15px;color:#8c8c8c;display:flex;align-items:center;justify-content:center;">✕</button>'
      + '</div>'
      + '<div id="aptVerList" style="padding:8px 12px;"></div>'
      + '<div id="aptVerHint" style="padding:4px 16px 12px;font-size:11px;color:#8c8c8c;line-height:1.6;border-top:1px solid #f0f0f0;"></div>';
    document.body.appendChild(panel);
    document.getElementById('aptVerClose').onclick = function () { panel.style.display = 'none'; };
    return panel;
  }
  function renderVersionPanel(panel) {
    var curEl = document.getElementById('aptVerCurrent');
    if (curEl) curEl.textContent = '当前 V' + (_ver.current || '1.0');
    var listEl = document.getElementById('aptVerList');
    if (!listEl) return;
    var html = ''
      + '<div style="display:flex;align-items:center;gap:8px;padding:6px 4px;margin-bottom:6px;">'
      + '<span style="font-size:12px;color:#595959;flex:1;">当前页面快照</span>'
      + '<button id="aptVerExportCurrent" style="padding:3px 12px;border:1px solid #d9d9d9;border-radius:6px;background:#fff;cursor:pointer;font-size:12px;color:#595959;">导出当前页面</button>'
      + '</div>';
    var list = _ver.history.slice().sort(function (a, b) { return _verNum(b.version) - _verNum(a.version); });
    if (list.length === 0) {
      html += '<div style="padding:16px 8px;text-align:center;color:#bfbfbf;font-size:12px;">暂无版本记录（框选确认修改后自动生成）</div>';
    } else {
      list.forEach(function (e) {
        var summary = ((e.changes || []).join('；') || (e.snap ? '（基线快照）' : '（无描述）'));
        html += '<div style="display:flex;align-items:center;gap:8px;padding:8px 4px;border-bottom:1px solid #f5f5f5;font-size:12px;">'
          + '<b style="color:#1677ff;flex-shrink:0;">v' + e.version + '</b>'
          + '<span style="color:#8c8c8c;flex-shrink:0;">' + (e.date || '—') + '</span>'
          + '<span style="flex:1;color:#595959;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="' + escapeHtml(summary) + '">' + escapeHtml(summary) + '</span>'
          + (e.snap
              ? '<button data-v="' + e.version + '" data-act="export" style="padding:2px 10px;border:1px solid #d9d9d9;border-radius:6px;background:#fff;cursor:pointer;font-size:12px;flex-shrink:0;">导出</button>'
                + '<button data-v="' + e.version + '" data-act="rollback" style="padding:2px 10px;border:1px solid #d9d9d9;border-radius:6px;background:#fff;cursor:pointer;font-size:12px;flex-shrink:0;">回退</button>'
              : '<button data-v="' + e.version + '" data-act="rollback" style="padding:2px 10px;border:1px solid #d9d9d9;border-radius:6px;background:#fff;cursor:pointer;font-size:12px;flex-shrink:0;color:#fa8c16;">回退指令</button>')
          + '</div>';
      });
    }
    listEl.innerHTML = html;
    var hintEl = document.getElementById('aptVerHint');
    if (hintEl) {
      hintEl.innerHTML = _ver.storageOk
        ? '快照为各版本确认时的页面状态，保存在本机（最多 ' + _ver.snapMax + ' 份，超限自动清理最旧）。导出时（Chrome/Edge）可直接选择保存位置，<b>建议存进产品库「详细设计/原型/」过程文件夹随项目留档</b>；正式版本以 AI 落盘的文件为准。'
        : '⚠️ 本页存储不可用（file:// 或隐私模式常见）→ 版本记录仅本次会话有效、刷新后消失；仍可随时导出当前页面。';
    }
    listEl.onclick = function (ev) {
      var btn = ev.target;
      if (!btn || !btn.dataset || !btn.dataset.act) return;
      if (btn.dataset.act === 'export') _verExportSnapshot(btn.dataset.v);
      else if (btn.dataset.act === 'rollback') _verRollback(btn.dataset.v);
    };
    var curBtn = document.getElementById('aptVerExportCurrent');
    if (curBtn) { curBtn.onclick = _verExportCurrent; }
  }

  // ============================================================
  // 获取下一个可用的注释编号（修复：删除后自动复用被删掉的编号）
  // ============================================================
  function getNextAnnotationId() {
    if (_annotations.length === 0) return 1;
    const used = new Set(_annotations.map(a => a.id));
    let n = 1;
    while (used.has(n)) n++;
    return n;
  }

  // ============================================================
  // 初始化
  // ============================================================
  function init() {
    injectStyles();
    createToolbar();
    // v1.2: 版本管理启动（此时 aptVersion 标注已存在，可读取文件侧版本并对账台账）
    _verLoad();
    _verSyncSpan();
    createAnnotationPanel();

    // 允许外部通过 window 注册注释
    window.__addAnnotation = addAnnotation;
    window.__addAnnotationOn = addAnnotationOn;
    window.__deleteAnnotation = deleteAnnotation;
    window.__clearAnnotations = clearAnnotations;
    window.__toggleAnnotationPanel = togglePanel;
    window.__toggleSelectionTool = toggleSelectionTool;
    window.__setPanelVisible = function (v) { _panelVisible = v; };
    window.__showFloatingTip = showFloatingTip;
    // ⚠️ Bug Fix: 多页面原型注释分组 - 设置当前活跃页面
    window.__setActivePage = setActivePage;
    // 多屏并排展示模式 API
    window.__setMultiScreenMode = setMultiScreenMode;
    window.__setPageFilter = setPageFilter;
    // v1.2: 版本管理只读 API
    window.__getPrototypeVersion = function () { return _ver.current || '1.0'; };
    window.__getVersionHistory = function () { return _ver.history.slice(); };

    // 触发就绪回调：确保注释注册在框架初始化完成后执行
    if (typeof window.__onAnnotationsReady === 'function') {
      try { window.__onAnnotationsReady(); } catch(e) { console.error('__onAnnotationsReady error:', e); }
      delete window.__onAnnotationsReady;
    }

    // 页面点击添加注释
    document.addEventListener('click', function(e) {
      if (!_addAnnotationActive) return;
      // 防止击中自身或弹窗
      if (e.target.closest('.apt-toolbar, .apt-card, .apt-panel, .apt-selector-overlay, .apt-selector-popup, #aptModifyPanel')) return;
      _addAnnotationActive = false;
      document.getElementById('aptAddAnnotation').classList.remove('active');
      document.body.style.cursor = '';
      showAnnotationEditor(e.clientX, e.clientY);
    });
  }

  // ============================================================
  // 注入样式 (全部内容不依赖外部CSS)
  // ============================================================
  function injectStyles() {
    const style = document.createElement('style');
    style.textContent = `
      /* --- 原型工具按钮 --- */
      .apt-toolbar {
        position: fixed;
        top: 12px;
        left: 50%;
        transform: translateX(-50%);
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 6px 16px;
        background: #fff;
        border: 1px solid #e8e8e8;
        border-radius: 20px;
        box-shadow: 0 4px 16px rgba(0,0,0,0.12);
        z-index: 99999;
        font-size: 13px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
        user-select: none;
      }
      .apt-toolbar-btn {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 5px 12px;
        border: none;
        border-radius: 12px;
        background: transparent;
        color: #595959;
        cursor: pointer;
        font-size: 13px;
        font-family: inherit;
        transition: all 0.2s;
        white-space: nowrap;
      }
      .apt-toolbar-btn:hover { background: #f0f0f0; color: #262626; }
      .apt-toolbar-btn.active { background: #e6f4ff; color: #1677ff; }
      .apt-toolbar-btn.danger.active { background: #fff1f0; color: #ff4d4f; }
      .apt-toolbar-divider {
        width: 1px;
        height: 20px;
        background: #e8e8e8;
        margin: 0 4px;
      }
      .apt-toolbar-label {
        color: #8c8c8c;
        font-size: 12px;
      }
      /* --- 工具栏折叠态 --- */
      .apt-toolbar .apt-tb-collapse-btn {
        display: inline-flex; align-items: center; justify-content: center;
        width: 24px; height: 24px; border: none; background: transparent;
        cursor: pointer; font-size: 14px; color: #8c8c8c; border-radius: 50%;
        transition: background .15s, transform .3s; flex-shrink: 0;
      }
      .apt-toolbar .apt-tb-collapse-btn:hover { background: #f0f0f0; color: #595959; }
      .apt-toolbar.collapsed .apt-tb-collapse-btn { transform: rotate(180deg); }
      .apt-toolbar.collapsed .apt-tb-hide { display: none !important; }
      /* --- 拖拽把手(三线点阵) --- */
      .apt-toolbar .apt-tb-drag {
        display: inline-flex; flex-direction: column; align-items: center; justify-content: center;
        gap: 2px; width: 16px; height: 24px; cursor: grab; flex-shrink: 0;
        opacity: 0.4; transition: opacity .15s;
      }
      .apt-toolbar .apt-tb-drag:hover { opacity: 0.8; }
      .apt-toolbar .apt-tb-drag span { display: block; width: 14px; height: 2px; background: #bfbfbf; border-radius: 1px; }

      /* --- 注释标记 (Badge) --- */
      .apt-marker {
        position: absolute;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 24px;
        height: 24px;
        border-radius: 50%;
        color: #fff;
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        z-index: 9999;
        box-shadow: 0 2px 6px rgba(0,0,0,0.2);
        transition: transform 0.2s, box-shadow 0.2s;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', sans-serif;
        user-select: none;
      }
      .apt-marker:hover {
        transform: scale(1.25);
        box-shadow: 0 3px 10px rgba(0,0,0,0.3);
      }
      .apt-marker .apt-pulse {
        position: absolute;
        inset: -3px;
        border-radius: 50%;
        animation: aptPulse 2s ease-in-out infinite;
        opacity: 0;
        pointer-events: none;
      }
      @keyframes aptPulse {
        0% { transform: scale(1); opacity: 0.5; }
        100% { transform: scale(1.8); opacity: 0; }
      }

      /* --- 注释连线 --- */
      .apt-connector {
        position: absolute;
        z-index: 9998;
        pointer-events: none;
      }

      /* --- 注释卡片 (Tooltip) --- */
      .apt-card {
        position: absolute;
        z-index: 10000;
        width: 320px;
        max-height: 280px;
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 6px 24px rgba(0,0,0,0.15);
        border: 1px solid #e8e8e8;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.25s, visibility 0.25s, transform 0.25s;
        transform: translateY(8px);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
        overflow: hidden;
        pointer-events: auto;
      }
      .apt-card.visible {
        opacity: 1;
        visibility: visible;
        transform: translateY(0);
      }
      .apt-card-header {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 14px;
        border-bottom: 1px solid #f0f0f0;
      }
      .apt-card-badge {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 22px;
        height: 22px;
        border-radius: 50%;
        color: #fff;
        font-size: 11px;
        font-weight: 600;
        flex-shrink: 0;
      }
      .apt-card-title {
        font-size: 14px;
        font-weight: 600;
        color: #262626;
        flex: 1;
        line-height: 1.4;
        min-width: 0;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
      .apt-card-header-btn {
        width: 24px; height: 24px; border: none; background: transparent;
        cursor: pointer; font-size: 13px; color: #8c8c8c; border-radius: 4px;
        display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        transition: background .15s, color .15s;
      }
      .apt-card-header-btn:hover { background: #f5f5f5; color: #595959; }
      .apt-card-body {
        padding: 12px 14px;
        font-size: 13px;
        color: #595959;
        line-height: 1.6;
        max-height: 180px;
        overflow-y: auto;
      }
      /* --- 卡片展开态 --- */
      .apt-card.expanded .apt-card-body {
        max-height: 600px;
      }
      .apt-card.expanded {
        width: 480px;
        max-height: 700px;
      }
      .apt-card-tag {
        display: inline-block;
        padding: 1px 8px;
        border-radius: 10px;
        font-size: 11px;
        font-weight: 500;
        margin-bottom: 6px;
      }

      /* --- 右侧注释面板 --- */
      .apt-panel {
        position: fixed;
        top: 64px;
        right: 0;
        width: 340px;
        height: calc(100vh - 64px);
        background: #fff;
        border-left: 1px solid #e8e8e8;
        box-shadow: -4px 0 16px rgba(0,0,0,0.06);
        z-index: 99990;
        display: flex;
        flex-direction: column;
        transition: transform 0.3s ease;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
      }
      .apt-panel.hidden {
        transform: translateX(100%);
      }
      .apt-panel-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 14px 16px;
        border-bottom: 1px solid #f0f0f0;
        flex-shrink: 0;
      }
      .apt-panel-title {
        font-size: 15px;
        font-weight: 600;
        color: #262626;
      }
      .apt-panel-count {
        font-size: 12px;
        color: #8c8c8c;
        margin-left: 8px;
      }
      .apt-panel-close {
        border: none;
        background: transparent;
        cursor: pointer;
        color: #8c8c8c;
        font-size: 18px;
        width: 28px;
        height: 28px;
        border-radius: 4px;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      .apt-panel-close:hover { background: #f5f5f5; }
      .apt-panel-body {
        flex: 1;
        overflow-y: auto;
        padding: 8px 0;
      }
      .apt-panel-group {
        margin-bottom: 4px;
      }
      .apt-panel-group-title {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 8px 16px;
        font-size: 12px;
        font-weight: 600;
        color: #8c8c8c;
        cursor: pointer;
        user-select: none;
      }
      .apt-panel-group-title:hover { color: #595959; }
      .apt-panel-group-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        flex-shrink: 0;
      }
      .apt-panel-item {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        padding: 10px 16px;
        cursor: pointer;
        transition: background 0.15s;
        border-left: 3px solid transparent;
      }
      .apt-panel-item:hover { background: #fafafa; }
      .apt-panel-item.active {
        background: #e6f4ff;
        border-left-color: #1677ff;
      }
      .apt-panel-item-badge {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 20px;
        height: 20px;
        border-radius: 50%;
        color: #fff;
        font-size: 10px;
        font-weight: 600;
        flex-shrink: 0;
        margin-top: 1px;
      }
      .apt-panel-item-content {
        flex: 1;
        min-width: 0;
      }
      .apt-panel-item-title {
        font-size: 13px;
        font-weight: 500;
        color: #262626;
        line-height: 1.4;
        margin-bottom: 2px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }
      .apt-panel-item-desc {
        font-size: 12px;
        color: #8c8c8c;
        line-height: 1.5;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
      }
      .apt-panel-empty {
        padding: 40px 16px;
        text-align: center;
        color: #bfbfbf;
        font-size: 14px;
      }

      /* --- 页面筛选 Tab（多屏并排模式） --- */
      .apt-panel-tabs {
        display: flex;
        gap: 0;
        padding: 0 12px;
        border-bottom: 1px solid #f0f0f0;
        flex-shrink: 0;
        overflow-x: auto;
      }
      .apt-panel-tab {
        padding: 8px 14px;
        font-size: 12px;
        color: #8c8c8c;
        cursor: pointer;
        border: none;
        background: transparent;
        border-bottom: 2px solid transparent;
        transition: all 0.15s;
        white-space: nowrap;
        font-family: inherit;
      }
      .apt-panel-tab:hover { color: #595959; }
      .apt-panel-tab.active {
        color: #1677ff;
        border-bottom-color: #1677ff;
        font-weight: 600;
      }
      /* --- 页面分节标题（多屏并排模式 renderPanel 二级分组） --- */
      .apt-panel-page-header {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 10px 16px 6px;
        font-size: 13px;
        font-weight: 600;
        color: #262626;
        background: #fafafa;
        border-top: 1px solid #f0f0f0;
        border-bottom: 1px solid #f0f0f0;
      }
      .apt-panel-page-header .apt-panel-page-count {
        font-size: 11px;
        font-weight: 400;
        color: #8c8c8c;
        margin-left: auto;
      }

      /* --- 框选工具 --- */
      .apt-selector {
        position: fixed;
        z-index: 99995;
        pointer-events: none;
        background: rgba(22, 119, 255, 0.08);
        border: 2px dashed #1677ff;
        border-radius: 4px;
        opacity: 0;
        transition: opacity 0.1s;
      }
      .apt-selector.visible { opacity: 1; }
      .apt-selector-overlay {
        position: fixed;
        inset: 0;
        z-index: 99990;
        cursor: crosshair;
        display: none;
      }
      .apt-selector-overlay.active { display: block; }
      .apt-selector-popup {
        position: fixed;
        z-index: 99998;
        background: #fff;
        border-radius: 10px;
        box-shadow: 0 6px 24px rgba(0,0,0,0.18);
        border: 1px solid #e8e8e8;
        padding: 16px 20px;
        min-width: 240px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', sans-serif;
        display: none;
      }
      .apt-selector-popup.visible { display: block; }
      .apt-selector-popup h4 {
        margin: 0 0 6px;
        font-size: 14px;
        font-weight: 600;
        color: #262626;
      }
      .apt-selector-popup p {
        margin: 0 0 12px;
        font-size: 12px;
        color: #8c8c8c;
      }
      .apt-selector-popup textarea {
        width: 100%;
        height: 60px;
        border: 1px solid #d9d9d9;
        border-radius: 6px;
        padding: 8px;
        font-size: 13px;
        font-family: inherit;
        resize: vertical;
        box-sizing: border-box;
        margin-bottom: 10px;
      }
      .apt-selector-popup textarea:focus {
        border-color: #1677ff;
        outline: none;
        box-shadow: 0 0 0 2px rgba(22,119,255,0.1);
      }
      .apt-selector-popup-btns {
        display: flex;
        gap: 8px;
        justify-content: flex-end;
      }
      .apt-selector-popup-btns button {
        padding: 5px 16px;
        border-radius: 6px;
        border: 1px solid #d9d9d9;
        background: #fff;
        cursor: pointer;
        font-size: 13px;
        font-family: inherit;
        transition: all 0.2s;
      }
      .apt-selector-popup-btns .primary {
        background: #1677ff;
        color: #fff;
        border-color: #1677ff;
      }
      .apt-selector-popup-btns .primary:hover { background: #4096ff; }

      /* --- 辅助: 高亮目标元素 --- */
      .apt-highlight {
        outline: 2px solid #1677ff !important;
        outline-offset: 2px !important;
      }
    `;
    document.head.appendChild(style);
  }

  // ============================================================
  // 工具栏
  // ============================================================
  function createToolbar() {
    const bar = document.createElement('div');
    bar.className = 'apt-toolbar';
    bar.innerHTML = `
      <span class="apt-tb-drag" title="拖拽移动工具栏"><span></span><span></span><span></span></span>
      <button class="apt-tb-collapse-btn" id="aptToggleCollapse" title="收起/展开工具栏">◀</button>
      <span class="apt-toolbar-label apt-tb-hide">🛠 原型工具</span>
      <span class="apt-toolbar-divider apt-tb-hide"></span>
      <button class="apt-toolbar-btn active apt-tb-hide" id="aptTogglePanel" title="切换注释面板">
        📋 注释面板
      </button>
      <button class="apt-toolbar-btn apt-tb-hide" id="aptToggleMarkers" title="显示/隐藏全部注释标记">
        🔵 注释标记
      </button>
      <span class="apt-toolbar-divider apt-tb-hide"></span>
      <button class="apt-toolbar-btn danger apt-tb-hide" id="aptToggleSelector" title="框选模式 - 拖拽框选区域用于修改">
        ✂️ 框选模式
      </button>
      <span class="apt-toolbar-divider apt-tb-hide"></span>
      <button class="apt-toolbar-btn apt-tb-hide" id="aptAddAnnotation" title="添加注释 - 点击页面任意位置添加新注释">
        ➕ 添加注释
      </button>
      <span class="apt-toolbar-divider apt-tb-hide"></span>
      <button class="apt-toolbar-btn apt-tb-hide" id="aptVersionBtn" title="版本历史：查看台账 / 导出快照 / 回退">
        📜 版本
      </button>
      <span class="apt-toolbar-btn apt-tb-hide" id="aptVersion" style="cursor:default;color:#bfbfbf;font-size:12px;">
        原型 V1.0
      </span>
    `;
    document.body.appendChild(bar);

    let collapsed = false;
    document.getElementById('aptToggleCollapse').onclick = function () {
      collapsed = !collapsed;
      bar.classList.toggle('collapsed', collapsed);
      this.title = collapsed ? '展开工具栏' : '收起工具栏';
    };

    // 切换注释面板
    document.getElementById('aptTogglePanel').onclick = function () {
      togglePanel();
      this.classList.toggle('active');
    };
    // 切换注释标记可见性
    document.getElementById('aptToggleMarkers').onclick = function () {
      const markers = document.querySelectorAll('.apt-marker');
      const cards = document.querySelectorAll('.apt-card');
      const hidden = markers[0] && markers[0].style.display === 'none';
      markers.forEach(m => m.style.display = hidden ? '' : 'none');
      cards.forEach(c => c.classList.remove('visible'));
      this.classList.toggle('active');
    };
    document.getElementById('aptToggleMarkers').classList.add('active');
    // 框选工具
    document.getElementById('aptToggleSelector').onclick = function () {
      toggleSelectionTool();
      this.classList.toggle('active');
    };
    // 添加注释工具
    document.getElementById('aptAddAnnotation').onclick = function () {
      _addAnnotationActive = !_addAnnotationActive;
      this.classList.toggle('active');
      document.body.style.cursor = _addAnnotationActive ? 'cell' : '';
      // 添加提示
      if (_addAnnotationActive) {
        showFloatingTip('点击页面上任意位置添加新注释');
      }
    };
    // 版本历史面板（v1.2：框架代管版本号，框选确认自动升版，这里只负责查看/导出/回退）
    document.getElementById('aptVersionBtn').onclick = toggleVersionPanel;

    // 工具栏拖拽 - 拖拽把手(三线区域)或工具栏边缘
    let dragStartX = 0, dragStartY = 0, dragOrigL = 0, dragOrigT = 0, dragging = false;
    bar.addEventListener('mousedown', function(e) {
      // 按钮/分隔线不触发拖动 (但允许从拖拽把手或空白区拖动)
      if (e.target.closest('.apt-toolbar-btn, .apt-toolbar-divider, .apt-toolbar-label')) return;
      // 从collapse按钮以外的任何空白/拖拽把手区域都可拖动
      // 初始化inline样式(首次拖拽时从CSS位置转为inline)
      if (!bar.style.left || bar.style.left === '' || bar.style.left === 'auto') {
        var r = bar.getBoundingClientRect();
        bar.style.left = r.left + 'px';
        bar.style.top = r.top + 'px';
        bar.style.transform = 'none';
      }
      dragStartX = e.clientX;
      dragStartY = e.clientY;
      dragOrigL = parseFloat(bar.style.left) || 0;
      dragOrigT = parseFloat(bar.style.top) || 0;
      dragging = true;
      bar.style.cursor = 'grabbing';
      e.preventDefault();
    });
    document.addEventListener('mousemove', function(e) {
      if (!dragging) return;
      bar.style.left = (dragOrigL + e.clientX - dragStartX) + 'px';
      bar.style.top = (dragOrigT + e.clientY - dragStartY) + 'px';
    });
    document.addEventListener('mouseup', function() {
      if (!dragging) return;
      dragging = false;
      bar.style.cursor = '';
    });
  }

  // ============================================================
  // 浮动提示
  // ============================================================
  let _tipTimer = null;
  function showFloatingTip(msg) {
    const existing = document.getElementById('aptFloatTip');
    if (existing) existing.remove();
    const tip = document.createElement('div');
    tip.id = 'aptFloatTip';
    tip.style.cssText = 'position:fixed;top:80px;left:50%;transform:translateX(-50%);background:#1677ff;color:#fff;padding:8px 20px;border-radius:20px;font-size:13px;font-family:-apple-system,sans-serif;z-index:99999;box-shadow:0 4px 12px rgba(0,0,0,.2);transition:opacity .3s;pointer-events:none;white-space:nowrap;';
    tip.textContent = msg;
    document.body.appendChild(tip);
    clearTimeout(_tipTimer);
    _tipTimer = setTimeout(function() {
      tip.style.opacity = '0';
      setTimeout(function() { tip.remove(); }, 300);
    }, 3000);
  }

  // ============================================================
  // 注释面板 (右侧)
  // ============================================================
  function createAnnotationPanel() {
    const panel = document.createElement('div');
    panel.className = 'apt-panel';
    panel.id = 'aptPanel';
    panel.innerHTML = `
      <div class="apt-panel-header">
        <div>
          <span class="apt-panel-title">功能注释</span>
          <span class="apt-panel-count" id="aptCount">0 条</span>
        </div>
        <button class="apt-panel-close" id="aptPanelClose">✕</button>
      </div>
      <div class="apt-panel-tabs" id="aptPanelTabs" style="display:none;"></div>
      <div class="apt-panel-body" id="aptPanelBody">
        <div class="apt-panel-empty">暂无注释</div>
      </div>
    `;
    document.body.appendChild(panel);
    document.getElementById('aptPanelClose').onclick = function () {
      togglePanel();
      const btn = document.getElementById('aptTogglePanel');
      if (btn) btn.classList.remove('active');
    };
  }

  // ============================================================
  // ⚠️ Bug Fix: 多页面原型注释分组 - 页面切换时过滤注释可见性
  // ============================================================
  function setActivePage(pageId) {
    _activePage = pageId;
    if (!_multiScreenMode) {
      updateAnnotationVisibility();
      renderPanel();
    }
  }

  // ============================================================
  // 多屏并排展示模式：多个页面同时可见，注释面板按页面分组
  // ============================================================
  function setMultiScreenMode(enabled, pageLabels) {
    _multiScreenMode = !!enabled;
    _pageLabels = pageLabels || {};
    _pageFilter = 'all';
    // 渲染页面筛选 Tab
    renderPanelTabs();
    // 多屏模式下所有注释标记都可见（因为所有页面都同时显示）
    updateAnnotationVisibility();
    renderPanel();
  }

  function setPageFilter(filter) {
    _pageFilter = filter || 'all';
    // 更新 Tab 高亮
    document.querySelectorAll('.apt-panel-tab').forEach(function(tab) {
      tab.classList.toggle('active', tab.dataset.pageFilter === _pageFilter);
    });
    updateAnnotationVisibility();
    renderPanel();
  }

  function renderPanelTabs() {
    var tabsEl = document.getElementById('aptPanelTabs');
    if (!tabsEl) return;
    if (!_multiScreenMode || Object.keys(_pageLabels).length === 0) {
      tabsEl.style.display = 'none';
      tabsEl.innerHTML = '';
      return;
    }
    tabsEl.style.display = 'flex';
    var html = '<button class="apt-panel-tab' + (_pageFilter === 'all' ? ' active' : '') + '" data-page-filter="all" onclick="window.__setPageFilter(\'all\')">全部</button>';
    Object.keys(_pageLabels).forEach(function(pageId) {
      html += '<button class="apt-panel-tab' + (_pageFilter === pageId ? ' active' : '') + '" data-page-filter="' + pageId + '" onclick="window.__setPageFilter(\'' + pageId + '\')">' + escapeHtml(_pageLabels[pageId]) + '</button>';
    });
    tabsEl.innerHTML = html;
  }

  function updateAnnotationVisibility() {
    // 多屏并排模式：所有页面同时可见，按 _pageFilter 过滤标记显示
    if (_multiScreenMode) {
      _annotations.forEach(function(a) {
        var marker = document.querySelector('.apt-marker[data-aid="' + a.id + '"]');
        if (marker) {
          var visible = (_pageFilter === 'all') || (!a.page) || (a.page === _pageFilter);
          marker.style.display = visible ? '' : 'none';
        }
        var card = document.getElementById('aptCard_' + a.id);
        if (card) {
          var visible = (_pageFilter === 'all') || (!a.page) || (a.page === _pageFilter);
          if (!visible) card.classList.remove('visible');
        }
      });
      return;
    }
    // 单页/传统多页模式
    if (!_activePage) {
      document.querySelectorAll('.apt-marker').forEach(function(m) { m.style.display = ''; });
      return;
    }
    _annotations.forEach(function(a) {
      var marker = document.querySelector('.apt-marker[data-aid="' + a.id + '"]');
      if (marker) {
        var visible = (!a.page) || (a.page === _activePage);
        marker.style.display = visible ? '' : 'none';
      }
      var card = document.getElementById('aptCard_' + a.id);
      if (card) {
        var visible = (!a.page) || (a.page === _activePage);
        if (!visible) card.classList.remove('visible');
      }
    });
  }

  function renderPanel() {
    const body = document.getElementById('aptPanelBody');
    if (!body) return;
    const count = document.getElementById('aptCount');

    // === 多屏并排模式 ===
    if (_multiScreenMode) {
      var visibleAnnotations;
      if (_pageFilter === 'all') {
        visibleAnnotations = _annotations;
      } else {
        visibleAnnotations = _annotations.filter(function(a) { return !a.page || a.page === _pageFilter; });
      }
      if (count) {
        count.textContent = _pageFilter === 'all'
          ? _annotations.length + ' 条'
          : visibleAnnotations.length + ' 条（' + (_pageLabels[_pageFilter] || _pageFilter) + '）';
      }
      if (visibleAnnotations.length === 0) {
        body.innerHTML = '<div class="apt-panel-empty">暂无注释</div>';
        return;
      }
      // 二级分组：页面 → 类型
      var html = '';
      var pageIds = _pageFilter === 'all' ? Object.keys(_pageLabels) : [_pageFilter];
      // 全局注释（page 为 null）单独一组
      var globalItems = visibleAnnotations.filter(function(a) { return !a.page; });
      var typeOrder = ['interaction', 'business', 'edgecase', 'permission', 'note'];
      // 先渲染全局注释
      if (globalItems.length > 0 && _pageFilter === 'all') {
        html += '<div class="apt-panel-page-header"><span>🌐 全局</span><span class="apt-panel-page-count">' + globalItems.length + ' 条</span></div>';
        html += renderTypeGroups(globalItems, typeOrder);
      }
      // 再渲染各页面注释
      pageIds.forEach(function(pageId) {
        var pageItems = visibleAnnotations.filter(function(a) { return a.page === pageId; });
        if (pageItems.length === 0) return;
        html += '<div class="apt-panel-page-header"><span>' + escapeHtml(_pageLabels[pageId] || pageId) + '</span><span class="apt-panel-page-count">' + pageItems.length + ' 条</span></div>';
        html += renderTypeGroups(pageItems, typeOrder);
      });
      body.innerHTML = html;
      return;
    }

    // === 单页 / 传统多页模式 ===
    var visibleAnnotations2;
    if (_activePage) {
      visibleAnnotations2 = _annotations.filter(function(a) {
        return !a.page || a.page === _activePage;
      });
    } else {
      visibleAnnotations2 = _annotations;
    }

    if (count) {
      if (_activePage) {
        count.textContent = visibleAnnotations2.length + ' 条（当前页面）';
      } else {
        count.textContent = _annotations.length + ' 条';
      }
    }

    if (visibleAnnotations2.length === 0 && _annotations.length === 0) {
      body.innerHTML = '<div class="apt-panel-empty">暂无注释</div>';
      return;
    }
    if (visibleAnnotations2.length === 0 && _annotations.length > 0) {
      body.innerHTML = '<div class="apt-panel-empty">当前页面无注释\n<div style="font-size:12px;color:#bfbfbf;margin-top:8px;">共 ' + _annotations.length + ' 条注释在其他页面</div></div>';
      return;
    }

    body.innerHTML = renderTypeGroups(visibleAnnotations2, ['interaction', 'business', 'edgecase', 'permission', 'note']);
  }

  // 辅助：按类型渲染注释分组 HTML
  function renderTypeGroups(items, typeOrder) {
    var groups = {};
    items.forEach(function(a) {
      if (!groups[a.type]) groups[a.type] = [];
      groups[a.type].push(a);
    });
    var html = '';
    typeOrder.forEach(function(type) {
      var typeItems = groups[type];
      if (!typeItems || typeItems.length === 0) return;
      var color = CONFIG.annotationColor[type] || '#1677ff';
      html += '<div class="apt-panel-group"><div class="apt-panel-group-title"><span class="apt-panel-group-dot" style="background:' + color + '"></span>' + (CONFIG.annotationLabel[type] || type) + ' (' + typeItems.length + ')</div>';
      typeItems.forEach(function(a) {
        html += '<div class="apt-panel-item" data-aid="' + a.id + '" onclick="window.__focusAnnotation(' + a.id + ')"><span class="apt-panel-item-badge" style="background:' + color + '">' + a.id + '</span><div class="apt-panel-item-content"><div class="apt-panel-item-title">' + escapeHtml(a.title) + '</div><div class="apt-panel-item-desc">' + escapeHtml(a.description) + '</div></div><span class="apt-panel-item-del" onclick="event.stopPropagation();window.__deleteAnnotation(' + a.id + ')" title="删除" style="flex-shrink:0;width:20px;height:20px;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#bfbfbf;border-radius:4px;font-size:12px;transition:color .15s,background .15s;margin-left:4px;" onmouseover="this.style.color=\'#ff4d4f\';this.style.background=\'#fff1f0\'" onmouseout="this.style.color=\'#bfbfbf\';this.style.background=\'transparent\'">✕</span></div>';
      });
      html += '</div>';
    });
    return html;
  }

  // ============================================================
  // 添加注释（修复：使用 getNextAnnotationId 复用已删除的编号）
  // ============================================================
  function addAnnotation(opts) {
    const id = getNextAnnotationId();
    const defaultOpts = {
      id: id,
      title: '未命名注释',
      description: '请补充说明',
      type: 'interaction', // interaction | business | edgecase | permission | note
      page: _activePage, // ⚠️ Bug Fix: 多页面原型 - 注释所属页面 ID，默认为当前活跃页面
      x: 100,
      y: 100,
      targetSelector: null,
    };
    const annotation = Object.assign({}, defaultOpts, opts);
    annotation.id = id;
    _annotations.push(annotation);
    renderMarker(annotation);
    renderPanel();
    return id;
  }

  /**
   * 在指定目标元素附近添加注释(自动计算位置)
   * @param {string|Element} target CSS选择器或DOM元素 — 注释标记将附着在此目标旁边
   * @param {string} position 位置: 'right'(默认)/'left'/'top'/'bottom'
   * @param {object} opts 注释配置: { title, description, type }
   * @returns {number} 注释ID
   */
  function addAnnotationOn(target, position, opts) {
    var el = typeof target === 'string' ? document.querySelector(target) : target;
    if (!el) {
      console.warn('addAnnotationOn: target not found', target);
      return -1;
    }
    var rect = el.getBoundingClientRect();
    var padding = 10; // 标记与目标之间的间距
    var x, y;
    switch ((position || 'right')) {
      case 'right':  x = rect.right + padding; y = rect.top + (rect.height / 2) - 12; break;
      case 'left':   x = rect.left - padding - 24; y = rect.top + (rect.height / 2) - 12; break;
      case 'top':    x = rect.left + (rect.width / 2) - 12; y = rect.top - padding - 24; break;
      case 'bottom': x = rect.left + (rect.width / 2) - 12; y = rect.bottom + padding; break;
      default:       x = rect.right + padding; y = rect.top + (rect.height / 2) - 12;
    }
    // 边界约束
    x = Math.max(5, Math.min(x, window.innerWidth - 30));
    y = Math.max(5, Math.min(y, window.innerHeight - 30));
    return addAnnotation(Object.assign({}, opts, { x: x, y: y, targetSelector: typeof target === 'string' ? target : null }));
  }

  function renderMarker(a) {
    const color = CONFIG.annotationColor[a.type] || '#1677ff';
    const container = document.getElementById('aptMarkerContainer') || (function () {
      const c = document.createElement('div');
      c.id = 'aptMarkerContainer';
      c.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:9999;';
      document.body.appendChild(c);
      return c;
    })();

    // 标记
    const marker = document.createElement('div');
    marker.className = 'apt-marker';
    marker.style.cssText = `left:${a.x}px;top:${a.y}px;background:${color};pointer-events:auto;cursor:grab;`;
    marker.dataset.aid = a.id;
    marker.innerHTML = `<span>${a.id}</span><span class="apt-pulse" style="border:2px solid ${color}"></span>`;
    marker.onclick = function (e) {
      e.stopPropagation();
      toggleCard(a.id);
    };
    // 标记拖拽
    marker.addEventListener('mousedown', function (e) {
      if (e.button !== 0) return;
      e.stopPropagation();
      const startX = e.clientX, startY = e.clientY;
      const origX = a.x, origY = a.y;
      marker.style.cursor = 'grabbing';
      marker.style.transition = 'none';
      function onMove(ev) {
        a.x = origX + ev.clientX - startX;
        a.y = origY + ev.clientY - startY;
        marker.style.left = a.x + 'px';
        marker.style.top = a.y + 'px';
        const card = document.getElementById('aptCard_' + a.id);
        if (card) {
          card.style.left = (a.x + 30) + 'px';
          card.style.top = Math.max(10, a.y - 50) + 'px';
        }
      }
      function onUp() {
        document.removeEventListener('mousemove', onMove);
        document.removeEventListener('mouseup', onUp);
        marker.style.cursor = 'grab';
        renderPanel();
      }
      document.addEventListener('mousemove', onMove);
      document.addEventListener('mouseup', onUp);
    });
    container.appendChild(marker);

    // 卡片
    const card = document.createElement('div');
    card.className = 'apt-card';
    card.id = 'aptCard_' + a.id;
    card.style.cssText = 'position:absolute;z-index:10000;';
    // 构建header
    var header = document.createElement('div');
    header.className = 'apt-card-header';
    var badge = document.createElement('span');
    badge.className = 'apt-card-badge';
    badge.style.background = color;
    badge.textContent = a.id;
    header.appendChild(badge);
    var titleSpan = document.createElement('span');
    titleSpan.className = 'apt-card-title';
    titleSpan.textContent = a.title;
    header.appendChild(titleSpan);
    // 展开按钮
    var expandBtn = document.createElement('button');
    expandBtn.className = 'apt-card-header-btn';
    expandBtn.title = '展开/缩小';
    expandBtn.textContent = '⛶';
    expandBtn.onclick = function(e) { e.stopPropagation(); card.classList.toggle('expanded'); };
    header.appendChild(expandBtn);
    card.appendChild(header);
    // body
    var body = document.createElement('div');
    body.className = 'apt-card-body';
    body.id = 'aptCardBody_' + a.id;
    body.dataset.aid = a.id;
    var tag = document.createElement('span');
    tag.className = 'apt-card-tag';
    tag.style.cssText = 'background:' + color + '22;color:' + color + ';display:inline-block;padding:1px 8px;border-radius:10px;font-size:11px;font-weight:500;margin-bottom:6px;';
    tag.textContent = CONFIG.annotationLabel[a.type];
    body.appendChild(tag);
    var descDiv = document.createElement('div');
    descDiv.className = 'apt-card-desc-text';
    descDiv.innerHTML = escapeHtml(a.description).replace(/\n/g, '<br>');
    body.appendChild(descDiv);
    card.appendChild(body);
    // 双击编辑注释内容
    body.addEventListener('dblclick', function (e) {
      e.stopPropagation();
      e.preventDefault();
      window.getSelection().removeAllRanges();
      enableEdit(a.id, this);
    });
    // 定位卡片
    card.style.left = (a.x + 30) + 'px';
    card.style.top = Math.max(10, a.y - 50) + 'px';
    // 如果超出右侧边界，放在左侧
    setTimeout(() => {
      const rect = card.getBoundingClientRect();
      if (rect.right > window.innerWidth - 20) {
        card.style.left = Math.max(10, a.x - 330) + 'px';
      }
    }, 0);
    container.appendChild(card);
  }

  // ============================================================
  // 注释卡片双击编辑
  // ============================================================
  function enableEdit(id, bodyEl) {
    const a = _annotations.find(x => x.id === id);
    if (!a) return;

    // 检出是否已在编辑中
    if (bodyEl.querySelector('.apt-card-edit-area')) return;

    const textDiv = bodyEl.querySelector('.apt-card-desc-text');
    const currentText = a.description;

    // 创建编辑区
    const editArea = document.createElement('div');
    editArea.className = 'apt-card-edit-area';
    editArea.style.cssText = 'margin-top:6px;';
    editArea.innerHTML = '<textarea style="width:100%;min-height:60px;border:1px solid #1677ff;border-radius:4px;padding:6px 8px;font-size:13px;font-family:inherit;color:#262626;resize:vertical;box-sizing:border-box;outline:none;line-height:1.5;">' + escapeHtml(currentText) + '</textarea>'
      + '<div style="display:flex;gap:6px;margin-top:6px;justify-content:flex-end;">'
      + '<button class="apt-card-edit-save" style="padding:3px 12px;background:#1677ff;color:#fff;border:none;border-radius:4px;cursor:pointer;font-size:12px;font-family:inherit;">保存</button>'
      + '<button class="apt-card-edit-cancel" style="padding:3px 12px;background:#fff;color:#595959;border:1px solid #d9d9d9;border-radius:4px;cursor:pointer;font-size:12px;font-family:inherit;">取消</button>'
      + '</div>';

    // 隐藏文字预览，插入编辑区
    textDiv.style.display = 'none';
    bodyEl.appendChild(editArea);

    const textarea = editArea.querySelector('textarea');
    textarea.focus();
    textarea.setSelectionRange(textarea.value.length, textarea.value.length);

    // 保存
    editArea.querySelector('.apt-card-edit-save').onclick = function () {
      saveEdit(id, textarea.value, bodyEl, textDiv);
    };
    // 取消
    editArea.querySelector('.apt-card-edit-cancel').onclick = function () {
      cancelEdit(bodyEl, textDiv, editArea);
    };
    // Ctrl+Enter 快捷保存
    textarea.onkeydown = function (e) {
      if (e.ctrlKey && e.key === 'Enter') {
        saveEdit(id, textarea.value, bodyEl, textDiv);
      }
      if (e.key === 'Escape') {
        cancelEdit(bodyEl, textDiv, editArea);
      }
    };
    // 点击外部取消编辑
    function outsideClick(e) {
      if (!bodyEl.contains(e.target)) {
        cancelEdit(bodyEl, textDiv, editArea);
        document.removeEventListener('mousedown', outsideClick);
      }
    }
    setTimeout(function () {
      document.addEventListener('mousedown', outsideClick);
    }, 100);
  }

  function saveEdit(id, newText, bodyEl, textDiv) {
    const a = _annotations.find(x => x.id === id);
    if (!a) return;
    const trimmed = newText.trim();
    a.description = trimmed || '(空)';
    textDiv.innerHTML = escapeHtml(a.description).replace(/\n/g, '<br>');
    textDiv.style.display = '';
    const editArea = bodyEl.querySelector('.apt-card-edit-area');
    if (editArea) editArea.remove();
    // 同步更新面板
    renderPanel();
    // 通知用户
    const toast = document.createElement('div');
    toast.style.cssText = 'position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:#f6ffed;border:1px solid #b7eb8f;border-radius:6px;padding:8px 16px;font-size:13px;color:#52c41a;z-index:99999;font-family:-apple-system,sans-serif;box-shadow:0 4px 12px rgba(0,0,0,.1);transition:opacity .3s;';
    toast.textContent = '✅ 注释 #' + id + ' 已更新';
    document.body.appendChild(toast);
    setTimeout(function () {
      toast.style.opacity = '0';
      setTimeout(function () { toast.remove(); }, 300);
    }, 2000);
  }

  function cancelEdit(bodyEl, textDiv, editArea) {
    textDiv.style.display = '';
    if (editArea) editArea.remove();
  }

  // ============================================================
  // 注释卡片切换
  // ============================================================
  window.__focusAnnotation = function (id) {
    const a = _annotations.find(x => x.id === id);
    // 多屏并排模式：不切换页面，直接滚动定位
    if (!_multiScreenMode) {
      // 传统多页模式：如果注释属于其他页面，先切换页面
      if (a && a.page && a.page !== _activePage && _activePage) {
        if (typeof window.__switchToPage === 'function') {
          window.__switchToPage(a.page);
        } else {
          setActivePage(a.page);
        }
      }
    }
    // 关闭其他卡片
    document.querySelectorAll('.apt-card.visible').forEach(c => c.classList.remove('visible'));
    document.querySelectorAll('.apt-panel-item.active').forEach(c => c.classList.remove('active'));
    // 打开目标卡片
    const card = document.getElementById('aptCard_' + id);
    if (card) card.classList.add('visible');
    // 高亮面板项
    const item = document.querySelector(`.apt-panel-item[data-aid="${id}"]`);
    if (item) {
      item.classList.add('active');
      item.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
    // 高亮目标元素并滚动到该位置
    if (a && a.targetSelector) {
      const el = document.querySelector(a.targetSelector);
      if (el) {
        el.classList.add('apt-highlight');
        setTimeout(() => el.classList.remove('apt-highlight'), 3000);
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }
  };

  function toggleCard(id) {
    const card = document.getElementById('aptCard_' + id);
    if (!card) return;
    const visible = card.classList.contains('visible');
    // 关闭其他
    document.querySelectorAll('.apt-card.visible').forEach(c => c.classList.remove('visible'));
    if (!visible) {
      card.classList.add('visible');
      // 同步高亮面板项
      const item = document.querySelector(`.apt-panel-item[data-aid="${id}"]`);
      if (item) {
        document.querySelectorAll('.apt-panel-item.active').forEach(c => c.classList.remove('active'));
        item.classList.add('active');
      }
    }
  }

  window.hideCard = function (id) {
    const card = document.getElementById('aptCard_' + id);
    if (card) card.classList.remove('visible');
    const item = document.querySelector(`.apt-panel-item[data-aid="${id}"]`);
    if (item) item.classList.remove('active');
  };

  // ============================================================
  // 面板切换
  // ============================================================
  function togglePanel() {
    _panelVisible = !_panelVisible;
    const panel = document.getElementById('aptPanel');
    if (panel) panel.classList.toggle('hidden', !_panelVisible);
    // 调整页面内容
    document.body.style.marginRight = _panelVisible ? '340px' : '0';
  }

  // ============================================================
  // 框选工具
  // ============================================================
  let _selStartX = 0, _selStartY = 0;
  let _selEl = null, _selOverlay = null, _selPopup = null;

  function toggleSelectionTool() {
    _selectionActive = !_selectionActive;
    if (_selectionActive) {
      createSelectionElements();
      _selOverlay.classList.add('active');
      document.body.style.cursor = 'crosshair';
    } else {
      if (_selOverlay) _selOverlay.classList.remove('active');
      if (_selEl) _selEl.classList.remove('visible');
      if (_selPopup) _selPopup.classList.remove('visible');
      document.body.style.cursor = '';
    }
  }

  function createSelectionElements() {
    if (document.getElementById('aptSelectorOverlay')) return;

    _selOverlay = document.createElement('div');
    _selOverlay.className = 'apt-selector-overlay';
    _selOverlay.id = 'aptSelectorOverlay';

    _selEl = document.createElement('div');
    _selEl.className = 'apt-selector';
    _selEl.id = 'aptSelectorRect';
    _selOverlay.appendChild(_selEl);

    _selPopup = document.createElement('div');
    _selPopup.className = 'apt-selector-popup';
    _selPopup.id = 'aptSelectorPopup';
    _selPopup.innerHTML = `
      <h4>✂️ 框选区域</h4>
      <p>描述你要对此区域进行的修改：</p>
      <textarea id="aptModifyDesc" placeholder="例如：将此区域改为表格视图、调整按钮布局、添加筛选条件..."></textarea>
      <div class="apt-selector-popup-btns">
        <button id="aptSelCancel">取消</button>
        <button class="primary" id="aptSelConfirm">确认修改</button>
      </div>
    `;
    document.body.appendChild(_selOverlay);
    document.body.appendChild(_selPopup);

    // 鼠标事件
    _selOverlay.onmousedown = function (e) {
      _selStartX = e.clientX;
      _selStartY = e.clientY;
      _selEl.style.left = _selStartX + 'px';
      _selEl.style.top = _selStartY + 'px';
      _selEl.style.width = '0px';
      _selEl.style.height = '0px';
      _selEl.classList.add('visible');
      _selPopup.classList.remove('visible');
    };
    _selOverlay.onmousemove = function (e) {
      if (!_selEl.classList.contains('visible')) return;
      const x = Math.min(_selStartX, e.clientX);
      const y = Math.min(_selStartY, e.clientY);
      const w = Math.abs(e.clientX - _selStartX);
      const h = Math.abs(e.clientY - _selStartY);
      _selEl.style.left = x + 'px';
      _selEl.style.top = y + 'px';
      _selEl.style.width = w + 'px';
      _selEl.style.height = h + 'px';
    };
    _selOverlay.onmouseup = function (e) {
      if (!_selEl.classList.contains('visible')) return;
      const w = parseInt(_selEl.style.width);
      const h = parseInt(_selEl.style.height);
      if (w < 20 && h < 20) {
        _selEl.classList.remove('visible');
        return;
      }
      // 显示弹窗
      const left = Math.min(_selStartX, e.clientX) + 20;
      const top = Math.min(_selStartY, e.clientY) + 20;
      _selPopup.style.left = Math.min(left, window.innerWidth - 260) + 'px';
      _selPopup.style.top = Math.min(top, window.innerHeight - 200) + 'px';
      _selPopup.classList.add('visible');
      document.getElementById('aptModifyDesc').focus();
    };
    document.getElementById('aptSelCancel').onclick = function () {
      _selPopup.classList.remove('visible');
      _selEl.classList.remove('visible');
    };
    document.getElementById('aptSelConfirm').onclick = function () {
      const desc = document.getElementById('aptModifyDesc').value.trim();
      if (!desc) { alert('请描述修改内容'); return; }
      // v1.2: 框选确认修改 = 一次版本迭代，框架自动升版并记录台账/快照（无需手工升号）
      const newVer = _verBump(desc);
      const rect = _selEl.getBoundingClientRect();
      const result = {
        version: newVer,
        action: '框选修改请求',
        region: {
          left: Math.round(rect.left), top: Math.round(rect.top),
          width: Math.round(rect.width), height: Math.round(rect.height),
          xpath_center: Math.round(rect.left + rect.width / 2) + ',' + Math.round(rect.top + rect.height / 2)
        },
        description: desc,
        timestamp: new Date().toISOString(),
      };
      // 生成结构化修改请求文本
      const requestText = '【框选修改请求】\n'
        + '版本号: ' + result.version + '（版本已由框架自动升版，AI 落盘时把文件同步到该版本）\n'
        + '区域坐标: (' + result.region.left + ', ' + result.region.top + ') '
        + '尺寸: ' + result.region.width + 'x' + result.region.height + '\n'
        + '修改描述: ' + result.description + '\n'
        + '时间戳: ' + result.timestamp + '\n'
        + '---\n'
        + '请将此内容粘贴到对话框，AI 将根据框选区域和描述执行对应修改。';

      // 尝试自动复制到剪贴板
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(requestText).then(function() {
            showModifyPanel(result, requestText, true);
          }).catch(function() {
            showModifyPanel(result, requestText, false);
          });
        } else {
          showModifyPanel(result, requestText, false);
        }
      } catch(e) {
        showModifyPanel(result, requestText, false);
      }

      _selPopup.classList.remove('visible');
      _selEl.classList.remove('visible');
    };

    function showModifyPanel(result, text, copied) {
      var panel = document.getElementById('aptModifyPanel');
      if (!panel) {
        panel = document.createElement('div');
        panel.id = 'aptModifyPanel';
        panel.style.cssText = 'position:fixed;top:76px;left:50%;transform:translateX(-50%);z-index:99999;background:#fff;border-radius:10px;box-shadow:0 8px 32px rgba(0,0,0,.18);border:1px solid #e8e8e8;padding:16px 20px;width:520px;max-width:90vw;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif;';
        document.body.appendChild(panel);
      }
      // ⚠️ Bug Fix: 关闭按钮设置 display:none 后，第二次弹出需要重置为可见
      panel.style.display = '';
      panel.innerHTML = ''
        + '<div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;padding-bottom:10px;border-bottom:1px solid #f0f0f0;">'
        + '<span style="font-size:18px;">✂️</span>'
        + '<span style="font-size:15px;font-weight:600;color:#262626;flex:1;">框选修改请求已就绪 · V' + result.version + '</span>'
        + '<button id="aptModifyClose" style="width:24px;height:24px;border:none;background:transparent;cursor:pointer;font-size:16px;color:#8c8c8c;display:flex;align-items:center;justify-content:center;">✕</button>'
        + '</div>'
        + '<div style="margin-bottom:10px;font-size:13px;color:#595959;line-height:1.6;">'
        + '<div style="margin-bottom:6px;"><strong>框选区域</strong>：(' + result.region.left + ', ' + result.region.top + ') ' + result.region.width + '×' + result.region.height + 'px</div>'
        + '<div style="margin-bottom:6px;"><strong>修改描述</strong>：' + escapeHtml(result.description) + '</div>'
        + '</div>'
        + '<div style="background:#fafafa;border:1px solid #f0f0f0;border-radius:6px;padding:10px 12px;margin-bottom:10px;font-size:12px;line-height:1.6;color:#595959;max-height:120px;overflow-y:auto;word-break:break-all;font-family:monospace;">'
        + escapeHtml(text)
        + '</div>'
        + (copied
          ? '<div style="margin-bottom:10px;font-size:12px;color:#52c41a;display:flex;align-items:center;gap:4px;">✅ 已自动复制到剪贴板 — 直接粘贴到对话框发送给AI即可</div>'
          : '<div style="margin-bottom:10px;font-size:12px;color:#fa8c16;display:flex;align-items:center;gap:4px;">📋 请手动复制上方内容，粘贴到对话框发送给AI</div>')
        + '<button id="aptModifyCopyBtn" style="width:100%;padding:8px;border:1px solid #d9d9d9;border-radius:6px;background:#fff;cursor:pointer;font-size:13px;font-family:inherit;color:#595959;transition:background .15s;" onmouseover="this.style.background=\'#f5f5f5\'" onmouseout="this.style.background=\'#fff\'">📋 复制修改请求并发送给AI</button>';

      // 关闭按钮
      document.getElementById('aptModifyClose').onclick = function() {
        panel.style.display = 'none';
      };
      // 复制按钮
      document.getElementById('aptModifyCopyBtn').onclick = function() {
        try {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(function() {
              document.getElementById('aptModifyCopyBtn').textContent = '✅ 已复制，请粘贴到对话框';
              document.getElementById('aptModifyCopyBtn').style.background = '#f6ffed';
              document.getElementById('aptModifyCopyBtn').style.borderColor = '#b7eb8f';
            });
          } else {
            // fallback: select the text area
            var ta = document.createElement('textarea');
            ta.value = text;
            ta.style.position = 'fixed';
            ta.style.opacity = '0';
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
            document.getElementById('aptModifyCopyBtn').textContent = '✅ 已复制，请粘贴到对话框';
          }
        } catch(e) {
          alert('复制失败，请手动选择上方文本复制。');
        }
      };
    }

    function escapeHtml(t) {
      if (!t) return '';
      var d = document.createElement('div');
      d.textContent = t;
      return d.innerHTML;
    }

    // 点击空白处取消
    _selOverlay.onclick = function (e) {
      if (e.target === _selOverlay && !_selPopup.classList.contains('visible')) {
        _selEl.classList.remove('visible');
      }
    };
  }

  // ============================================================
  // 清理注释
  // ============================================================
  function clearAnnotations() {
    _annotations = [];
    const container = document.getElementById('aptMarkerContainer');
    if (container) container.innerHTML = '';
    renderPanel();
  }

  // 删除单条注释
  function deleteAnnotation(id) {
    try {
      var idx = -1;
      for (var i = 0; i < _annotations.length; i++) {
        if (_annotations[i].id === id) { idx = i; break; }
      }
      if (idx === -1) return;
      _annotations.splice(idx, 1);
      // 移除DOM元素 - 使用 remove() API (比 removeChild 更安全)
      var marker = document.querySelector('.apt-marker[data-aid="' + id + '"]');
      if (marker) marker.remove();
      var card = document.getElementById('aptCard_' + id);
      if (card) card.remove();
      renderPanel();
    } catch(ex) { console.error('deleteAnnotation error:', ex); }
  }

  // ============================================================
  // 辅助
  // ============================================================
  function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ============================================================
  // 添加注释编辑器弹窗
  // ============================================================
  function showAnnotationEditor(x, y) {
    var existing = document.getElementById('aptAnnotatePopup');
    if (existing) existing.remove();

    var popup = document.createElement('div');
    popup.id = 'aptAnnotatePopup';
    popup.style.cssText = 'position:fixed;z-index:99999;background:#fff;border-radius:10px;box-shadow:0 8px 32px rgba(0,0,0,.18);border:1px solid #e8e8e8;padding:16px 20px;width:360px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif;';

    var types = [
      { v: 'interaction', l: '交互说明', c: '#1677ff' },
      { v: 'business', l: '业务逻辑', c: '#fa8c16' },
      { v: 'edgecase', l: '边界异常', c: '#ff4d4f' },
      { v: 'permission', l: '权限规则', c: '#52c41a' },
      { v: 'note', l: '备注', c: '#722ed1' },
    ];
    var typeRadios = types.map(function(t) {
      return '<label style="display:inline-flex;align-items:center;gap:4px;margin-right:8px;font-size:12px;cursor:pointer;"><input type="radio" name="aptNewType" value="' + t.v + '" style="accent-color:' + t.c + '"><span style="color:' + t.c + '">' + t.l + '</span></label>';
    }).join('');

    popup.innerHTML = '<div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;padding-bottom:10px;border-bottom:1px solid #f0f0f0;">'
      + '<span style="font-size:16px;">➕</span>'
      + '<span style="font-size:15px;font-weight:600;color:#262626;flex:1;">添加新注释</span>'
      + '<button id="aptAnnotateClose" style="width:24px;height:24px;border:none;background:transparent;cursor:pointer;font-size:16px;color:#8c8c8c;display:flex;align-items:center;justify-content:center;">✕</button>'
      + '</div>'
      + '<div style="margin-bottom:8px;font-size:12px;color:#8c8c8c;">点击位置：(' + x + ', ' + y + ')</div>'
      + '<div style="margin-bottom:10px;"><input id="aptAnnotateTitle" style="width:100%;height:32px;border:1px solid #d9d9d9;border-radius:6px;padding:0 10px;font-size:13px;font-family:inherit;box-sizing:border-box;outline:none;" placeholder="注释标题（必填）"></div>'
      + '<div style="margin-bottom:10px;"><textarea id="aptAnnotateDesc" style="width:100%;height:60px;border:1px solid #d9d9d9;border-radius:6px;padding:6px 10px;font-size:13px;font-family:inherit;resize:vertical;box-sizing:border-box;outline:none;" placeholder="注释说明"></textarea></div>'
      + '<div style="margin-bottom:12px;font-size:12px;color:#595959;">类型：<br>' + typeRadios + '</div>'
      + '<div style="display:flex;gap:8px;justify-content:flex-end;padding-top:8px;border-top:1px solid #f0f0f0;">'
      + '<button id="aptAnnotateCancel" style="padding:5px 16px;border:1px solid #d9d9d9;border-radius:6px;background:#fff;cursor:pointer;font-size:13px;font-family:inherit;color:#595959;">取消</button>'
      + '<button id="aptAnnotateSave" style="padding:5px 16px;background:#1677ff;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:13px;font-family:inherit;">添加注释</button>'
      + '</div>';

    // 定位
    var left = Math.min(x, window.innerWidth - 380);
    var top = Math.min(y + 20, window.innerHeight - 320);
    if (top < 10) top = y + 20;
    popup.style.left = Math.max(10, left) + 'px';
    popup.style.top = Math.max(10, top) + 'px';
    document.body.appendChild(popup);

    document.getElementById('aptAnnotateTitle').focus();

    document.getElementById('aptAnnotateClose').onclick = function() { popup.remove(); };
    document.getElementById('aptAnnotateCancel').onclick = function() { popup.remove(); };
    document.getElementById('aptAnnotateSave').onclick = function() {
      var title = document.getElementById('aptAnnotateTitle').value.trim();
      if (!title) { alert('请输入注释标题'); return; }
      var desc = document.getElementById('aptAnnotateDesc').value.trim();
      var typeEl = document.querySelector('input[name="aptNewType"]:checked');
      var type = typeEl ? typeEl.value : 'interaction';
      var id = addAnnotation({ title: title, description: desc || '无说明', type: type, x: x, y: y });
      popup.remove();
      showFloatingTip('已添加注释 #' + id);
    };
  }

  // ============================================================
  // 启动
  // ============================================================
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

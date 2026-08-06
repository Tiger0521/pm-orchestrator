import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const PROCESS_ID_PATTERN = String.raw`\b(?:req|diagnostic|epic|feature|story|matrix|flow|proto|contract|rules|sprint)-\d+\b`;

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function safeName(value, label) {
  if (!value || value === '.' || value === '..' || /[\s:/\\*?<>|"]/.test(value)) {
    fail(`${label}为空或包含禁用字符: ${value}`);
  }
}

function escapedRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function processIdFromReference(value) {
  const basename = value.trim().replaceAll('\\', '/').split('/').at(-1)?.replace(/\.md$/i, '') || '';
  const match = basename.match(new RegExp(`^(${PROCESS_ID_PATTERN})$`, 'i'));
  return match?.[1]?.toLowerCase() || '';
}

function processIdsIn(text) {
  return [...text.matchAll(new RegExp(PROCESS_ID_PATTERN, 'gi'))].map((match) => match[0].toLowerCase());
}

function replacementForProcessId(sourceId, idLinks, referenceLabels, sourceLabel) {
  const targetName = idLinks.get(sourceId);
  if (targetName) return { targetName };
  const label = referenceLabels.get(sourceId);
  if (label) return { label };
  throw new Error(`${sourceLabel}: 无法将过程 ID ${sourceId} 映射为产品库文档或可读名称`);
}

function rewriteWikiLinks(text, idLinks, referenceLabels, sourceLabel) {
  return text.replace(/(!?)\[\[([^\]|#^]+)(#[^\]|]+|\^[^\]|]+)?(?:\|([^\]]+))?\]\]/g, (whole, embed, rawTarget, anchor = '', alias = '') => {
    const sourceId = processIdFromReference(rawTarget);
    if (!sourceId) return whole;
    const replacement = replacementForProcessId(sourceId, idLinks, referenceLabels, sourceLabel);
    if (replacement.targetName) return `${embed}[[${replacement.targetName}${anchor}${alias ? `|${alias}` : ''}]]`;
    return alias.trim() || replacement.label;
  });
}

function rewriteMarkdownLinks(text, idLinks, referenceLabels, sourceLabel) {
  return text.replace(/(!?)\[([^\]]*)\]\(([^)\s]+)(\s+"[^"]*")?\)/g, (whole, embed, label, href) => {
    if (/^[a-z][a-z0-9+.-]*:/i.test(href) || href.startsWith('//')) return whole;
    const [rawTarget, fragment = ''] = href.split(/(?=#)/, 2);
    const sourceId = processIdFromReference(rawTarget);
    if (!sourceId) return whole;
    const replacement = replacementForProcessId(sourceId, idLinks, referenceLabels, sourceLabel);
    if (replacement.targetName) return `${embed}[[${replacement.targetName}${fragment}${label ? `|${label}` : ''}]]`;
    return label.trim() || replacement.label;
  });
}

function rewriteProcessReferences(text, idLinks, referenceLabels, sourceLabel) {
  let rewritten = rewriteMarkdownLinks(text, idLinks, referenceLabels, sourceLabel);
  rewritten = rewriteWikiLinks(rewritten, idLinks, referenceLabels, sourceLabel);
  const replacements = new Map(idLinks);
  for (const [sourceId, label] of referenceLabels) if (!replacements.has(sourceId)) replacements.set(sourceId, label);
  for (const [sourceId, replacement] of replacements) {
    rewritten = rewritten.replace(new RegExp(`\\b${escapedRegex(sourceId)}\\b`, 'gi'), () => replacement);
  }
  const unresolved = [...new Set(processIdsIn(rewritten))];
  if (unresolved.length) throw new Error(`${sourceLabel}: 产品库文档不得保留过程 ID: ${unresolved.join(', ')}`);
  return rewritten;
}

function keepLibraryFrontmatter(raw, dropGeneratedFields = true) {
  const kept = [];
  let skipNested = false;
  for (const line of raw) {
    const top = line.match(/^([A-Za-z][A-Za-z0-9_-]*):/);
    if (top) {
      const excluded = dropGeneratedFields
        ? ['id', 'product', 'type', 'capability', 'status', 'projectId', 'refs', 'aliases', 'tags']
        : ['id', 'status', 'projectId', 'refs'];
      skipNested = excluded.includes(top[1]);
      if (skipNested) continue;
    } else if (skipNested && /^[ \t]/.test(line)) {
      continue;
    } else {
      skipNested = false;
    }
    kept.push(line);
  }
  return kept;
}

function parseFrontmatter(text) {
  const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/);
  if (lines[0]?.trim() !== '---') throw new Error('正式产物缺少 frontmatter');
  const end = lines.indexOf('---', 1);
  if (end < 0) throw new Error('正式产物 frontmatter 未闭合');
  const raw = lines.slice(1, end);
  const values = {};
  for (const line of raw) {
    const match = line.match(/^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$/);
    if (match) values[match[1]] = match[2].trim().replace(/^['"]|['"]$/g, '');
  }
  return { raw, body: lines.slice(end + 1).join('\n').replace(/^\n+/, ''), values };
}

function sectionValue(body, heading) {
  const escaped = heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = body.match(new RegExp(`^##\\s+${escaped}\\s*$\\n+([\\s\\S]+?)(?=\\n##\\s|$)`, 'm'));
  if (!match) return '';
  return match[1].split(/\r?\n/).map((line) => line.trim().replace(/^[`*_ ]+|[`*_ ]+$/g, '')).find(Boolean) || '';
}

function capabilityPath(value) {
  const parts = value.split(/[/，]/).map((item) => item.trim()).filter(Boolean);
  if (parts.length < 1 || parts.length > 2) fail(`能力名称必须是一层叶子能力或父能力/子能力: ${value}`);
  return parts.map((part) => {
    safeName(part, '能力名称');
    return part.endsWith('能力') ? part : `${part}能力`;
  }).join('/');
}

function walkFiles(root, predicate = () => true) {
  if (!fs.existsSync(root)) return [];
  const result = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const target = path.join(root, entry.name);
    if (entry.isDirectory()) result.push(...walkFiles(target, predicate));
    else if (entry.isFile() && predicate(target)) result.push(target);
  }
  return result;
}

function architecturePath(libraryDir) {
  const matches = fs.readdirSync(libraryDir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && /^.+架构设计\.md$/u.test(entry.name))
    .map((entry) => path.join(libraryDir, entry.name));
  if (matches.length !== 1) fail('产品库必须且只能有一个匹配 /^.+架构设计\.md$/ 的架构设计文件');
  return matches[0];
}
function parseProductMatrix(lines) {
  const matrixStart = lines.findIndex((l) => l.trim() === '<!-- product-matrix:start -->');
  const matrixEnd = lines.findIndex((l) => l.trim() === '<!-- product-matrix:end -->');
  if (matrixStart < 0 || matrixEnd < 0 || matrixEnd <= matrixStart) fail('架构设计根文档缺少产品矩阵标记区域');
  const products = [];
  for (let i = matrixStart + 1; i < matrixEnd; i++) {
    const startMatch = lines[i].trim().match(/^<!-- product:(.+):start -->$/);
    if (!startMatch) continue;
    const productFull = startMatch[1];
    const endMarker = `<!-- product:${productFull}:end -->`;
    let endIdx = -1;
    for (let j = i + 1; j < matrixEnd; j++) {
      if (lines[j].trim() === endMarker) { endIdx = j; break; }
    }
    if (endIdx < 0) fail(`架构设计根文档中的产品 ${productFull} 标记未闭合`);
    const markerLines = lines.slice(i + 1, endIdx);
    const shortLine = markerLines.find((l) => /^\*\*简称\*\*：/.test(l));
    const short = shortLine ? shortLine.replace(/^\*\*简称\*\*：/, '').trim() : '';
    const capCount = markerLines.filter((l) => /^-\s+\[\[.+能力文档/.test(l)).length;
    const storyIndex = markerLines.findIndex((l) => l.trim() === '### 故事索引');
    const storyCount = storyIndex < 0 ? 0 : markerLines.slice(storyIndex + 1).filter((l) => /^-\s+\[\[/.test(l)).length;
    products.push({ full: productFull, short, capCount, storyCount, startIdx: i, endIdx });
    i = endIdx;
  }
  return { matrixStart, matrixEnd, products };
}

function storyFilenameStem(title) {
  const value = title.trim();
  if (!/^[\u4e00-\u9fffA-Za-z0-9]+(?:-[\u4e00-\u9fffA-Za-z0-9]+)*$/u.test(value)) fail(`用户故事标题只能包含中文、英文字母、数字和单个中划线，才能作为产品库文件名: ${title}`);
  return value.endsWith('故事') ? value : `${value}故事`;
}

function generateAliases(product, docType, capability, storyTitle = '') {
  if (docType === '需求卡片' || docType === '设计文档') return [product];
  if (docType === '能力文档') return [capability];
  if (docType === '用户故事') return [`${capability} ${storyTitle}`];
  return [];
}

function generateTags(productShort, docType, capability) {
  const tags = [productShort, docType];
  if (capability) tags.push(capability);
  return tags;
}

function rewriteDocument(source, product, productShort, docType, capability, relative, idLinks, referenceLabels) {
  const { raw, body: sourceBody, values } = parseFrontmatter(fs.readFileSync(source, 'utf8'));
  const kept = keepLibraryFrontmatter(raw);
  const body = rewriteProcessReferences(sourceBody, idLinks, referenceLabels, source);
  const front = ['---', `product: "${product}"`, `type: "${docType}"`];
  if (capability) front.push(`capability: "${capability}"`);
  const aliases = generateAliases(product, docType, capability, values.title || '');
  const tags = generateTags(productShort, docType, capability);
  front.push('aliases:');
  for (const a of aliases) front.push(`  - ${a}`);
  front.push('tags:');
  for (const t of tags) front.push(`  - ${t}`);
  front.push(...kept, '---');
  return rewriteProcessReferences(`${front.join('\n')}\n\n${body.trimEnd()}\n`, idLinks, referenceLabels, source);
}


function validateLibrary(scriptDir, libraryDir, bashExe) {
  const validator = path.join(scriptDir, 'validate-product-library.sh').replaceAll('\\', '/');
  const target = libraryDir.replaceAll('\\', '/');
  const result = spawnSync(bashExe, [validator, target], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`${result.stdout || ''}${result.stderr || ''}`);
}

function extractOverview(epicSourcePath, idLinks, referenceLabels) {
  const { body } = parseFrontmatter(fs.readFileSync(epicSourcePath, 'utf8'));
  const match = body.match(/^##\s+产品定位\s*\n+([\s\S]+?)(?=\n##\s|$)/m);
  return match ? rewriteProcessReferences(match[1].trim(), idLinks, referenceLabels, epicSourcePath) : '';
}

function generateProductBlock(product, short, plans) {
  const capGroups = new Map();
  const storyGroups = new Map();
  for (const plan of plans) {
    const parts = plan.capability.split('/');
    const parent = parts.length > 1 ? parts[0] : plan.capability;
    const linkName = path.parse(plan.relative).name;
    if (plan.type === '能力文档') {
      if (!capGroups.has(parent)) capGroups.set(parent, []);
      capGroups.get(parent).push(`- [[${linkName}|${plan.capability}]]`);
    } else if (plan.type === '用户故事') {
      if (!storyGroups.has(parent)) storyGroups.set(parent, []);
      storyGroups.get(parent).push(`- [[${linkName}|${plan.title}]]`);
    }
  }
  const lines = [`**简称**：${short}`, '', '### 能力索引', ''];
  for (const [parent, links] of capGroups) { lines.push(`#### ${parent}`, ...links, ''); }
  lines.push('### 故事索引', '');
  for (const [parent, links] of storyGroups) { lines.push(`#### ${parent}`, ...links, ''); }
  return lines.join('\n');
}

function updateArchitecture(archPath, product, short, plans, epicSource, idLinks, referenceLabels) {
  const lines = fs.readFileSync(archPath, 'utf8').split(/\r?\n/);
  const { matrixEnd, products } = parseProductMatrix(lines);
  const productStart = `<!-- product:${product}:start -->`;
  const productEnd = `<!-- product:${product}:end -->`;
  const markerContent = generateProductBlock(product, short, plans);
  const existing = products.find((p) => p.full === product);
  if (existing) {
    lines.splice(existing.startIdx + 1, existing.endIdx - existing.startIdx - 1, '', markerContent, '');
  } else {
    const overview = extractOverview(epicSource, idLinks, referenceLabels);
    const block = [`## ${product}`, '', overview, '', productStart, '', markerContent, '', productEnd, ''];
    lines.splice(matrixEnd, 0, ...block);
  }
  fs.writeFileSync(archPath, `${lines.join('\n').trimEnd()}\n`, 'utf8');
}

function exportProduct(args) {
  if (args.length < 6 || args.length > 7 || (args.length === 7 && args[5] !== '--apply')) {
    fail('用法: export <脚本目录> <项目目录> <产品库目录> <产品全名> <产品简称> [--apply] <bash>');
  }
  const [scriptDirRaw, projectRaw, libraryRaw, productName, productShort] = args;
  const applyChanges = args.length === 7;
  const bashExe = args.at(-1);
  const scriptDir = path.resolve(scriptDirRaw);
  const projectDir = path.resolve(projectRaw);
  const libraryDir = path.resolve(libraryRaw);
  safeName(productName, '产品全名');
  safeName(productShort, '产品简称');
  if (!/^[\u4e00-\u9fff]{2,6}$/u.test(productShort)) fail('产品简称必须为 2-6 个汉字');
  if (!/^[一-鿿]{2,6}：[一-鿿]+$/u.test(productName)) fail('产品全名格式应为 简称：描述（2-6 汉字简称＋全角冒号＋汉字描述）');
  if (productName.split('：')[0] !== productShort) fail('产品简称必须等于全名中冒号前的部分');
  if (!fs.statSync(projectDir, { throwIfNoEntry: false })?.isDirectory() || !fs.statSync(libraryDir, { throwIfNoEntry: false })?.isDirectory()) fail('项目目录或产品库目录不存在');
  if (path.basename(path.dirname(libraryDir)) !== 'product-library') fail('产品库目录不符合 v2 结构');
  const archPath = architecturePath(libraryDir);
  const registered = parseProductMatrix(fs.readFileSync(archPath, 'utf8').split(/\r?\n/)).products;
  for (const item of registered) {
    if (item.full === productName && item.short !== productShort) fail(`产品已登记简称 ${item.short}，请使用 rename-product.sh 变更`);
    if (item.short === productShort && item.full !== productName) fail(`简称已被产品 ${item.full} 使用`);
  }

  const refsPath = path.join(projectDir, 'refs.json');
  if (!fs.existsSync(refsPath)) fail('项目缺少 refs.json');
  let refs;
  try { refs = JSON.parse(fs.readFileSync(refsPath, 'utf8')); } catch (error) { fail(`refs.json 无法读取: ${error.message}`); }
  const referenceLabels = new Map();
  for (const node of refs.nodes || []) {
    if (typeof node.id !== 'string' || !processIdFromReference(node.id)) continue;
    const title = typeof node.title === 'string' ? node.title.trim() : '';
    if (title) referenceLabels.set(node.id.toLowerCase(), title);
  }
  const sources = [];
  const seen = new Set();
  for (const node of refs.nodes || []) {
    if (typeof node.path !== 'string') continue;
    const source = path.resolve(projectDir, node.path);
    if (path.relative(projectDir, source).startsWith('..')) fail(`refs.json 路径越界: ${node.path}`);
    if (seen.has(source) || !fs.statSync(source, { throwIfNoEntry: false })?.isFile() || path.extname(source).toLowerCase() !== '.md') continue;
    const parsed = parseFrontmatter(fs.readFileSync(source, 'utf8'));
    if (['requirement-card', 'epic', 'feature', 'user-story'].includes(parsed.values.type)) {
      sources.push({ source, nodeId: typeof node.id === 'string' ? node.id.toLowerCase() : '', ...parsed }); seen.add(source);
    }
  }
  if (!sources.length) fail('refs.json 未登记可导出的正式产物');
  const byType = new Map();
  for (const item of sources) {
    const list = byType.get(item.values.type) || [];
    list.push(item); byType.set(item.values.type, list);
  }
  if ((byType.get('requirement-card') || []).length !== 1 || (byType.get('epic') || []).length !== 1) fail('每个产品必须恰好包含一份需求卡片和一份 Epic');
  if (!(byType.get('feature') || []).length) fail('产品至少需要一份 Feature');

  const featureCaps = new Map();
  const capabilityOwners = new Map();
  for (const item of byType.get('feature') || []) {
    const id = item.values.id || path.parse(item.source).name;
    const capability = capabilityPath(item.values.capabilityPath || sectionValue(item.body, '能力名称') || item.values.title || '');
    const owner = capabilityOwners.get(capability);
    if (owner) fail(`Feature ${id} 与 ${owner} 规范化后使用同一能力路径: ${capability}`);
    capabilityOwners.set(capability, id);
    featureCaps.set(id, capability);
    if (item.nodeId) featureCaps.set(item.nodeId, capability);
  }
  const productDir = path.join(libraryDir, productName);
  const existingStoryPathsByTitle = new Map();
  for (const existing of walkFiles(productDir, (file) => file.includes(`${path.sep}UserStory${path.sep}`) && file.endsWith('.md'))) {
    try {
      const values = parseFrontmatter(fs.readFileSync(existing, 'utf8')).values;
      if (!values.title || !values.capability) continue;
      const titleKey = `${values.capability}\u0000${values.title.trim()}`;
      existingStoryPathsByTitle.set(titleKey, existingStoryPathsByTitle.has(titleKey) ? '' : existing);
    } catch { /* validation reports malformed existing files */ }
  }

  const plans = [];
  const req = byType.get('requirement-card')[0];
  const epic = byType.get('epic')[0];
  plans.push({ source: req.source, relative: `${productShort}-需求卡片.md`, type: '需求卡片', capability: '', id: req.values.id || path.parse(req.source).name });
  plans.push({ source: epic.source, relative: `${productShort}-设计文档.md`, type: '设计文档', capability: '', id: epic.values.id || path.parse(epic.source).name });
  for (const item of (byType.get('feature') || []).sort((a, b) => (a.values.id || a.source).localeCompare(b.values.id || b.source))) {
    const id = item.values.id || path.parse(item.source).name;
    const capability = featureCaps.get(id);
    const slug = capability.replaceAll('/', '-');
    plans.push({ source: item.source, relative: path.join(...capability.split('/'), `${productShort}-${slug}-能力文档.md`), type: '能力文档', capability, id });
  }

  for (const item of (byType.get('user-story') || []).sort((a, b) => (a.values.id || a.source).localeCompare(b.values.id || b.source))) {
    const id = item.values.id || path.parse(item.source).name;
    const featureId = (`${item.raw.join('\n')}\n${item.body}`.match(/feature-[0-9]+/g) || []).find((candidate) => featureCaps.has(candidate));
    if (!featureId) fail(`用户故事无法关联 Feature: ${item.source}`);
    const capability = featureCaps.get(featureId);
    const slug = capability.replaceAll('/', '-');
    const title = (item.values.title || '').trim();
    const filename = `${productShort}-${slug}-${storyFilenameStem(title)}.md`;
    const titleKey = `${capability}\u0000${title}`;
    const existingStoryPath = existingStoryPathsByTitle.get(titleKey);
    if (existingStoryPath === '') fail(`产品库中存在同一能力下重名的用户故事: ${capability}/${item.values.title}`);
    plans.push({ source: item.source, relative: path.join(...capability.split('/'), 'UserStory', filename), type: '用户故事', capability, id, title, existingStoryPath });
  }

  const idLinks = new Map();
  for (const plan of plans) {
    const targetName = path.parse(plan.relative).name;
    idLinks.set(plan.id.toLowerCase(), targetName);
    const nodeId = sources.find((item) => item.source === plan.source)?.nodeId;
    if (nodeId) idLinks.set(nodeId, targetName);
  }
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pm-library-export-'));
  try {
    const stage = path.join(tempRoot, productName);
    fs.mkdirSync(stage, { recursive: true });
    const statuses = [];
    for (const plan of plans) {
      const staged = path.join(stage, plan.relative);
      const target = path.join(productDir, plan.relative);
      fs.mkdirSync(path.dirname(staged), { recursive: true });
      fs.writeFileSync(staged, rewriteDocument(plan.source, productName, productShort, plan.type, plan.capability, plan.relative, idLinks, referenceLabels), 'utf8');
      const status = !fs.existsSync(target) ? 'NEW' : fs.readFileSync(target).equals(fs.readFileSync(staged)) ? 'UNCHANGED' : 'UPDATE';
      statuses.push({ status, staged, target });
    }
    const plannedTargets = new Set(statuses.map((item) => path.resolve(item.target)));
    const storyRenames = plans
      .filter((plan) => plan.existingStoryPath && path.resolve(plan.existingStoryPath) !== path.resolve(path.join(productDir, plan.relative)))
      .map((plan) => ({ source: plan.existingStoryPath, target: path.join(productDir, plan.relative) }));
    const renamedSources = new Set(storyRenames.map((item) => path.resolve(item.source)));
    const stale = walkFiles(productDir, (file) => file.endsWith('.md') && !plannedTargets.has(path.resolve(file)) && !renamedSources.has(path.resolve(file)))
      .map((target) => ({ status: 'STALE', target }))
      .sort((a, b) => a.target.localeCompare(b.target));

    console.log(applyChanges ? 'EXPORT_STATUS=APPLYING' : 'EXPORT_STATUS=PREVIEW');
    for (const item of statuses) console.log(`${item.status}\t${path.relative(libraryDir, item.target)}`);
    for (const item of stale) console.log(`${item.status}\t${path.relative(libraryDir, item.target)}`);
    for (const item of storyRenames) console.log(`RENAME\t${path.relative(libraryDir, item.source)}\t${path.relative(libraryDir, item.target)}`);

    if (!applyChanges) {
      if (stale.length) console.log('STALE 文件仅提示并保留；如需归档或删除，请单独处理。');
      console.log('确认以上清单后，以相同参数追加 --apply 执行写入。');
      return;
    }
    const backupArch = fs.readFileSync(archPath);
    const backupProduct = path.join(tempRoot, 'backup');
    const existed = fs.existsSync(productDir);
    if (existed) fs.cpSync(productDir, backupProduct, { recursive: true });
    try {
      fs.mkdirSync(productDir, { recursive: true });
      for (const capability of new Set(featureCaps.values())) {
        fs.mkdirSync(path.join(productDir, ...capability.split('/'), 'UserStory'), { recursive: true });
      }
      for (const item of statuses) {
        if (item.status === 'UNCHANGED') continue;
        fs.mkdirSync(path.dirname(item.target), { recursive: true });
        fs.copyFileSync(item.staged, item.target);
      }

      for (const item of storyRenames) fs.rmSync(item.source, { force: true });
      updateArchitecture(archPath, productName, productShort, plans, epic.source, idLinks, referenceLabels);
      validateLibrary(scriptDir, libraryDir, bashExe);
    } catch (error) {
      fs.writeFileSync(archPath, backupArch);
      fs.rmSync(productDir, { recursive: true, force: true });
      if (existed) fs.cpSync(backupProduct, productDir, { recursive: true });
      fail(`导出失败，已回滚: ${error.message}`);
    }
    console.log('EXPORT_STATUS=APPLIED');
    console.log(`PRODUCT_PATH=${productDir}`);
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

function renameProduct(args) {
  if (args.length < 5 || args.length > 6 || (args.length === 6 && args[4] !== '--apply')) {
    fail('用法: rename <脚本目录> <产品库目录> <产品全名> <新简称> [--apply] <bash>');
  }
  const [scriptDirRaw, libraryRaw, productName, newShort] = args;
  const applyChanges = args.length === 6;
  const bashExe = args.at(-1);
  const scriptDir = path.resolve(scriptDirRaw);
  const libraryDir = path.resolve(libraryRaw);
  if (!/^[\u4e00-\u9fff]{2,6}$/u.test(newShort)) fail('新简称必须为 2-6 个汉字');
  const archPath = architecturePath(libraryDir);
  const productDir = path.join(libraryDir, productName);
  if (path.basename(path.dirname(libraryDir)) !== 'product-library' || !fs.existsSync(archPath) || !fs.statSync(productDir, { throwIfNoEntry: false })?.isDirectory()) fail('产品库或产品目录不符合 v2 结构');
  const originalLines = fs.readFileSync(archPath, 'utf8').split(/\r?\n/);
  const { products: registered } = parseProductMatrix(originalLines);
  const current = registered.find((p) => p.full === productName);
  if (!current) fail('产品未登记在架构设计根文档');
  if (current.short === newShort) fail('新简称与当前简称相同');
  const conflict = registered.find((p) => p.short === newShort && p.full !== productName);
  if (conflict) fail(`新简称已被产品 ${conflict.full} 使用`);
  if (!/^[一-鿿]{2,6}：[一-鿿]+$/u.test(productName)) fail('产品全名格式应为 简称：描述，rename 暂只支持该格式');
  if (productName.split('：')[0] !== current.short) fail('产品全名前缀与当前简称不符，请先修正产品矩阵');
  const desc = productName.split('：')[1];
  const newFullName = `${newShort}：${desc}`;
  const newProductDir = path.join(libraryDir, newFullName);
  if (fs.existsSync(newProductDir)) fail(`目标产品目录已存在: ${newFullName}`);
  const affected = walkFiles(productDir, (file) => file.endsWith('.md') && path.basename(file).startsWith(`${current.short}-`)).sort();
  if (!affected.length) fail('未找到以当前简称开头的产品文件');
  const targets = affected.map((source) => ({ source, target: path.join(path.dirname(source), newShort + path.basename(source).slice(current.short.length)) }));
  for (const item of targets) if (fs.existsSync(item.target)) fail(`目标文件已存在: ${item.target}`);
  console.log(applyChanges ? 'RENAME_STATUS=APPLYING' : 'RENAME_STATUS=PREVIEW');
  console.log(`PRODUCT=${productName}`);
  console.log(`FULL_NAME=${productName}->${newFullName}`);
  console.log(`SHORT_NAME=${current.short}->${newShort}`);
  for (const item of targets) console.log(`RENAME\t${path.relative(libraryDir, item.source)}\t${path.relative(libraryDir, item.target)}`);
  console.log(`RENAME\t${path.relative(libraryDir, productDir)}\t${path.relative(libraryDir, newProductDir)}`);
  if (!applyChanges) {
    console.log('确认以上清单后，以相同参数追加 --apply 执行改名。');
    return;
  }
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pm-library-rename-'));
  const backupProduct = path.join(tempRoot, productName);
  fs.cpSync(productDir, backupProduct, { recursive: true });
  const outsideBackups = new Map();
  const backupArch = fs.readFileSync(archPath);
  try {
    for (const file of walkFiles(libraryDir, (target) => target.endsWith('.md') && !target.startsWith(productDir + path.sep) && target !== archPath)) {
      const data = fs.readFileSync(file);
      const text = data.toString('utf8');
      if (text.includes(`[[${current.short}-`) || text.includes(productName)) outsideBackups.set(file, data);
    }
    try {
      for (const item of targets) fs.renameSync(item.source, item.target);
      const lines = fs.readFileSync(archPath, 'utf8').split(/\r?\n/);
      const productStartMarker = `<!-- product:${productName}:start -->`;
      const productEndMarker = `<!-- product:${productName}:end -->`;
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim() === productStartMarker) {
          for (let j = i + 1; j < lines.length; j++) {
            if (lines[j].trim() === productEndMarker) break;
            const m = lines[j].match(/^(\*\*简称\*\*：)(.+)$/);
            if (m) { lines[j] = `${m[1]}${newShort}`; break; }
          }
          break;
        }
      }
      fs.writeFileSync(archPath, `${lines.join('\n').trimEnd()}\n`, 'utf8');
      for (const file of walkFiles(libraryDir, (target) => target.endsWith('.md'))) {
        const text = fs.readFileSync(file, 'utf8');
        let updated = text.replaceAll(`[[${current.short}-`, `[[${newShort}-`);
        updated = updated.replaceAll(productName, newFullName);
        if (updated !== text) fs.writeFileSync(file, updated, 'utf8');
      }
      fs.renameSync(productDir, newProductDir);
      validateLibrary(scriptDir, libraryDir, bashExe);
    } catch (error) {
      fs.writeFileSync(archPath, backupArch);
      fs.rmSync(productDir, { recursive: true, force: true });
      fs.rmSync(newProductDir, { recursive: true, force: true });
      fs.cpSync(backupProduct, productDir, { recursive: true });
      for (const [file, data] of outsideBackups) fs.writeFileSync(file, data);
      fail(`简称变更失败，已回滚: ${error.message}`);
    }
    console.log('RENAME_STATUS=APPLIED');
    console.log(`SHORT_NAME=${current.short}->${newShort}`);
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

const [command, ...args] = process.argv.slice(2);
if (command === 'export') exportProduct(args);
else if (command === 'rename') renameProduct(args);
else fail('未知命令');

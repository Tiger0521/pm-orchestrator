#!/usr/bin/env node
// backfill-library-ids.mjs
// 一次性迁移脚本：扫描产品库文档，按目录结构推导并注入继承式 ID 到 frontmatter。
//
// 不被任何 instruction/workflow/SKILL.md 引用，与主流程零耦合，可随时删除。
//
// 用法:
//   node scripts/backfill-library-ids.mjs <产品库目录> [产品全名]
//
// 不传产品全名时处理产品库中所有产品；传产品全名时只处理指定产品。
// 已有合法 id 字段的文档跳过，不重复分配。

import fs from 'node:fs';
import path from 'node:path';

// === 从 product-library-tools.mjs 复制的工具函数 ===

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
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

function architecturePath(libraryDir) {
  const matches = fs.readdirSync(libraryDir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && /^.+架构设计\.md$/u.test(entry.name))
    .map((entry) => path.join(libraryDir, entry.name));
  if (matches.length !== 1) fail('产品库必须且只能有一个匹配 /^.+架构设计\\.md$/ 的架构设计文件');
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
    products.push({ full: productFull, short });
    i = endIdx;
  }
  return { matrixStart, matrixEnd, products };
}

// === 迁移脚本逻辑 ===

function isValidLibraryId(id, shortName) {
  if (!id) return false;
  const escaped = shortName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(`^${escaped}-(?:REQ|EPIC|EPIC-F\\d{2,}|EPIC-F\\d{2,}-S\\d{2,})$`);
  return pattern.test(id);
}

function injectIdField(text, libraryId) {
  const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/);
  if (lines[0]?.trim() !== '---') throw new Error('文档缺少 frontmatter');
  const end = lines.indexOf('---', 1);
  if (end < 0) throw new Error('文档 frontmatter 未闭合');
  const raw = lines.slice(1, end);

  let insertIndex = raw.findIndex((line) => /^product\s*:/i.test(line));
  if (insertIndex < 0) insertIndex = 0;

  raw.splice(insertIndex, 0, `id: "${libraryId}"`);
  return ['---', ...raw, '---', ...lines.slice(end + 1)].join('\n');
}

function findStoryDir(capabilityDir) {
  for (const name of ['UserStory', 'stories']) {
    const dir = path.join(capabilityDir, name);
    if (fs.existsSync(dir) && fs.statSync(dir).isDirectory()) return dir;
  }
  return null;
}

function findCapabilityLeaves(productDir) {
  const leaves = [];
  for (const entry of fs.readdirSync(productDir, { withFileTypes: true })) {
    if (!entry.isDirectory() || !entry.name.endsWith('能力')) continue;
    const dirPath = path.join(productDir, entry.name);
    const hasCapabilityDoc = fs.readdirSync(dirPath).some((f) => f.endsWith('-能力文档.md'));
    if (hasCapabilityDoc) {
      leaves.push({ relativePath: entry.name, absolutePath: dirPath });
    } else {
      for (const subEntry of fs.readdirSync(dirPath, { withFileTypes: true })) {
        if (!subEntry.isDirectory() || !subEntry.name.endsWith('能力')) continue;
        const subDirPath = path.join(dirPath, subEntry.name);
        leaves.push({ relativePath: path.join(entry.name, subEntry.name), absolutePath: subDirPath });
      }
    }
  }
  return leaves.sort((a, b) => a.relativePath.localeCompare(b.relativePath));
}

function processDocument(filePath, libraryId, shortName, libraryDir) {
  const text = fs.readFileSync(filePath, 'utf8');
  let values;
  try {
    ({ values } = parseFrontmatter(text));
  } catch (error) {
    console.log(`WARN\t${path.relative(libraryDir, filePath)}\tfrontmatter 解析失败: ${error.message}`);
    return 'skipped';
  }

  if (isValidLibraryId(values.id, shortName)) {
    console.log(`SKIP\t${path.relative(libraryDir, filePath)}\t${values.id}`);
    return 'skipped';
  }

  const newText = injectIdField(text, libraryId);
  fs.writeFileSync(filePath, newText, 'utf8');
  console.log(`ASSIGN\t${path.relative(libraryDir, filePath)}\t${libraryId}`);
  return 'assigned';
}

function processProduct(libraryDir, productFull, productShort) {
  const productDir = path.join(libraryDir, productFull);
  if (!fs.statSync(productDir, { throwIfNoEntry: false })?.isDirectory()) {
    fail(`产品目录不存在: ${productDir}`);
  }

  console.log(`\n=== 产品: ${productFull} (简称: ${productShort}) ===`);
  let assigned = 0;
  let skipped = 0;

  // 需求卡片 -> <简称>-REQ
  const reqCard = path.join(productDir, `${productShort}-需求卡片.md`);
  if (fs.existsSync(reqCard)) {
    const result = processDocument(reqCard, `${productShort}-REQ`, productShort, libraryDir);
    if (result === 'assigned') assigned++; else skipped++;
  }

  // 设计文档 -> <简称>-EPIC
  const designDoc = path.join(productDir, `${productShort}-设计文档.md`);
  if (fs.existsSync(designDoc)) {
    const result = processDocument(designDoc, `${productShort}-EPIC`, productShort, libraryDir);
    if (result === 'assigned') assigned++; else skipped++;
  }

  // 能力文档和用户故事 -> <简称>-EPIC-F<nnn> / <简称>-EPIC-F<nnn>-S<nnn>
  const leaves = findCapabilityLeaves(productDir);
  leaves.forEach((leaf, index) => {
    const featureNum = String(index + 1).padStart(2, '0');
    const featureId = `${productShort}-EPIC-F${featureNum}`;

    // 能力文档
    const capDocs = fs.readdirSync(leaf.absolutePath).filter((f) => f.endsWith('-能力文档.md'));
    for (const doc of capDocs) {
      const result = processDocument(path.join(leaf.absolutePath, doc), featureId, productShort, libraryDir);
      if (result === 'assigned') assigned++; else skipped++;
    }

    // 用户故事
    const storyDir = findStoryDir(leaf.absolutePath);
    if (storyDir) {
      const stories = fs.readdirSync(storyDir).filter((f) => f.endsWith('.md')).sort();
      stories.forEach((story, storyIndex) => {
        const storyNum = String(storyIndex + 1).padStart(2, '0');
        const storyId = `${featureId}-S${storyNum}`;
        const result = processDocument(path.join(storyDir, story), storyId, productShort, libraryDir);
        if (result === 'assigned') assigned++; else skipped++;
      });
    }
  });

  console.log(`--- 小计: 分配 ${assigned} 份, 跳过 ${skipped} 份 ---`);
  return { assigned, skipped };
}

// === 主逻辑 ===

const [libraryDirRaw, productFilter] = process.argv.slice(2);

if (!libraryDirRaw) {
  fail('用法: node scripts/backfill-library-ids.mjs <产品库目录> [产品全名]');
}

const libraryDir = path.resolve(libraryDirRaw);
if (!fs.statSync(libraryDir, { throwIfNoEntry: false })?.isDirectory()) {
  fail(`产品库目录不存在: ${libraryDir}`);
}

const archPath = architecturePath(libraryDir);
const products = parseProductMatrix(fs.readFileSync(archPath, 'utf8').split(/\r?\n/)).products;

if (!products.length) {
  fail('架构设计根文档的产品矩阵中没有登记任何产品');
}

const targets = productFilter
  ? products.filter((p) => p.full === productFilter)
  : products;

if (!targets.length) {
  fail(`未找到产品: ${productFilter}`);
}

let totalAssigned = 0;
let totalSkipped = 0;

for (const product of targets) {
  if (!product.short) {
    console.log(`WARN: 产品 ${product.full} 没有简称，跳过`);
    continue;
  }
  const { assigned, skipped } = processProduct(libraryDir, product.full, product.short);
  totalAssigned += assigned;
  totalSkipped += skipped;
}

console.log(`\n=== 总计: 分配 ${totalAssigned} 份, 跳过 ${totalSkipped} 份 ===`);

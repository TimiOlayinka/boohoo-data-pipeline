/* ─────────────────────────────────────────────
   Data Quality & Lineage — Interactive Frontend v2
   Features: drag/zoom lineage, test details, failure reasons
   ───────────────────────────────────────────── */

let allModels = [];
let lineageData = null;
let activeFilter = 'all';
let selectedNode = null;

// Lineage state
let nodes = {};
let camera = { x: 0, y: 0, zoom: 1 };
let dragging = null;
let panning = false;
let panStart = { x: 0, y: 0 };
let hoverNode = null;

// ─── Init ───
document.addEventListener('DOMContentLoaded', async () => {
    await loadData();
    initTabs();
    initFilters();
    initSearch();
    initPanel();
});

async function loadData() {
    const [summary, models, lineage] = await Promise.all([
        fetch('/api/summary').then(r => r.json()),
        fetch('/api/models').then(r => r.json()),
        fetch('/api/lineage').then(r => r.json()),
    ]);

    allModels = models;
    lineageData = lineage;

    renderKPIs(summary);
    renderBadges(summary);
    renderQualityTable(models);
    renderCosts(models, summary);
    initLineage(lineage);

    document.getElementById('refresh-time').textContent = new Date().toLocaleTimeString();
}

// ─── KPI Strip ───
function renderKPIs(s) {
    document.getElementById('kpis').innerHTML = [
        { label: 'Models', value: s.total_models, color: 'var(--indigo)' },
        { label: 'Pass Rate', value: s.pass_rate + '%', color: 'var(--green)' },
        { label: 'Total Rows', value: fmtNum(s.total_rows), color: 'var(--blue)' },
        { label: 'Tests Passing', value: s.tests_pass, color: 'var(--green)' },
        { label: 'Tests Failing', value: s.tests_fail, color: s.tests_fail > 0 ? 'var(--red)' : 'var(--green)' },
        { label: 'Warnings', value: s.tests_warn, color: s.tests_warn > 0 ? 'var(--amber)' : 'var(--green)' },
        { label: 'Daily Cost', value: '\u00A3' + s.daily_cost, color: 'var(--cyan)' },
        { label: 'Monthly Cost', value: '\u00A3' + s.monthly_cost, color: 'var(--purple)' },
    ].map(k => `<div class="kpi-card"><div class="kpi-label">${k.label}</div><div class="kpi-value" style="color:${k.color}">${k.value}</div></div>`).join('');
}

function renderBadges(s) {
    document.getElementById('badge-pass').innerHTML = `\u25CF ${s.tests_pass} Pass`;
    document.getElementById('badge-warn').innerHTML = `\u25B2 ${s.tests_warn} Warn`;
    document.getElementById('badge-fail').innerHTML = `\u2715 ${s.tests_fail} Fail`;
}

// ─── Tabs ───
function initTabs() {
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
            if (tab.dataset.tab === 'lineage') requestAnimationFrame(() => renderLineage());
        });
    });
}

// ─── Filters ───
function initFilters() {
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeFilter = btn.dataset.filter;
            filterTable();
        });
    });
}

function initSearch() {
    document.getElementById('model-search').addEventListener('input', filterTable);
}

function filterTable() {
    const search = document.getElementById('model-search').value.toLowerCase();
    document.querySelectorAll('#quality-tbody tr').forEach(row => {
        const layer = row.dataset.layer;
        const name = row.dataset.name;
        const matchLayer = activeFilter === 'all' || layer === activeFilter;
        const matchSearch = !search || name.includes(search);
        row.style.display = matchLayer && matchSearch ? '' : 'none';
    });
}

// ─── Quality Table ───
function renderQualityTable(models) {
    const wrap = document.getElementById('quality-table-wrap');
    wrap.innerHTML = `<table class="quality-table"><thead><tr>
        <th>Status</th><th>Layer</th><th>Model</th><th>Domain</th>
        <th>Rows</th><th>Freshness</th><th>Tests</th><th>Coverage</th><th>Cost/Day</th>
    </tr></thead><tbody id="quality-tbody"></tbody></table>`;

    const tbody = document.getElementById('quality-tbody');
    models.forEach(m => {
        const total = m.tests_pass + m.tests_fail + m.tests_warn;
        const pW = total > 0 ? (m.tests_pass / total * 100) : 0;
        const fW = total > 0 ? (m.tests_fail / total * 100) : 0;
        const wW = total > 0 ? (m.tests_warn / total * 100) : 0;
        const tr = document.createElement('tr');
        tr.dataset.layer = m.layer;
        tr.dataset.name = m.name;
        tr.innerHTML = `
            <td><span class="status-dot ${m.status}"></span>${m.status.toUpperCase()}</td>
            <td><span class="layer-tag ${m.layer}">${m.layer}</span></td>
            <td class="mono">${m.name}</td>
            <td>${m.domain}</td>
            <td class="num">${m.rows.toLocaleString()}</td>
            <td>${m.freshness}</td>
            <td>${m.tests_pass}\u2713 ${m.tests_fail}\u2715 ${m.tests_warn}\u25B2</td>
            <td><div class="test-bar"><div class="pass" style="width:${pW}%"></div><div class="fail" style="width:${fW}%"></div><div class="warn" style="width:${wW}%"></div></div></td>
            <td class="num">\u00A3${m.cost_day.toFixed(2)}</td>`;
        tr.addEventListener('click', () => openPanel(m.name));
        tbody.appendChild(tr);
    });
}

// ─── Costs ───
function renderCosts(models, summary) {
    const layers = summary.layers;
    const maxCost = Math.max(...Object.values(layers).map(l => l.cost));
    const colors = { rdl: 'var(--indigo)', odl: 'var(--green)', adl: 'var(--amber)' };
    const labels = { rdl: 'Raw Data Layer', odl: 'Operational Data Layer', adl: 'Analytical Data Layer' };

    document.getElementById('costs-layer-cards').innerHTML = Object.entries(layers).map(([key, l]) => `
        <div class="cost-card">
            <div class="cost-card-header">
                <div><div class="cost-card-title"><span class="layer-tag ${key}">${key}</span> ${labels[key]}</div></div>
                <div class="cost-card-value" style="color:${colors[key]}">\u00A3${l.cost.toFixed(2)}</div>
            </div>
            <div style="font-size:12px;color:var(--text-secondary)">${l.models} models \u2014 ${l.healthy}\u2713 ${l.warning}\u25B2 ${l.failing}\u2715</div>
            <div class="cost-bar-wrap"><div class="cost-bar" style="width:${l.cost/maxCost*100}%;background:${colors[key]}"></div></div>
        </div>
    `).join('');

    const sorted = [...models].sort((a, b) => b.cost_day - a.cost_day);
    document.getElementById('costs-table-wrap').innerHTML = `<table class="quality-table"><thead><tr>
        <th>Model</th><th>Layer</th><th>Rows</th><th>Cost/Day</th><th>Cost/Month</th><th>% of Total</th>
    </tr></thead><tbody>${sorted.map(m => `<tr style="cursor:pointer" onclick="openPanel('${m.name}')">
        <td class="mono">${m.name}</td>
        <td><span class="layer-tag ${m.layer}">${m.layer}</span></td>
        <td class="num">${m.rows.toLocaleString()}</td>
        <td class="num">\u00A3${m.cost_day.toFixed(2)}</td>
        <td class="num">\u00A3${(m.cost_day * 30).toFixed(2)}</td>
        <td class="num">${(m.cost_day / summary.daily_cost * 100).toFixed(1)}%</td>
    </tr>`).join('')}</tbody></table>`;
}

// ═══════════════════════════════════════════════
// INTERACTIVE LINEAGE GRAPH
// ═══════════════════════════════════════════════

const LAYER_COLORS = { source: '#555', rdl: '#818cf8', odl: '#34d399', adl: '#fbbf24' };
const STATUS_COLORS = { pass: '#34d399', warn: '#fbbf24', fail: '#f87171' };
const LAYER_ORDER = ['source', 'rdl', 'odl', 'adl'];

function initLineage(data) {
    const canvas = document.getElementById('lineage-canvas');
    const W = canvas.clientWidth;
    const H = canvas.clientHeight;

    // Position nodes in columns
    const colX = { source: 100, rdl: W * 0.3, odl: W * 0.6, adl: W * 0.85 };
    const columns = {};
    LAYER_ORDER.forEach(l => { columns[l] = data.nodes.filter(n => n.layer === l); });

    nodes = {};
    Object.entries(columns).forEach(([layer, layerNodes]) => {
        const x = colX[layer];
        const gap = Math.min(22, (H - 60) / Math.max(layerNodes.length, 1));
        const startY = (H - layerNodes.length * gap) / 2;
        layerNodes.forEach((node, i) => {
            nodes[node.id] = {
                x, y: startY + i * gap + gap / 2,
                vx: 0, vy: 0,
                ...node
            };
        });
    });

    // Canvas interaction
    canvas.addEventListener('mousedown', onMouseDown);
    canvas.addEventListener('mousemove', onMouseMove);
    canvas.addEventListener('mouseup', onMouseUp);
    canvas.addEventListener('wheel', onWheel, { passive: false });
    canvas.addEventListener('dblclick', onDblClick);

    renderLineage();
}

function renderLineage() {
    const canvas = document.getElementById('lineage-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;

    canvas.width = canvas.clientWidth * dpr;
    canvas.height = canvas.clientHeight * dpr;
    ctx.scale(dpr, dpr);

    const W = canvas.clientWidth;
    const H = canvas.clientHeight;

    ctx.clearRect(0, 0, W, H);
    ctx.save();
    ctx.translate(camera.x, camera.y);
    ctx.scale(camera.zoom, camera.zoom);

    // Draw edges
    lineageData.edges.forEach(e => {
        const from = nodes[e.from];
        const to = nodes[e.to];
        if (!from || !to) return;

        const isHighlighted = selectedNode && (e.from === selectedNode || e.to === selectedNode);
        ctx.strokeStyle = isHighlighted ? 'rgba(129,140,248,0.6)' : 'rgba(255,255,255,0.05)';
        ctx.lineWidth = isHighlighted ? 2 : 0.8;

        ctx.beginPath();
        ctx.moveTo(from.x, from.y);
        const midX = (from.x + to.x) / 2;
        ctx.bezierCurveTo(midX, from.y, midX, to.y, to.x, to.y);
        ctx.stroke();

        // Arrow head for highlighted edges
        if (isHighlighted) {
            const angle = Math.atan2(to.y - from.y, to.x - from.x);
            const ax = to.x - 8 * Math.cos(angle);
            const ay = to.y - 8 * Math.sin(angle);
            ctx.fillStyle = 'rgba(129,140,248,0.6)';
            ctx.beginPath();
            ctx.moveTo(to.x, to.y);
            ctx.lineTo(ax - 4 * Math.sin(angle), ay + 4 * Math.cos(angle));
            ctx.lineTo(ax + 4 * Math.sin(angle), ay - 4 * Math.cos(angle));
            ctx.fill();
        }
    });

    // Draw layer labels
    ctx.font = '11px Inter';
    ctx.fillStyle = '#444';
    ctx.textAlign = 'center';
    const colX = { source: 100, rdl: W * 0.3 / camera.zoom, odl: W * 0.6 / camera.zoom, adl: W * 0.85 / camera.zoom };

    // Draw nodes
    Object.entries(nodes).forEach(([id, n]) => {
        const isSource = n.layer === 'source';
        const isSelected = selectedNode === id;
        const isHover = hoverNode === id;
        const isConnected = selectedNode && lineageData.edges.some(e =>
            (e.from === selectedNode && e.to === id) || (e.to === selectedNode && e.from === id) || id === selectedNode
        );

        const r = isSource ? 4 : (isSelected ? 8 : (isHover ? 7 : 5));
        const color = LAYER_COLORS[n.layer] || '#555';

        // Glow for failing/selected
        if (n.status === 'fail' || isSelected) {
            ctx.shadowColor = isSelected ? '#818cf8' : '#f87171';
            ctx.shadowBlur = isSelected ? 16 : 10;
        }

        ctx.beginPath();
        ctx.arc(n.x, n.y, r, 0, Math.PI * 2);
        ctx.fillStyle = selectedNode && !isConnected && !isSelected ? 'rgba(255,255,255,0.08)' : color;
        ctx.fill();

        ctx.shadowBlur = 0;

        // Status ring
        if (n.status === 'fail') {
            ctx.strokeStyle = STATUS_COLORS.fail;
            ctx.lineWidth = 2.5;
            ctx.stroke();
        } else if (n.status === 'warn') {
            ctx.strokeStyle = STATUS_COLORS.warn;
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        if (isSelected) {
            ctx.strokeStyle = '#fff';
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        // Labels
        if (!isSource) {
            const label = id.length > 20 ? id.substring(0, 18) + '\u2026' : id;
            ctx.font = isSelected ? 'bold 10px JetBrains Mono' : '9px JetBrains Mono';
            ctx.textAlign = 'left';
            ctx.fillStyle = isSelected ? '#fff' : (isConnected ? 'rgba(255,255,255,0.6)' : 'rgba(255,255,255,0.25)');
            ctx.fillText(label, n.x + r + 6, n.y + 3);
        }
    });

    // Tooltip
    if (hoverNode && nodes[hoverNode] && !hoverNode.startsWith('source:')) {
        const n = nodes[hoverNode];
        const ttX = n.x + 12;
        const ttY = n.y - 40;
        const ttW = 180;
        const ttH = 50;

        ctx.fillStyle = 'rgba(14,14,21,0.95)';
        ctx.strokeStyle = 'rgba(255,255,255,0.1)';
        ctx.lineWidth = 1;
        roundRect(ctx, ttX, ttY, ttW, ttH, 6);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = '#e8e8ed';
        ctx.font = 'bold 10px JetBrains Mono';
        ctx.textAlign = 'left';
        ctx.fillText(hoverNode, ttX + 8, ttY + 16);
        ctx.font = '9px Inter';
        ctx.fillStyle = '#8b8b9e';
        ctx.fillText(`${n.layer.toUpperCase()} | ${n.rows.toLocaleString()} rows`, ttX + 8, ttY + 30);
        ctx.fillStyle = STATUS_COLORS[n.status] || '#8b8b9e';
        ctx.fillText(`Status: ${n.status.toUpperCase()}`, ttX + 8, ttY + 42);
    }

    ctx.restore();
}

function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r);
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
}

function screenToWorld(sx, sy) {
    return { x: (sx - camera.x) / camera.zoom, y: (sy - camera.y) / camera.zoom };
}

function findNodeAt(wx, wy) {
    let closest = null, minDist = 15;
    Object.entries(nodes).forEach(([id, n]) => {
        const d = Math.sqrt((wx - n.x) ** 2 + (wy - n.y) ** 2);
        if (d < minDist) { closest = id; minDist = d; }
    });
    return closest;
}

function onMouseDown(e) {
    const rect = e.target.getBoundingClientRect();
    const w = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
    const hit = findNodeAt(w.x, w.y);

    if (hit) {
        dragging = hit;
        e.target.style.cursor = 'grabbing';
    } else {
        panning = true;
        panStart = { x: e.clientX - camera.x, y: e.clientY - camera.y };
        e.target.style.cursor = 'grabbing';
    }
}

function onMouseMove(e) {
    const rect = e.target.getBoundingClientRect();
    const w = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);

    if (dragging && nodes[dragging]) {
        nodes[dragging].x = w.x;
        nodes[dragging].y = w.y;
        renderLineage();
    } else if (panning) {
        camera.x = e.clientX - panStart.x;
        camera.y = e.clientY - panStart.y;
        renderLineage();
    } else {
        const hit = findNodeAt(w.x, w.y);
        if (hit !== hoverNode) {
            hoverNode = hit;
            e.target.style.cursor = hit ? 'pointer' : 'grab';
            renderLineage();
        }
    }
}

function onMouseUp(e) {
    if (dragging) {
        const rect = e.target.getBoundingClientRect();
        const w = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
        const hit = findNodeAt(w.x, w.y);
        if (hit && !hit.startsWith('source:')) {
            selectedNode = hit;
            openPanel(hit);
        }
    }
    dragging = null;
    panning = false;
    e.target.style.cursor = 'grab';
    renderLineage();
}

function onWheel(e) {
    e.preventDefault();
    const rect = e.target.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;

    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    const newZoom = Math.max(0.3, Math.min(3, camera.zoom * delta));

    camera.x = mx - (mx - camera.x) * (newZoom / camera.zoom);
    camera.y = my - (my - camera.y) * (newZoom / camera.zoom);
    camera.zoom = newZoom;

    renderLineage();
}

function onDblClick(e) {
    const rect = e.target.getBoundingClientRect();
    const w = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
    const hit = findNodeAt(w.x, w.y);
    if (hit && !hit.startsWith('source:')) {
        selectedNode = hit;
        openPanel(hit);
        renderLineage();
    }
}

// ─── Detail Panel ───
function initPanel() {
    document.getElementById('panel-close').addEventListener('click', closePanel);
    document.getElementById('overlay').addEventListener('click', closePanel);
}

async function openPanel(modelName) {
    const [modelRes, testsRes] = await Promise.all([
        fetch(`/api/models/${modelName}`),
        fetch(`/api/tests/${modelName}`),
    ]);
    if (!modelRes.ok) return;
    const m = await modelRes.json();
    const tests = await testsRes.json();

    const statusColor = { pass: 'var(--green)', warn: 'var(--amber)', fail: 'var(--red)' };

    // Build test detail HTML
    const testRows = tests.map(t => {
        const icon = t.status === 'pass' ? '\u2713' : t.status === 'fail' ? '\u2715' : '\u25B2';
        const color = statusColor[t.status];
        return `
            <div class="test-detail-row ${t.status}">
                <div class="test-detail-header">
                    <span class="test-icon" style="color:${color}">${icon}</span>
                    <span class="test-name">${t.test}</span>
                    <span class="test-column">${t.column || 'table'}</span>
                    <span class="test-severity sev-${t.severity}">${t.severity}</span>
                </div>
                ${t.message ? `<div class="test-message">${t.message}</div>` : ''}
                <div class="test-sql"><code>${t.sql}</code></div>
            </div>
        `;
    }).join('');

    document.getElementById('panel-content').innerHTML = `
        <div class="panel-model-name">${m.name}</div>
        <div class="panel-layer"><span class="layer-tag ${m.layer}">${m.layer}</span> <span style="color:var(--text-secondary);font-size:12px">${m.domain}</span></div>

        <div class="panel-section">
            <div class="panel-section-title">Status & Quality</div>
            <div class="panel-stat"><span class="panel-stat-label">Status</span><span class="panel-stat-value" style="color:${statusColor[m.status]}">${m.status.toUpperCase()}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Tests Pass</span><span class="panel-stat-value" style="color:var(--green)">${m.tests_pass}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Tests Fail</span><span class="panel-stat-value" style="color:${m.tests_fail > 0 ? 'var(--red)' : 'var(--green)'}">${m.tests_fail}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Tests Warn</span><span class="panel-stat-value" style="color:${m.tests_warn > 0 ? 'var(--amber)' : 'var(--green)'}">${m.tests_warn}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Test Details (${tests.length})</div>
            <div class="test-detail-list">${testRows || '<div style="color:var(--text-muted);font-size:12px">No tests configured</div>'}</div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Metrics</div>
            <div class="panel-stat"><span class="panel-stat-label">Row Count</span><span class="panel-stat-value">${m.rows.toLocaleString()}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Columns</span><span class="panel-stat-value">${m.columns}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Freshness</span><span class="panel-stat-value">${m.freshness}</span></div>
            ${m.versions_avg > 0 ? `<div class="panel-stat"><span class="panel-stat-label">Avg Versions</span><span class="panel-stat-value">${m.versions_avg}</span></div>` : ''}
            <div class="panel-stat"><span class="panel-stat-label">Brand</span><span class="panel-stat-value">${m.brand}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Cost</div>
            <div class="panel-stat"><span class="panel-stat-label">Daily</span><span class="panel-stat-value" style="color:var(--cyan)">\u00A3${m.cost_day.toFixed(2)}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Monthly</span><span class="panel-stat-value" style="color:var(--cyan)">\u00A3${(m.cost_day * 30).toFixed(2)}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Yearly</span><span class="panel-stat-value" style="color:var(--cyan)">\u00A3${(m.cost_day * 365).toFixed(2)}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Upstream (${m.upstream.length})</div>
            <ul class="panel-deps">${m.upstream.length > 0 ? m.upstream.map(u =>
                `<li onclick="${u.startsWith('source:') ? '' : `openPanel('${u}')`}">${u}</li>`
            ).join('') : '<li style="color:var(--text-muted)">No upstream</li>'}</ul>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Downstream (${m.downstream.length})</div>
            <ul class="panel-deps">${m.downstream.length > 0 ? m.downstream.map(d =>
                `<li onclick="openPanel('${d}')">${d}</li>`
            ).join('') : '<li style="color:var(--text-muted)">No downstream</li>'}</ul>
        </div>
    `;

    document.getElementById('detail-panel').classList.add('open');
    document.getElementById('overlay').classList.add('open');
}

function closePanel() {
    document.getElementById('detail-panel').classList.remove('open');
    document.getElementById('overlay').classList.remove('open');
    selectedNode = null;
    renderLineage();
}

// ─── Helpers ───
function fmtNum(n) {
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(0) + 'k';
    return n.toString();
}

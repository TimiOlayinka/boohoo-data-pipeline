/* ─────────────────────────────────────────────
   Data Quality & Lineage — Interactive Frontend
   ───────────────────────────────────────────── */

let allModels = [];
let lineageData = null;
let activeFilter = 'all';
let selectedNode = null;

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
    renderLineage(lineage);

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
        { label: 'Daily Cost', value: '£' + s.daily_cost, color: 'var(--cyan)' },
        { label: 'Monthly Cost', value: '£' + s.monthly_cost, color: 'var(--purple)' },
    ].map(k => `<div class="kpi-card"><div class="kpi-label">${k.label}</div><div class="kpi-value" style="color:${k.color}">${k.value}</div></div>`).join('');
}

function renderBadges(s) {
    document.getElementById('badge-pass').innerHTML = `● ${s.tests_pass} Pass`;
    document.getElementById('badge-warn').innerHTML = `▲ ${s.tests_warn} Warn`;
    document.getElementById('badge-fail').innerHTML = `✕ ${s.tests_fail} Fail`;
}

// ─── Tabs ───
function initTabs() {
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
            if (tab.dataset.tab === 'lineage') renderLineage(lineageData);
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
            <td>${m.tests_pass}✓ ${m.tests_fail}✕ ${m.tests_warn}▲</td>
            <td><div class="test-bar"><div class="pass" style="width:${pW}%"></div><div class="fail" style="width:${fW}%"></div><div class="warn" style="width:${wW}%"></div></div></td>
            <td class="num">£${m.cost_day.toFixed(2)}</td>`;
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
                <div>
                    <div class="cost-card-title"><span class="layer-tag ${key}">${key}</span> ${labels[key]}</div>
                </div>
                <div class="cost-card-value" style="color:${colors[key]}">£${l.cost.toFixed(2)}</div>
            </div>
            <div style="font-size:12px;color:var(--text-secondary)">${l.models} models — ${l.healthy}✓ ${l.warning}▲ ${l.failing}✕</div>
            <div class="cost-bar-wrap"><div class="cost-bar" style="width:${l.cost/maxCost*100}%;background:${colors[key]}"></div></div>
        </div>
    `).join('');

    // Cost table sorted by cost descending
    const sorted = [...models].sort((a, b) => b.cost_day - a.cost_day);
    document.getElementById('costs-table-wrap').innerHTML = `<table class="quality-table"><thead><tr>
        <th>Model</th><th>Layer</th><th>Rows</th><th>Cost/Day</th><th>Cost/Month</th><th>% of Total</th>
    </tr></thead><tbody>${sorted.map(m => `<tr style="cursor:pointer" onclick="openPanel('${m.name}')">
        <td class="mono">${m.name}</td>
        <td><span class="layer-tag ${m.layer}">${m.layer}</span></td>
        <td class="num">${m.rows.toLocaleString()}</td>
        <td class="num">£${m.cost_day.toFixed(2)}</td>
        <td class="num">£${(m.cost_day * 30).toFixed(2)}</td>
        <td class="num">${(m.cost_day / summary.daily_cost * 100).toFixed(1)}%</td>
    </tr>`).join('')}</tbody></table>`;
}

// ─── Lineage Graph (Canvas) ───
function renderLineage(data) {
    const canvas = document.getElementById('lineage-canvas');
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;

    canvas.width = canvas.clientWidth * dpr;
    canvas.height = canvas.clientHeight * dpr;
    ctx.scale(dpr, dpr);

    const W = canvas.clientWidth;
    const H = canvas.clientHeight;

    const layerColors = { source: '#555', rdl: '#818cf8', odl: '#34d399', adl: '#fbbf24' };
    const statusColors = { pass: '#34d399', warn: '#fbbf24', fail: '#f87171' };

    // Position nodes in columns by layer
    const layerOrder = ['source', 'rdl', 'odl', 'adl'];
    const columns = {};
    layerOrder.forEach(l => { columns[l] = data.nodes.filter(n => n.layer === l); });

    const colX = { source: 80, rdl: W * 0.3, odl: W * 0.6, adl: W * 0.85 };
    const nodePositions = {};

    Object.entries(columns).forEach(([layer, nodes]) => {
        const x = colX[layer];
        const gap = Math.min(18, (H - 40) / Math.max(nodes.length, 1));
        const startY = (H - nodes.length * gap) / 2;
        nodes.forEach((node, i) => {
            nodePositions[node.id] = { x, y: startY + i * gap + gap / 2, node };
        });
    });

    // Clear
    ctx.clearRect(0, 0, W, H);

    // Draw layer labels
    ctx.font = '10px Inter';
    ctx.fillStyle = '#555566';
    Object.entries(colX).forEach(([layer, x]) => {
        ctx.textAlign = 'center';
        ctx.fillText(layer.toUpperCase(), x, 16);
    });

    // Draw edges
    ctx.strokeStyle = 'rgba(255,255,255,0.06)';
    ctx.lineWidth = 1;
    data.edges.forEach(e => {
        const from = nodePositions[e.from];
        const to = nodePositions[e.to];
        if (!from || !to) return;

        ctx.beginPath();
        ctx.moveTo(from.x, from.y);
        // Bezier curve
        const midX = (from.x + to.x) / 2;
        ctx.bezierCurveTo(midX, from.y, midX, to.y, to.x, to.y);
        ctx.stroke();
    });

    // Draw nodes
    Object.entries(nodePositions).forEach(([id, pos]) => {
        const n = pos.node;
        const r = n.layer === 'source' ? 3 : 5;
        const color = layerColors[n.layer] || '#555';
        const borderColor = statusColors[n.status] || color;

        ctx.beginPath();
        ctx.arc(pos.x, pos.y, r, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();

        if (n.status === 'fail') {
            ctx.strokeStyle = statusColors.fail;
            ctx.lineWidth = 2;
            ctx.stroke();
        } else if (n.status === 'warn') {
            ctx.strokeStyle = statusColors.warn;
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }

        // Highlight selected
        if (selectedNode === id) {
            ctx.strokeStyle = '#fff';
            ctx.lineWidth = 2;
            ctx.stroke();
        }
    });

    // Labels for non-source nodes (abbreviated)
    ctx.font = '9px JetBrains Mono';
    ctx.textAlign = 'left';
    Object.entries(nodePositions).forEach(([id, pos]) => {
        if (pos.node.layer === 'source') return;
        const label = id.length > 18 ? id.substring(0, 16) + '…' : id;
        ctx.fillStyle = selectedNode === id ? '#fff' : 'rgba(255,255,255,0.35)';
        ctx.fillText(label, pos.x + 8, pos.y + 3);
    });

    // Click handler
    canvas.onclick = (e) => {
        const rect = canvas.getBoundingClientRect();
        const mx = e.clientX - rect.left;
        const my = e.clientY - rect.top;

        let clicked = null;
        Object.entries(nodePositions).forEach(([id, pos]) => {
            const dx = mx - pos.x, dy = my - pos.y;
            if (Math.sqrt(dx * dx + dy * dy) < 10) clicked = id;
        });

        if (clicked && !clicked.startsWith('source:')) {
            selectedNode = clicked;
            renderLineage(lineageData);
            openPanel(clicked);

            // Highlight connected edges
            ctx.lineWidth = 1.5;
            data.edges.forEach(e => {
                if (e.from === clicked || e.to === clicked) {
                    const from = nodePositions[e.from];
                    const to = nodePositions[e.to];
                    if (!from || !to) return;
                    ctx.strokeStyle = 'rgba(129,140,248,0.5)';
                    ctx.beginPath();
                    ctx.moveTo(from.x, from.y);
                    const midX = (from.x + to.x) / 2;
                    ctx.bezierCurveTo(midX, from.y, midX, to.y, to.x, to.y);
                    ctx.stroke();
                }
            });
        }
    };
}

// ─── Detail Panel ───
function initPanel() {
    document.getElementById('panel-close').addEventListener('click', closePanel);
    document.getElementById('overlay').addEventListener('click', closePanel);
}

async function openPanel(modelName) {
    const res = await fetch(`/api/models/${modelName}`);
    if (!res.ok) return;
    const m = await res.json();

    const statusColor = { pass: 'var(--green)', warn: 'var(--amber)', fail: 'var(--red)' };

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
            <div class="panel-section-title">Metrics</div>
            <div class="panel-stat"><span class="panel-stat-label">Row Count</span><span class="panel-stat-value">${m.rows.toLocaleString()}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Columns</span><span class="panel-stat-value">${m.columns}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Freshness</span><span class="panel-stat-value">${m.freshness}</span></div>
            ${m.versions_avg > 0 ? `<div class="panel-stat"><span class="panel-stat-label">Avg Versions</span><span class="panel-stat-value">${m.versions_avg}</span></div>` : ''}
            <div class="panel-stat"><span class="panel-stat-label">Brand</span><span class="panel-stat-value">${m.brand}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">💰 Cost</div>
            <div class="panel-stat"><span class="panel-stat-label">Daily</span><span class="panel-stat-value" style="color:var(--cyan)">£${m.cost_day.toFixed(2)}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Monthly</span><span class="panel-stat-value" style="color:var(--cyan)">£${(m.cost_day * 30).toFixed(2)}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Yearly</span><span class="panel-stat-value" style="color:var(--cyan)">£${(m.cost_day * 365).toFixed(2)}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">⬆️ Upstream (${m.upstream.length})</div>
            <ul class="panel-deps">${m.upstream.length > 0 ? m.upstream.map(u =>
                `<li onclick="${u.startsWith('source:') ? '' : `openPanel('${u}')`}">${u}</li>`
            ).join('') : '<li style="color:var(--text-muted)">No upstream dependencies</li>'}</ul>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">⬇️ Downstream (${m.downstream.length})</div>
            <ul class="panel-deps">${m.downstream.length > 0 ? m.downstream.map(d =>
                `<li onclick="openPanel('${d}')">${d}</li>`
            ).join('') : '<li style="color:var(--text-muted)">No downstream consumers</li>'}</ul>
        </div>
    `;

    document.getElementById('detail-panel').classList.add('open');
    document.getElementById('overlay').classList.add('open');
}

function closePanel() {
    document.getElementById('detail-panel').classList.remove('open');
    document.getElementById('overlay').classList.remove('open');
    selectedNode = null;
    if (lineageData) renderLineage(lineageData);
}

// ─── Helpers ───
function fmtNum(n) {
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(0) + 'k';
    return n.toString();
}

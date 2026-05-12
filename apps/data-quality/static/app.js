/* Data Quality & Lineage — v3: schema, focus mode, chain filter, domain filter */

let allModels=[], lineageData=null, activeFilter='all', activeDomain='all', activeStatus='all', activeAttention=false, selectedNode=null;
let nodes={}, camera={x:0,y:0,zoom:1}, dragging=null, panning=false, panStart={x:0,y:0}, hoverNode=null;
let focusChain=null; // set of node IDs in the isolated chain

const LAYER_COLORS={source:'#555',rdl:'#818cf8',odl:'#34d399',adl:'#fbbf24'};
const STATUS_COLORS={pass:'#34d399',warn:'#fbbf24',fail:'#f87171'};

document.addEventListener('DOMContentLoaded', async()=>{
    const [summary,models,lineage,domains]=await Promise.all([
        fetch('/api/summary').then(r=>r.json()),
        fetch('/api/models').then(r=>r.json()),
        fetch('/api/lineage').then(r=>r.json()),
        fetch('/api/domains').then(r=>r.json()),
    ]);
    allModels=models; lineageData=lineage;
    renderKPIs(summary); renderBadges(summary);
    renderDomainFilter(domains);
    renderQualityTable(models); renderCosts(models,summary);
    initLineage(lineage); initTabs(); initFilters(); initSearch(); initPanel();
    document.getElementById('refresh-time').textContent=new Date().toLocaleTimeString();
});

// ─── KPI Strip ───
function renderKPIs(s){
    document.getElementById('kpis').innerHTML=[
        {label:'Models',value:s.total_models,color:'var(--indigo)'},
        {label:'Pass Rate',value:s.pass_rate+'%',color:'var(--green)'},
        {label:'Total Rows',value:fmtNum(s.total_rows),color:'var(--blue)'},
        {label:'Tests Passing',value:s.tests_pass,color:'var(--green)'},
        {label:'Tests Failing',value:s.tests_fail,color:s.tests_fail>0?'var(--red)':'var(--green)'},
        {label:'Warnings',value:s.tests_warn,color:s.tests_warn>0?'var(--amber)':'var(--green)'},
        {label:'Daily Cost',value:'\u00A3'+s.daily_cost,color:'var(--cyan)'},
        {label:'Monthly Cost',value:'\u00A3'+s.monthly_cost,color:'var(--purple)'},
    ].map(k=>`<div class="kpi-card"><div class="kpi-label">${k.label}</div><div class="kpi-value" style="color:${k.color}">${k.value}</div></div>`).join('');
}
function renderBadges(s){
    document.getElementById('badge-pass').innerHTML=`\u25CF ${s.tests_pass} Pass`;
    document.getElementById('badge-warn').innerHTML=`\u25B2 ${s.tests_warn} Warn`;
    document.getElementById('badge-fail').innerHTML=`\u2715 ${s.tests_fail} Fail`;
}

// ─── Domain Filter ───
function renderDomainFilter(domains){
    const wrap=document.getElementById('domain-filter');
    if(!wrap) return;
    wrap.innerHTML=`<select id="domain-select" class="domain-select">
        <option value="all">All Domains</option>
        ${domains.map(d=>`<option value="${d}">${d}</option>`).join('')}
    </select>`;
    document.getElementById('domain-select').addEventListener('change',e=>{
        activeDomain=e.target.value; filterTable(); filterLineageByDomain();
    });
}

function renderStatusFilter(){
    const wrap=document.getElementById('status-filter');
    if(!wrap) return;
    wrap.innerHTML=`<select id="status-select" class="domain-select">
        <option value="all">All Statuses</option>
        <option value="pass">✓ Passing</option>
        <option value="warn">▲ Warnings</option>
        <option value="fail">✕ Failing</option>
    </select>`;
    document.getElementById('status-select').addEventListener('change',e=>{
        activeStatus=e.target.value; filterTable(); filterLineageByDomain();
    });
}

function renderAttentionFilter(){
    const wrap=document.getElementById('attention-filter');
    if(!wrap) return;
    const failCount=allModels.filter(m=>m.status==='fail').length;
    const warnCount=allModels.filter(m=>m.status==='warn').length;
    const attentionCount=failCount+warnCount;
    wrap.innerHTML=`<button id="attention-btn" class="attention-btn" title="Show models that need attention">
        ⚠ Needs Attention <span class="attention-count">${attentionCount}</span>
    </button>`;
    document.getElementById('attention-btn').addEventListener('click',e=>{
        const btn=e.currentTarget;
        btn.classList.toggle('active');
        activeAttention=btn.classList.contains('active');
        filterTable(); filterLineageByDomain();
    });
}

function filterLineageByDomain(){
    const filtered=getFilteredModelNames();
    if(activeDomain==='all'&&activeStatus==='all'&&!activeAttention){
        focusChain=null;
    } else {
        const chain=new Set(filtered);
        // include connected source nodes
        lineageData.edges.forEach(e=>{
            if(chain.has(e.from)) chain.add(e.to);
            if(chain.has(e.to)) chain.add(e.from);
        });
        focusChain=chain;
    }
    renderLineage();
}

function getFilteredModelNames(){
    return allModels.filter(m=>{
        if(activeDomain!=='all'&&m.business_domain!==activeDomain) return false;
        if(activeStatus!=='all'&&m.status!==activeStatus) return false;
        if(activeAttention&&m.status==='pass') return false;
        return true;
    }).map(m=>m.name);
}

// ─── Tabs ───
function initTabs(){
    document.querySelectorAll('.tab').forEach(tab=>{
        tab.addEventListener('click',()=>{
            document.querySelectorAll('.tab').forEach(t=>t.classList.remove('active'));
            document.querySelectorAll('.tab-panel').forEach(p=>p.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('tab-'+tab.dataset.tab).classList.add('active');
            if(tab.dataset.tab==='lineage') requestAnimationFrame(()=>renderLineage());
        });
    });
}

// ─── Filters ───
function initFilters(){
    document.querySelectorAll('.filter-btn').forEach(btn=>{
        btn.addEventListener('click',()=>{
            document.querySelectorAll('.filter-btn').forEach(b=>b.classList.remove('active'));
            btn.classList.add('active'); activeFilter=btn.dataset.filter; filterTable();
        });
    });
    renderStatusFilter();
    renderAttentionFilter();
}
function initSearch(){document.getElementById('model-search').addEventListener('input',filterTable);}

function filterTable(){
    const search=document.getElementById('model-search').value.toLowerCase();
    document.querySelectorAll('#quality-tbody tr').forEach(row=>{
        const layer=row.dataset.layer, name=row.dataset.name;
        const bDomain=row.dataset.bdomain, status=row.dataset.status;
        const matchLayer=activeFilter==='all'||layer===activeFilter;
        const matchDomain=activeDomain==='all'||bDomain===activeDomain;
        const matchStatus=activeStatus==='all'||status===activeStatus;
        const matchAttention=!activeAttention||status!=='pass';
        const matchSearch=!search||name.includes(search);
        row.style.display=matchLayer&&matchSearch&&matchDomain&&matchStatus&&matchAttention?'':'none';
    });
}

// ─── Quality Table ───
function renderQualityTable(models){
    const wrap=document.getElementById('quality-table-wrap');
    wrap.innerHTML=`<table class="quality-table"><thead><tr>
        <th>Status</th><th>Layer</th><th>Schema</th><th>Model</th><th>Domain</th>
        <th>Rows</th><th>Freshness</th><th>Tests</th><th>Coverage</th><th>Cost/Day</th>
    </tr></thead><tbody id="quality-tbody"></tbody></table>`;
    const tbody=document.getElementById('quality-tbody');
    models.forEach(m=>{
        const total=m.tests_pass+m.tests_fail+m.tests_warn;
        const pW=total>0?(m.tests_pass/total*100):0, fW=total>0?(m.tests_fail/total*100):0, wW=total>0?(m.tests_warn/total*100):0;
        const tr=document.createElement('tr');
        tr.dataset.layer=m.layer; tr.dataset.name=m.name; tr.dataset.bdomain=m.business_domain; tr.dataset.status=m.status;
        tr.innerHTML=`
            <td><span class="status-dot ${m.status}"></span>${m.status.toUpperCase()}</td>
            <td><span class="layer-tag ${m.layer}">${m.layer}</span></td>
            <td class="mono" style="font-size:10px;color:var(--text-secondary)">${m.schema||''}</td>
            <td class="mono">${m.name}</td>
            <td>${m.business_domain}</td>
            <td class="num">${m.rows.toLocaleString()}</td>
            <td>${m.freshness}</td>
            <td>${m.tests_pass}\u2713 ${m.tests_fail}\u2715 ${m.tests_warn}\u25B2</td>
            <td><div class="test-bar"><div class="pass" style="width:${pW}%"></div><div class="fail" style="width:${fW}%"></div><div class="warn" style="width:${wW}%"></div></div></td>
            <td class="num">\u00A3${m.cost_day.toFixed(2)}</td>`;
        tr.addEventListener('click',()=>openPanel(m.name));
        tbody.appendChild(tr);
    });
}

// ─── Costs ───
function renderCosts(models,summary){
    const layers=summary.layers, maxCost=Math.max(...Object.values(layers).map(l=>l.cost));
    const colors={rdl:'var(--indigo)',odl:'var(--green)',adl:'var(--amber)'};
    const labels={rdl:'Raw Data Layer',odl:'Operational Data Layer',adl:'Analytical Data Layer'};
    document.getElementById('costs-layer-cards').innerHTML=Object.entries(layers).map(([k,l])=>`
        <div class="cost-card"><div class="cost-card-header">
            <div><div class="cost-card-title"><span class="layer-tag ${k}">${k}</span> ${labels[k]}</div></div>
            <div class="cost-card-value" style="color:${colors[k]}">\u00A3${l.cost.toFixed(2)}</div>
        </div><div style="font-size:12px;color:var(--text-secondary)">${l.models} models</div>
        <div class="cost-bar-wrap"><div class="cost-bar" style="width:${l.cost/maxCost*100}%;background:${colors[k]}"></div></div></div>`).join('');
    const sorted=[...models].sort((a,b)=>b.cost_day-a.cost_day);
    document.getElementById('costs-table-wrap').innerHTML=`<table class="quality-table"><thead><tr>
        <th>Model</th><th>Layer</th><th>Rows</th><th>Cost/Day</th><th>Cost/Month</th><th>%</th>
    </tr></thead><tbody>${sorted.map(m=>`<tr style="cursor:pointer" onclick="openPanel('${m.name}')">
        <td class="mono">${m.name}</td><td><span class="layer-tag ${m.layer}">${m.layer}</span></td>
        <td class="num">${m.rows.toLocaleString()}</td><td class="num">\u00A3${m.cost_day.toFixed(2)}</td>
        <td class="num">\u00A3${(m.cost_day*30).toFixed(2)}</td><td class="num">${(m.cost_day/summary.daily_cost*100).toFixed(1)}%</td>
    </tr>`).join('')}</tbody></table>`;
}

// ═══════════════════════════════════════
// INTERACTIVE LINEAGE GRAPH
// ═══════════════════════════════════════

function initLineage(data){
    const canvas=document.getElementById('lineage-canvas');
    const W=canvas.clientWidth, H=canvas.clientHeight;
    const colX={source:100,rdl:W*0.3,odl:W*0.6,adl:W*0.85};
    const columns={}; ['source','rdl','odl','adl'].forEach(l=>{columns[l]=data.nodes.filter(n=>n.layer===l);});
    nodes={};
    Object.entries(columns).forEach(([layer,ln])=>{
        const x=colX[layer], gap=Math.min(22,(H-60)/Math.max(ln.length,1)), startY=(H-ln.length*gap)/2;
        ln.forEach((node,i)=>{nodes[node.id]={x,y:startY+i*gap+gap/2,...node};});
    });
    canvas.addEventListener('mousedown',onMouseDown);
    canvas.addEventListener('mousemove',onMouseMove);
    canvas.addEventListener('mouseup',onMouseUp);
    canvas.addEventListener('wheel',onWheel,{passive:false});
    canvas.addEventListener('dblclick',onDblClick);
    renderLineage();
}

function getChainFor(nodeId){
    // BFS to find all connected nodes (full chain upstream + downstream)
    const visited=new Set([nodeId]);
    const queue=[nodeId];
    while(queue.length){
        const cur=queue.shift();
        lineageData.edges.forEach(e=>{
            if(e.from===cur&&!visited.has(e.to)){visited.add(e.to);queue.push(e.to);}
            if(e.to===cur&&!visited.has(e.from)){visited.add(e.from);queue.push(e.from);}
        });
    }
    return visited;
}

function renderLineage(){
    const canvas=document.getElementById('lineage-canvas');
    if(!canvas)return;
    const ctx=canvas.getContext('2d'), dpr=window.devicePixelRatio||1;
    canvas.width=canvas.clientWidth*dpr; canvas.height=canvas.clientHeight*dpr;
    ctx.scale(dpr,dpr);
    const W=canvas.clientWidth, H=canvas.clientHeight;
    ctx.clearRect(0,0,W,H);
    ctx.save(); ctx.translate(camera.x,camera.y); ctx.scale(camera.zoom,camera.zoom);

    const visibleNodes=focusChain?new Set([...focusChain]):null;

    // Edges
    lineageData.edges.forEach(e=>{
        const from=nodes[e.from], to=nodes[e.to];
        if(!from||!to) return;
        if(visibleNodes&&!visibleNodes.has(e.from)&&!visibleNodes.has(e.to)) return;
        const isHL=selectedNode&&(e.from===selectedNode||e.to===selectedNode);
        const dimmed=visibleNodes&&(!visibleNodes.has(e.from)||!visibleNodes.has(e.to));
        ctx.strokeStyle=isHL?'rgba(129,140,248,0.6)':dimmed?'rgba(255,255,255,0.02)':'rgba(255,255,255,0.05)';
        ctx.lineWidth=isHL?2:0.8;
        ctx.beginPath(); ctx.moveTo(from.x,from.y);
        const mx=(from.x+to.x)/2;
        ctx.bezierCurveTo(mx,from.y,mx,to.y,to.x,to.y); ctx.stroke();
        if(isHL){
            const a=Math.atan2(to.y-from.y,to.x-from.x);
            ctx.fillStyle='rgba(129,140,248,0.6)';
            ctx.beginPath(); ctx.moveTo(to.x,to.y);
            ctx.lineTo(to.x-8*Math.cos(a)-4*Math.sin(a),to.y-8*Math.sin(a)+4*Math.cos(a));
            ctx.lineTo(to.x-8*Math.cos(a)+4*Math.sin(a),to.y-8*Math.sin(a)-4*Math.cos(a));
            ctx.fill();
        }
    });

    // Nodes
    Object.entries(nodes).forEach(([id,n])=>{
        const isSrc=n.layer==='source', isSel=selectedNode===id, isHov=hoverNode===id;
        const inChain=!visibleNodes||visibleNodes.has(id);
        const isConn=selectedNode&&lineageData.edges.some(e=>(e.from===selectedNode&&e.to===id)||(e.to===selectedNode&&e.from===id)||id===selectedNode);
        const r=isSrc?4:(isSel?8:(isHov?7:5));
        const color=LAYER_COLORS[n.layer]||'#555';

        if(!inChain){
            ctx.globalAlpha=0.08;
            ctx.beginPath(); ctx.arc(n.x,n.y,3,0,Math.PI*2);
            ctx.fillStyle='#555'; ctx.fill(); ctx.globalAlpha=1; return;
        }

        if(n.status==='fail'||isSel){ctx.shadowColor=isSel?'#818cf8':'#f87171';ctx.shadowBlur=isSel?16:10;}
        ctx.beginPath(); ctx.arc(n.x,n.y,r,0,Math.PI*2);
        ctx.fillStyle=selectedNode&&!isConn&&!isSel?'rgba(255,255,255,0.08)':color;
        ctx.fill(); ctx.shadowBlur=0;
        if(n.status==='fail'){ctx.strokeStyle=STATUS_COLORS.fail;ctx.lineWidth=2.5;ctx.stroke();}
        else if(n.status==='warn'){ctx.strokeStyle=STATUS_COLORS.warn;ctx.lineWidth=2;ctx.stroke();}
        if(isSel){ctx.strokeStyle='#fff';ctx.lineWidth=2;ctx.stroke();}

        if(!isSrc){
            const label=id.length>20?id.substring(0,18)+'\u2026':id;
            ctx.font=isSel?'bold 10px JetBrains Mono':'9px JetBrains Mono';
            ctx.textAlign='left';
            ctx.fillStyle=isSel?'#fff':(isConn?'rgba(255,255,255,0.6)':'rgba(255,255,255,0.25)');
            ctx.fillText(label,n.x+r+6,n.y+3);
        }
    });

    // Tooltip
    if(hoverNode&&nodes[hoverNode]&&!hoverNode.startsWith('source:')){
        const n=nodes[hoverNode], ttX=n.x+12, ttY=n.y-50, ttW=200, ttH=60;
        ctx.fillStyle='rgba(14,14,21,0.95)'; ctx.strokeStyle='rgba(255,255,255,0.1)'; ctx.lineWidth=1;
        roundRect(ctx,ttX,ttY,ttW,ttH,6); ctx.fill(); ctx.stroke();
        ctx.fillStyle='#e8e8ed'; ctx.font='bold 10px JetBrains Mono'; ctx.textAlign='left';
        ctx.fillText(hoverNode,ttX+8,ttY+16);
        ctx.font='9px Inter'; ctx.fillStyle='#8b8b9e';
        const schema=allModels.find(m=>m.name===hoverNode)?.schema||'';
        ctx.fillText(`${schema}.${hoverNode}`,ttX+8,ttY+30);
        ctx.fillText(`${n.layer.toUpperCase()} | ${n.rows.toLocaleString()} rows`,ttX+8,ttY+42);
        ctx.fillStyle=STATUS_COLORS[n.status]||'#8b8b9e';
        ctx.fillText(`Status: ${n.status.toUpperCase()}`,ttX+8,ttY+54);
    }

    // Focus mode indicator
    if(focusChain){
        ctx.restore(); // exit camera transform for HUD
        ctx.fillStyle='rgba(129,140,248,0.15)'; ctx.fillRect(0,H-30,W,30);
        ctx.fillStyle='#818cf8'; ctx.font='11px Inter'; ctx.textAlign='center';
        ctx.fillText(`Focus mode: ${focusChain.size} nodes | Double-click empty space or press ESC to reset`,W/2,H-10);
        return; // already restored
    }
    ctx.restore();
}

function roundRect(ctx,x,y,w,h,r){
    ctx.beginPath();ctx.moveTo(x+r,y);ctx.lineTo(x+w-r,y);ctx.quadraticCurveTo(x+w,y,x+w,y+r);
    ctx.lineTo(x+w,y+h-r);ctx.quadraticCurveTo(x+w,y+h,x+w-r,y+h);ctx.lineTo(x+r,y+h);
    ctx.quadraticCurveTo(x,y+h,x,y+h-r);ctx.lineTo(x,y+r);ctx.quadraticCurveTo(x,y,x+r,y);ctx.closePath();
}
function screenToWorld(sx,sy){return{x:(sx-camera.x)/camera.zoom,y:(sy-camera.y)/camera.zoom};}
function findNodeAt(wx,wy){
    let closest=null,minDist=15;
    Object.entries(nodes).forEach(([id,n])=>{const d=Math.sqrt((wx-n.x)**2+(wy-n.y)**2);if(d<minDist){closest=id;minDist=d;}});
    return closest;
}

let dragMoved=false;
function onMouseDown(e){
    const rect=e.target.getBoundingClientRect(), w=screenToWorld(e.clientX-rect.left,e.clientY-rect.top);
    const hit=findNodeAt(w.x,w.y); dragMoved=false;
    if(hit){dragging=hit;e.target.style.cursor='grabbing';}
    else{panning=true;panStart={x:e.clientX-camera.x,y:e.clientY-camera.y};e.target.style.cursor='grabbing';}
}
function onMouseMove(e){
    const rect=e.target.getBoundingClientRect(), w=screenToWorld(e.clientX-rect.left,e.clientY-rect.top);
    if(dragging&&nodes[dragging]){nodes[dragging].x=w.x;nodes[dragging].y=w.y;dragMoved=true;renderLineage();}
    else if(panning){camera.x=e.clientX-panStart.x;camera.y=e.clientY-panStart.y;dragMoved=true;renderLineage();}
    else{const hit=findNodeAt(w.x,w.y);if(hit!==hoverNode){hoverNode=hit;e.target.style.cursor=hit?'pointer':'grab';renderLineage();}}
}
function onMouseUp(e){
    if(dragging&&!dragMoved){
        const hit=dragging;
        if(hit&&!hit.startsWith('source:')){
            if(selectedNode===hit){
                // 2nd click on same node: focus chain + open panel
                focusChain=getChainFor(hit);
                openPanel(hit);
            } else {
                // 1st click: just highlight
                selectedNode=hit;
                focusChain=null; // reset any previous focus
            }
        }
    } else if(!dragging&&!panning&&!dragMoved){
        // clicked empty space = deselect
        selectedNode=null; focusChain=null;
    }
    dragging=null;panning=false;e.target.style.cursor='grab';renderLineage();
}
function onWheel(e){
    e.preventDefault();
    const rect=e.target.getBoundingClientRect(),mx=e.clientX-rect.left,my=e.clientY-rect.top;
    const delta=e.deltaY>0?0.9:1.1, newZoom=Math.max(0.3,Math.min(3,camera.zoom*delta));
    camera.x=mx-(mx-camera.x)*(newZoom/camera.zoom);camera.y=my-(my-camera.y)*(newZoom/camera.zoom);
    camera.zoom=newZoom; renderLineage();
}
function onDblClick(e){
    // Double-click empty space = full reset
    const rect=e.target.getBoundingClientRect(), w=screenToWorld(e.clientX-rect.left,e.clientY-rect.top);
    const hit=findNodeAt(w.x,w.y);
    if(!hit){
        focusChain=null; selectedNode=null; closePanel(); renderLineage();
    }
}

// ESC to reset focus
document.addEventListener('keydown',e=>{
    if(e.key==='Escape'){focusChain=null;selectedNode=null;closePanel();renderLineage();}
});

// ─── Detail Panel (NO overlay blur) ───
function initPanel(){
    document.getElementById('panel-close').addEventListener('click',closePanel);
}

async function openPanel(modelName){
    const [modelRes,testsRes]=await Promise.all([fetch(`/api/models/${modelName}`),fetch(`/api/tests/${modelName}`)]);
    if(!modelRes.ok) return;
    const m=await modelRes.json(), tests=await testsRes.json();
    const sc={pass:'var(--green)',warn:'var(--amber)',fail:'var(--red)'};

    const testRows=tests.map(t=>{
        const icon=t.status==='pass'?'\u2713':t.status==='fail'?'\u2715':'\u25B2';
        return `<div class="test-detail-row ${t.status}">
            <div class="test-detail-header">
                <span class="test-icon" style="color:${sc[t.status]}">${icon}</span>
                <span class="test-name">${t.test}</span>
                <span class="test-column">${t.column||'table'}</span>
                <span class="test-severity sev-${t.severity}">${t.severity}</span>
            </div>
            ${t.message?`<div class="test-message">${t.message}</div>`:''}
            <div class="test-sql"><code>${t.sql}</code></div>
        </div>`;
    }).join('');

    // Build upstream/downstream with schema
    function depList(deps,direction){
        if(!deps.length) return `<li style="color:var(--text-muted)">No ${direction}</li>`;
        return deps.map(d=>{
            const depModel=allModels.find(x=>x.name===d);
            const schema=depModel?depModel.schema:'source';
            const clickable=!d.startsWith('source:');
            return `<li ${clickable?`onclick="openPanel('${d}')"`:''}><span class="dep-schema">${schema}.</span>${d}</li>`;
        }).join('');
    }

    document.getElementById('panel-content').innerHTML=`
        <div class="panel-model-name">${m.name}</div>
        <div class="panel-layer"><span class="layer-tag ${m.layer}">${m.layer}</span>
            <span style="color:var(--text-secondary);font-size:12px">${m.schema}.${m.name}</span></div>

        <div class="panel-section">
            <div class="panel-section-title">Status & Quality</div>
            <div class="panel-stat"><span class="panel-stat-label">Status</span><span class="panel-stat-value" style="color:${sc[m.status]}">${m.status.toUpperCase()}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Domain</span><span class="panel-stat-value">${m.domain}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Tests Pass</span><span class="panel-stat-value" style="color:var(--green)">${m.tests_pass}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Tests Fail</span><span class="panel-stat-value" style="color:${m.tests_fail>0?'var(--red)':'var(--green)'}">${m.tests_fail}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Tests Warn</span><span class="panel-stat-value" style="color:${m.tests_warn>0?'var(--amber)':'var(--green)'}">${m.tests_warn}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Test Details (${tests.length})</div>
            <div class="test-detail-list">${testRows||'<div style="color:var(--text-muted);font-size:12px">No tests</div>'}</div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Metrics</div>
            <div class="panel-stat"><span class="panel-stat-label">Row Count</span><span class="panel-stat-value">${m.rows.toLocaleString()}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Columns</span><span class="panel-stat-value">${m.columns}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Freshness</span><span class="panel-stat-value">${m.freshness}</span></div>
            ${m.versions_avg>0?`<div class="panel-stat"><span class="panel-stat-label">Avg Versions</span><span class="panel-stat-value">${m.versions_avg}</span></div>`:''}
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Cost</div>
            <div class="panel-stat"><span class="panel-stat-label">Daily</span><span class="panel-stat-value" style="color:var(--cyan)">\u00A3${m.cost_day.toFixed(2)}</span></div>
            <div class="panel-stat"><span class="panel-stat-label">Monthly</span><span class="panel-stat-value" style="color:var(--cyan)">\u00A3${(m.cost_day*30).toFixed(2)}</span></div>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Upstream (${m.upstream.length})</div>
            <ul class="panel-deps">${depList(m.upstream,'upstream')}</ul>
        </div>

        <div class="panel-section">
            <div class="panel-section-title">Downstream (${m.downstream.length})</div>
            <ul class="panel-deps">${depList(m.downstream,'downstream')}</ul>
        </div>
    `;

    document.getElementById('detail-panel').classList.add('open');
    // No overlay — panel slides over without blurring the lineage
}

function closePanel(){
    document.getElementById('detail-panel').classList.remove('open');
    selectedNode=null; renderLineage();
}

function fmtNum(n){if(n>=1e6)return(n/1e6).toFixed(1)+'M';if(n>=1e3)return(n/1e3).toFixed(0)+'k';return n.toString();}

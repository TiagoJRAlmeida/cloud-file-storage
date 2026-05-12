// ── State ──
let token = null;
let currentUser = null;
let currentPage = 1;
const PAGE_SIZE = 20;
const QUOTA_BYTES = 100 * 1024 * 1024; // 100 MB default display

// ── Helpers ──
// const apiUrl = () => document.getElementById('api-url').value.replace(/\/$/, '');
const apiUrl = '/api'
const log = (msg, type='info') => {
    const el = document.getElementById('log');
    el.innerHTML = `<span class="${type}">${new Date().toLocaleTimeString()} › ${msg}</span>`;
};
const fmt = (bytes) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes/1024).toFixed(1) + ' KB';
    return (bytes/1048576).toFixed(2) + ' MB';
};
const authHeader = () => ({ 'Authorization': `Bearer ${token}` });

// ── Health check ──
async function checkHealth() {
    try {
        const r = await fetch(`${apiUrl}/health`);
        const ok = r.ok;
        document.getElementById('status-dot').className = 'status-dot ' + (ok ? 'online' : '');
        document.getElementById('status-text').textContent = ok ? 'API online' : 'API error';
    } catch {
        document.getElementById('status-dot').className = 'status-dot';
        document.getElementById('status-text').textContent = 'unreachable';
    }
}
checkHealth();
setInterval(checkHealth, 15000);

// ── Auth ──
async function doLogin() {
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    if (!username || !password) { log('Enter credentials', 'err'); return; }
    try {
        const r = await fetch(`${apiUrl}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
        });
        if (!r.ok) { 
            const errText = await r.text();
            log(`Login failed: invalid credentials: ${errText}`, 'err'); 
            return; 
        }
        const d = await r.json();
        token = d.access_token;
        currentUser = username;
        showUserPanel();
        log(`Logged in as ${username}`, 'ok');
        loadFiles();
    } catch(e) { log('Login error: ' + e.message, 'err'); }
}

function doLogout() {
    token = null; currentUser = null; currentPage = 1;
    document.getElementById('auth-panel').style.display = 'flex';
    document.getElementById('user-panel').style.display = 'none';
    document.getElementById('logged-in-label').style.display = 'none';
    document.getElementById('refresh-btn').style.display = 'none';
    document.getElementById('pagination').style.display = 'none';
    document.getElementById('file-count').textContent = '';
    document.getElementById('file-table-wrap').innerHTML =
        `<div class="empty"><span class="empty-icon">🔒</span>Login to manage your files</div>`;
    log('Logged out');
}

function showUserPanel() {
    document.getElementById('auth-panel').style.display = 'none';
    document.getElementById('user-panel').style.display = 'flex';
    document.getElementById('user-display').textContent = currentUser;
    document.getElementById('logged-in-label').textContent = currentUser;
    document.getElementById('logged-in-label').style.display = 'inline';
    document.getElementById('refresh-btn').style.display = 'inline-block';
}

// ── Files ──
async function loadFiles() {
    if (!token) return;
    try {
        const r = await fetch(`${apiUrl}/files?page=${currentPage}&page_size=${PAGE_SIZE}`, {
        headers: authHeader()
        });
        if (!r.ok) { log('Could not load files', 'err'); return; }
        const d = await r.json();
        renderTable(d.files);
        document.getElementById('file-count').textContent = `${d.total} file${d.total!==1?'s':''}`;
        // Pagination
        const totalPages = Math.max(1, Math.ceil(d.total / PAGE_SIZE));
        document.getElementById('page-info').textContent = `Page ${currentPage} / ${totalPages}`;
        document.getElementById('pagination').style.display = d.total > PAGE_SIZE ? 'flex' : 'none';
        updateQuota(d.files);
    } catch(e) { log('Error: ' + e.message, 'err'); }
}

function updateQuota(files) {
    const used = files.reduce((s, f) => s + (f.size || 0), 0);
    const pct = Math.min(100, (used / QUOTA_BYTES) * 100).toFixed(1);
    document.getElementById('quota-text').textContent = `${fmt(used)} / ${fmt(QUOTA_BYTES)}`;
    document.getElementById('quota-fill').style.width = pct + '%';
}

function renderTable(files) {
if (!files || files.length === 0) {
    document.getElementById('file-table-wrap').innerHTML =
    `<div class="empty"><span class="empty-icon">📂</span>No files yet. Upload something.</div>`;
    return;
}
const rows = files.map(f => `
    <tr>
    <td>
        <div class="file-name">${escHtml(f.filename || 'unnamed')}</div>
        <div class="file-id">${f.file_id}</div>
    </td>
    <td><span class="file-type-badge">${escHtml((f.content_type||'').split('/')[1] || f.content_type || '—')}</span></td>
    <td class="file-size">${f.size != null ? fmt(f.size) : '—'}</td>
    <td class="actions">
        <button class="btn-sm" onclick="downloadFile('${f.file_id}','${escHtml(f.filename||'file')}')">↓ DL</button>
        <button class="btn-share" onclick="shareFile('${f.file_id}')">🔗 Share</button>
        <button class="btn-sm" onclick="showMeta('${f.file_id}')">ℹ Meta</button>
        <button class="btn-danger" onclick="deleteFile('${f.file_id}')">✕</button>
    </td>
    </tr>`).join('');
document.getElementById('file-table-wrap').innerHTML = `
    <table>
    <thead>
        <tr>
        <th>File</th><th>Type</th><th>Size</th><th>Actions</th>
        </tr>
    </thead>
    <tbody>${rows}</tbody>
    </table>`;
}

function escHtml(s) {
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function changePage(dir) {
    currentPage = Math.max(1, currentPage + dir);
    loadFiles();
}

// ── Upload ──
function handleDrop(e) {
    e.preventDefault();
    document.getElementById('drop-zone').classList.remove('drag-over');
    const file = e.dataTransfer.files[0];
    if (file) uploadFile(file);
}

function uploadSelected() {
    const input = document.getElementById('file-input');
    if (input.files[0]) uploadFile(input.files[0]);
}

async function uploadFile(file) {
    if (!token) { log('Not logged in', 'err'); return; }
    log(`<span class="spinner"></span>Uploading ${file.name}…`, 'info');
    const formData = new FormData();
    formData.append('file', file);
    try {
        const r = await fetch(`${apiUrl}/files/upload`, {
            method: 'POST',
            headers: authHeader(),
            body: formData
        });
        if (!r.ok) {
            const d = await r.json().catch(() => ({}));
            log(`Upload failed: ${d.detail || r.status}`, 'err');
            return;
        }
        const d = await r.json();
        log(`Uploaded "${d.filename}" (${fmt(d.size)})`, 'ok');
        loadFiles();
    } catch(e) { log('Upload error: ' + e.message, 'err'); }
    document.getElementById('file-input').value = '';
}

// ── Download ──
async function downloadFile(fileId, filename) {
    try {
        const r = await fetch(`${apiUrl}/files/${fileId}`, { headers: authHeader() });
        if (!r.ok) { log('Download failed', 'err'); return; }
        const blob = await r.blob();
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = filename;
        a.click();
        log(`Downloaded "${filename}"`, 'ok');
    } catch(e) { log('Download error: ' + e.message, 'err'); }
}

// ── Delete ──
async function deleteFile(fileId) {
    if (!confirm('Delete this file?')) return;
    try {
        const r = await fetch(`${apiUrl}/files/${fileId}`, {
        method: 'DELETE', headers: authHeader()
        });
        if (!r.ok) { log('Delete failed', 'err'); return; }
        log('File deleted', 'ok');
        loadFiles();
    } catch(e) { log('Delete error: ' + e.message, 'err'); }
}

// ── Share ──
async function shareFile(fileId) {
    const ttl = parseInt(document.getElementById('ttl').value) || 3600;
    try {
        const r = await fetch(`${apiUrl}/files/${fileId}/share?ttl_seconds=${ttl}`, {
            method: 'POST', headers: authHeader()
        });
        if (!r.ok) { log('Share failed', 'err'); return; }
        const d = await r.json();
        showModal('Presigned Share URL', `URL: ${d.presigned_url}\n\nExpires in: ${d.expires_in_seconds}s`);
        log('Share URL generated', 'ok');
    } catch(e) { log('Share error: ' + e.message, 'err'); }
}

// ── Metadata ──
async function showMeta(fileId) {
    try {
        const r = await fetch(`${apiUrl}/files/${fileId}/meta`, { headers: authHeader() });
        if (!r.ok) { log('Metadata fetch failed', 'err'); return; }
        const d = await r.json();
        showModal('File Metadata', JSON.stringify(d, null, 2));
    } catch(e) { log('Meta error: ' + e.message, 'err'); }
}

// ── Modal ──
function showModal(title, body) {
    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-body').textContent = body;
    document.getElementById('modal').classList.add('open');
}
function closeModal() {
    document.getElementById('modal').classList.remove('open');
}
function copyModal() {
    navigator.clipboard.writeText(document.getElementById('modal-body').textContent);
    log('Copied to clipboard', 'ok');
}
document.getElementById('modal').addEventListener('click', function(e) {
    if (e.target === this) closeModal();
});
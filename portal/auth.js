// Shared helpers. Requires window.PORTAL (config.js) and supabase-js loaded first.
const cfgOK=()=>window.PORTAL&&!/YOUR-/.test(window.PORTAL.SUPABASE_URL+window.PORTAL.SUPABASE_ANON_KEY);
const sb=cfgOK()?supabase.createClient(PORTAL.SUPABASE_URL,PORTAL.SUPABASE_ANON_KEY):null;
const here=()=>location.origin+location.pathname.replace(/[^/]*$/,'');
async function getProfile(){
  const {data:{session}}=await sb.auth.getSession(); if(!session) return null;
  let {data:p}=await sb.from('profiles').select('*').eq('id',session.user.id).single();
  if(!p){await new Promise(r=>setTimeout(r,800));({data:p}=await sb.from('profiles').select('*').eq('id',session.user.id).single())}
  if(p) sb.from('profiles').update({last_seen:new Date().toISOString()}).eq('id',p.id).then(()=>{});
  return p;
}
async function requireRole(role){
  if(!sb){document.body.innerHTML='<div class="wrap"><div class="card">សូមបំពេញ <b>config.js</b> (Supabase URL និង anon key) ជាមុនសិន។</div></div>';return null}
  const p=await getProfile(); if(!p){location.replace('login.html');return null}
  if(role&&p.role!==role){location.replace(p.role==='admin'?'admin.html':'customer.html');return null}
  return p;
}
async function signOut(){await sb.auth.signOut();location.replace('login.html')}
const kh=n=>String(n).replace(/\d/g,d=>'០១២៣៤៥៦៧៨៩'[d]);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function whoHtml(p){return `<div class="who">${p.avatar?`<img src="${esc(p.avatar)}" alt="">`:''}<span>${esc(p.name||p.email)}</span><span class="pill ${p.role==='admin'?'pro':''}">${esc(p.role)}</span><button class="btn" onclick="signOut()">ចាកចេញ</button></div>`}

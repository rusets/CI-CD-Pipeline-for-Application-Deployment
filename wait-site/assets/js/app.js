const DEFAULT_API = "https://api.ci-wake.online"
const REDIRECT_DELAY_MS = 800

let btnWake, bar, msg, timer = null, pct = 0, targetUrl = ""

function qs(n){ const p=new URLSearchParams(location.search); return p.get(n)||"" }
function setMsg(t){ if(msg) msg.textContent=t }
function tick(){ pct=Math.min(100,pct+4+Math.random()*6); if(bar) bar.style.width=pct+"%" }

async function doWake(api){ await fetch(`${api}/wake`,{method:"POST",mode:"cors"}) }
async function getStatus(api){
  const r=await fetch(`${api}/status`,{mode:"cors"})
  const ct=(r.headers.get("content-type")||"").toLowerCase()
  return ct.includes("application/json") ? await r.json() : {}
}

function startPolling(api){
  if(timer) clearInterval(timer)
  timer=setInterval(async()=>{
    try{
      tick()
      const d=await getStatus(api)
      const ip=d.publicIp||d.public_ip||d.ip||""
      const st=d.state||d.status||"unknown"
      setMsg(`Status: ${st}${ip?` — ${ip}`:""}`)
      if(st==="running" || d.ready===true){
        clearInterval(timer)
        if(bar) bar.style.width="100%"
        const dest=targetUrl||d.url||d.targetUrl||`http://${ip}/`
        setTimeout(()=>{ location.href=dest },REDIRECT_DELAY_MS)
      }
    }catch(_){ setMsg("Checking status…") }
  },1200)
}

function resetBar(){ pct=0; if(bar) bar.style.width="0%" }
function disable(btn,d){ if(btn){ btn.disabled=d; btn.classList.toggle("disabled",d) } }

function onWake(){
  const api=qs("api")||DEFAULT_API
  targetUrl=qs("url")||""
  resetBar(); disable(btnWake,true); setMsg("Waking up…")
  doWake(api).then(()=> startPolling(api)).catch(()=>{
    setMsg("Wake request failed"); disable(btnWake,false)
  })
}

document.addEventListener("DOMContentLoaded",()=>{
  btnWake=document.querySelector("[data-wake]")
  bar=document.querySelector("[data-bar]")
  msg=document.querySelector("[data-status]")
  if(btnWake) btnWake.addEventListener("click", onWake)
})
// ============ Utilities ============
const $ = (q, ctx=document) => ctx.querySelector(q);
const $$ = (q, ctx=document) => Array.from(ctx.querySelectorAll(q));
const setTheme = (name) => {
  document.body.setAttribute('data-theme', name);
  localStorage.setItem('theme', name);
  // refresh bg color hint for bubbles
  startBubbles(true);
};

const stored = localStorage.getItem('theme');
if (stored) document.body.setAttribute('data-theme', stored);
$("#year") && ($("#year").textContent = new Date().getFullYear());

// ============ Active nav ============
const page = document.documentElement.getAttribute('data-page') || '';
$$('.nav a').forEach(a => {
  if ((page === 'home' && a.getAttribute('href') === '/') ||
      a.getAttribute('href').includes(page)) {
    a.classList.add('active-link');
    a.style.background = '#121a34';
  }
});

// ============ Theme toggles ============
$('#themeToggle')?.addEventListener('click', () => {
  const themes = ['sunset','ocean','candy','forest'];
  const current = document.body.getAttribute('data-theme') || themes[0];
  const next = themes[(themes.indexOf(current) + 1) % themes.length];
  setTheme(next);
  $('#themeToggle').textContent = next === 'sunset' ? '☀️' :
                                  next === 'ocean'  ? '🌊' :
                                  next === 'candy'  ? '🍭' : '🌲';
});
$$('.swatch').forEach(b => b.addEventListener('click', () => setTheme(b.dataset.theme)));

// ============ Tilt effect ============
$$('.tilt').forEach(card => {
  const strength = 10;
  let raf;
  function onMove(e){
    const rect = card.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width - 0.5;
    const y = (e.clientY - rect.top) / rect.height - 0.5;
    cancelAnimationFrame(raf);
    raf = requestAnimationFrame(() => {
      card.style.transform = `rotateX(${(-y*strength)}deg) rotateY(${(x*strength)}deg) translateZ(0)`;
    });
  }
  function reset(){ card.style.transform = ''; }
  card.addEventListener('pointermove', onMove);
  card.addEventListener('pointerleave', reset);
});

// ============ Confetti (simple) ============
$('#confettiBtn')?.addEventListener('click', () => confettiBurst());
function confettiBurst(){
  const colors = getThemeColors();
  for(let i=0;i<80;i++){
    const s = document.createElement('span');
    s.className = 'confetti';
    s.style.position = 'fixed';
    s.style.left = Math.random()*100+'%';
    s.style.top = '-10px';
    s.style.width = s.style.height = (6 + Math.random()*6) + 'px';
    s.style.background = colors[Math.floor(Math.random()*colors.length)];
    s.style.transform = `translateY(0) rotate(${Math.random()*360}deg)`;
    s.style.borderRadius = '2px';
    s.style.zIndex = 3;
    document.body.appendChild(s);
    const endY = window.innerHeight + 40;
    s.animate([{transform: s.style.transform},{transform:`translateY(${endY}px) rotate(${720*Math.random()}deg)`}],
              {duration: 800 + Math.random()*900, easing: 'cubic-bezier(.2,.8,.2,1)'}).onfinish = () => s.remove();
  }
}
function getThemeColors(){
  const cs = getComputedStyle(document.body);
  return [cs.getPropertyValue('--brand').trim(), cs.getPropertyValue('--brand-2').trim(), cs.getPropertyValue('--accent').trim()];
}

// ============ Filters on /projects ============
const grid = $('#projectsGrid');
if (grid){
  const buttons = $$('.filter-btn');
  buttons.forEach(btn => btn.addEventListener('click', () => {
    buttons.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const f = btn.dataset.filter;
    $$('#projectsGrid .card').forEach(card => {
      const tags = (card.getAttribute('data-tags') || '').split(/\s+/);
      const show = f === 'all' || tags.includes(f);
      card.style.display = show ? '' : 'none';
    });
  }));
}

// ============ Form demo on /contact ============
$('#contactForm')?.addEventListener('submit', (e) => {
  e.preventDefault();
  const form = e.currentTarget;
  if (!form.reportValidity()) return;
  $('#formSuccess').classList.remove('hidden');
  form.remove();
  confettiBurst();
});

// ============ Pulse demo ============
$('#pulseDemo')?.addEventListener('click', (e) => {
  e.currentTarget.classList.add('glow-pulse');
  setTimeout(() => e.currentTarget.classList.remove('glow-pulse'), 1400);
});

// ============ Canvas bubbles ============
let bubbleRAF, ctx, canvas;
function startBubbles(restart=false){
  if (restart && bubbleRAF) cancelAnimationFrame(bubbleRAF);
  if (!canvas){ canvas = document.getElementById('bg-bubbles'); }
  if (!canvas) return;
  ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const resize = () => {
    canvas.width = innerWidth * dpr; canvas.height = innerHeight * dpr;
    ctx.scale(dpr, dpr);
  };
  resize(); window.addEventListener('resize', resize);

  const colors = getThemeColors();
  const bubbles = Array.from({length: 32}, () => ({
    x: Math.random()*innerWidth,
    y: innerHeight + Math.random()*innerHeight,
    r: 8 + Math.random()*26,
    vy: 0.4 + Math.random()*1.2,
    vx: (Math.random()-.5)*0.6,
    c: colors[Math.floor(Math.random()*colors.length)]
  }));

  function step(){
    ctx.clearRect(0,0,innerWidth,innerHeight);
    bubbles.forEach(b => {
      b.y -= b.vy; b.x += b.vx;
      if (b.y + b.r < -10) { b.y = innerHeight + b.r + 10; b.x = Math.random()*innerWidth; }
      ctx.beginPath();
      ctx.fillStyle = b.c;
      ctx.globalAlpha = 0.12;
      ctx.arc(b.x, b.y, b.r, 0, Math.PI*2);
      ctx.fill();
      ctx.globalAlpha = 1;
    });
    bubbleRAF = requestAnimationFrame(step);
  }
  step();
}
startBubbles();

// ============ Keyboard nicety ============
document.addEventListener('keydown', (e) => {
  if ((e.key === 't' || e.key === 'T') && (e.ctrlKey || e.metaKey)) {
    e.preventDefault(); $('#themeToggle')?.click();
  }
});

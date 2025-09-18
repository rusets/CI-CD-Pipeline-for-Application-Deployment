// ============================================================
// Ruslan AWS — small client script
// - Theme toggle (persisted in localStorage)
// - Mobile burger menu
// - Active nav link + year
// ============================================================

const $ = (q, ctx = document) => ctx.querySelector(q);
const $$ = (q, ctx = document) => Array.from(ctx.querySelectorAll(q));

// Set current year
const y = $('#year'); if (y) y.textContent = new Date().getFullYear();

// Theme (dark/light) — saved in localStorage
const root = document.documentElement;
const toggle = document.getElementById('theme-toggle'); // IMPORTANT: id must be "theme-toggle"
const saved = localStorage.getItem('na-theme');
if (saved === 'light') root.classList.add('light');

if (toggle) {
  const setIcon = () => { toggle.textContent = root.classList.contains('light') ? '☀︎' : '☾'; };
  setIcon();
  toggle.addEventListener('click', () => {
    root.classList.toggle('light');
    localStorage.setItem('na-theme', root.classList.contains('light') ? 'light' : 'dark');
    setIcon();
  });
}

// Mobile nav (burger)
const burger = $('#burger');
const nav = $('#nav');
if (burger && nav) burger.addEventListener('click', () => nav.classList.toggle('open'));

// Mark active link (for single-file hosting or when path ends with that link)
$$('.nav a').forEach(a => {
  const href = a.getAttribute('href');
  if (location.pathname.endsWith(href)) a.classList.add('active');
});
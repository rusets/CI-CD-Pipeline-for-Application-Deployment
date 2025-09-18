// Текущий год в футере
document.getElementById('year').textContent = new Date().getFullYear();

// Бургер-меню
const burger = document.getElementById('burger');
const nav = document.getElementById('nav');
if (burger && nav) burger.addEventListener('click', () => nav.classList.toggle('open'));

// Тема (dark/light) — запоминаем в localStorage
const root = document.documentElement;
const toggle = document.getElementById('themeToggle');

const saved = localStorage.getItem('na-theme');
if (saved === 'light') root.classList.add('light');

if (toggle) {
  const setIcon = () => (toggle.textContent = root.classList.contains('light') ? '☀︎' : '☾');
  setIcon();
  toggle.addEventListener('click', () => {
    root.classList.toggle('light');
    localStorage.setItem('na-theme', root.classList.contains('light') ? 'light' : 'dark');
    setIcon();
  });
}

// Подсветка активного пункта меню (по URL)
document.querySelectorAll('.nav a').forEach(a => {
  if (location.pathname.endsWith(a.getAttribute('href'))) a.classList.add('active');
});
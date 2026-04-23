const revealNodes = document.querySelectorAll('.reveal');

const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        revealObserver.unobserve(entry.target);
      }
    });
  },
  {
    threshold: 0.18,
    rootMargin: '0px 0px -60px 0px',
  }
);

revealNodes.forEach((node) => revealObserver.observe(node));

const navLinks = document.querySelectorAll('.top-nav nav a');

navLinks.forEach((link) => {
  link.addEventListener('click', (event) => {
    const targetId = link.getAttribute('href');
    if (!targetId || !targetId.startsWith('#')) {
      return;
    }

    const section = document.querySelector(targetId);
    if (!section) {
      return;
    }

    event.preventDefault();
    section.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});

const sectionIds = ['hero', 'evolution', 'architecture', 'tx', 'rx', 'security', 'media'];
const sections = sectionIds
  .map((id) => document.getElementById(id))
  .filter((section) => section !== null);

const linkById = new Map(
  Array.from(navLinks).map((link) => [link.getAttribute('href')?.replace('#', ''), link])
);

const activeObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) {
        return;
      }

      const id = entry.target.id;
      navLinks.forEach((link) => link.classList.remove('active'));
      const activeLink = linkById.get(id);
      if (activeLink) {
        activeLink.classList.add('active');
      }
    });
  },
  {
    threshold: 0.45,
  }
);

sections.forEach((section) => activeObserver.observe(section));

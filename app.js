/* ============================================================
   OpenWorld — product site interactions
   ============================================================ */
(() => {
  "use strict";
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const fine = window.matchMedia("(pointer: fine)").matches;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const pad = (n) => String(n).padStart(2, "0");

  /* ------------------------------------------------------------
     Project data
     ------------------------------------------------------------ */
  const PROJECTS = {
    provenance: {
      name: "Provenance", letter: "P", color: "teal", category: "CONSOLE EMULATION",
      desc: "多平台开源模拟器前端 · iOS / tvOS",
      long: "一个前端，连接多个模拟核心。统一资料库、封面、存档与控制器配置，支持 iOS 与 tvOS，面向大屏与手柄优化。",
      version: "3.2.0", stars: "6.8k", size: "42 MB",
      platform: "iOS 18+ / tvOS", license: "GPL-2.0", status: "Active", source: "GitHub",
      tech: { Language: "Swift · C", Graphics: "Metal", Input: "Controller / Touch", Data: "Local + GitHub" },
      media: "128 items",
      url: "https://github.com/Provenance-Emu/Provenance",
      bullets: ["统一的多核心管理", "封面、存档与金手指", "控制器与多人游戏"],
      compat: [["Console", 92, "LISTED"], ["Handheld", 78, "LISTED"], ["Arcade", 64, "PARTIAL"], ["PC", 12, "N/A"]],
      resources: [["Release 3.2.0", "GitHub Release · 42 MB"], ["Source Code", "GitHub Repository"], ["Documentation", "Official Docs"]],
      changelog: [["3.2.0", "控制器映射与存档修复", "2026.10"], ["3.1.0", "新增核心与封面缓存", "2026.08"]],
    },
    retroarch: {
      name: "RetroArch", letter: "R", color: "violet", category: "EMULATION FRONTEND",
      desc: "统一接口，连接多个模拟核心与平台。",
      long: "统一界面，连接多个模拟核心。覆盖主机、掌机与街机，把资料库、着色器、金手指与控制器配置收进一个前端。",
      version: "1.21.0", stars: "9.4k", size: "126 MB",
      platform: "iOS / tvOS / macOS", license: "GPL-3.0", status: "Active", source: "GitHub",
      tech: { Language: "C · C++", Graphics: "Metal · Vulkan", Input: "Controller / Keyboard", Data: "Local + Cores" },
      media: "96 items",
      url: "https://github.com/libretro/RetroArch",
      bullets: ["40+ 模拟核心", "着色器与覆盖层", "跨平台配置同步"],
      compat: [["Console", 94, "LISTED"], ["Handheld", 90, "LISTED"], ["Arcade", 86, "LISTED"], ["PC", 42, "PARTIAL"]],
      resources: [["Release 1.21.0", "GitHub Release · 126 MB"], ["Source Code", "GitHub Repository"], ["Documentation", "Libretro Docs"]],
      changelog: [["1.21.0", "新增 Metal 渲染路径", "2026.09"], ["1.20.0", "核心管理与菜单更新", "2026.06"]],
    },
    fex: {
      name: "FEX-Emu", letter: "F", color: "orange", category: "X86 ON ARM",
      desc: "在 ARM 上运行 x86 / x86_64 应用与游戏。",
      long: "在 ARM64 Linux 上运行 x86 / x86_64 应用与游戏。把指令翻译、图形层与运行时组合成一条可用的兼容路径。",
      version: "2508", stars: "7.1k", size: "38 MB",
      platform: "Linux ARM64", license: "MIT", status: "Active", source: "GitHub",
      tech: { Language: "C++", Graphics: "Vulkan / OpenGL", Input: "Keyboard / Controller", Data: "Rootfs + Local" },
      media: "48 items",
      url: "https://github.com/FEX-Emu/FEX",
      bullets: ["x86 / x86_64 指令翻译", "Thunk 图形与音频", "面向游戏与桌面应用"],
      compat: [["x86 apps", 88, "LISTED"], ["x86_64 apps", 82, "LISTED"], ["D3D games", 61, "PARTIAL"], ["Anti-cheat", 8, "N/A"]],
      resources: [["Release 2508", "GitHub Release · 38 MB"], ["Source Code", "GitHub Repository"], ["Documentation", "FEX Wiki"]],
      changelog: [["2508", "改善图形 thunk 与启动速度", "2026.08"], ["2507", "新增 x86_64 指令支持", "2026.07"]],
    },
    utm: {
      name: "UTM", letter: "U", color: "blue", category: "VIRTUALIZATION",
      desc: "在 Apple 设备上运行其他系统。",
      long: "基于 QEMU 的虚拟机应用，在 iPhone、iPad 与 Mac 上运行其他操作系统。支持多种架构、外接键盘与共享目录。",
      version: "4.6.2", stars: "12.8k", size: "94 MB",
      platform: "iOS / macOS", license: "Apache-2.0", status: "Active", source: "GitHub",
      tech: { Language: "Swift", Graphics: "Metal", Input: "Touch / Keyboard", Data: "QEMU + Local" },
      media: "64 items",
      url: "https://github.com/utmapp/UTM",
      bullets: ["QEMU 后端", "多架构虚拟机", "共享目录与外设"],
      compat: [["Linux", 86, "LISTED"], ["Windows", 72, "PARTIAL"], ["macOS", 38, "PARTIAL"], ["DOS", 90, "LISTED"]],
      resources: [["Release 4.6.2", "GitHub Release · 94 MB"], ["Source Code", "GitHub Repository"], ["Documentation", "UTM Docs"]],
      changelog: [["4.6.2", "修复 iOS 外接键盘输入", "2026.09"], ["4.6.0", "新增共享目录与 Metal 加速", "2026.07"]],
    },
    box64: {
      name: "Box64", letter: "B", color: "pink", category: "X86_64 TRANSLATION",
      desc: "让 x86_64 Linux 程序在 ARM 设备上运行。",
      long: "让 x86_64 Linux 程序运行在 ARM 设备上。通过动态重编译与原生库桥接，把桌面程序与游戏带进 ARM 世界。",
      version: "0.3.6", stars: "5.9k", size: "18 MB",
      platform: "Linux ARM64", license: "MIT", status: "Active", source: "GitHub",
      tech: { Language: "C", Graphics: "OpenGL / Vulkan", Input: "Keyboard / Controller", Data: "Rootfs + Local" },
      media: "32 items",
      url: "https://github.com/ptitSeb/box64",
      bullets: ["动态重编译", "原生库桥接", "包装器与 Wine 集成"],
      compat: [["x86_64 apps", 84, "LISTED"], ["Games", 68, "PARTIAL"], ["Wine", 76, "LISTED"], ["Native AVX", 34, "PARTIAL"]],
      resources: [["Release 0.3.6", "GitHub Release · 18 MB"], ["Source Code", "GitHub Repository"], ["Documentation", "Box64 Docs"]],
      changelog: [["0.3.6", "增强 Wine 与 AVX 支持", "2026.08"], ["0.3.4", "改善动态重编译性能", "2026.05"]],
    },
    dxmt: {
      name: "DXMT", letter: "D", color: "gold", category: "D3D → METAL",
      desc: "把 Direct3D 带到 Metal，让游戏在 Apple 设备上运行。",
      long: "把 Direct3D 11 / 12 调用翻译到 Metal，为 Apple 设备上的 Windows 游戏提供图形路径。与 Wine / CrossOver 生态配合使用。",
      version: "0.80", stars: "4.7k", size: "22 MB",
      platform: "macOS", license: "MIT", status: "Active", source: "GitHub",
      tech: { Language: "C++", Graphics: "Metal", Input: "D3D11 / D3D12", Data: "Wine + Local" },
      media: "24 items",
      url: "https://github.com/3Shain/dxmt",
      bullets: ["D3D11 → Metal", "D3D12 → Metal", "Wine 图形后端"],
      compat: [["D3D11", 82, "LISTED"], ["D3D12", 54, "PARTIAL"], ["DXGI", 78, "LISTED"], ["Ray tracing", 12, "N/A"]],
      resources: [["Release 0.80", "GitHub Release · 22 MB"], ["Source Code", "GitHub Repository"], ["Documentation", "DXMT Wiki"]],
      changelog: [["0.80", "D3D12 指令覆盖提升", "2026.09"], ["0.72", "优化 Metal 管线缓存", "2026.06"]],
    },
  };

  const PROJECT_ORDER = ["provenance", "retroarch", "fex", "utm", "box64", "dxmt"];
  const colorClass = (p) => `project-icon ${p.color}`;
  const iconHTML = (p) => `<span class="${colorClass(p)}">${p.letter}</span>`;

  /* ------------------------------------------------------------
     Nav, menu, reveal, pointer
     ------------------------------------------------------------ */
  function initNav() {
    const nav = $("#nav");
    const progress = $("#progress");
    const ghost = $(".hero-ghost");
    const orbitA = $(".orbit-a");
    const orbitB = $(".orbit-b");
    let ticking = false;
    const update = () => {
      const y = window.scrollY;
      nav?.classList.toggle("scrolled", y > 16);
      const max = document.documentElement.scrollHeight - window.innerHeight;
      if (progress) progress.style.width = `${max > 0 ? Math.min(100, (y / max) * 100) : 0}%`;
      if (ghost) ghost.style.transform = `translateX(-50%) translateY(${y * 0.075}px)`;
      if (orbitA) orbitA.style.transform = `rotate(-22deg) translateY(${y * 0.035}px)`;
      if (orbitB) orbitB.style.transform = `rotate(-28deg) translateY(${y * 0.055}px)`;
      ticking = false;
    };
    window.addEventListener("scroll", () => {
      if (!ticking) { ticking = true; requestAnimationFrame(update); }
    }, { passive: true });
    update();

    const menu = $("#mobileMenu");
    const btn = $("#menuBtn");
    const close = $("#menuClose");
    const open = () => {
      menu?.classList.add("open");
      menu?.setAttribute("aria-hidden", "false");
      btn?.setAttribute("aria-expanded", "true");
      document.body.classList.add("lock");
      close?.focus();
    };
    const shut = () => {
      menu?.classList.remove("open");
      menu?.setAttribute("aria-hidden", "true");
      btn?.setAttribute("aria-expanded", "false");
      document.body.classList.remove("lock");
    };
    btn?.addEventListener("click", () => menu?.classList.contains("open") ? shut() : open());
    close?.addEventListener("click", shut);
    $$("a", menu).forEach((a) => a.addEventListener("click", shut));
    document.addEventListener("keydown", (e) => { if (e.key === "Escape" && menu?.classList.contains("open")) shut(); });
  }

  function initReveal() {
    const nodes = $$(".reveal");
    if (reduced || !("IntersectionObserver" in window)) {
      nodes.forEach((n) => n.classList.add("is-in"));
      return;
    }
    const obs = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) { entry.target.classList.add("is-in"); obs.unobserve(entry.target); }
      });
    }, { threshold: .07, rootMargin: "0px 0px -5% 0px" });
    nodes.forEach((n) => obs.observe(n));
  }

  function initPointer() {
    if (!fine) return;
    const glow = $("#glow");
    let raf = 0, x = 0, y = 0;
    window.addEventListener("pointermove", (e) => {
      x = e.clientX; y = e.clientY;
      if (glow) glow.style.opacity = "1";
      if (!raf) raf = requestAnimationFrame(() => {
        if (glow) glow.style.transform = `translate(${x}px, ${y}px) translate(-50%,-50%)`;
        raf = 0;
      });
    }, { passive: true });
    document.addEventListener("pointerleave", () => { if (glow) glow.style.opacity = "0"; });

    const device = $("#device");
    const stage = $(".hero-device");
    if (device && stage) {
      stage.addEventListener("pointermove", (e) => {
        const r = stage.getBoundingClientRect();
        const px = (e.clientX - r.left) / r.width - .5;
        const py = (e.clientY - r.top) / r.height - .5;
        device.style.transform = `rotateY(${px * 5 - 2}deg) rotateX(${-py * 3 + 1}deg) translateY(-2px)`;
      });
      stage.addEventListener("pointerleave", () => { device.style.transform = ""; });
    }

    $$(".btn, .nav-get").forEach((el) => {
      el.addEventListener("pointermove", (e) => {
        const r = el.getBoundingClientRect();
        const dx = (e.clientX - (r.left + r.width / 2)) / r.width;
        const dy = (e.clientY - (r.top + r.height / 2)) / r.height;
        el.style.translate = `${dx * 3}px ${dy * 2}px`;
      });
      el.addEventListener("pointerleave", () => { el.style.translate = "0 0"; });
    });
  }

  /* ------------------------------------------------------------
     Hero app tabs
     ------------------------------------------------------------ */
  function initAppTabs() {
    const tabs = $$(".app-tab");
    const screens = $$(".app-screen");
    const select = (key, focus = false) => {
      tabs.forEach((tab) => {
        const on = tab.dataset.appTab === key;
        tab.classList.toggle("active", on);
        tab.setAttribute("aria-selected", String(on));
        tab.tabIndex = on ? 0 : -1;
        if (on && focus) tab.focus();
      });
      screens.forEach((s) => {
        const on = s.dataset.appScreen === key;
        s.hidden = !on;
        s.classList.toggle("active", on);
      });
    };
    let autoIndex = 0;
    let interacted = false;
    let paused = false;
    const hero = $(".hero");
    tabs.forEach((tab, index) => {
      tab.addEventListener("click", () => { interacted = true; select(tab.dataset.appTab); });
      tab.addEventListener("focus", () => { interacted = true; });
      tab.addEventListener("keydown", (e) => {
        let next = -1;
        if (e.key === "ArrowRight") next = (index + 1) % tabs.length;
        if (e.key === "ArrowLeft") next = (index - 1 + tabs.length) % tabs.length;
        if (e.key === "Home") next = 0;
        if (e.key === "End") next = tabs.length - 1;
        if (next >= 0) { e.preventDefault(); select(tabs[next].dataset.appTab, true); }
      });
    });
    const stage = $(".hero-device");
    stage?.addEventListener("pointerenter", () => { paused = true; });
    stage?.addEventListener("pointerleave", () => { paused = false; });
    if (!reduced) {
      setInterval(() => {
        if (interacted || paused || document.hidden) return;
        autoIndex = (autoIndex + 1) % tabs.length;
        select(tabs[autoIndex].dataset.appTab);
      }, 6800);
    }
    select("discover");
  }

  /* ------------------------------------------------------------
     Discover search / filter
     ------------------------------------------------------------ */
  function initDiscover() {
    const search = $("#projectSearch");
    const chips = $$(".filter-chips .chip");
    const cards = $$(".project-card");
    const count = $("#resultCount");
    let filter = "all";
    const apply = () => {
      const q = (search?.value || "").trim().toLowerCase();
      let n = 0;
      cards.forEach((card) => {
        const matchFilter = filter === "all" || card.dataset.filter === filter;
        const hay = `${card.dataset.search} ${card.textContent}`.toLowerCase();
        const matchSearch = !q || hay.includes(q);
        const show = matchFilter && matchSearch;
        card.classList.toggle("hide", !show);
        if (show) n++;
      });
      if (count) count.textContent = `${pad(n)} PROJECT${n === 1 ? "" : "S"}`;
    };
    chips.forEach((chip) => chip.addEventListener("click", () => {
      filter = chip.dataset.filter;
      chips.forEach((c) => c.classList.toggle("active", c === chip));
      apply();
    }));
    search?.addEventListener("input", apply);
    document.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        search?.focus();
      }
    });
  }

  /* ------------------------------------------------------------
     Project dialog
     ------------------------------------------------------------ */
  let activeProject = null;
  let activePdTab = "overview";
  const favs = (() => {
    try { return new Set(JSON.parse(localStorage.getItem("ow-favs") || "[]")); } catch (_) { return new Set(); }
  })();
  const saveFavs = () => { try { localStorage.setItem("ow-favs", JSON.stringify([...favs])); } catch (_) {} };

  function renderProjectStats(p) {
    const el = $("#pdStats");
    if (!el) return;
    el.innerHTML = [
      ["PLATFORM", p.platform], ["LICENSE", p.license], ["STATUS", p.status], ["DATA SOURCE", p.source],
    ].map(([k, v]) => `<div class="pd-stat"><span>${k}</span><strong>${v}</strong></div>`).join("");
  }
  function renderProjectBody() {
    const p = PROJECTS[activeProject];
    const body = $("#pdBody");
    if (!p || !body) return;
    if (activePdTab === "overview") {
      body.innerHTML = `<div class="pd-overview"><div><p>${p.long}</p><ul class="pd-list">${p.bullets.map((b) => `<li>${b}</li>`).join("")}</ul></div><div class="pd-tech"><span>TECHNICAL PROFILE</span><dl>${Object.entries(p.tech).map(([k, v]) => `<div><dt>${k}</dt><dd>${v}</dd></div>`).join("")}</dl></div></div>`;
    } else if (activePdTab === "compat") {
      body.innerHTML = `<div class="pd-compat">${p.compat.map(([name, pct, state]) => `<div class="pd-compat-row"><span>${name}</span><div class="pd-compat-bar"><i style="--p:${pct}%"></i></div><em>${state}</em></div>`).join("")}</div>`;
    } else if (activePdTab === "resources") {
      body.innerHTML = p.resources.map(([name, meta]) => `<div class="pd-resource"><div><strong>${name}</strong><span>${meta.toUpperCase()}</span></div><span>→</span></div>`).join("");
    } else {
      body.innerHTML = p.changelog.map(([v, text, date]) => `<div class="pd-change"><span>${v}</span><span>${text}</span><span>${date}</span></div>`).join("");
    }
  }
  function setPdTab(tab, focus = false) {
    activePdTab = tab;
    $$(".pd-tab").forEach((b) => {
      const on = b.dataset.pdTab === tab;
      b.classList.toggle("active", on);
      b.setAttribute("aria-selected", String(on));
      b.tabIndex = on ? 0 : -1;
      if (on && focus) b.focus();
    });
    renderProjectBody();
  }
  function openProject(id) {
    const p = PROJECTS[id];
    if (!p) return;
    activeProject = id;
    setPdTab("overview");
    const dlg = $("#projectDialog");
    $("#pdName").textContent = p.name;
    $("#pdDesc").textContent = p.desc;
    $("#pdIcon").className = colorClass(p);
    $("#pdIcon").textContent = p.letter;
    $("#pdUrl").href = p.url;
    $("#pdFootName").textContent = `${p.name} · Release ${p.version}`;
    $("#pdFootMeta").textContent = `${p.platform} · ${p.size} · SHA-256 可校验`;
    $("#pdGet").href = p.url;
    renderProjectStats(p);
    const fav = $("#pdFav");
    if (fav) {
      fav.setAttribute("aria-pressed", String(favs.has(id)));
      fav.querySelector("span").textContent = favs.has(id) ? "已收藏" : "收藏项目";
    }
    renderProjectBody();
    if (typeof dlg?.showModal === "function") dlg.showModal();
    document.body.classList.add("lock");
  }
  function closeProject() {
    const dlg = $("#projectDialog");
    if (typeof dlg?.close === "function") dlg.close();
    document.body.classList.remove("lock");
  }
  function initProjectDialog() {
    $$("[data-project-open]").forEach((el) => el.addEventListener("click", () => openProject(el.dataset.projectOpen)));
    $$(".project-card").forEach((el) => el.addEventListener("click", () => openProject(el.dataset.project)));
    $("#pdClose")?.addEventListener("click", closeProject);
    $("#projectDialog")?.addEventListener("click", (e) => { if (e.target === $("#projectDialog")) closeProject(); });
    $("#projectDialog")?.addEventListener("close", () => document.body.classList.remove("lock"));
    $("#pdFav")?.addEventListener("click", () => {
      if (!activeProject) return;
      if (favs.has(activeProject)) favs.delete(activeProject); else favs.add(activeProject);
      saveFavs();
      const fav = $("#pdFav");
      fav.setAttribute("aria-pressed", String(favs.has(activeProject)));
      fav.querySelector("span").textContent = favs.has(activeProject) ? "已收藏" : "收藏项目";
    });
    const tabs = $$(".pd-tab");
    tabs.forEach((tab, i) => {
      tab.addEventListener("click", () => setPdTab(tab.dataset.pdTab));
      tab.addEventListener("keydown", (e) => {
        let next = -1;
        if (e.key === "ArrowRight") next = (i + 1) % tabs.length;
        if (e.key === "ArrowLeft") next = (i - 1 + tabs.length) % tabs.length;
        if (next >= 0) { e.preventDefault(); setPdTab(tabs[next].dataset.pdTab, true); }
      });
    });
  }

  /* ------------------------------------------------------------
     Atlas
     ------------------------------------------------------------ */
  function initAtlas() {
    const tabs = $$(".atlas-tab");
    const panels = $$(".atlas-panel");
    const count = $("#atlasCount");
    const select = (key, focus = false) => {
      tabs.forEach((tab) => {
        const on = tab.dataset.atlas === key;
        tab.classList.toggle("active", on);
        tab.setAttribute("aria-selected", String(on));
        tab.tabIndex = on ? 0 : -1;
        if (on && focus) tab.focus();
      });
      panels.forEach((p) => {
        const on = p.dataset.atlasPanel === key;
        p.hidden = !on;
        p.classList.toggle("active", on);
      });
      if (count) count.textContent = key === "emulators" ? "6 PROJECTS" : "4 PROJECTS";
    };
    tabs.forEach((tab, i) => {
      tab.addEventListener("click", () => select(tab.dataset.atlas));
      tab.addEventListener("keydown", (e) => {
        let next = -1;
        if (e.key === "ArrowRight") next = (i + 1) % tabs.length;
        if (e.key === "ArrowLeft") next = (i - 1 + tabs.length) % tabs.length;
        if (next >= 0) { e.preventDefault(); select(tabs[next].dataset.atlas, true); }
      });
    });
    const filters = $$(".atlas-filters .chip");
    const cards = $$(".emu-card");
    filters.forEach((chip) => chip.addEventListener("click", () => {
      filters.forEach((c) => c.classList.toggle("active", c === chip));
      cards.forEach((card) => {
        const show = chip.dataset.platform === "all" || card.dataset.platform === chip.dataset.platform;
        card.classList.toggle("hide", !show);
      });
    }));
  }

  /* ------------------------------------------------------------
     Research graph
     ------------------------------------------------------------ */
  const GRAPH = {
    kernel: { label: "Kernel", cat: "SYSTEM", desc: "底层系统能力与驱动接口，决定模拟与虚拟化能走多深。", projects: "Kernel · Drivers", platform: "iOS / macOS", status: "Active", related: ["emulation", "compatibility"], project: "utm" },
    emulation: { label: "Emulation", cat: "CORE", desc: "把不同硬件的行为翻译成当前设备能执行的指令。", projects: "RetroArch · Provenance", platform: "Multi", status: "Active", related: ["graphics", "runtime"], project: "retroarch" },
    graphics: { label: "Graphics", cat: "RENDER", desc: "把图形 API 映射到 Metal，决定游戏能不能真正跑起来。", projects: "DXMT · MoltenVK", platform: "Apple Silicon", status: "Active", related: ["virtualization", "media"], project: "dxmt" },
    virtualization: { label: "Virtualization", cat: "SYSTEM", desc: "虚拟化 · 在 Apple 设备上运行其他系统。", projects: "UTM · QEMU", platform: "iOS / macOS", status: "Active", related: ["runtime", "graphics"], project: "utm" },
    compatibility: { label: "Compatibility", cat: "MATRIX", desc: "按平台、核心与真实运行结果维护的兼容性矩阵。", projects: "Community verifies", platform: "All", status: "Live", related: ["emulation", "ai"], project: "provenance" },
    runtime: { label: "Runtime", cat: "TRANSLATION", desc: "指令翻译与运行时桥接，让不同架构共享同一套软件。", projects: "FEX-Emu · Box64", platform: "ARM64", status: "Active", related: ["emulation", "virtualization"], project: "fex" },
    media: { label: "Media", cat: "EVIDENCE", desc: "真实截图、演示与视频，按来源归档，证明它真的在运行。", projects: "Media Intelligence", platform: "OpenWorld", status: "Live", related: ["compatibility", "graphics"], project: "provenance" },
    ai: { label: "AI", cat: "ASSIST", desc: "用模型整理项目、补全资料、发现关联，但不替代来源。", projects: "OpenWorld Assist", platform: "OpenWorld", status: "Experimental", related: ["compatibility", "media"], project: "provenance" },
  };
  const GRAPH_EDGES = [
    ["kernel", "emulation"], ["emulation", "graphics"], ["emulation", "virtualization"],
    ["graphics", "virtualization"], ["kernel", "compatibility"], ["compatibility", "media"],
    ["virtualization", "media"], ["virtualization", "runtime"], ["emulation", "runtime"],
    ["compatibility", "ai"], ["ai", "media"], ["runtime", "graphics"],
  ];
  let graphSelected = "virtualization";

  function drawGraphLines() {
    const svg = $("#graphLines");
    if (!svg) return;
    const pos = {};
    $$(".graph-node").forEach((n) => {
      const key = n.dataset.node;
      const x = parseFloat(n.style.getPropertyValue("--x")) * 10;
      const y = parseFloat(n.style.getPropertyValue("--y")) * 6.2;
      pos[key] = [x, y];
    });
    svg.innerHTML = GRAPH_EDGES.map(([a, b]) => {
      const [x1, y1] = pos[a] || [0, 0];
      const [x2, y2] = pos[b] || [0, 0];
      const mx = (x1 + x2) / 2;
      const my = Math.min(y1, y2) - 38;
      return `<path data-a="${a}" data-b="${b}" d="M${x1} ${y1} Q ${mx} ${my} ${x2} ${y2}"/>`;
    }).join("");
    updateGraphHighlight();
  }
  function updateGraphHighlight() {
    const node = GRAPH[graphSelected];
    $$(".graph-lines path").forEach((path) => {
      path.classList.toggle("hot", path.dataset.a === graphSelected || path.dataset.b === graphSelected);
    });
  }
  function selectGraph(key, focus = false) {
    const node = GRAPH[key];
    if (!node) return;
    graphSelected = key;
    $$(".graph-node").forEach((n) => {
      const on = n.dataset.node === key;
      n.classList.toggle("active", on);
      if (on && focus) n.focus();
    });
    $("#graphCat").textContent = node.cat;
    $("#graphTitle").textContent = node.label;
    $("#graphDesc").textContent = node.desc;
    $("#graphProjects").textContent = node.projects;
    $("#graphPlatform").textContent = node.platform;
    $("#graphStatus").textContent = node.status;
    $("#graphIndex").textContent = `${pad(Object.keys(GRAPH).indexOf(key) + 1)} / 08`;
    $("#graphRelated").innerHTML = node.related.map((r) => `<button type="button" data-jump="${r}">${GRAPH[r].label}</button>`).join("");
    bindGraphJumps();
    updateGraphHighlight();
  }
  function bindGraphJumps() {
    $$("#graphRelated [data-jump]").forEach((b) => b.addEventListener("click", () => selectGraph(b.dataset.jump)));
  }
  function initGraph() {
    drawGraphLines();
    $$(".graph-node").forEach((n) => n.addEventListener("click", () => selectGraph(n.dataset.node)));
    bindGraphJumps();
    $("#graphView")?.addEventListener("click", () => openProject(GRAPH[graphSelected].project));
    window.addEventListener("resize", drawGraphLines, { passive: true });
    selectGraph("virtualization");
  }

  /* ------------------------------------------------------------
     Downloads
     ------------------------------------------------------------ */
  const DL = {
    app: { pct: 68, status: "downloading", speed: "12.4 MB/s", name: "iOSHub 3.2.1" },
    runtime: { pct: 34, status: "paused", speed: "已暂停", name: "Desktop Runtime" },
    shader: { pct: 100, status: "verified", speed: "SHA-256 verified", name: "Shader Cache" },
    media: { pct: 12, status: "failed", speed: "校验失败 · 重试", name: "Media Pack" },
  };
  let dlTimer = 0;
  let dlStarted = false;

  function dlRow(id) { return document.querySelector(`.dl-row[data-dl="${id}"]`); }
  function renderDL(id) {
    const d = DL[id];
    const row = dlRow(id);
    if (!d || !row) return;
    const bar = $(".dl-bar i", row);
    const pct = $(".dl-pct", row);
    const speed = $(".dl-speed", row);
    const action = $(".dl-action", row);
    const info = $(".dl-info em", row);
    if (bar) bar.style.width = `${d.pct}%`;
    if (pct) pct.textContent = `${Math.floor(d.pct)}%`;
    if (speed) speed.textContent = d.speed;
    if (info) info.textContent = id === "app" ? "iPhone & iPad · 3.9 MB" : id === "runtime" ? "macOS · 126 MB" : id === "shader" ? "All platforms · 38 MB" : "Optional · 210 MB";
    row.classList.toggle("done", d.status === "verified");
    row.classList.toggle("failed", d.status === "failed");
    if (!action) return;
    const icon = action.querySelector("svg use");
    const label = action.querySelector("span");
    action.classList.toggle("verified", d.status === "verified");
    action.classList.toggle("failed", d.status === "failed");
    if (d.status === "downloading") { icon?.setAttribute("href", "#i-pause"); if (label) label.textContent = "暂停"; action.disabled = false; }
    else if (d.status === "paused") { icon?.setAttribute("href", "#i-play"); if (label) label.textContent = "继续"; action.disabled = false; }
    else if (d.status === "queued") { icon?.setAttribute("href", "#i-play"); if (label) label.textContent = "开始"; action.disabled = false; }
    else if (d.status === "failed") { icon?.setAttribute("href", "#i-refresh"); if (label) label.textContent = "重试"; action.disabled = false; }
    else if (d.status === "verifying") { icon?.setAttribute("href", "#i-download"); if (label) label.textContent = "校验中"; action.disabled = true; }
    else { icon?.setAttribute("href", "#i-check"); if (label) label.textContent = "已校验"; action.disabled = false; }
  }
  function dlTick() {
    Object.keys(DL).forEach((id) => {
      const d = DL[id];
      if (d.status !== "downloading") return;
      d.pct = Math.min(100, d.pct + (0.5 + Math.random() * 1.1));
      d.speed = `${(8 + Math.random() * 7).toFixed(1)} MB/s`;
      if (d.pct >= 100) {
        d.pct = 100; d.status = "verifying"; d.speed = "SHA-256 校验中…";
        setTimeout(() => {
          if (d.status !== "verifying") return;
          d.status = "verified"; d.speed = "SHA-256 verified";
          renderDL(id);
          toast(`${d.name} · SHA-256 已校验`);
        }, 850);
      }
      renderDL(id);
    });
    const done = Object.values(DL).filter((d) => d.status === "verified").length;
    const head = $(".dm-head strong");
    if (head) head.textContent = `${Object.keys(DL).length} 个任务 · ${done} 个已完成`;
  }
  function initDownloads() {
    Object.keys(DL).forEach(renderDL);
    $$("[data-dl-action]").forEach((btn) => btn.addEventListener("click", () => {
      const id = btn.dataset.dlAction;
      const d = DL[id];
      if (!d) return;
      if (d.status === "downloading") { d.status = "paused"; d.speed = "已暂停"; }
      else if (d.status === "paused" || d.status === "queued" || d.status === "failed") { d.status = "downloading"; d.speed = "重新连接…"; }
      else if (d.status === "verified") { toast(`${d.name} · SHA-256 verified`); return; }
      renderDL(id);
    }));
    $$("[data-dl-setting]").forEach((btn) => btn.addEventListener("click", () => {
      const on = btn.getAttribute("aria-checked") === "true";
      btn.setAttribute("aria-checked", String(!on));
      toast(btn.dataset.dlSetting === "wifi" ? (!on ? "已开启仅 Wi-Fi 下载" : "已允许蜂窝网络下载") : (!on ? "已开启 SHA-256 自动校验" : "已关闭自动校验"));
    }));
    $$(".dl-seg button").forEach((btn) => btn.addEventListener("click", () => {
      $$(".dl-seg button").forEach((b) => b.classList.toggle("active", b === btn));
      toast(`并发任务：${btn.textContent} 个`);
    }));
    const section = $("#downloads");
    if (!section || !("IntersectionObserver" in window)) { dlStarted = true; dlTimer = setInterval(dlTick, 700); return; }
    const obs = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting) && !dlStarted) {
        dlStarted = true;
        dlTimer = setInterval(dlTick, 700);
        obs.disconnect();
      }
    }, { threshold: .2 });
    obs.observe(section);
  }

  /* ------------------------------------------------------------
     Library compare
     ------------------------------------------------------------ */
  let compareSelected = ["provenance", "retroarch", "utm"];
  function renderCompare() {
    const table = $("#compareTable");
    if (!table) return;
    const rows = [
      ["Platform", (p) => p.platform], ["License", (p) => p.license], ["Graphics", (p) => p.tech.Graphics],
      ["Status", (p) => p.status], ["Media", (p) => p.media],
    ];
    const head = `<tr><th>PROJECT</th>${compareSelected.map((id) => `<th>${PROJECTS[id].name}</th>`).join("")}</tr>`;
    const body = rows.map(([label, get]) => `<tr><td>${label.toUpperCase()}</td>${compareSelected.map((id) => `<td>${get(PROJECTS[id])}</td>`).join("")}</tr>`).join("");
    table.querySelector("thead").innerHTML = head;
    table.querySelector("tbody").innerHTML = body;
  }
  function initLibrary() {
    renderCompare();
    $$(".compare-chip").forEach((chip) => chip.addEventListener("click", () => {
      const id = chip.dataset.compare;
      if (compareSelected.includes(id)) {
        if (compareSelected.length === 1) { toast("至少保留一个项目"); return; }
        compareSelected = compareSelected.filter((x) => x !== id);
        chip.classList.remove("active");
      } else {
        if (compareSelected.length >= 3) { toast("最多对比 3 个项目"); return; }
        compareSelected.push(id);
        chip.classList.add("active");
      }
      renderCompare();
    }));
  }

  /* ------------------------------------------------------------
     Film + media lightbox + toasts
     ------------------------------------------------------------ */
  function openFilm() {
    const dlg = $("#filmDialog");
    const video = $("#filmVideo");
    if (!dlg) return;
    if (typeof dlg.showModal === "function") dlg.showModal();
    document.body.classList.add("lock");
    if (video) {
      try { video.currentTime = 0; } catch (_) {}
      video.play?.().catch(() => {});
    }
  }
  function closeFilm() {
    const dlg = $("#filmDialog");
    const video = $("#filmVideo");
    video?.pause?.();
    if (typeof dlg?.close === "function") dlg.close();
    document.body.classList.remove("lock");
  }
  function initFilm() {
    $$("[data-film]").forEach((b) => b.addEventListener("click", openFilm));
    $("#filmClose")?.addEventListener("click", closeFilm);
    $("#filmDialog")?.addEventListener("click", (e) => { if (e.target === $("#filmDialog")) closeFilm(); });
    $("#filmDialog")?.addEventListener("close", () => { $("#filmVideo")?.pause?.(); document.body.classList.remove("lock"); });

    const lightbox = document.createElement("div");
    lightbox.className = "lightbox";
    lightbox.setAttribute("role", "dialog");
    lightbox.setAttribute("aria-label", "媒体预览");
    lightbox.innerHTML = `<button type="button" class="lb-close" aria-label="关闭">×</button><figure><img alt=""><figcaption></figcaption></figure>`;
    document.body.appendChild(lightbox);
    const closeLb = () => { lightbox.classList.remove("open"); document.body.classList.remove("lock"); };
    lightbox.querySelector(".lb-close").addEventListener("click", closeLb);
    lightbox.addEventListener("click", (e) => { if (e.target === lightbox) closeLb(); });
    document.addEventListener("keydown", (e) => { if (e.key === "Escape" && lightbox.classList.contains("open")) closeLb(); });

    $$(".media-card").forEach((card) => card.addEventListener("click", () => {
      const key = card.dataset.media;
      if (key === "video") { openFilm(); return; }
      const bg = card.querySelector(".media-bg");
      const raw = bg ? getComputedStyle(bg).backgroundImage : "";
      const url = raw.replace(/^url\(["']?/, "").replace(/["']?\)$/, "");
      const title = card.querySelector(".media-caption strong")?.textContent || "";
      const sub = card.querySelector(".media-caption em")?.textContent || "";
      const source = card.querySelector(".media-source")?.textContent || "";
      lightbox.querySelector("img").src = url;
      lightbox.querySelector("img").alt = bg?.getAttribute("aria-label") || "";
      lightbox.querySelector("figcaption").textContent = `${title} — ${sub} / ${source}`;
      lightbox.classList.add("open");
      document.body.classList.add("lock");
    }));
  }

  let toastTimer = 0;
  function toast(msg) {
    const el = $("#toast");
    if (!el) return;
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.remove("show"), 2200);
  }

  /* ------------------------------------------------------------
     Global search
     ------------------------------------------------------------ */
  function initGlobalSearch() {
    const input = $("#globalQuery");
    const rows = $$(".global-row");
    const chips = $$("[data-global-filter]");
    const count = $("#globalCount");
    const list = $("#globalResults");
    let kind = "all";
    const apply = () => {
      const q = (input?.value || "").trim().toLowerCase();
      let visible = 0;
      rows.forEach((row) => {
        const kinds = (row.dataset.kind || "").split(",");
        const matchKind = kind === "all" || kinds.includes(kind) || (kind === "open" && row.dataset.open === "true");
        const hay = `${row.dataset.search || ""} ${row.textContent}`.toLowerCase();
        const matchText = !q || hay.includes(q);
        row.classList.toggle("hide", !(matchKind && matchText));
        if (matchKind && matchText) visible++;
      });
      if (count) count.textContent = `${pad(visible)} RESULT${visible === 1 ? "" : "S"}`;
      let empty = $(".global-empty", list);
      if (!visible && list) {
        if (!empty) { empty = document.createElement("div"); empty.className = "global-empty"; empty.textContent = "没有结果。试试 metal、translation 或 open source。"; list.appendChild(empty); }
        empty.hidden = false;
      } else if (empty) empty.hidden = true;
    };
    input?.addEventListener("input", apply);
    $("#globalSubmit")?.addEventListener("click", () => { apply(); toast(`${count?.textContent || "0"} · RELEVANCE`); });
    chips.forEach((chip) => chip.addEventListener("click", () => {
      kind = chip.dataset.globalFilter;
      chips.forEach((c) => c.classList.toggle("active", c === chip));
      apply();
    }));
    apply();
  }

  /* ------------------------------------------------------------
     World + misc
     ------------------------------------------------------------ */
  function initWorld() {
    $$(".world-node, .world-dock button").forEach((node) => node.addEventListener("click", () => {
      const target = $(node.dataset.go);
      target?.scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "start" });
    }));
    $$(".footer-cols a[href^='#'], .nav-links a[href^='#']").forEach((a) => {
      a.addEventListener("click", (e) => {
        const target = $(a.getAttribute("href"));
        if (!target) return;
        e.preventDefault();
        target.scrollIntoView({ behavior: reduced ? "auto" : "smooth", block: "start" });
      });
    });
  }

  function init() {
    initNav();
    initReveal();
    initPointer();
    initAppTabs();
    initDiscover();
    initProjectDialog();
    initAtlas();
    initGraph();
    initDownloads();
    initLibrary();
    initGlobalSearch();
    initFilm();
    initWorld();
    const fullSha = "675247dce3d4213b3321ff171df664c5c49c98e7ca91d51bfe6814f46ac2c32b";
    $("#copySha")?.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(fullSha);
        toast("SHA-256 已复制");
      } catch (_) {
        toast("SHA-256 · " + fullSha.slice(0, 12) + "…");
      }
    });
    $$(".project-card, .emu-card, .port-card, .media-card, .get-card, .device").forEach((el) => {
      el.dataset.sheen = "";
      el.addEventListener("pointermove", (e) => {
        const r = el.getBoundingClientRect();
        el.style.setProperty("--mx", `${e.clientX - r.left}px`);
        el.style.setProperty("--my", `${e.clientY - r.top}px`);
      });
    });
    window.__owReady = true;
    document.documentElement.classList.add("ready");
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();

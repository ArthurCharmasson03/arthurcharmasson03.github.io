// Bilingual switch (FR/EN) and chart tooltips. No dependencies.
(function () {
  var root = document.documentElement;
  var titles = {
    fr: "Arthur Charmasson, ingénieur simulation",
    en: "Arthur Charmasson, simulation engineer"
  };

  function readStored() {
    try { return localStorage.getItem("lang"); } catch (e) { return null; }
  }
  function store(lang) {
    try { localStorage.setItem("lang", lang); } catch (e) { /* storage unavailable: ignore */ }
  }
  function initialLang() {
    var m = /[?&]lang=(fr|en)\b/.exec(window.location.search);
    if (m) return m[1];
    var s = readStored();
    if (s === "fr" || s === "en") return s;
    return root.getAttribute("lang") === "en" ? "en" : "fr";
  }
  function apply(lang) {
    root.setAttribute("lang", lang);
    document.title = titles[lang];
    var btn = document.getElementById("lang-toggle");
    if (btn) {
      btn.textContent = lang === "fr" ? "English" : "Français";
      btn.setAttribute("aria-label", lang === "fr" ? "Read this page in English" : "Lire cette page en français");
    }
  }

  apply(initialLang());
  var toggle = document.getElementById("lang-toggle");
  if (toggle) {
    toggle.addEventListener("click", function () {
      var next = root.getAttribute("lang") === "fr" ? "en" : "fr";
      apply(next);
      store(next);
    });
  }

  // On GitHub Pages (<user>.github.io), send code and folder links to GitHub's own
  // viewer (syntax highlighting, rendered README). Elsewhere they keep their relative href.
  var host = window.location.hostname;
  if (/\.github\.io$/i.test(host)) {
    var user = host.split(".")[0];
    var first = window.location.pathname.split("/")[1] || "";
    var repo = first && !/\.html?$/i.test(first) ? first : host;
    var branch = "main"; // change if your default branch has another name
    document.querySelectorAll("a[data-gh]").forEach(function (a) {
      var path = a.getAttribute("data-gh");
      var kind = /\/$/.test(path) ? "tree" : "blob";
      a.href = "https://github.com/" + user + "/" + repo + "/" + kind + "/" + branch + "/" + path.replace(/\/$/, "");
    });
  }

  // Tooltips: any chart element with data-tip-fr / data-tip-en
  var tip = document.createElement("div");
  tip.className = "tooltip";
  tip.setAttribute("role", "status");
  tip.hidden = true;
  document.body.appendChild(tip);

  function textFor(el) {
    var lang = root.getAttribute("lang") || "fr";
    return el.getAttribute("data-tip-" + lang) || el.getAttribute("data-tip-fr") || "";
  }
  function place(x, y) {
    var pad = 12, w = tip.offsetWidth, h = tip.offsetHeight;
    var left = Math.min(x + pad, window.innerWidth - w - 8);
    var top = y - h - pad < 8 ? y + pad : y - h - pad;
    tip.style.left = Math.max(8, left) + "px";
    tip.style.top = top + "px";
  }
  function show(el, x, y) {
    tip.textContent = textFor(el);
    tip.hidden = false;
    place(x, y);
  }
  function hide() { tip.hidden = true; }

  document.querySelectorAll("[data-tip-fr]").forEach(function (el) {
    el.addEventListener("pointerenter", function (e) { show(el, e.clientX, e.clientY); });
    el.addEventListener("pointermove", function (e) { place(e.clientX, e.clientY); });
    el.addEventListener("pointerleave", hide);
    el.addEventListener("focus", function () {
      var r = el.getBoundingClientRect();
      show(el, r.left + r.width / 2, r.top);
    });
    el.addEventListener("blur", hide);
  });
  window.addEventListener("scroll", hide, { passive: true });

  // Cp sections: switch between η = 0.2 and η = 0.9
  document.querySelectorAll("[data-cp-show]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var key = btn.getAttribute("data-cp-show");
      document.querySelectorAll("[data-cp-show]").forEach(function (b) {
        b.setAttribute("aria-pressed", b === btn ? "true" : "false");
      });
      document.querySelectorAll(".cp-section").forEach(function (sec) {
        sec.hidden = sec.id !== "cp-" + key;
      });
      hide();
    });
  });

  // Cp crosshair: reads the curve data embedded in #cp-data and shows the four values at x/c
  var cpEl = document.getElementById("cp-data");
  var cpData = null;
  try { cpData = cpEl ? JSON.parse(cpEl.textContent) : null; } catch (e) { cpData = null; }
  function interp(pts, x) {
    if (x <= pts[0][0]) return pts[0][1];
    for (var i = 1; i < pts.length; i++) {
      if (pts[i][0] >= x) {
        var a = pts[i - 1], b = pts[i], t = (x - a[0]) / ((b[0] - a[0]) || 1);
        return a[1] + t * (b[1] - a[1]);
      }
    }
    return pts[pts.length - 1][1];
  }
  function num(v, lang, nd) {
    var s = v.toFixed(nd).replace("-", "−");
    return lang === "fr" ? s.replace(".", ",") : s;
  }
  if (cpData) {
    document.querySelectorAll("svg.cp").forEach(function (svg) {
      var key = svg.getAttribute("data-cp");
      var L = +svg.getAttribute("data-l"), R = +svg.getAttribute("data-r");
      var hair = svg.querySelector(".xhair"), hit = svg.querySelector(".cp-hit");
      var d = cpData[key];
      function move(e) {
        var m = svg.getScreenCTM();
        if (!m) return;
        var p = svg.createSVGPoint(); p.x = e.clientX; p.y = e.clientY;
        var u = p.matrixTransform(m.inverse()).x;
        var x = Math.min(1, Math.max(0, (u - L) / (R - L)));
        hair.setAttribute("x1", u); hair.setAttribute("x2", u);
        hair.setAttribute("visibility", "visible");
        var lang = root.getAttribute("lang") || "fr";
        var lines = lang === "fr"
          ? ["x/c = " + num(x, "fr", 2),
             "Extrados : " + num(interp(d.me.upper, x), "fr", 2) + " (NASA " + num(interp(d.nasa.upper, x), "fr", 2) + ")",
             "Intrados : " + num(interp(d.me.lower, x), "fr", 2) + " (NASA " + num(interp(d.nasa.lower, x), "fr", 2) + ")"]
          : ["x/c = " + num(x, "en", 2),
             "Upper: " + num(interp(d.me.upper, x), "en", 2) + " (NASA " + num(interp(d.nasa.upper, x), "en", 2) + ")",
             "Lower: " + num(interp(d.me.lower, x), "en", 2) + " (NASA " + num(interp(d.nasa.lower, x), "en", 2) + ")"];
        tip.textContent = lines.join("\n");
        tip.style.whiteSpace = "pre";
        tip.hidden = false;
        place(e.clientX, e.clientY);
      }
      hit.addEventListener("pointermove", move);
      hit.addEventListener("pointerenter", move);
      hit.addEventListener("pointerleave", function () {
        hair.setAttribute("visibility", "hidden");
        tip.style.whiteSpace = "";
        hide();
      });
    });
  }
})();

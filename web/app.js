const groups = {
  A: ["墨西哥", "南非", "韩国", "捷克"],
  B: ["加拿大", "波黑", "卡塔尔", "瑞士"],
  C: ["巴西", "摩洛哥", "海地", "苏格兰"],
  D: ["美国", "巴拉圭", "澳大利亚", "土耳其"],
  E: ["德国", "库拉索", "科特迪瓦", "厄瓜多尔"],
  F: ["荷兰", "日本", "瑞典", "突尼斯"],
  G: ["比利时", "埃及", "伊朗", "新西兰"],
  H: ["西班牙", "佛得角", "沙特阿拉伯", "乌拉圭"],
  I: ["法国", "塞内加尔", "伊拉克", "挪威"],
  J: ["阿根廷", "阿尔及利亚", "奥地利", "约旦"],
  K: ["葡萄牙", "民主刚果", "乌兹别克斯坦", "哥伦比亚"],
  L: ["英格兰", "克罗地亚", "加纳", "巴拿马"]
};

const standingsData = {
  A: [
    { rank: 1, team: "墨西哥", played: 1, wins: 1, draws: 0, losses: 0, gf: 2, ga: 0, gd: 2, points: 3 },
    { rank: 2, team: "韩国", played: 1, wins: 1, draws: 0, losses: 0, gf: 2, ga: 1, gd: 1, points: 3 },
    { rank: 3, team: "捷克", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 2, gd: -1, points: 0 },
    { rank: 4, team: "南非", played: 1, wins: 0, draws: 0, losses: 1, gf: 0, ga: 2, gd: -2, points: 0 }
  ],
  B: [
    { rank: 1, team: "瑞士", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: 2, team: "加拿大", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: 3, team: "卡塔尔", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: 4, team: "波黑", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 }
  ],
  C: [
    { rank: 1, team: "苏格兰", played: 1, wins: 1, draws: 0, losses: 0, gf: 1, ga: 0, gd: 1, points: 3 },
    { rank: 2, team: "摩洛哥", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: 3, team: "巴西", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: 4, team: "海地", played: 1, wins: 0, draws: 0, losses: 1, gf: 0, ga: 1, gd: -1, points: 0 }
  ],
  D: [
    { rank: 1, team: "美国", played: 1, wins: 1, draws: 0, losses: 0, gf: 4, ga: 1, gd: 3, points: 3 },
    { rank: 2, team: "澳大利亚", played: 1, wins: 1, draws: 0, losses: 0, gf: 2, ga: 0, gd: 2, points: 3 },
    { rank: 3, team: "土耳其", played: 1, wins: 0, draws: 0, losses: 1, gf: 0, ga: 2, gd: -2, points: 0 },
    { rank: 4, team: "巴拉圭", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 4, gd: -3, points: 0 }
  ],
  E: [
    { rank: 1, team: "德国", played: 1, wins: 1, draws: 0, losses: 0, gf: 7, ga: 1, gd: 6, points: 3 },
    { rank: 2, team: "科特迪瓦", played: 1, wins: 1, draws: 0, losses: 0, gf: 1, ga: 0, gd: 1, points: 3 },
    { rank: 3, team: "厄瓜多尔", played: 1, wins: 0, draws: 0, losses: 1, gf: 0, ga: 1, gd: -1, points: 0 },
    { rank: 4, team: "库拉索", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 7, gd: -6, points: 0 }
  ],
  F: [
    { rank: 1, team: "瑞典", played: 1, wins: 1, draws: 0, losses: 0, gf: 5, ga: 1, gd: 4, points: 3 },
    { rank: 2, team: "日本", played: 1, wins: 0, draws: 1, losses: 0, gf: 2, ga: 2, gd: 0, points: 1 },
    { rank: 3, team: "荷兰", played: 1, wins: 0, draws: 1, losses: 0, gf: 2, ga: 2, gd: 0, points: 1 },
    { rank: 4, team: "突尼斯", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 5, gd: -4, points: 0 }
  ],
  G: ["比利时", "埃及", "伊朗", "新西兰"].map((team, index) => emptyStanding(index + 1, team)),
  H: ["西班牙", "佛得角", "沙特阿拉伯", "乌拉圭"].map((team, index) => emptyStanding(index + 1, team)),
  I: ["法国", "塞内加尔", "伊拉克", "挪威"].map((team, index) => emptyStanding(index + 1, team)),
  J: ["阿根廷", "阿尔及利亚", "奥地利", "约旦"].map((team, index) => emptyStanding(index + 1, team)),
  K: ["葡萄牙", "民主刚果", "乌兹别克斯坦", "哥伦比亚"].map((team, index) => emptyStanding(index + 1, team)),
  L: ["英格兰", "克罗地亚", "加纳", "巴拿马"].map((team, index) => emptyStanding(index + 1, team))
};

const results = [
  { date: "2026-06-12", time: "03:00", group: "A", team1: "墨西哥", team2: "南非", s1: 2, s2: 0 },
  { date: "2026-06-12", time: "10:00", group: "A", team1: "韩国", team2: "捷克", s1: 2, s2: 1 },
  { date: "2026-06-13", time: "03:00", group: "B", team1: "加拿大", team2: "波黑", s1: 1, s2: 1 },
  { date: "2026-06-13", time: "09:00", group: "D", team1: "美国", team2: "巴拉圭", s1: 4, s2: 1 },
  { date: "2026-06-14", time: "03:00", group: "B", team1: "卡塔尔", team2: "瑞士", s1: 1, s2: 1 },
  { date: "2026-06-14", time: "06:00", group: "C", team1: "巴西", team2: "摩洛哥", s1: 1, s2: 1 },
  { date: "2026-06-14", time: "09:00", group: "C", team1: "海地", team2: "苏格兰", s1: 0, s2: 1 },
  { date: "2026-06-14", time: "12:00", group: "D", team1: "澳大利亚", team2: "土耳其", s1: 2, s2: 0 },
  { date: "2026-06-15", time: "01:00", group: "E", team1: "德国", team2: "库拉索", s1: 7, s2: 1 },
  { date: "2026-06-15", time: "04:00", group: "F", team1: "荷兰", team2: "日本", s1: 2, s2: 2 },
  { date: "2026-06-15", time: "07:00", group: "E", team1: "科特迪瓦", team2: "厄瓜多尔", s1: 1, s2: 0 },
  { date: "2026-06-15", time: "10:00", group: "F", team1: "瑞典", team2: "突尼斯", s1: 5, s2: 1 }
];

const nextMatches = [
  { date: "2026-06-16", time: "00:00", group: "H", venue: "亚特兰大", match: "西班牙 vs 佛得角" },
  { date: "2026-06-16", time: "03:00", group: "G", venue: "西雅图", match: "比利时 vs 埃及" },
  { date: "2026-06-16", time: "06:00", group: "H", venue: "迈阿密", match: "沙特阿拉伯 vs 乌拉圭" },
  { date: "2026-06-16", time: "09:00", group: "G", venue: "洛杉矶", match: "伊朗 vs 新西兰" },
  { date: "2026-06-17", time: "03:00", group: "I", venue: "纽约/新泽西", match: "法国 vs 塞内加尔" },
  { date: "2026-06-17", time: "06:00", group: "I", venue: "波士顿", match: "伊拉克 vs 挪威" },
  { date: "2026-06-17", time: "09:00", group: "J", venue: "堪萨斯城", match: "阿根廷 vs 阿尔及利亚" },
  { date: "2026-06-17", time: "12:00", group: "J", venue: "旧金山湾区", match: "奥地利 vs 约旦" }
];

const knockoutSlots = [
  { match: "M73", date: "6月29日 03:00", venue: "洛杉矶", pairing: "A2 vs B2" },
  { match: "M74", date: "6月30日 04:30", venue: "波士顿", pairing: "E1 vs A3/B3/C3/D3/F3" },
  { match: "M79", date: "7月01日 09:00", venue: "墨西哥城", pairing: "A1 vs C3/E3/F3/H3/I3" },
  { match: "M85", date: "7月03日 11:00", venue: "温哥华", pairing: "B1 vs E3/F3/G3/I3/J3" },
  { match: "M101", date: "7月15日 03:00", venue: "达拉斯", pairing: "M97 胜者 vs M98 胜者" },
  { match: "M104", date: "7月20日 03:00", venue: "纽约/新泽西", pairing: "两场半决赛胜者" }
];

const impacts = [
  {
    title: "旧分组已撤销",
    body: "项目现在按你提供的分组图重建 A-L 组，并统一使用中文队名；此前英文分组只保留为已修正历史。"
  },
  {
    title: "德国和瑞典的净胜球信号最强",
    body: "德国 7-1 库拉索、瑞典 5-1 突尼斯会显著推高小组头名概率，也会影响后续淘汰赛路径。"
  },
  {
    title: "巴西首战平局会压低小组头名概率",
    body: "巴西 1-1 摩洛哥后，C 组当前由苏格兰 3 分领跑，巴西需要后两轮重新拉开积分和净胜球。"
  },
  {
    title: "B 组四队同分",
    body: "加拿大、波黑、卡塔尔、瑞士均为 1 分，当前排序按百度排名页保留；后续一场胜负会大幅改变出线概率。"
  }
];

function emptyStanding(rank, team) {
  return { rank, team, played: 0, wins: 0, draws: 0, losses: 0, gf: 0, ga: 0, gd: 0, points: 0 };
}

function renderGroupFilter() {
  const select = document.getElementById("group-filter");
  select.innerHTML = `<option value="all">全部小组</option>` +
    Object.keys(groups).map(group => `<option value="${group}">小组 ${group}</option>`).join("");
  select.addEventListener("change", () => renderStandings(select.value));
}

function renderStandings(selected = "all") {
  const board = document.getElementById("group-standings");
  const visibleGroups = selected === "all" ? Object.keys(groups) : [selected];
  board.innerHTML = visibleGroups.map(group => {
    const rows = standingsData[group].map(row => `
      <tr>
        <td>${row.rank}</td>
        <td>${row.team}</td>
        <td class="num">${row.played}</td>
        <td class="num">${row.points}</td>
        <td class="num">${row.gd > 0 ? "+" : ""}${row.gd}</td>
        <td class="num">${row.gf}/${row.ga}</td>
      </tr>
    `).join("");
    return `
      <section class="group-card">
        <div class="group-title"><span>小组 ${group}</span><span>${groups[group].join(" / ")}</span></div>
        <table>
          <thead>
            <tr><th>#</th><th>球队</th><th class="num">赛</th><th class="num">分</th><th class="num">净</th><th class="num">进/失</th></tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>
      </section>
    `;
  }).join("");
}

function renderResults() {
  const body = document.getElementById("results-body");
  body.innerHTML = results.map(match => `
    <tr>
      <td>${match.date} ${match.time}</td>
      <td>${match.group}</td>
      <td>${match.team1} vs ${match.team2}</td>
      <td><strong>${match.s1}-${match.s2}</strong></td>
    </tr>
  `).join("");
}

function renderNextMatches() {
  const body = document.getElementById("next-matches-body");
  body.innerHTML = nextMatches.map(item => `
    <tr>
      <td>${item.date} ${item.time}</td>
      <td>${item.group}</td>
      <td>${item.match}</td>
      <td>${item.venue}</td>
    </tr>
  `).join("");
}

function renderKnockoutSlots() {
  const body = document.getElementById("knockout-body");
  body.innerHTML = knockoutSlots.map(item => `
    <tr>
      <td>${item.match}</td>
      <td>${item.date}</td>
      <td>${item.pairing}</td>
      <td>${item.venue}</td>
    </tr>
  `).join("");
}

function renderImpactList() {
  const list = document.getElementById("impact-list");
  list.innerHTML = impacts.map(item => `
    <div class="impact-item">
      <strong>${item.title}</strong>
      <p>${item.body}</p>
    </div>
  `).join("");
}

function renderGoalBars() {
  const deltas = [];
  results.forEach(match => {
    deltas.push({ team: match.team1, gd: match.s1 - match.s2 });
    deltas.push({ team: match.team2, gd: match.s2 - match.s1 });
  });
  const best = deltas
    .filter(item => item.gd > 0)
    .sort((a, b) => b.gd - a.gd)
    .slice(0, 6);
  const max = Math.max(...best.map(item => item.gd), 1);
  document.getElementById("goal-bars").innerHTML = best.map(item => `
    <div class="bar-row">
      <span>${item.team}</span>
      <div class="bar-track"><div class="bar-fill" style="width:${(item.gd / max) * 100}%"></div></div>
      <strong>+${item.gd}</strong>
    </div>
  `).join("");
}

function wireNav() {
  const links = document.querySelectorAll(".nav-link");
  links.forEach(link => {
    link.addEventListener("click", () => {
      links.forEach(item => item.classList.remove("is-active"));
      link.classList.add("is-active");
    });
  });
}

document.getElementById("metric-teams").textContent = Object.values(groups).flat().length;
document.getElementById("metric-results").textContent = results.length;
document.getElementById("metric-next").textContent = nextMatches.length;
renderGroupFilter();
renderStandings();
renderResults();
renderNextMatches();
renderKnockoutSlots();
renderImpactList();
renderGoalBars();
wireNav();

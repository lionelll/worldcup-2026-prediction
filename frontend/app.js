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

let standingsData = {
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
  G: [
    { rank: "T1", team: "伊朗", played: 1, wins: 0, draws: 1, losses: 0, gf: 2, ga: 2, gd: 0, points: 1 },
    { rank: "T1", team: "新西兰", played: 1, wins: 0, draws: 1, losses: 0, gf: 2, ga: 2, gd: 0, points: 1 },
    { rank: "T3", team: "比利时", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: "T3", team: "埃及", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 }
  ],
  H: [
    { rank: "T1", team: "沙特阿拉伯", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: "T1", team: "乌拉圭", played: 1, wins: 0, draws: 1, losses: 0, gf: 1, ga: 1, gd: 0, points: 1 },
    { rank: "T3", team: "西班牙", played: 1, wins: 0, draws: 1, losses: 0, gf: 0, ga: 0, gd: 0, points: 1 },
    { rank: "T3", team: "佛得角", played: 1, wins: 0, draws: 1, losses: 0, gf: 0, ga: 0, gd: 0, points: 1 }
  ],
  I: [
    { rank: 1, team: "挪威", played: 1, wins: 1, draws: 0, losses: 0, gf: 4, ga: 1, gd: 3, points: 3 },
    { rank: 2, team: "法国", played: 1, wins: 1, draws: 0, losses: 0, gf: 3, ga: 1, gd: 2, points: 3 },
    { rank: 3, team: "塞内加尔", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 3, gd: -2, points: 0 },
    { rank: 4, team: "伊拉克", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 4, gd: -3, points: 0 }
  ],
  J: [
    { rank: 1, team: "阿根廷", played: 1, wins: 1, draws: 0, losses: 0, gf: 3, ga: 0, gd: 3, points: 3 },
    { rank: 2, team: "奥地利", played: 1, wins: 1, draws: 0, losses: 0, gf: 3, ga: 1, gd: 2, points: 3 },
    { rank: 3, team: "约旦", played: 1, wins: 0, draws: 0, losses: 1, gf: 1, ga: 3, gd: -2, points: 0 },
    { rank: 4, team: "阿尔及利亚", played: 1, wins: 0, draws: 0, losses: 1, gf: 0, ga: 3, gd: -3, points: 0 }
  ],
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
  { date: "2026-06-15", time: "10:00", group: "F", team1: "瑞典", team2: "突尼斯", s1: 5, s2: 1 },
  { date: "2026-06-16", time: "00:00", group: "H", team1: "西班牙", team2: "佛得角", s1: 0, s2: 0 },
  { date: "2026-06-16", time: "03:00", group: "G", team1: "比利时", team2: "埃及", s1: 1, s2: 1 },
  { date: "2026-06-16", time: "06:00", group: "H", team1: "沙特阿拉伯", team2: "乌拉圭", s1: 1, s2: 1 },
  { date: "2026-06-16", time: "09:00", group: "G", team1: "伊朗", team2: "新西兰", s1: 2, s2: 2 },
  { date: "2026-06-17", time: "03:00", group: "I", team1: "法国", team2: "塞内加尔", s1: 3, s2: 1 },
  { date: "2026-06-17", time: "06:00", group: "I", team1: "伊拉克", team2: "挪威", s1: 1, s2: 4 },
  { date: "2026-06-17", time: "09:00", group: "J", team1: "阿根廷", team2: "阿尔及利亚", s1: 3, s2: 0 },
  { date: "2026-06-17", time: "12:00", group: "J", team1: "奥地利", team2: "约旦", s1: 3, s2: 1 },
  { date: "2026-06-18", time: "01:00", group: "K", team1: "葡萄牙", team2: "民主刚果", s1: 1, s2: 1 },
  { date: "2026-06-18", time: "04:00", group: "L", team1: "英格兰", team2: "克罗地亚", s1: 4, s2: 2 },
  { date: "2026-06-18", time: "07:00", group: "L", team1: "加纳", team2: "巴拿马", s1: 1, s2: 0 },
  { date: "2026-06-18", time: "10:00", group: "K", team1: "乌兹别克斯坦", team2: "哥伦比亚", s1: 1, s2: 3 },
  { date: "2026-06-19", time: "00:00", group: "A", team1: "捷克", team2: "南非", s1: 1, s2: 1 },
  { date: "2026-06-19", time: "03:00", group: "B", team1: "瑞士", team2: "波黑", s1: 4, s2: 1 },
  { date: "2026-06-19", time: "06:00", group: "B", team1: "加拿大", team2: "卡塔尔", s1: 6, s2: 0 },
  { date: "2026-06-19", time: "09:00", group: "A", team1: "墨西哥", team2: "韩国", s1: 1, s2: 0 },
  { date: "2026-06-20", time: "03:00", group: "D", team1: "美国", team2: "澳大利亚", s1: 2, s2: 0 },
  { date: "2026-06-20", time: "06:00", group: "C", team1: "苏格兰", team2: "摩洛哥", s1: 0, s2: 1 },
  { date: "2026-06-20", time: "08:30", group: "C", team1: "巴西", team2: "海地", s1: 3, s2: 0 },
  { date: "2026-06-20", time: "11:00", group: "D", team1: "土耳其", team2: "巴拉圭", s1: 0, s2: 1 }
];

function buildStandingsFromResults() {
  const computed = Object.fromEntries(
    Object.entries(groups).map(([group, teams]) => [
      group,
      teams.map((team, index) => emptyStanding(index + 1, team))
    ])
  );

  results.forEach(match => {
    const table = computed[match.group];
    const team1 = table.find(row => row.team === match.team1);
    const team2 = table.find(row => row.team === match.team2);
    if (!team1 || !team2) return;
    team1.played += 1;
    team2.played += 1;
    team1.gf += match.s1;
    team1.ga += match.s2;
    team2.gf += match.s2;
    team2.ga += match.s1;
    if (match.s1 > match.s2) {
      team1.wins += 1;
      team2.losses += 1;
      team1.points += 3;
    } else if (match.s1 < match.s2) {
      team2.wins += 1;
      team1.losses += 1;
      team2.points += 3;
    } else {
      team1.draws += 1;
      team2.draws += 1;
      team1.points += 1;
      team2.points += 1;
    }
  });

  Object.values(computed).forEach(table => {
    table.forEach(row => { row.gd = row.gf - row.ga; });
    table.sort((a, b) =>
      b.points - a.points || b.gd - a.gd || b.gf - a.gf || a.team.localeCompare(b.team, "zh-CN")
    );
    table.forEach((row, index) => { row.rank = index + 1; });
  });
  return computed;
}

standingsData = buildStandingsFromResults();

const nextMatches = [
  { date: "2026-06-21", time: "01:00", group: "F", venue: "休斯顿", match: "荷兰 vs 瑞典" },
  { date: "2026-06-21", time: "04:00", group: "E", venue: "多伦多", match: "德国 vs 科特迪瓦" },
  { date: "2026-06-21", time: "08:00", group: "E", venue: "堪萨斯城", match: "厄瓜多尔 vs 库拉索" },
  { date: "2026-06-21", time: "12:00", group: "F", venue: "蒙特雷", match: "突尼斯 vs 日本" }
];

const knockoutSlots = [
  { match: "M73", date: "6月29日 03:00", venue: "洛杉矶", pairing: "A2 vs B2" },
  { match: "M74", date: "6月30日 04:30", venue: "波士顿", pairing: "E1 vs A3/B3/C3/D3/F3" },
  { match: "M79", date: "7月01日 09:00", venue: "墨西哥城", pairing: "A1 vs C3/E3/F3/H3/I3" },
  { match: "M85", date: "7月03日 11:00", venue: "温哥华", pairing: "B1 vs E3/F3/G3/I3/J3" },
  { match: "M101", date: "7月15日 03:00", venue: "达拉斯", pairing: "M97 胜者 vs M98 胜者" },
  { match: "M104", date: "7月20日 03:00", venue: "纽约/新泽西", pairing: "两场半决赛胜者" }
];

const dataStatus = [
  {
    type: "schedule",
    item: "worldcup_2026_groups.csv",
    status: "已按用户图录入，待确认",
    need: "确认 A-L 组队名和槽位完全正确",
    approved: false
  },
  {
    type: "schedule",
    item: "worldcup_2026_schedule.csv",
    status: "已按用户图录入，待确认",
    need: "确认日期、时间、场地、对阵槽位；如需精确球场名，需要官方来源",
    approved: false
  },
  {
    type: "results",
    item: "worldcup_2026_results_asof_2026-06-20.csv",
    status: "已录入 32 场，待最终确认",
    need: "确认截至 2026-06-20 的 32 场完赛比分及来源无误",
    approved: false
  },
  {
    type: "results",
    item: "worldcup_2026_standings_asof_2026-06-15.csv",
    status: "已录入排名，待确认",
    need: "确认积分、进球、失球、净胜球和页面排序口径",
    approved: false
  },
  {
    type: "training",
    item: "historical_matches.csv",
    status: "字段校验通过，来源待确认",
    need: "确认数据来源、下载日期或快照日期，以及是否允许作为训练集",
    approved: false
  },
  {
    type: "training",
    item: "team_elo.csv",
    status: "未提供",
    need: "提供 Elo 快照，或确认允许从历史比赛结果推断简化 Elo",
    approved: false
  },
  {
    type: "mapping",
    item: "FIFA Annex C 完整映射",
    status: "未提供完整 495 种映射",
    need: "提供官方映射表，或确认当前只使用候选第三名槽位约束",
    approved: false
  }
];

const blockedOutputs = [
  "冠军概率 Top 10 和二项分布误差棒",
  "四强概率 Top 10",
  "各队晋级阶梯图/桑基图",
  "单队晋级漏斗图",
  "模型准确率、Brier Score、Log Loss",
  "任何写入报告结论的具体概率数值"
];

const confirmationNotes = [
  {
    title: "缺数据时先确认",
    body: "后续缺少赛程、比分、排名、Elo、历史训练集来源或 Annex C 时，必须先向你确认，不用假设值补齐。"
  },
  {
    title: "结果尚未完成核验",
    body: "output 目录里的概率和图表尚未完成数据核验，因此不纳入正式报告。"
  },
  {
    title: "R 主程序已加闸门",
    body: "data/data_approval.csv 没有 approved=true 时，正式模型会停止；--allow-unconfirmed-data 只用于检查代码。"
  },
  {
    title: "赛中数据单独处理",
    body: "截至 2026-06-20 的 32 场已赛结果只用于当前积分、滚动 Elo 和近 10 场状态，不回填到赛前训练数据。"
  },
  {
    title: "时间泄漏已修复",
    body: "历史 Elo 和状态特征按比赛日期逐场生成，只允许使用该场开赛前的信息。"
  },
  {
    title: "平局概率已校准",
    body: "使用 2025 年比赛拟合平局校准系数，并仅用 2026 年 6 月 10 日前比赛验证。"
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
    const rows = standingsData[group].map(row => {
      const current = routeDataset?.currentStatus?.find(item => item.team === row.team);
      const status = current?.top2_status || "待模型计算";
      const statusClass = status === "已锁定前二" ? "is-locked" : (status === "已无缘前二" ? "is-eliminated" : "");
      return `
      <tr>
        <td>${row.rank}</td>
        <td><strong>${row.team}</strong><small class="group-status ${statusClass}">${status}</small></td>
        <td class="num">${row.played}</td>
        <td class="num">${row.points}</td>
        <td class="num">${row.gd > 0 ? "+" : ""}${row.gd}</td>
        <td class="num">${row.gf}/${row.ga}</td>
      </tr>
    `;
    }).join("");
    return `
      <section class="group-card">
        <div class="group-title"><span>小组 ${group}</span><span>待确认</span></div>
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
      <td><strong>${match.s1}-${match.s2}</strong> <small>待确认</small></td>
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
  list.innerHTML = confirmationNotes.map(item => `
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

function renderDataStatusCards() {
  const container = document.getElementById("champion-chart");
  container.innerHTML = dataStatus.map(row => `
    <div class="impact-item">
      <strong>${row.item}</strong>
      <p>${row.status}。需要：${row.need}。</p>
    </div>
  `).join("");
}

function renderBlockedOutputs() {
  const container = document.getElementById("final-four-chart");
  container.innerHTML = blockedOutputs.map(item => `
    <div class="bar-row">
      <span>暂停</span>
      <div class="bar-track"><div class="bar-fill" style="width:100%;background:var(--amber)"></div></div>
      <strong>${item}</strong>
    </div>
  `).join("");
}

function renderPendingTable(filter = "all") {
  const body = document.getElementById("stage-body");
  const rows = filter === "all" ? dataStatus : dataStatus.filter(row => row.type === filter);
  body.innerHTML = rows.map(row => `
    <tr>
      <td>${row.item}</td>
      <td>${row.status}</td>
      <td>${row.need}</td>
      <td><strong>${row.approved ? "是" : "否"}</strong></td>
    </tr>
  `).join("");
}

function renderTeamFilter() {
  const select = document.getElementById("team-filter");
  select.innerHTML = `
    <option value="all">全部</option>
    <option value="schedule">分组赛程</option>
    <option value="results">已赛结果</option>
    <option value="training">训练与强度</option>
    <option value="mapping">赛制映射</option>
  `;
  select.addEventListener("change", () => renderPendingTable(select.value));
}

function renderModelMetrics() {
  const container = document.getElementById("model-metrics");
  const metrics = [
    { label: "正式模型", value: "暂停" },
    { label: "确认文件", value: "data/data_approval.csv" },
    { label: "主程序保护", value: "已启用" },
    { label: "验证参数", value: "--allow-unconfirmed-data" }
  ];
  container.innerHTML = metrics.map(m => `
    <div class="metric-row">
      <span>${m.label}</span>
      <strong>${m.value}</strong>
    </div>
  `).join("");
}

function renderCoefChart() {
  const container = document.getElementById("coef-chart");
  const items = [
    "确认历史训练集来源和快照日期",
    "确认是否使用外部 Elo 或简化 Elo",
    "确认分组、赛程、场地和槽位",
    "确认截至 2026-06-20 的 32 场已结束比分与排名",
    "补齐或确认 Annex C 第三名映射口径"
  ];
  container.innerHTML = items.map(item => `
    <div class="bar-row">
      <span>待办</span>
      <div class="bar-track"><div class="bar-fill" style="width:100%;background:var(--blue)"></div></div>
      <strong>${item}</strong>
    </div>
  `).join("");
}

function updateMetrics() {
  const approved = dataStatus.filter(row => row.approved).length;
  document.getElementById("metric-approval").textContent = `${approved} / ${dataStatus.length}`;
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

function parseCSV(text) {
  const rows = [];
  let row = [];
  let cell = "";
  let quoted = false;
  const source = text.replace(/^\uFEFF/, "");
  for (let i = 0; i < source.length; i += 1) {
    const char = source[i];
    if (quoted) {
      if (char === '"' && source[i + 1] === '"') {
        cell += '"';
        i += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        cell += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ",") {
      row.push(cell);
      cell = "";
    } else if (char === "\n") {
      row.push(cell.replace(/\r$/, ""));
      if (row.some(value => value !== "")) rows.push(row);
      row = [];
      cell = "";
    } else {
      cell += char;
    }
  }
  if (cell !== "" || row.length) {
    row.push(cell.replace(/\r$/, ""));
    rows.push(row);
  }
  if (rows.length < 2) return [];
  const headers = rows[0];
  return rows.slice(1).map(values => Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ""])));
}

function escapeHTML(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

async function fetchCSV(name) {
  const response = await fetch(`./data/${name}`, { cache: "no-store" });
  if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
  return parseCSV(await response.text());
}

const routeStageKeys = ["round_of_32", "round_of_16", "quarter_final", "semi_final", "final"];
const routeStageLabels = ["32强", "16强", "8强", "四强", "决赛"];
const featuredRouteTeams = ["西班牙", "法国", "阿根廷", "巴西", "葡萄牙"];
let routeDataset = null;
let overallRouteView = "groups";
let routeState = { team: "西班牙", stageIndex: 0, prefix: "ROOT", history: [] };

function pct(value, digits = 1) {
  const number = Number(value || 0);
  return `${(number * 100).toFixed(digits)}%`;
}

function groupBy(rows, field) {
  return rows.reduce((groups, row) => {
    const key = row[field];
    if (!groups[key]) groups[key] = [];
    groups[key].push(row);
    return groups;
  }, {});
}

function renderOverallGroups() {
  const canvas = document.getElementById("overall-route-canvas");
  const grouped = groupBy(routeDataset.groupPositions, "group");
  canvas.innerHTML = `<div class="route-group-grid">${"ABCDEFGHIJKL".split("").map(group => {
    const rows = (grouped[group] || []).sort((a, b) => Number(b.qualified) - Number(a.qualified));
    return `<section class="route-group">
      <h3>GROUP ${group}</h3>
      ${rows.map(row => {
        const current = routeDataset.currentStatus.find(item => item.team === row.team) || {};
        const statusClass = current.top2_status === "已锁定前二" ? "is-locked" : (current.top2_status === "已无缘前二" ? "is-eliminated" : "");
        return `<div class="route-group-row">
        <div class="route-team-summary"><strong>${escapeHTML(row.team)}</strong><small class="group-status ${statusClass}">当前 ${current.points ?? "-"} 分 · ${escapeHTML(current.top2_status || "待计算")}</small></div>
        <span title="小组第一概率">1 ${pct(row.first, 0)}</span>
        <span title="小组第二概率">2 ${pct(row.second, 0)}</span>
        <span title="小组第三概率">3 ${pct(row.third, 0)}</span>
        <span title="晋级32强概率">出 ${pct(row.qualified, 0)}</span>
      </div>`}).join("")}
    </section>`;
  }).join("")}</div>`;
}

function bracketSideSummary(matchId, side) {
  const rows = routeDataset.bracketSlots
    .filter(row => row.match_id === matchId && row.side === side)
    .sort((a, b) => Number(b.slot_probability) - Number(a.slot_probability));
  const top = rows.slice(0, 2);
  const topProbability = top.reduce((sum, row) => sum + Number(row.slot_probability), 0);
  const labels = top.map(row => `${escapeHTML(row.team)} ${pct(row.slot_probability, 0)}`);
  if (1 - topProbability > 0.005) labels.push(`其他 ${pct(1 - topProbability, 0)}`);
  return labels.join(" / ") || "待定";
}

function renderOverallBracket() {
  const canvas = document.getElementById("overall-route-canvas");
  const stages = [
    ["round_of_32", "32强"],
    ["round_of_16", "16强"],
    ["quarter_final", "8强"],
    ["semi_final", "半决赛"],
    ["final", "决赛"]
  ];
  canvas.innerHTML = `<div class="bracket-grid">${stages.map(([stage, label]) => {
    const matches = routeDataset.schedule
      .filter(row => row.stage.toLowerCase() === stage)
      .sort((a, b) => a.match_date.localeCompare(b.match_date) || a.match_id.localeCompare(b.match_id));
    return `<section class="bracket-stage">
      <h3>${label}</h3>
      ${matches.map(match => `<div class="bracket-match">
        <strong>${escapeHTML(match.match_id)}</strong>
        <div class="bracket-side">${bracketSideSummary(match.match_id, "team_1")}</div>
        <div class="bracket-side">${bracketSideSummary(match.match_id, "team_2")}</div>
      </div>`).join("")}
    </section>`;
  }).join("")}</div>`;
}

function renderOverallRoute() {
  if (!routeDataset) return;
  if (overallRouteView === "groups") renderOverallGroups();
  else renderOverallBracket();
}

function aggregateOpponentRows(rows) {
  const byOpponent = new Map();
  rows.forEach(row => {
    const current = byOpponent.get(row.opponent) || {
      opponent: row.opponent,
      encounterCount: 0,
      advanceCount: 0,
      contextCount: Number(row.context_count),
      nodeId: row.node_id
    };
    current.encounterCount += Number(row.encounter_count);
    current.advanceCount += Number(row.advance_count);
    current.nodeId = row.node_id;
    byOpponent.set(row.opponent, current);
  });
  return [...byOpponent.values()]
    .map(row => ({
      ...row,
      opponentProbability: row.encounterCount / Math.max(row.contextCount, 1),
      advanceProbability: row.advanceCount / Math.max(row.encounterCount, 1),
      contribution: row.advanceCount / routeDataset.simulations,
      lowSample: row.encounterCount < 30
    }))
    .sort((a, b) => b.opponentProbability - a.opponentProbability);
}

function summarizeOther(rows) {
  const encounterCount = rows.reduce((sum, row) => sum + row.encounterCount, 0);
  const advanceCount = rows.reduce((sum, row) => sum + row.advanceCount, 0);
  return {
    opponent: "其他",
    encounterCount,
    advanceCount,
    opponentProbability: rows.reduce((sum, row) => sum + row.opponentProbability, 0),
    advanceProbability: advanceCount / Math.max(encounterCount, 1),
    contribution: advanceCount / routeDataset.simulations,
    lowSample: encounterCount < 30,
    nodeId: ""
  };
}

function renderRouteProgress() {
  const row = routeDataset.teamStages.find(item => item.team === routeState.team) || {};
  const labels = ["当前小组", ...routeStageLabels, "冠军"];
  const values = [row.round_of_32, row.round_of_32, row.round_of_16, row.quarter_final, row.semi_final, row.final, row.champion];
  document.getElementById("route-progress").innerHTML = labels.map((label, index) => `
    <div class="route-stage-pill ${index === routeState.stageIndex + 1 ? "is-current" : ""}">
      <strong>${label}</strong><span>${pct(values[index])}</span>
    </div>
  `).join("");
}

function renderTeamRoute() {
  if (!routeDataset) return;
  renderRouteProgress();
  const canvas = document.getElementById("team-route-canvas");
  const back = document.getElementById("route-back");
  back.disabled = routeState.history.length === 0;
  document.getElementById("route-breadcrumb").textContent = routeState.history.length
    ? `当前路径：${routeState.team} → ${routeState.history.map(item => item.opponent).join(" → ")}`
    : `当前路径：${routeState.team}，从32强潜在对手开始`;

  if (routeState.stageIndex >= routeStageKeys.length) {
    const stageRow = routeDataset.teamStages.find(row => row.team === routeState.team);
    canvas.innerHTML = `<div class="route-opponent" style="grid-column:1/-1;cursor:default">
      <strong>${escapeHTML(routeState.team)}的冠军节点</strong>
      <div class="route-opponent-stats"><span>夺冠概率 ${pct(stageRow?.champion)}</span><span>所选路径已走完</span><span>模拟 ${routeDataset.simulations.toLocaleString()} 次</span></div>
    </div>`;
    return;
  }

  const stage = routeStageKeys[routeState.stageIndex];
  const exactRows = routeDataset.routeNodes.filter(row =>
    row.team === routeState.team && row.stage === stage && row.parent_prefix === routeState.prefix
  );
  let opponents = aggregateOpponentRows(exactRows);
  if (opponents.length > 5) opponents = [...opponents.slice(0, 5), summarizeOther(opponents.slice(5))];
  if (!opponents.length) {
    canvas.innerHTML = `<div class="route-opponent" style="grid-column:1/-1;cursor:default">
      <strong>该条件路径没有后续样本</strong><small>可能是球队已被淘汰，或该分支在本次模拟中未晋级。</small>
    </div>`;
    return;
  }
  canvas.innerHTML = opponents.map((row, index) => {
    const canDrill = row.opponent !== "其他" && row.advanceCount > 0;
    return `<button type="button" class="route-opponent ${row.lowSample ? "is-low-sample" : ""}"
      data-route-index="${index}" ${canDrill ? "" : "disabled"}>
      <strong>${escapeHTML(row.opponent)}</strong>
      <div class="route-opponent-stats">
        <span>遇到 ${pct(row.opponentProbability)}</span>
        <span>晋级 ${pct(row.advanceProbability)}</span>
        <span>贡献 ${pct(row.contribution)}</span>
      </div>
      <small>${row.lowSample ? `仅 ${row.encounterCount} 次样本，稳定性不足` : `${row.encounterCount} 次对阵样本`}${canDrill ? "；点击查看下一轮" : ""}</small>
    </button>`;
  }).join("");
  canvas.querySelectorAll("[data-route-index]").forEach(button => {
    button.addEventListener("click", () => {
      const row = opponents[Number(button.dataset.routeIndex)];
      routeState.history.push({ stageIndex: routeState.stageIndex, prefix: routeState.prefix, opponent: row.opponent });
      routeState.prefix = row.nodeId;
      routeState.stageIndex += 1;
      renderTeamRoute();
    });
  });
}

function wireRouteControls() {
  document.querySelectorAll("[data-overall-view]").forEach(button => {
    button.addEventListener("click", () => {
      overallRouteView = button.dataset.overallView;
      document.querySelectorAll("[data-overall-view]").forEach(item => item.classList.toggle("is-active", item === button));
      renderOverallRoute();
    });
  });
  document.getElementById("route-zoom").addEventListener("input", event => {
    document.getElementById("overall-route-canvas").style.zoom = `${event.target.value}%`;
  });
  document.getElementById("route-team").addEventListener("change", event => {
    routeState = { team: event.target.value, stageIndex: 0, prefix: "ROOT", history: [] };
    renderTeamRoute();
  });
  document.getElementById("route-back").addEventListener("click", () => {
    const previous = routeState.history.pop();
    if (!previous) return;
    routeState.stageIndex = previous.stageIndex;
    routeState.prefix = previous.prefix;
    renderTeamRoute();
  });
}

async function loadRouteDashboard() {
  const state = document.getElementById("route-data-state");
  try {
    const [routeNodes, bracketSlots, groupPositions, teamStages, currentStatus, metadata, schedule] = await Promise.all([
      fetchCSV("team_route_nodes.csv"),
      fetchCSV("bracket_slot_probabilities.csv"),
      fetchCSV("group_position_probabilities.csv"),
      fetchCSV("team_stage_probabilities.csv"),
      fetchCSV("current_group_status.csv"),
      fetchCSV("run_metadata.csv"),
      fetchCSV("worldcup_2026_schedule.csv")
    ]);
    const meta = Object.fromEntries(metadata.map(row => [row.key, row.value]));
    routeDataset = {
      routeNodes,
      bracketSlots,
      groupPositions,
      teamStages,
      currentStatus,
      schedule,
      simulations: Number(meta.simulations || 0),
      formal: String(meta.formal_data_approved).toLowerCase() === "true",
      annexMode: meta.annex_c_mode || "unknown"
    };
    state.classList.toggle("is-formal", routeDataset.formal);
    state.textContent = routeDataset.formal
      ? `正式预测：${routeDataset.simulations.toLocaleString()} 次模拟，Annex C 官方映射已确认。`
      : `未确认预览：${routeDataset.simulations.toLocaleString()} 次模拟；当前使用 ${routeDataset.annexMode}，不得作为正式结论。`;
    renderOverallRoute();
    renderTeamRoute();
    renderStandings(document.getElementById("group-filter").value || "all");
  } catch (error) {
    state.textContent = `路线数据暂不可用：${error.message}`;
    document.getElementById("overall-route-canvas").innerHTML = "<p>请先运行 R/worldcup_predictor.R 和 R/make_charts.R。</p>";
    document.getElementById("team-route-canvas").innerHTML = "<p>等待经过确认的路线输出。</p>";
  }
}

function renderMethodRows(targetId, rows) {
  const target = document.getElementById(targetId);
  target.innerHTML = rows.map(([label, value]) => `
    <div class="method-stat-row"><span>${escapeHTML(label)}</span><strong>${escapeHTML(value)}</strong></div>
  `).join("");
}

async function loadMethodValidation() {
  try {
    const [audit, fit, comparison, rolling, logistic, metadata] = await Promise.all([
      fetchCSV("data_quality_audit.csv"),
      fetchCSV("poisson_fit_statistics.csv"),
      fetchCSV("poisson_model_comparison.csv"),
      fetchCSV("rolling_origin_validation.csv"),
      fetchCSV("logistic_metrics.csv"),
      fetchCSV("run_metadata.csv")
    ]);
    const auditByItem = Object.fromEntries(audit.map(row => [row.item, row]));
    const meta = Object.fromEntries(metadata.map(row => [row.key, row.value]));
    const logisticByMetric = Object.fromEntries(logistic.map(row => [row.metric, Number(row.value)]));
    const rollingMean = Object.fromEntries(comparison.map(row => {
      const modelRows = rolling.filter(item => item.model === row.model);
      const mean = modelRows.reduce((sum, item) => sum + Number(item.log_loss), 0) / modelRows.length;
      return [row.model, mean];
    }));
    const selected = meta.selected_poisson_model || "full";
    const selectedFit = fit.map(row => Number(row.pearson_dispersion));
    renderMethodRows("method-data-audit", [
      ["原始记录", Number(auditByItem.raw_rows?.value || 0).toLocaleString()],
      ["无效日期 / 比分", `${auditByItem.invalid_dates?.value || 0} / ${auditByItem.invalid_scores?.value || 0}`],
      ["重复比赛键", auditByItem.duplicate_match_keys?.value || "0"],
      ["总进球≥10", `${auditByItem.high_score_matches_total_ge_10?.value || 0}（仅标记）`]
    ]);
    renderMethodRows("method-poisson-fit", [
      ["选中规格", selected],
      ["先列队离散度", selectedFit[0]?.toFixed(3) || "-"],
      ["后列队离散度", selectedFit[1]?.toFixed(3) || "-"],
      ["诊断口径", "Deviance / Pearson / Cook"]
    ]);
    renderMethodRows("method-model-selection", [
      ["方法", "Rolling-origin"],
      ["验证窗口", "3 个"],
      ["选中模型均值", rollingMean[selected]?.toFixed(4) || "-"],
      ["随机 K 折", "未使用"]
    ]);
    renderMethodRows("method-logistic", [
      ["任务", "第一列球队胜 / 非胜"],
      ["准确率", `${(logisticByMetric.accuracy * 100).toFixed(1)}%`],
      ["ROC AUC", logisticByMetric.auc.toFixed(3)],
      ["进入赛事模拟", "否"]
    ]);
  } catch (error) {
    document.getElementById("method-validation").innerHTML = `<p>课程方法诊断暂不可用：${escapeHTML(error.message)}</p>`;
  }
}

function downloadPDF() {
  const btn = document.getElementById("btn-pdf");
  btn.textContent = "生成中...";
  btn.disabled = true;
  const el = document.querySelector("main");
  const opt = {
    margin: [10, 10, 10, 10],
    filename: "2026世界杯预测项目数据确认版.pdf",
    image: { type: "jpeg", quality: 0.95 },
    html2canvas: { scale: 2, useCORS: true, scrollY: 0 },
    jsPDF: { unit: "mm", format: "a3", orientation: "portrait" },
    pagebreak: { mode: ["avoid-all", "css", "legacy"] }
  };
  html2pdf().set(opt).from(el).save().then(() => {
    btn.textContent = "下载 PDF";
    btn.disabled = false;
  }).catch(() => {
    btn.textContent = "下载 PDF";
    btn.disabled = false;
    alert("PDF 生成失败，请重试");
  });
}

renderGroupFilter();
renderStandings();
renderResults();
renderNextMatches();
renderKnockoutSlots();
renderImpactList();
renderGoalBars();
renderDataStatusCards();
renderBlockedOutputs();
renderTeamFilter();
renderPendingTable();
renderModelMetrics();
renderCoefChart();
updateMetrics();
wireNav();
wireRouteControls();
loadRouteDashboard();
loadMethodValidation();

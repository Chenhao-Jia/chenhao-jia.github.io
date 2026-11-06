# 第一版实际验证记录

验证日期：2026-11-07（Asia/Shanghai）。交付状态：**用户已明确授权公开发布；预览与生产构建、检查及测试通过；源码已推送，GitHub Actions Pages 部署成功，线上页面及核心资源已验证 HTTP 200。**

## 材料与实现

- 完整阅读任务书，检查了目录与祖先目录的项目规则；未发现适用的 `AGENTS.md`。初始资料包不是 Git 仓库，没有可继承的网站或远程配置。
- 正式信息来自用户指定目录中的 DOCX、论文 XLSX、照片及后来补充的 `PROFILE_INPUT.yml`。`PROFILE_INPUT.example.yml` 只用于字段参考；学校、学院和导师来自本人补充的输入表，GitHub 账号 `Chenhao-Jia` 来自聊天中的明确确认。
- 原 DOCX 仅补全两个中英文简介内容控件，其他 OOXML 内容与备份对照一致。原件备份在上级 `.local/backups/`，根目录已生成 `PROFILE_INPUT.yml`，不会被网站读取或公开。
- Minimal Light 官方源码下载至临时目录，取得提交 `dd114c3fef2d97adc1c6b6d46901e0d96ab83a7c`。本地改造布局及浅色样式，清除演示身份、照片、论文、域名、Analytics、外部字体和图标脚本。源码来源及许可见 `THIRD_PARTY_NOTICES.md`。
- 主页实际显示头像、姓名、博士生身份、Shandong University、School of Cyber Science and Technology、导师 Meiqin Wang、About、Research Interests、五篇论文、Scholar 和 GitHub。论文按年倒序，同年按 YAML 顺序；本人署名由显式 `self: true` 加粗。Paper、DOI、本地 BibTeX 有依据才显示。没有 Code、Slides、CV 或完整教育资料时不生成入口或空栏目。
- 网站在独立的 `academic-site/`，本地分支为 `main`。用户已明确授权公开发布；已通过认证 GitHub API 创建公开仓库 `Chenhao-Jia/chenhao-jia.github.io`（HTTP 201），远程默认分支为 `main`，创建时为空，没有覆盖既有内容。源码已正常推送，部署及线上证据见末节。

## 实际运行环境

| 组件 | 实际版本 / 状态 |
| --- | --- |
| 操作系统 | Windows，PowerShell |
| Ruby | 3.3.13，官方 RubyInstaller 便携包，SHA256 与官方下载页一致 |
| Bundler | 2.5.22 |
| Jekyll | 4.4.1 |
| Nokogiri | 1.19.7 |
| Sass embedded | 1.108.0 |
| 时区依赖 | tzinfo 2.0.6 / tzinfo-data 1.2026.6 |
| 依赖安装 | `bundle install` 成功，40 gems；`bundle check` 成功 |
| 锁文件 | 本次真实解析生成，包含 Windows 与 x86_64-linux 平台 |

没有安装系统级 Ruby，也没有永久修改 PATH。首次在中文路径下编译原生依赖失败；改用任务专用英文临时路径的 Ruby/gems，并利用已有 MSYS2 编译器及项目内 make 后成功。Ruby 脚本使用站点工作目录，避开 Windows `__dir__` 编码问题。首次构建还发现缺少 Windows 时区依赖和 Liquid include 参数语法问题，均已修复并重新构建成功。

来源、失败尝试和安装日志保存在上级 `.local/runtime-notes.md`、`.local/bundle-install-*.log`，均不在网站源码或产物中。若临时运行时被清理，应按 README 重建环境，不能保证缓存永久存在。

## 构建、内容与产物检查

以下命令在实际准备好的 Ruby 环境、站点目录执行：

```powershell
bundle check
bundle exec ruby scripts/generate_bibtex.rb --check
bundle exec ruby scripts/validate_content.rb --mode preview
bundle exec jekyll build --config _config.yml,_config.preview.yml --trace
bundle exec ruby scripts/check_site.rb _site
bundle exec ruby scripts/test_site.rb
```

- 预览内容验证：通过，五篇论文的必填字段、唯一 ID、年份、完整作者字段、状态、URL、本地附件和 YAML 结构均符合检查规则。非公开邮箱没有写入网站数据。
- BibTeX 同步检查：通过，五份引用从论文 YAML 的题名、作者、年份、期刊、DOI 和卷期页码生成。回归测试还验证改动题名时 `--check` 会拒绝过期引用，且不修改文件；重新生成后通过。
- 真实 Jekyll 预览构建：通过。构建生成首页、404、本站 CSS/图标/头像、五份 BibTeX、robots 和 sitemap。Sass 使用 `@use`，关闭不必要的 source map。
- 产物检查：通过。检查站内路径、编码文件名、fragment、CSS/图片/附件、重复 HTML ID、空链接、核心远程资源、演示残留，以及源码/资料文件隔离。预览覆盖配置仍有 `noindex`；正式 production 产物已无预览提示和 noindex，canonical 为 `https://chenhao-jia.github.io/`，sitemap 与 robots 地址一致。
- 授权后的正式发布检查：实际运行 `bundle exec ruby scripts/validate_content.rb --mode production`、`JEKYLL_ENV=production` 下的 `bundle exec jekyll build --config _config.yml --trace` 和 `bundle exec ruby scripts/check_site.rb _site`，全部通过。两项内容确认布尔值均为 `true`，BibTeX 同步及全部 7 组回归测试通过。
- 源码公开范围：检查 Git 候选文件，未发现原始 DOCX/XLSX/压缩包、学号、私人邮箱、凭据模式或工具缓存。照片没有 EXIF/GPS 信息。`exclude` 和 `.gitignore` 分别管理网页产物与未跟踪源码，不能替代公开前人工审核。
- 工作流 YAML 解析及权限/条件检查：通过；当前官方 Actions 版本已核对。远程运行 [42270666738](https://github.com/Chenhao-Jia/chenhao-jia.github.io/actions/runs/42270666738) 的检查、生产构建和部署三个作业均成功，Linux CI 与 Pages 部署已实际验证。

## 临时夹具回归

`scripts/test_site.rb` 实际执行三次临时 Jekyll 构建；所有合成资料只存在于自动清理的系统临时目录，正式 `_data/` 与 `_site/` 未被测试改写。

- 空论文及空可选栏目：栏目与导航一起隐藏，无虚构论文、CV 或空按钮。
- 三篇论文、跨年和同年顺序、长题目、15 位作者、HTML 特殊字符和脚本文本：排序稳定，文本正确转义，只加粗显式本人字段。
- 缺少可选资源、带空格编码的本地附件、有效锚点、项目式测试 `baseurl`：通过，路径只加一次前缀。
- 故意破坏文件、锚点、ID、年份或题目：检查脚本以非零退出并指出问题。
- 未确认资料的生产门禁回归：测试夹具将 `content_confirmed` 与 `ready_for_publication` 设为 `false` 时，生产检查按预期拒绝。这表示门禁有效；当前已授权的正式数据两项均为 `true`，已单独通过真实生产验证。
- 仅将 `ready_for_publication` 改成 `true` 仍不能绕过姓名、简介、内容确认及地址要求。
- 独立合成生产夹具：实际使用 `JEKYLL_ENV=production` 和单独 `_config.yml` 构建成功；canonical、sitemap、robots 地址一致，且没有预览提示或 noindex。合成数据始终只在临时目录；本人内容的发布授权和正式构建另行记录。

## 浏览器与文档显示

实际启动：

```powershell
# 从上级资料包目录启动；与 README 相同命令，已实测。
powershell -File .\academic-site\scripts\preview.ps1
```

服务 `http://127.0.0.1:4000/` 返回 HTTP 200；监听回环地址，使用 `--no-watch`，修改内容后需要重启。验证结束后停止本次服务；用户可用以上命令再次启动。

| 浏览器宽度 | 实测结果 |
| --- | --- |
| 375 px | 单列，长题目/作者/按钮正常换行；无横向滚动 |
| 768 px | 单列，资料区和正文清晰；无横向滚动 |
| 1440 px | 左侧资料栏、右侧学术正文；正文宽度受限，无横向滚动 |

实际 DOM 测得 document scrollWidth 分别为 360、753、1425 px（与对应视口相差原生竖向滚动条宽度）。截图及目视检查一致。页内 Publications 导航可跳转；Tab 焦点可见，Skip to content 回车后焦点进入 main；404 页面可返回首页。头像正常加载，样式来自本站，控制台未观察到 warning/error。

页面没有 JavaScript 或外部字体依赖，实际 DOM 的 script 数为 0，简介、论文及链接均已在 HTML 中。浏览器工具没有提供关闭 JavaScript 的开关，因此**未另行执行浏览器禁用 JavaScript 模式**；静态产物及零脚本检查已完成。

代表性截图保存在上级目录（不进入公开源码或网页）：

- `.local/screenshots/desktop-1440.jpg`
- `.local/screenshots/tablet-768.jpg`
- `.local/screenshots/mobile-375.jpg`

DOCX 的标准渲染脚本已尝试，但因未安装 LibreOffice 失败；使用已安装 Microsoft Word 导出 PDF，再以 bundled pypdfium2 渲染。全部一页已目视检查，无裁切、重叠或意外新增页；截图在上级 `.local/docx-render-word/page-1.png`。

## 论文元数据与外链

五条 DOI 来自用户论文表，完整题名、作者顺序、期刊、年份经出版商登记的 Crossref 元数据核对；没有从同名搜索结果推断身份，没有推断共同一作或获奖。题名拼写、缺词和末尾多余字符的差异见 `CONTENT_TODO.md`。

12 个外链采用有时限、跟随重定向的 HTTP GET 检查（不下载响应正文）：6 个返回 200（含本人确认的 GitHub 账号入口），5 个连接超时而无法确认，Scholar 返回 429 限流；没有观察到 404。DBST 的 Paper 地址重定向至出版商 HTML 页面，不能据此声称 PDF 下载成功。部分全文地址来自出版商元数据，无法保证任何网络环境下都可访问。

详细逐项记录在上级 `.local/external-link-check.json`；DOI 元数据证据在上级 `.local/evidence.json` 及 Crossref 缓存。外链受阻保留为“未确认”，没有伪装成全部可达或全部失效。

## 首次部署与线上证据

**已上线：[https://chenhao-jia.github.io/](https://chenhao-jia.github.io/)。** 本人明确授权后，将审查过的站点源码正常推送至 [Chenhao-Jia/chenhao-jia.github.io](https://github.com/Chenhao-Jia/chenhao-jia.github.io) 的 `main`。没有强制推送或覆盖已有仓库；原始资料、私人输入表、备份和运行时继续留在公开仓库之外。

| 项目 | 实际结果 |
| --- | --- |
| 网站代码提交 | `9e1f9394f352d2d96d9c34d9248461a8d3f22280` |
| 自定义工作流 | [42270666738](https://github.com/Chenhao-Jia/chenhao-jia.github.io/actions/runs/42270666738)，结论 success |
| 三个作业 | check、生产 artifact 构建、deploy 全部 success |
| Pages artifact | ID `13528578903`，名称 `github-pages`，仅包含 `_site/` |
| 部署记录 | ID `7607721833`，环境 `github-pages`，最新状态 success |
| Pages 设置 | 发布来源为 workflow；`PAGES_DEPLOY_ENABLED=true`；HTTPS 已启用 |
| 首页 | HTTP 200，正确姓名及 Shandong University，五篇论文，无预览提示或 noindex |
| 核心资源 | CSS、头像、第一篇本地 BibTeX、robots、sitemap、404.html 均返回 HTTP 200 |

线上浏览器复核也已完成：实际打开 HTTPS 域名，canonical 正确、五篇论文和头像正常加载，没有预览提示；1440 px 视口的 scrollWidth 为 1425 px，375 px 视口为 360 px（正文宽 316 px），均无横向溢出。手机端 Publications 锚点跳转正常，控制台未观察到 warning/error。线上代表性截图存放在公开仓库之外：

- `.local/screenshots/published-desktop-1440.jpg`
- `.local/screenshots/published-mobile-375.jpg`

首次推送曾产生 GitHub 的旧式默认 Pages 运行 `42270503196`，为保留唯一自定义发布流程已取消；随后自定义推送运行 `42270510590` 的检查通过，当时部署开关未设置，因此未发布。开启获准开关后的完整自定义工作流 `42270666738` 成功部署。Pages 顶层元数据仍残留已取消旧运行的 `errored`，当前真实部署记录为 success，网站和核心资源均为 HTTP 200；不为消除旧状态而改回分支发布。

工作流在部署开关未设置时仍仅检查；PR 只读且不发布。默认分支 push/manual 必须通过前置检查和生产内容验证才发布，只上传 `_site/`。Pages 元数据调用位于获准流程，部署作业单独具有 `pages: write` / `id-token: write` 与 `github-pages` 环境。

本节部署 SHA 指网站产物对应的代码提交。README、部署说明、待办和验证报告均从网页产物中排除；后续纯文档提交可能使仓库 HEAD 与已部署代码 SHA 不同，不改变当前网站产物。

当前没有阻止上线的待补事项。CV、导师网址、代码或 Slides 等可选资料可按真实提供情况继续补充；外链网络受限、浏览器禁用 JavaScript 模式未单独验证等限制仍如上所述，维护与回退方法见 `DEPLOYMENT.md`。

## 英文简介更新 2026-11-07

- 按本人更新的中文简介，将 Word 对应英文补入山东大学及学院信息；仅修改英文内容控件，中文原文与其他内容保持不变，原件另作本地备份。
- Word 全部一页经原生 Word 导出及 PNG 目视检查通过，没有裁切、重叠或多余页面。标准渲染器仍受缺少 LibreOffice 限制。
- 网站英文与 Word 英文逐字核对一致。根据本人最新要求，网站仅显示英文简介；中文简介正文、展开入口及相关样式已删除，公开数据中的 `bio_zh` 为空。
- 生产内容验证、Jekyll 构建及站内检查通过；GitHub Actions 对最终网站版本完成全部检查、生产构建和部署，运行 [42272660407](https://github.com/Chenhao-Jia/chenhao-jia.github.io/actions/runs/42272660407) 结论为 success，代码提交为 `d89886720e6a390f65637cd90be983108d26b08e`。
- 公开首页返回 HTTP 200；实际浏览器确认新英文已显示，中文简介和入口不存在，头像加载正常，桌面无横向溢出，控制台未观察到 warning/error。
- 最新网站截图位于公开仓库之外的 `.local/screenshots/updated-english-bio.jpg`。私人 Word、备份与排版检查图未上传。

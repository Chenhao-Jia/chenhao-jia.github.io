# 个人学术主页维护说明

这是基于 Minimal Light 源码改造的 Jekyll 单页学术主页，以英文展示简介、研究方向和论文。内容通过 YAML 维护，不需要修改 HTML。本人已授权公开发布，生产检查及全部测试通过，网站已上线：[chenhao-jia.github.io](https://chenhao-jia.github.io/)。实际构建、浏览器检查和环境限制以 [VALIDATION_REPORT.md](VALIDATION_REPORT.md) 为准。

## 本机预览

网站工程是本目录 `academic-site/`，不是上一级资料包。使用 Ruby **3.3.13**、Bundler **2.5.22** 和仓库内的 `Gemfile.lock`。依赖来自 RubyGems；不要删除锁文件后随意升级全部依赖。

本次已配置的 Windows 工作环境，在上级资料包目录运行即可启动：

```powershell
powershell -File .\academic-site\scripts\preview.ps1
```

启动脚本会使用上级 `.local/use-ruby.ps1` 加载本机任务专用 Ruby，只修改当前进程 PATH，不安装系统软件。打开 [本地主页](http://127.0.0.1:4000/)，停止服务按 `Ctrl+C`。本机 `.bundle/config` 已指向可用的 ASCII 临时依赖目录，**不要重新设置为中文路径下的 `vendor/bundle`**。若临时运行时被清理，查看上级 `.local/runtime-notes.md`；照片、内容和源码均不依赖该缓存保存。

将来单独克隆本目录时，需要自行准备相同 Ruby/Bundler。Windows 建议放在英文路径，并安装 RubyInstaller 官方 Devkit；参考 [RubyInstaller](https://rubyinstaller.org/) 和 [Jekyll Windows 文档](https://jekyllrb.com/docs/installation/windows/)。新环境安装一次依赖：

```powershell
bundle config set --local path vendor/bundle
bundle _2.5.22_ install
```

在当前机器手动执行检查时，先于上级资料包目录运行 `. .\.local\use-ruby.ps1`，再 `Set-Location .\academic-site`。在网站目录执行：

```powershell
bundle exec ruby scripts/generate_bibtex.rb --check
bundle exec ruby scripts/validate_content.rb --mode preview
bundle exec jekyll build --config _config.yml,_config.preview.yml --trace
bundle exec ruby scripts/check_site.rb _site
bundle exec jekyll serve --config _config.yml,_config.preview.yml --host 127.0.0.1 --port 4000 --no-watch
```

如果新环境尚未安装指定 Bundler，可在自己选择的 Ruby 环境中执行 `gem install bundler -v 2.5.22 --no-document`。安装失败时保留错误信息，不要跳过校验或删除依赖约束来掩盖失败。

本次验证使用 `--no-watch`：修改 YAML、Markdown、布局、CSS 或配置后，按 `Ctrl+C` 停止服务，重新运行预览脚本并刷新浏览器。修改 `Gemfile` 后还需重新安装依赖。预览覆盖配置只用于本地，带 `noindex`，不代表内容可以公开。

## 修改哪个文件

| 文件 | 日常用途 |
| --- | --- |
| `_data/profile.yml` | 姓名、身份、单位、简介、研究方向、头像、公开联系入口及内容确认状态 |
| `_data/publications.yml` | 所有论文及 Paper / Code / Slides / BibTeX / DOI 资源 |
| `_data/projects.yml` | 可公开的科研项目或工具 |
| `_data/news.yml` | 新闻，日期使用带引号的 `YYYY-MM-DD` |
| `_data/education.yml` | 经确认的教育经历 |
| `_config.yml` | GitHub 用户名、站点地址和发布就绪状态 |
| `assets/img/`、`assets/files/` | 已获准公开的照片和附件 |
| `index.md`、`_includes/`、`_layouts/`、`_sass/` | 页面组合、布局和样式，通常不必改 |

上级 `PROFILE_INPUT.yml` 只是首次导入表，**后续以本目录 `_data/*.yml` 为唯一内容维护入口**，不用同步改输入表和首页。正式资料文件夹内的 `01_在读学生信息采集表.docx` 已补全中英文简介；原件备份在上级 `.local/backups/`。原始 DOCX、XLSX、压缩包和输入表都留在网站源码目录之外。

网站仅展示 `bio_en` 英文简介，不展示中文简介。网站不会直接读取私人 Word 文档，更新资料表后需将确认的英文简介同步到这里。

简介、论文题目、作者和说明按普通文本转义，不执行其中的 HTML，也不把个人简介当作任意 Markdown。包含冒号、引号时可用 YAML 双引号并转义内部双引号，例如 `note: "Talk title: \"S-box Optimization\""`。多行简介可用：

```yaml
bio_en: |
  I am a Ph.D. student who began my doctoral studies in 2025.
  My research focuses on block ciphers, S-box design and optimization,
  and hardware implementations.
```

不要直接照抄未确认的示例身份字段。本人已确认 GitHub 用户名 `Chenhao-Jia`，并更新正式输入表中的学校 `Shandong University`、院系 `School of Cyber Science and Technology` 和导师 `Meiqin Wang`，这些信息已同步到网站数据。导师网址仍为空。站点配置地址为 `https://chenhao-jia.github.io`，本地分支为 `main`；源码已推送到公开仓库 `Chenhao-Jia/chenhao-jia.github.io` 的 `main`，GitHub Actions 的检查、生产构建与 Pages 部署均成功；上线证据见验证报告。

## 添加或修改论文

编辑 `_data/publications.yml` 的 `main:` 列表。下例取自当前真实论文，用于说明字段；已有该条目，**不要原样重复添加**。新增时使用新且唯一的 `id`，并根据真实材料填写完整作者顺序、题目、年份、发表载体和状态。

```yaml
main:
  - id: "jia2026lowlatency"
    title: "A New Optimized Implementation Method for Boolean Functions Towards Low-Latency: Application to S-Boxes"
    authors:
      - name: "Chenhao Jia"
        self: true
      - name: "Tingting Cui"
        self: false
      - name: "Yanhong Fan"
        self: false
      - name: "Puwen Wei"
        self: false
      - name: "Meiqin Wang"
        self: false
    venue: "IACR Transactions on Cryptographic Hardware and Embedded Systems"
    year: 2026
    status: published
    citation:
      volume: "2026"
      number: "3"
      pages: "147--170"
    links:
      paper: "https://tches.iacr.org/index.php/TCHES/article/download/13086/12639"
      doi: "https://doi.org/10.46586/tches.v2026.i3.147-170"
      bibtex: "/assets/files/jia2026lowlatency.bib"
```

`self: true` 仅标记本人署名，页面据此加粗。年份为四位整数，不加引号。`status` 只能是 `published`、`accepted` 或 `preprint`，分别表示已发表、已接收和预印本；投稿中或未公开工作不录入公开数据。共同一作、通讯作者和奖项只在有依据且允许公开时写入 `note`。

`links` 支持 `paper`、`code`、`slides`、`bibtex`、`doi`。没有资源就省略该项或设为空字符串，按钮自动隐藏；所有资源都没有时用 `links: {}`。不要填 `#`、服务通用首页或不存在的本地文件。资源网址使用完整 `https://...`；站内附件使用 `/assets/files/...`，页面自动处理站点路径，无需手工拼接域名。论文按年份倒序，同年保留 YAML 中的先后顺序。

`_data/publications.yml` 是论文信息的唯一编辑来源。可选 `citation` 中的 `volume`、`number`、`pages` 分别记录真实卷号、期号和页码；页码范围使用 `--`。题目、完整作者、载体、年份和 DOI 均取自该条已有字段，不在引用文件内重复维护。每次修改论文数据后，在检查或预览前执行一次：

```powershell
bundle exec ruby scripts/generate_bibtex.rb
```

脚本从 YAML 生成本地 `/assets/files/*.bib` 链接对应的引用文件，并保护标题中的大小写。不要手工改生成文件；提交时同时包含 YAML 和重新生成的 `.bib`。外部 BibTeX 链接及未提供 BibTeX 的条目不会被改动。日常预览和 Actions 使用 `--check` 只检查同步状态，不写文件，过期会明确失败。

不要把整篇论文或付费附件复制进仓库；优先链接出版社、DOI、公开代码仓库或原始数据托管地址。

## 照片、CV 和邮箱

替换头像时将获准公开的图像上传到 `assets/img/`，再改 `profile.yml` 的 `avatar: "/assets/img/实际文件名.jpg"`；清空 `avatar` 即隐藏照片。不要使用模板作者照片或虚构人物照片。

有可公开 CV 时放入 `assets/files/`，将 `profile.yml` 内 `links.cv` 指向实际文件，如 `/assets/files/cv.pdf`，也可填写真实外部 CV 地址。未提供时保持空字符串，页面不生成下载按钮。

当前公开数据中 `email_public: false` 且 `email: ""`。只有本人同意公开后才填写邮箱并设置 `email_public: true`；它会出现在网页和公开源码里。隐藏网页邮箱时也应清空源码中的 `email`。上级私人输入表中的地址不会自动出现在网页中。

## 新闻、项目和教育经历

三个文件目前可保持 `[]`，空栏目及其导航自动隐藏。新增时将 `[]` 改成列表，仅填写真实且允许公开的内容：

- News 每条使用 `date: "YYYY-MM-DD"`、`title: "真实新闻"`，`url` 可省略或留空。
- Project 每条使用 `name`、`description` 和 `links` 映射；例如真实仓库可放在 `links` 下的 `Code` 键。没有链接时用 `links: {}`。
- Education 每条使用 `period`、`degree`，可再提供 `institution` 和 `department`；不据入学年份推断毕业时间。

这些是字段说明，不是可直接公开的示例经历。第一版未增加 Talks/Service 专用栏目，确有资料时再扩展，避免空标题。

## 通过 GitHub 网页维护

在已创建的仓库 [Chenhao-Jia/chenhao-jia.github.io](https://github.com/Chenhao-Jia/chenhao-jia.github.io) 的 **Code** 页打开所需 `_data/*.yml`，点铅笔编辑，再提交到维护分支或发起 Pull Request。上传照片/CV 用 **Add file → Upload files**，放进相应 `assets/` 子目录，再修改数据路径。先检查 **Actions** 的内容校验和构建结果；失败日志会指出文件、条目和字段。Pull Request 只检查，不发布。默认分支提交是否上线还取决于部署开关与生产校验，详见 [DEPLOYMENT.md](DEPLOYMENT.md)。

每次改动至少运行预览数据校验、构建和产物检查。修改结构或样式后再运行 `bundle exec ruby scripts/test_site.rb`，它只在临时目录生成空列表、长标题和多作者等测试数据，不改正式 `_data/`。不要将临时夹具复制到正式数据中。

## 公开前检查范围

只将 `academic-site/` 作为网站源码仓库；不要上传上级资料包。密码、Token、私钥、学号、私人联系信息、未公开论文、实验总目录、工业工艺库或未授权附件不能放进公开仓库。`exclude` 仅控制 `_site/`，`.gitignore` 仅阻止未跟踪文件被误加入，均无法让已公开的 Git 历史变私密。公开源码和网页产物要分别检查。

当前发布进度及可选补充内容见 [CONTENT_TODO.md](CONTENT_TODO.md)。模板来源、版本及许可证见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)；模板许可不自动覆盖个人照片、简历或论文。

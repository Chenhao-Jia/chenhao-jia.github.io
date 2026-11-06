# GitHub Pages 部署说明

**已获本人授权，源码已推送，GitHub Pages 已部署成功。** 网站：[https://chenhao-jia.github.io/](https://chenhao-jia.github.io/)，公开源码：[Chenhao-Jia/chenhao-jia.github.io](https://github.com/Chenhao-Jia/chenhao-jia.github.io)，默认分支为 `main`。`ready_for_publication`、`content_confirmed` 均为 `true`；仓库部署变量 `PAGES_DEPLOY_ENABLED=true`，Pages 发布来源为 GitHub Actions。已验证首页和核心资源 HTTP 200，详细提交、工作流及部署证据见 `VALIDATION_REPORT.md`。

## 地址与仓库边界

根据已确认的用户名，个人主页目标仓库应为 `Chenhao-Jia/chenhao-jia.github.io`，个人站点地址为 `https://chenhao-jia.github.io`；仓库名及默认域名中的用户名使用小写，`baseurl` 保持空字符串。该仓库创建时为空，没有覆盖既有内容；源码现已正常推送，远程默认分支及本地分支均为 `main`。本版校验按个人站点设计，不将普通项目仓库的 `/repository/` 路径混入地址。

只把 `academic-site/` 内的源码作为该仓库的根目录，保留 `_data/`、布局、资产、脚本、工作流和锁文件。上级原始 DOCX、XLSX、照片资料包、`PROFILE_INPUT.yml`、备份、日志及运行时不在公开仓库范围内。不要把模板上游仓库设成推送目标。已有同名仓库时先检查现有内容，再合并；不删除重建，不 force-push。

## 当前发布流程与后续重部署

本轮已获得本人对当前网站内容的公开发布授权。以下首次发布步骤均已完成，后续正常提交沿用同一流程：

1. 将已核对的站点源码正常提交并推送到 `Chenhao-Jia/chenhao-jia.github.io` 的 `main`，不 force-push、不覆盖其他仓库。
2. 在仓库 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**，不同时启用从分支发布或另一套 Pages 工作流。
3. 设置仓库变量 `PAGES_DEPLOY_ENABLED=true`，允许已通过内容验证的默认分支进入部署流程。这是变量，不是密码或 Token；默认不设置或非 `true` 时不会部署。
4. 通过默认分支推送或 **Actions → Run workflow** 触发。只有校验、生产构建、产物检查和部署全部成功，并取得部署作业返回的真实 `page_url`，才能报告已上线。代码已提交、仓库已创建或只看到检查成功都不等于网页已上线。

本次部署使用网站代码提交 `9e1f9394f352d2d96d9c34d9248461a8d3f22280`，工作流 [42270666738](https://github.com/Chenhao-Jia/chenhao-jia.github.io/actions/runs/42270666738) 的三个作业均成功。以后按相同检查流程维护内容即可；更换目标账号、仓库、公开范围或新增私人材料时，再确认对应变更。

## 生产命令

先使用 README 中的同一 Ruby 3.3.13 / Bundler 2.5.22 环境，在网站目录运行：

```powershell
bundle exec ruby scripts/validate_content.rb --mode production
if ($LASTEXITCODE -ne 0) { throw '生产资料未通过校验，请先补齐或确认。' }
$env:JEKYLL_ENV = 'production'
bundle exec jekyll build --config _config.yml --trace
if ($LASTEXITCODE -ne 0) { throw '生产构建失败，请查看日志。' }
bundle exec ruby scripts/check_site.rb _site
Remove-Item Env:JEKYLL_ENV
```

第一条非零退出时停止后续生产步骤。当前正式资料已获发布授权，两项内容确认开关均为 `true`，实际生产内容验证、production 构建和产物检查已通过。回归测试仍验证缺少确认或资料时会明确拒绝发布，不能跳过检查。不要把 `_config.preview.yml` 带入生产构建。预览 `noindex` 不提供隐私保护；本地未发布的材料也不能随意进入公开源码。

## 工作流如何隔离检查和部署

`.github/workflows/pages.yml` 使用 Ruby 3.3.13 与 `Gemfile.lock`。`pull_request`、`main` 的 `push` 和手动运行先执行预览内容校验、临时排版测试、Jekyll 构建和站内链接/文件检查。检查作业仅有 `contents: read`，不请求启用 Pages；因此尚未启用 Pages 的仓库也可运行检查。

生产构建和发布同时要求：仓库变量 `PAGES_DEPLOY_ENABLED == 'true'`、事件为默认分支的 `push` 或该分支的手动运行、前置检查成功，以及生产内容校验成功。PR 和其他分支的手动运行不会发布；没有 `pull_request_target`。

获准流程才调用 `actions/configure-pages`，且 `enablement: false`，不会自行更改 Pages 设置。它还将已配置的 Pages origin/path 与 `_config.yml` 比较，阻止发到错误地址。只将 `_site/` 上传为 Pages artifact。部署作业依赖已成功的生产构建，使用官方 `actions/deploy-pages`，仅该作业有 `pages: write`、`id-token: write` 和 `github-pages` 环境；并发控制避免同一引用上的部署互相打断。

Actions 版本及官方依据记录在 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。不要自行给检查作业加写权限，或把上传目录改成仓库根目录。

## 后续更新与回退

开启开关后，默认分支上的有效提交会重新构建并部署。日常先用 Pull Request 检查再合并。临时停止后续部署，将仓库变量删除或设成 `false`；这不会撤下已经上线的网页。

内容误改时，在 GitHub 找到正常提交并使用 **Revert** 生成恢复提交，或在本地正常 `git revert` 后按相同流程推送。重新运行旧提交的工作流不会自动改变当前源码版本；以恢复提交重新构建更容易审查。不要为回退使用强制推送或删除重建仓库。若误公开凭据，先撤销凭据，再处理历史，删网页文件不足以撤回公开记录。

官方说明：[创建 Pages 网站](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)、[选择发布来源](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)、[自定义 Pages 工作流](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)。

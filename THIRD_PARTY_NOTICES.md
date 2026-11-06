# 第三方来源与许可

本地取得日期：2026-11-07。

## Minimal Light

- 官方仓库：[yaoyao-liu/minimal-light](https://github.com/yaoyao-liu/minimal-light)。
- 实际取得的提交：[`dd114c3fef2d97adc1c6b6d46901e0d96ab83a7c`](https://github.com/yaoyao-liu/minimal-light/tree/dd114c3fef2d97adc1c6b6d46901e0d96ab83a7c)。
- 许可：CC0 1.0 Universal；原许可全文保存在 `LICENSE.minimal-light.txt`。
- 改造基础：实际阅读并选择性使用 `_layouts/homepage.html` 与 `_sass/minimal-light-no-dark-mode.scss` 的桌面资料栏、正文容器和窄屏单列结构，在本站本地维护布局与样式。没有设置 `remote_theme`，构建不需要在线下载主题。
- 已清理上游的演示姓名、照片、CV、论文、演示域名、CNAME、Google Analytics 标识、字体/图标 CDN 和预编译演示网站；上述样例不代表本站作者的资料。
- 上游 Gemfile 使用 Jekyll 3.8 系列。本站调整为 Jekyll 4.4 系列、Ruby 3.3.13，以可复现锁文件和实际构建结果为准，不继续依赖旧版远程主题环境。

CC0 的保留仅适用于相应模板代码，不自动授予本站个人照片、论文、CV、数据或其他内容的再分发权。个人材料按原权利人与具体资源的授权处理。

## 构建工具和部署 Actions

Jekyll、Liquid、Kramdown、Sass 等 Ruby 依赖由 RubyGems 获取，具体版本保存在 `Gemfile.lock`，不把本地安装的 gem 和工具链复制到公开网站。

工作流采用以下经官方文档和实际官方标签核对的版本：

- `actions/checkout@v6`：[官方仓库](https://github.com/actions/checkout/tree/v6)。
- `ruby/setup-ruby@v1`：[官方说明](https://github.com/ruby/setup-ruby)。官方建议使用 v1 跟随可用 Ruby 构建；Bundler 读取本站锁文件版本。
- `actions/configure-pages@v5`、`actions/upload-pages-artifact@v4`、`actions/deploy-pages@v4`：[GitHub Pages 自定义工作流文档](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)。版本选择与文档支持的稳定接口一致，不要求一律使用最新主版本。
- [Jekyll 安装要求](https://jekyllrb.com/docs/installation/)：Ruby 2.7 及以上；本站固定 Ruby 3.3.13，并以本地实际依赖安装与构建验证兼容性。

GitHub Actions 的远程执行尚未发生；版本核对不等于已经成功部署。

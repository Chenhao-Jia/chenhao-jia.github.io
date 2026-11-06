# 资料待办与确认边界

正式资料来源为上级正式资料目录中的学生信息 DOCX、论文链接 XLSX、照片，以及本人后续更新的 `PROFILE_INPUT.yml` 和明确确认的信息；`PROFILE_INPUT.example.yml` 仅参考结构，没有把示例字段当成事实。本人现已确认 GitHub 用户名 `Chenhao-Jia`、学校 `Shandong University`、院系 `School of Cyber Science and Technology` 和导师 `Meiqin Wang`，已同步到网站数据。后续网站内容只维护本目录 `_data/*.yml`。

## 当前发布进度

- 本人已明确授权将当前网站发布到个人 GitHub，无需重复索要同一授权。
- 公开仓库 `Chenhao-Jia/chenhao-jia.github.io` 已通过认证 GitHub API 创建（HTTP 201），默认分支 `main`；创建时为空仓库，没有覆盖既有远程内容。
- 姓名、英文简介、学校、院系、导师、论文、照片和资源已整理为公开版本；`content_confirmed` 与 `ready_for_publication` 均为 `true`。
- 生产内容验证、实际 `JEKYLL_ENV=production` 构建、站内产物检查及全部 7 组回归测试通过。私人邮箱仍不公开，原始资料与输入表继续留在网站仓库之外。
- 远程推送、Actions 和 Pages 部署正在执行；尚未验证上线，最终结果和证据见 `VALIDATION_REPORT.md`。无需为可选资料拖延发布。

## 可以稍后补充

- 可公开导师网址：当前留空；学校、院系和导师姓名已根据本人更新的正式输入表填写，无需重复补充。
- 是否公开邮箱：目前不公开，网站源码的邮箱为空。原 DOCX 的学术邮箱仅留在上级私人输入表。
- ORCID、DBLP、CV 等真实个人入口：未提供的保持空值，不用服务首页代替。GitHub 已使用确认账号的个人主页，Google Scholar 来自正式 DOCX。
- Code / Slides：页面已支持，未提供或未核验时不显示。已有论文使用真实 Paper、DOI 和本地 BibTeX，不填无效按钮。
- 完整教育经历、项目、新闻、学术服务和报告：没有确认材料时不展示。仅有博士入学年，不推断过往学校、学位或毕业时间。

## 已整理的资料差异

- 论文表中的 `Structual Attack on full-round DBST` 已按出版商记录规范为 `Structure attack on full-round DBST`，年份为 2024。
- 2026 年 TCHES 论文题目按 Crossref 主标题与副标题补上 `Implementation`，使用 `A New Optimized Implementation Method for Boolean Functions Towards Low-Latency: Application to S-Boxes`。
- ChaCha 论文单元格显示地址末尾有 `|`，实际超链接与正式 DOI 均不含该字符，已使用干净地址。
- IACR 部分页面受到防自动访问保护；相应全文地址来自出版商登记元数据，不能据本环境访问受阻判定失效，也不声称全部外链已实测下载成功。访问结果以验证报告为准。

没有论文、头像、CV 或学校资料都不需要编造。原始材料、私人输入表、备份和本地验证日志不能自动上传到公开仓库；`noindex` 只影响搜索引擎提示，不保护隐私。

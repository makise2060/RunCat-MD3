# 参与贡献 RunCat365

感谢您有兴趣为 **RunCat365** 做出贡献 🐈  
RunCat365 是一款以奔跑猫咪动画形式呈现的 Windows 系统监控应用程序。

我们欢迎各类贡献：错误报告、功能请求以及代码贡献。

本文档描述了参与本项目贡献的规则、步骤及期望。

---

## 开始之前

- **仅接受英文贡献。** 任何其他语言的贡献可能会被关闭。
- **本项目仅支持 Windows 平台。** 与 Linux、macOS 或其他平台相关的问题或请求将不被接受。
- 请务必使用提供的 **Issue** 和 **Pull Request** 模板。未遵循模板的提交可能会被关闭。
- 在所有交流中保持尊重、建设性和专业态度。

---

## 目录

- [开始之前](#开始之前)
- [Issues](#issues)
  - [错误报告](#错误报告)
  - [功能请求](#功能请求)
  - [其他问题](#其他问题)
- [Pull Requests](#pull-requests)
  - [提交 Pull Request 之前](#提交-pull-request-之前)
  - [克隆并处理仓库](#克隆并处理仓库)
  - [提交 Pull Request](#提交-pull-request)
- [代码风格指南](#代码风格指南)
- [审核流程](#审核流程)
- [致谢](#致谢)

---

## Issues

### 错误报告

报告错误的步骤：

1. 确认不存在报告相同错误的现有 Issue。  
   若已存在，请以评论形式补充相关信息，而非创建新 Issue。
2. 点击 `New issue` 并选择 `Bug Report` 模板。
3. 遵循所有清单步骤，确认该错误仍可复现。
4. 提供清晰完整的信息。更多细节有助于维护者更快地解决问题。
5. 提交 Issue 并保持关注，因为维护者可能会要求提供额外信息。

---

### 功能请求

提出新功能的步骤：

1. 检查是否已存在类似的功能请求。  
   若存在，请参与现有讨论，而非开启新讨论。
2. 确保您的建议能使广泛用户受益，而非仅满足个人偏好。
3. 点击 `New issue` 并选择 `Feature Request` 模板。
4. 尽可能清晰完整地填写模板。
5. 提交 Issue 并保持在线以便回答后续问题。

---

### 其他问题

> [!IMPORTANT]
> 此选项仅适用于不符合上述类别的问题。
> 未使用适当模板的问题将被直接关闭，恕不另行通知。

1. 点击 `New issue` 并选择 `Blank issue`。
2. 清晰详细地描述您的请求。
3. 提交 Issue 并关注维护者的反馈。

---

## Pull Requests

### 提交 Pull Request 之前

- 需要 **.NET 9.0** 环境。
- 所有代码必须使用 **英文** 编写。  
  面向用户的其他语言文本请使用本地化系统。
- 使用 **[Allman 缩进风格](https://en.wikipedia.org/wiki/Indentation_style#Allman_style)**。
- 当类型可从赋值语句明显推断时，使用 `var`。
- 遵循代码库中现有的格式和约定。
- 每个 Pull Request 专注于**单一变更或上下文**。  
  对于多个不相关的变更，请创建单独的 Pull Request。
- 保持代码整洁、可读且易于理解。
- 本仓库采用 **Apache-2.0** 许可证。

---

### 克隆并处理仓库

1. Fork `main` 分支。
2. 确保已安装 Git。
3. 将您的 Fork 克隆到本地：

   ```bash
   git clone https://github.com/your-username/RunCat365.git
   cd RunCat365
   ```
4. 创建新分支：

   ```bash
   git switch -c branch-name
   ```

   使用简短、描述性的分支名称。
5. 使用您偏好的 IDE 进行更改
   （推荐使用 Visual Studio）。
6. 将函数保留在其各自的类中。
7. 验证项目能够构建并正常运行，无错误。
8. 确保没有进行不必要或意外的更改。
9. 暂存您的更改：

   ```bash
   git add .
   ```
10. 提交您的更改：

    ```bash
    git commit -m "Clear and descriptive commit message"
    ```
11. 推送分支：

    ```bash
    git push origin branch-name
    ```

---

### 提交 Pull Request

1. 点击 **New pull request**。
2. 选择您处理过的分支。
3. 选择贡献类型。
4. 清晰完整地填写所有请求信息。
5. 确保满足所有清单项。
6. 提交 Pull Request。

---

## 代码风格指南

* 遵循现有项目约定。
* 使用 [Allman 缩进风格](https://en.wikipedia.org/wiki/Indentation_style#Allman_style)。
* 使用有意义且描述性的名称。
* 避免不必要的复杂性。
* 优先选择可读且自解释的代码，而非巧妙的解决方案。

---

## 审核流程

* Pull Request 将在时间允许的情况下进行审核。
* 不保证所有贡献都会被接受。
* 维护者可能会在合并前要求更改。
* 不活跃或无响应的 Pull Request 可能会被关闭。

---

## 致谢

再次感谢您为 **RunCat365** 做出贡献。  
您的时间和努力帮助这个项目变得更好 😸

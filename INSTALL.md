# 🐟 WorkBuddy 闲鱼连接器 · 安装指南

把闲鱼（Goofish）能力封装成标准 MCP 工具，接入 WorkBuddy 后用自然语言直接操作你的闲鱼账号。

> 本指南是 [xianyu-mcp-server](./README.md) 的 WorkBuddy 快速接入版；协议细节、FAQ 与免责声明见项目原 README。
> 基于 DoLovya/xianyu-mcp-server 与 pyxianyu 构建，本仓库为其 WorkBuddy 分发版。

---

## ✨ 能力一览（20 个 MCP 工具）

| 分类 | 工具 | 说明 |
|------|------|------|
| 登录 | `qr_login_generate` / `qr_login_status` / `qr_login_cookie` / `qr_login_save_env` | 扫码登录全流程，无需手动抓 Cookie |
| 登录 | `validate_login` / `refresh_login` | Cookie 校验与登录态刷新 |
| 商品（读） | `search_items` / `get_item_detail` / `list_my_items` / `get_my_profile` | 搜索全站商品、查详情、查自己的商品与个人信息 |
| 商品（写） | `publish_physical_item` / `edit_item` / `downshelf_item` / `reshelf_item` | 发布、编辑、下架、重新上架 |
| 媒体 | `upload_media` | 上传图片等媒体资源 |
| 消息 | `list_conversations` / `list_conversation_messages` / `send_text_message` / `send_image_message` | 会话列表、历史消息、主动发送文字/图片（可做 AI 客服） |

内置**风控护栏**：读写分离限速、写操作串行化、指数退避，降低自动化触发封号的风险。

---

## 📦 安装

### 环境要求

- macOS / Linux（Windows 请在 WSL 中运行）
- Python **3.11+**
- git

### 一键安装

```bash
git clone --recurse-submodules https://github.com/DoLovya/xianyu-mcp-server.git
cd xianyu-mcp-server
chmod +x install.sh
./install.sh
```

脚本会自动完成：环境检查 → 创建虚拟环境 `.venv` → 安装依赖 → 初始化 `.env` → MCP 握手冒烟测试 → 打印 WorkBuddy 配置。

如需自动写入 WorkBuddy 的 MCP 配置文件，加参数：

```bash
./install.sh --write-config
```

---

## 🔌 接入 WorkBuddy

### 方式一：自动写入（推荐）

```bash
./install.sh --write-config
```

### 方式二：手动添加

打开 WorkBuddy → 左侧边栏「连接器」→ 右上角「**自定义连接器**」→「配置 MCP」，粘贴：

```json
{
  "mcpServers": {
    "xianyu": {
      "command": "/绝对路径/xianyu-mcp-server/.venv/bin/python",
      "args": ["-m", "xianyu_mcp.server"],
      "cwd": "/绝对路径/xianyu-mcp-server",
      "env": {}
    }
  }
}
```

> ⚠️ 把路径替换为你本机的实际绝对路径（`install.sh` 运行结束会打印现成的配置，直接复制即可）。

**最后一步**：保存后回到连接器列表，对 `xianyu` 点击「**信任/启用**」——新 MCP 服务器不会自动激活。

---

## 🔑 登录闲鱼（二选一）

### 方式一：扫码登录（推荐）

激活连接器后，直接对 WorkBuddy 说：

> 生成闲鱼登录二维码

然后依次执行：用闲鱼 App 扫码 → 确认登录 → 保存 Cookie，全程无需手动操作。

### 方式二：粘贴 Cookie

1. 电脑浏览器打开 [www.goofish.com](https://www.goofish.com) 并登录
2. F12 打开开发者工具 → Network → 复制任意请求的完整 Cookie
3. 粘贴到项目根目录 `.env` 文件中：

```ini
XIANYU_COOKIE=粘贴到这里
```

---

## 💬 使用示例

登录完成后，直接用自然语言：

- 「帮我搜一下闲鱼上的二手 Switch，按最新发布排序」
- 「看看我店里有哪些在售商品」
- 「把这个商品降价 20 元」
- 「看看最近有没有人给我发消息，有的话先帮我打个招呼」
- 「把我店里所有价格低于 50 的商品下架」（写操作受风控护栏保护，自动控制节奏）

---

## ⚠️ 注意事项

- 闲鱼**没有官方开放 API**，本项目基于 Web 端协议分析实现，平台接口变更可能导致功能临时失效。
- Cookie 等同于账号登录凭证：**不要分享、不要提交到公开仓库**，只保存在本地 `.env`。
- 所有写操作（改价、下架、发消息）以你的账号身份执行，涉及对外发送前请再次确认内容。
- 自动化操作存在触发平台风控的可能，请勿高频滥用；使用行为需符合当地法律法规及平台服务条款。
- 本项目仅供学习与个人效率工具使用，完整免责声明见 [原 README](./README.md#免责声明)。

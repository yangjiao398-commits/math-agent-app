# math-agent-app

付费 Flutter 3 客户端（iOS + Android）。后台是同机的 [word-math-md](https://github.com/yangjiao398-commits/word-math-md)：试卷入库、KaTeX 预览、知识点训练、OCR 阅卷仍在 3010 服务上；本 App 只走 `/api/app/*`。
- 试卷 PDF 分享、微信/支付宝开通会员、答卷扫描评分也走 `/api/app/*`。

## 和后台怎么接

| App 能力 | 后台接口 |
| --- | --- |
| 登录（短信） | `POST /api/app/auth/sms` `POST /api/app/auth/login` |
| 会员态 | `GET /api/app/me` |
| 试卷列表 / 题目预览 | `GET /api/app/papers` `GET /api/app/papers/{id}/preview` |
| 知识点训练 | `GET /api/app/knowledge-points` `POST /api/app/questions-by-knowledge` `POST /api/app/practice/preview` |
| 推送令牌 | `POST /api/app/devices` |
| KaTeX / CDN / 套餐 | `GET /api/app/config` |

题目 HTML 与现网 preview 相同：服务端 KaTeX 0.18.4 渲染 `stemHtml`，App 用 **WebView + katex.min.css** 显示。配图 URL 由后台改写到国内 OSS/CDN（`APP_CDN_BASE`）。

开发环境：`APP_SMS_PROVIDER=dev`，验证码 `888888`，新用户送 7 天试用。

```bash
# 本机 Android 模拟器
flutter run --dart-define=API_BASE=http://10.0.2.2:3010

# iOS 模拟器
flutter run --dart-define=API_BASE=http://127.0.0.1:3010
```

真机请把 API_BASE 换成电脑局域网 IP，并保证 word-math-md 监听 `0.0.0.0:3010`。

## 生成 iOS / Android 工程

本机需 Flutter 3 SDK（`>=3.3 <4.0`）：

```bash
flutter create --org com.mathagent --project-name math_agent_app --platforms=ios,android .
flutter pub get
```

Android 需允许明文 HTTP（连本地 3010）：`android:usesCleartextTraffic="true"`。iOS 调试需在 `Info.plist` 放行本地网络。

## 推送

- iOS：APNs
- Android：个推（可用极光替换）+ 华为 / 小米 / OPPO / vivo 厂商通道

接入步骤见 `docs/PUSH.md`。上云见 `docs/CLOUD.md`。

# 华东云部署（阿里云或腾讯云）

math-agent-app 是客户端；API / 题库 / 公式预览仍由 word-math-md 提供。上云时把 3010 放到 VPC，前面加网关与 WAF。

## 建议拓扑

1. **Postgres（华东）**  
   阿里云 RDS PostgreSQL 或腾讯云 TencentDB for PostgreSQL。把现有 Supabase 表（papers、questions、app_users…）迁过去，或继续用 Supabase 作过渡。
2. **OSS + CDN**  
   试卷配图从题库对象存储同步到 OSS（阿里云 OSS / 腾讯云 COS），绑定国内 CDN 域名，填 `APP_CDN_BASE=https://cdn.xxx.com`。App WebView 里的 `<img>` 走 CDN，KaTeX 字体也可放同一 CDN。
3. **短信**  
   `APP_SMS_PROVIDER=aliyun` 或 `tencent`，配签名与模板。开发机保持 `dev`。
4. **WAF**  
   只暴露 `/api/app/*`、登录与支付回调。管理端（Word 转换、入库、知识点维护）走独立域名 + IP 白名单，不要给 App 用。
5. **支付**  
   微信 App 支付 / 支付宝 App 支付，回调写 `app_orders` 并续期 `app_memberships`。

## 环境变量（word-math-md）

```
APP_PUBLIC_ORIGIN=https://api.math-agent.cn
APP_CDN_BASE=https://cdn.math-agent.cn
APP_JWT_SECRET=...
APP_SMS_PROVIDER=aliyun
APP_ANDROID_PUSH=getui
APP_TRIAL_DAYS=7
```

App 构建：

```
flutter build apk --dart-define=API_BASE=https://api.math-agent.cn --dart-define=CDN_BASE=https://cdn.math-agent.cn
flutter build ipa --dart-define=API_BASE=https://api.math-agent.cn --dart-define=CDN_BASE=https://cdn.math-agent.cn
```

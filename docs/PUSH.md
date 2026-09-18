# 推送通道

## iOS：APNs

1. Apple Developer 开通 Push Notifications，上传 APNs Key（.p8）或证书。
2. `ios/Runner/AppDelegate.swift` 调用 `registerForRemoteNotifications`。
3. 把 device token 报到 `POST /api/app/devices`，`platform=ios`，`vendor=apns`。
4. 服务端用 APNs HTTP/2 推送（可走阿里云移动推送 / 腾讯云 TPNS 的 APNs 通道，避免自建长连）。

## Android：个推或极光 + 厂商通道

国内安卓不能只靠 FCM。默认 **个推**（`APP_ANDROID_PUSH=getui`），也可换成极光（`jpush`）。

厂商通道（在个推/极光控制台开通，按厂商文档加 SDK）：

| 厂商 | 说明 |
| --- | --- |
| 华为 | 华为推送 Kit + `agconnect-services.json` |
| 小米 | 小米推送 |
| OPPO | OPPO 推送 |
| vivo | vivo 推送 |

App 启动后 `PushService.registerIfPossible()` 上报 `push_token`。后台按 `vendor` 选通道下发：会员到期、新卷入库、批改完成等。

开发阶段 token 允许为空；上架前必须换成正式 AppID / AppKey，不要把密钥提交进 git。

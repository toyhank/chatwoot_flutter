# Chatwoot Mobile API 文档 (自定义扩展)

本文档描述了为移动端应用扩展的登录和每日签到接口，包含资金余额（Balance）的处理。

---

## 1. 用户登录 (Login)

用于移动端用户通过邮箱和密码登录，并获取用户基础信息及当前资金余额。

- **接口地址**: `/api/mobile/register/login`
- **请求方法**: `POST`
- **请求格式**: `application/json`

### 请求参数
| 参数名 | 类型 | 必填 | 说明 |
| :--- | :--- | :--- | :--- |
| `email` | String | 是 | 用户注册邮箱 |
| `password` | String | 是 | 登录密码 |

### 响应示例 (成功 200)
```json
{
  "status": 200,
  "msg": "登录成功",
  "data": {
    "uid": 123,
    "email": "user@example.com",
    "nickname": "张三",
    "avatar": "http://domain.com/avatar.png",
    "phone": "",
    "access_token": "eyJhbGciOiJIUzI1NiJ...",
    "balance": 105,
    "message": "登录成功"
  }
}
```
> **注意**: `access_token` 是后续所有需要认证接口（如签到）必须携带的凭证。

---

## 2. 每日签到 (Daily Check-in)

用户每日点击签到，系统会验证今日是否已完成。若未签到，则余额增加 **5** 单位。

- **接口地址**: `/api/mobile/user/check_in`
- **请求方法**: `POST`
- **认证方式**: `Bearer Token` (Header 中携带)

### 请求头 (Header)
| Key | Value | 说明 |
| :--- | :--- | :--- |
| `Authorization` | `Bearer <YOUR_ACCESS_TOKEN>` | 登录接口返回的 token |

### 响应示例 (成功 200)
```json
{
  "status": 200,
  "msg": "签到成功，余额已增加",
  "data": {
    "balance": 110
  }
}
```

### 响应示例 (重复签到 422)
```json
{
  "status": 422,
  "msg": "今天已经签到过了",
  "data": {
    "balance": 110
  }
}
```

### 响应示例 (未登录 401)
```json
{
  "status": 401,
  "msg": "未授权,请先登录"
}
```

---

## 3. 错误码说明

| 状态码 | 说明 |
| :--- | :--- |
| `200` | 操作成功 |
| `401` | Token 失效或未登录 |
| `404` | 资源不存在 |
| `422` | 业务逻辑错误（如重复签到） |
| `500` | 服务器内部错误 |

# IoT智能家居 - 后端接口文档

## 📋 文档说明

- **项目名称**: IoT智能家居管理系统
- **API版本**: v1.0
- **Base URL**: `https://your-api.com/api/v1/web`
- **文档版本**: 1.0.0
- **最后更新**: 2025-01-01

## 🔐 认证说明

### Token认证
所有需要认证的接口都需要在请求头中携带Token：

```http
Authorization: Bearer {access_token}
```

### 响应格式
所有接口直接返回数据，使用HTTP状态码表示请求状态：

**成功响应** (HTTP 200):
```json
{
  // 直接返回数据对象
}
```

**错误响应** (HTTP 4xx/5xx):
```json
{
  "message": "错误信息描述"
}
```

### HTTP状态码说明
- `200 OK`: 请求成功
- `201 Created`: 创建成功
- `400 Bad Request`: 请求参数错误
- `401 Unauthorized`: 未授权，Token无效或过期
- `403 Forbidden`: 无权限访问
- `404 Not Found`: 资源不存在
- `409 Conflict`: 资源冲突（如重复创建）
- `500 Internal Server Error`: 服务器内部错误

## 📑 目录

1. [认证接口](#1-认证接口)
2. [设备管理接口](#2-设备管理接口)
3. [家庭管理接口](#3-家庭管理接口)
4. [家庭成员接口](#4-家庭成员接口)
5. [消息通知接口](#5-消息通知接口)
6. [签到积分接口](#6-签到积分接口)
7. [设置接口](#7-设置接口)

---

## 1. 认证接口

### 1.1 用户注册

**接口地址**: `POST /auth/register`

**请求参数**:
```json
{
  "phone": "13800138000",
  "password": "123456",
  "nickname": "用户昵称",
  "gender": "male",
  "avatar": "头像URL"
}
```

**响应数据** (HTTP 200):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "role": "user",
  "account": {
    "id": 1,
    "nickname": "用户昵称",
    "gender": "male",
    "phone": "13800138000",
    "email": null,
    "avatar": "头像URL",
    "role": "user",
    "current_family_id": null,
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

**错误响应** (HTTP 400):
```json
{
  "message": "手机号已被注册"
}
```

### 1.2 用户登录

**接口地址**: `POST /auth/login`

**请求参数**:
```json
{
  "phone": "13800138000",
  "password": "123456"
}
```

**响应数据** (HTTP 200):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "role": "user",
  "account": {
    "id": 1,
    "nickname": "用户昵称",
    "gender": "male",
    "phone": "13800138000",
    "email": "user@example.com",
    "avatar": "头像URL",
    "role": "user",
    "current_family_id": 1,
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

### 1.3 退出登录

**接口地址**: `POST /auth/logout`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{}
```

### 1.4 获取RSA公钥

**接口地址**: `GET /auth/rsa_public_key`

**响应数据** (HTTP 200):
```json
{
  "public_key": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
}
```

### 1.5 获取用户信息

**接口地址**: `GET /auth/profile`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "nickname": "用户昵称",
  "gender": "male",
  "phone": "13800138000",
  "email": "user@example.com",
  "avatar": "头像URL",
  "role": "user",
  "current_family_id": 1,
  "created_at": "2025-01-01T00:00:00Z"
}
```

### 1.6 获取当前家庭

**接口地址**: `GET /auth/current-family`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "name": "我的家",
  "avatar": null,
  "description": "温馨的家",
  "invite_code": "ABC12345",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### 1.7 删除账户

**接口地址**: `DELETE /auth/account`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{}
```

---

## 2. 设备管理接口

### 2.1 获取设备列表

**接口地址**: `GET /devices/`

**请求头**: 需要Token认证

**请求参数**: 
| 参数 | 类型 | 必填 | 说明 |
|-----|------|------|------|
| status | string | 否 | 设备状态 (online/offline) |
| page | integer | 否 | 页码，默认1 |
| page_size | integer | 否 | 每页数量，默认20 |

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "name": "客厅空调",
    "sn": "AC001_250101_000001",
    "status": "online",
    "account_id": 1,
    "model_id": 1,
    "created_at": "2025-01-01T00:00:00Z"
  },
  {
    "id": 2,
    "name": "卧室灯",
    "sn": "LIGHT001_250101_000002",
    "status": "online",
    "account_id": 1,
    "model_id": 2,
    "created_at": "2025-01-01T00:00:00Z"
  }
]
```

### 2.2 绑定设备

**接口地址**: `POST /devices/bind-by-sn/`

**请求头**: 需要Token认证

**请求参数**:
```json
{
  "sn": "AC001_250101_000001",
  "name": "客厅空调"
}
```

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "name": "客厅空调",
  "sn": "AC001_250101_000001",
  "status": "online",
  "account_id": 1,
  "model_id": 1,
  "created_at": "2025-01-01T00:00:00Z"
}
```

### 2.3 解绑设备

**接口地址**: `DELETE /devices/unbind-by-sn/{sn}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| sn | string | 设备序列号 |

**响应数据** (HTTP 200):
```json
{}
```

### 2.4 更新设备名称

**接口地址**: `PATCH /devices/{id}/name`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| id | integer | 设备ID |

**请求参数**:
```json
{
  "name": "新的设备名称"
}
```

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "name": "新的设备名称",
  "sn": "AC001_250101_000001",
  "status": "online",
  "account_id": 1,
  "model_id": 1,
  "created_at": "2025-01-01T00:00:00Z"
}
```

---

## 3. 家庭管理接口

### 3.1 获取家庭列表

**接口地址**: `GET /families/`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "name": "我的家",
    "avatar": null,
    "description": "温馨的家",
    "invite_code": "ABC12345",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  }
]
```

### 3.2 创建家庭

**接口地址**: `POST /families/`

**请求头**: 需要Token认证

**请求参数**:
```json
{
  "name": "我的家",
  "avatar": "头像URL",
  "description": "温馨的家"
}
```

**响应数据** (HTTP 201):
```json
{
  "id": 1,
  "name": "我的家",
  "avatar": "头像URL",
  "description": "温馨的家",
  "invite_code": "ABC12345",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### 3.3 删除家庭

**接口地址**: `DELETE /families/{id}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| id | integer | 家庭ID |

**响应数据** (HTTP 200):
```json
{}
```

### 3.4 添加设备到家庭

**接口地址**: `POST /families/{family_id}/devices/{device_id}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| family_id | integer | 家庭ID |
| device_id | integer | 设备ID |

**响应数据** (HTTP 200):
```json
{}
```

### 3.5 从家庭移除设备

**接口地址**: `DELETE /families/{family_id}/devices/{device_id}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| family_id | integer | 家庭ID |
| device_id | integer | 设备ID |

**响应数据** (HTTP 200):
```json
{}
```

---

## 4. 家庭成员接口

### 4.1 获取家庭成员列表

**接口地址**: `GET /family-members/family/{family_id}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| family_id | integer | 家庭ID |

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "nickname": "爸爸",
    "role": "owner",
    "joined_at": "2025-01-01T00:00:00Z",
    "account": {
      "id": 1,
      "nickname": "测试用户",
      "gender": "male",
      "phone": "13800138000",
      "email": "test@example.com",
      "avatar": null,
      "role": "user",
      "current_family_id": 1,
      "created_at": "2025-01-01T00:00:00Z"
    }
  }
]
```

### 4.2 通过邀请码加入家庭

**接口地址**: `POST /family-members/join-by-invite-code`

**请求头**: 需要Token认证

**请求参数**:
```json
{
  "invite_code": "ABC12345",
  "nickname": "家庭成员昵称"
}
```

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "name": "我的家",
  "avatar": null,
  "description": "温馨的家",
  "invite_code": "ABC12345",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### 4.3 更新成员信息

**接口地址**: `PATCH /family-members/{id}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| id | integer | 成员ID |

**请求参数**:
```json
{
  "nickname": "新昵称"
}
```

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "nickname": "新昵称",
  "role": "member",
  "joined_at": "2025-01-01T00:00:00Z",
  "account": {
    "id": 1,
    "nickname": "测试用户",
    "gender": "male",
    "phone": "13800138000",
    "email": "test@example.com",
    "avatar": null,
    "role": "user",
    "current_family_id": 1,
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

### 4.4 移除成员

**接口地址**: `DELETE /family-members/{id}`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| id | integer | 成员ID |

**响应数据** (HTTP 200):
```json
{}
```

---

## 5. 消息通知接口

### 5.1 获取设备消息列表

**接口地址**: `GET /device-messages/`

**请求头**: 需要Token认证

**请求参数**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|------|------|
| level | string | 否 | 消息级别 (normal/warning/error) |
| status | string | 否 | 消息状态 (new/read) |
| page | integer | 否 | 页码，默认1 |
| page_size | integer | 否 | 每页数量，默认20 |

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "device_id": 1,
    "level": "normal",
    "message": "空调已开启",
    "detail": {
      "temperature": 26
    },
    "status": "new",
    "created_at": "2025-01-01T10:00:00Z",
    "updated_at": null
  },
  {
    "id": 2,
    "device_id": 3,
    "level": "error",
    "message": "摄像头离线",
    "detail": null,
    "status": "new",
    "created_at": "2025-01-01T09:00:00Z",
    "updated_at": null
  }
]
```

### 5.2 标记消息为已读

**接口地址**: `PATCH /device-messages/{id}/make-read`

**请求头**: 需要Token认证

**路径参数**:
| 参数 | 类型 | 说明 |
|-----|------|------|
| id | integer | 消息ID |

**响应数据** (HTTP 200):
```json
{}
```

### 5.3 标记所有消息为已读

**接口地址**: `PATCH /device-messages/mark-all-read`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{}
```

### 5.4 获取系统消息列表

**接口地址**: `GET /system-messages/`

**请求头**: 需要Token认证

**请求参数**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|------|------|
| type | string | 否 | 消息类型 (maintenance/update/announcement/security) |
| page | integer | 否 | 页码，默认1 |
| page_size | integer | 否 | 每页数量，默认20 |

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "title": "系统维护通知",
    "content": "系统将于今晚22:00-24:00进行维护",
    "type": "maintenance",
    "priority": "high",
    "platforms": ["web", "mobile"],
    "extra": null,
    "created_at": "2025-01-01T08:00:00Z",
    "updated_at": "2025-01-01T08:00:00Z"
  }
]
```

### 5.5 获取未读消息数量

**接口地址**: `GET /device-messages/unread-count`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{
  "device_messages": 2,
  "system_messages": 1
}
```

---

## 6. 签到积分接口

### 6.1 签到

**接口地址**: `POST /check-in/`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{
  "id": 1,
  "check_in_type": "normal",
  "points_earned": 5,
  "continuous_days": 8,
  "check_in_time": "2025-01-01T08:00:00Z",
  "extra": null
}
```

### 6.2 获取签到日历

**接口地址**: `GET /check-in/calendar`

**请求头**: 需要Token认证

**请求参数**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|------|------|
| year | integer | 否 | 年份，默认当前年 |
| month | integer | 否 | 月份，默认当前月 |

**响应数据** (HTTP 200):
```json
{
  "dates": [
    "2025-01-01",
    "2025-01-02",
    "2025-01-03",
    "2025-01-04",
    "2025-01-05",
    "2025-01-06",
    "2025-01-07"
  ]
}
```

### 6.3 获取签到统计

**接口地址**: `GET /check-in/stats`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{
  "total_check_ins": 30,
  "continuous_days": 7,
  "longest_continuous": 15
}
```

### 6.4 获取签到历史

**接口地址**: `GET /check-in/history`

**请求头**: 需要Token认证

**请求参数**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|------|------|
| page | integer | 否 | 页码，默认1 |
| page_size | integer | 否 | 每页数量，默认20 |

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "check_in_type": "bonus",
    "points_earned": 20,
    "continuous_days": 7,
    "check_in_time": "2025-01-07T08:00:00Z",
    "extra": null
  },
  {
    "id": 2,
    "check_in_type": "normal",
    "points_earned": 5,
    "continuous_days": 6,
    "check_in_time": "2025-01-06T08:00:00Z",
    "extra": null
  }
]
```

### 6.5 获取积分余额

**接口地址**: `GET /points/balance`

**请求头**: 需要Token认证

**响应数据** (HTTP 200):
```json
{
  "balance": 520
}
```

### 6.6 获取积分历史

**接口地址**: `GET /points/history`

**请求头**: 需要Token认证

**请求参数**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|------|------|
| page | integer | 否 | 页码，默认1 |
| page_size | integer | 否 | 每页数量，默认20 |

**响应数据** (HTTP 200):
```json
[
  {
    "id": 1,
    "type": "earn",
    "amount": 5,
    "description": "每日签到",
    "created_at": "2025-01-01T08:00:00Z"
  },
  {
    "id": 2,
    "type": "earn",
    "amount": 20,
    "description": "连续签到7天奖励",
    "created_at": "2025-01-01T08:00:00Z"
  }
]
```

---

## 7. 设置接口

### 7.1 提交反馈

**接口地址**: `POST /feedback/`

**请求头**: 需要Token认证

**请求参数**:
```json
{
  "type": "bug",
  "content": "反馈内容详细描述...",
  "contact": "联系方式（可选）"
}
```

**响应数据** (HTTP 201):
```json
{
  "id": 1,
  "type": "bug",
  "content": "反馈内容详细描述...",
  "contact": "联系方式",
  "status": "pending",
  "created_at": "2025-01-01T08:00:00Z"
}
```

### 7.2 获取版本信息

**接口地址**: `GET /version-info/`

**响应数据** (HTTP 200):
```json
{
  "version": "1.0.0",
  "build_number": 1,
  "update_time": "2025-01-01",
  "description": "首次发布版本",
  "download_url": "https://example.com/download",
  "force_update": false
}
```

---

## 📊 数据模型

### User (用户)
```typescript
{
  id: number;
  nickname: string;
  gender: 'male' | 'female' | 'other';
  phone: string;
  email?: string;
  avatar?: string;
  role: 'user' | 'admin';
  current_family_id?: number;
  created_at: string;
}
```

### Device (设备)
```typescript
{
  id: number;
  name: string;
  sn: string;  // 格式: modecode_YYMMDD_NNNNNN
  status: 'online' | 'offline';
  account_id: number;
  model_id: number;
  created_at: string;
}
```

### Family (家庭)
```typescript
{
  id: number;
  name: string;
  avatar?: string;
  description?: string;
  invite_code: string;
  created_at: string;
  updated_at: string;
}
```

### FamilyMember (家庭成员)
```typescript
{
  id: number;
  nickname: string;
  role: 'owner' | 'admin' | 'member';
  joined_at: string;
  account: User;
}
```

### DeviceMessage (设备消息)
```typescript
{
  id: number;
  device_id: number;
  level: 'normal' | 'warning' | 'error' | 'info';
  message: string;
  detail?: any;
  status: 'new' | 'read';
  created_at: string;
  updated_at?: string;
}
```

### SystemMessage (系统消息)
```typescript
{
  id: number;
  title: string;
  content: string;
  type: 'maintenance' | 'update' | 'announcement' | 'security';
  priority: 'low' | 'normal' | 'high';
  platforms: string[];
  extra?: any;
  created_at: string;
  updated_at: string;
}
```

### CheckinRecord (签到记录)
```typescript
{
  id: number;
  check_in_type: 'normal' | 'bonus' | 'makeup';
  points_earned: number;
  continuous_days: number;
  check_in_time: string;
  extra?: any;
}
```

### CheckinStats (签到统计)
```typescript
{
  total_check_ins: number;
  continuous_days: number;
  longest_continuous: number;
}
```

### PointsHistory (积分历史)
```typescript
{
  id: number;
  type: 'earn' | 'spend' | 'expire';
  amount: number;
  description: string;
  created_at: string;
}
```

---

## 🔒 错误码说明

| 错误码 | 说明 |
|-------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，Token无效或过期 |
| 403 | 禁止访问，权限不足 |
| 404 | 资源不存在 |
| 409 | 资源冲突（如设备已被绑定） |
| 422 | 请求参数验证失败 |
| 500 | 服务器内部错误 |

### 错误响应示例

**401 Unauthorized**:
```json
{
  "message": "Token已过期，请重新登录"
}
```

**409 Conflict**:
```json
{
  "message": "设备已被其他用户绑定"
}
```

---

## 🌐 MQTT接口说明

### Topic规则

```
app/{sn}/data           # 后台 -> app (设备数据推送)
app/{sn}/status         # 后台 -> app (设备状态推送)
app/{sn}/control        # app -> 后台 (设备控制指令)
system/notice           # 系统通知
home/{home_id}/notice   # 家庭通知
```

### 设备数据消息格式

**Topic**: `app/{sn}/data`

```json
{
  "sn": "AC001_250101_000001",
  "timestamp": 1704067200000,
  "data": {
    "temperature": 26,
    "humidity": 60,
    "power": true,
    "mode": "cool"
  }
}
```

### 设备状态消息格式

**Topic**: `app/{sn}/status`

```json
{
  "sn": "AC001_250101_000001",
  "status": "online",
  "timestamp": 1704067200000
}
```

### 设备控制指令格式

**Topic**: `app/{sn}/control`

```json
{
  "action": "setPower",
  "value": true,
  "timestamp": 1704067200000
}
```

### 系统通知格式

**Topic**: `system/notice`

```json
{
  "type": "maintenance",
  "title": "系统维护通知",
  "content": "系统将于今晚22:00-24:00进行维护",
  "timestamp": 1704067200000
}
```

---

## 📝 附录

### A. 支持的设备型号

| 型号代码 | 设备类型 | SN示例 |
|---------|---------|--------|
| AC001-003 | 空调 | AC001_250101_000001 |
| LIGHT001-003 | 智能灯 | LIGHT001_250101_000002 |
| CAM001-003 | 摄像头 | CAM001_250101_000003 |
| TV001-003 | 智能电视 | TV001_250101_000004 |
| FALL001-003 | 跌倒检测器 | FALL001_250101_000005 |
| WIFI001-003 | 路由器 | WIFI001_250101_000006 |
| ROBOT001-003 | 扫地机器人 | ROBOT001_250101_000007 |
| WASH001-003 | 洗衣机 | WASH001_250101_000008 |
| FRIDGE001-003 | 冰箱 | FRIDGE001_250101_000009 |
| SPEAKER001-003 | 音箱 | SPEAKER001_250101_000010 |
| AIR001-003 | 空气净化器 | AIR001_250101_000011 |
| M701001 | 环境监测器 | M701001_250101_000012 |

### B. 测试账号

```
手机号: 13800138000
密码: 123456
```

### C. 开发环境配置

```
Base URL: https://dev-api.example.com/api/v1/web
MQTT Broker: mqtt://dev-broker.example.com:1883
```

### D. 生产环境配置

```
Base URL: https://api.example.com/api/v1/web
MQTT Broker: mqtts://broker.example.com:8883
```

---

## 📮 联系方式

- **技术支持**: support@iot-app.com
- **API问题**: api@iot-app.com
- **文档更新**: docs@iot-app.com

---

**文档版本**: v1.0.0  
**最后更新**: 2025-01-01  
**维护团队**: IoT App Backend Team


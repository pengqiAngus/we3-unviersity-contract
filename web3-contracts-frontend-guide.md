# 易登教育 Web3 合约接口文档

## 目录

- [概述](#概述)
- [合约地址配置](#合约地址配置)
- [YiDengToken (YD) 代币合约](#yidengtoken-yd-代币合约)
- [CourseCertificate (YDCC) NFT 合约](#coursecertificate-ydcc-nft合约)
- [CourseMarket 课程市场合约](#coursemarket-课程市场合约)

## 概述

本文档提供了易登教育 Web3 平台的智能合约前端集成指南。系统包含三个主要合约：

1. YiDengToken (YD)：平台通证
2. CourseCertificate (YDCC)：课程完成证书 NFT
3. CourseMarket：课程市场

## 合约地址配置

```typescript
interface ContractAddresses {
  YiDengToken: string;
  CourseCertificate: string;
  CourseMarket: string;
}
```

## YiDengToken (YD) 代币合约

### 常量值

| 名称           | 值      | 描述                   |
| -------------- | ------- | ---------------------- |
| TOKENS_PER_ETH | 1000    | 1 ETH 可兑换的 YD 数量 |
| MAX_SUPPLY     | 1250000 | 最大供应量             |
| decimals       | 0       | 代币精度               |

### 状态变量

| 名称                    | 类型      | 描述                               |
| ----------------------- | --------- | ---------------------------------- |
| teamAllocation          | uint256   | 团队分配比例：20% = 25 万 YD       |
| marketingAllocation     | uint256   | 市场营销分配比例：10% = 12.5 万 YD |
| communityAllocation     | uint256   | 社区分配比例：10% = 12.5 万 YD     |
| initialDistributionDone | bool      | 标记初始代币分配是否已完成         |
| signers                 | address[] | 多签人列表                         |
| requiredSignatures      | uint256   | 需要的签名数量                     |
| withdrawalId            | uint256   | 提款请求 ID 计数器                 |

### 方法列表

| 方法名                   | 参数 (类型)                                                                | 返回值 (类型)              | 触发事件 (参数)                                                                                                                             | 说明                                     |
| ------------------------ | -------------------------------------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| buyWithETH               | - (payable)                                                                | -                          | TokensPurchased (buyer: address, ethAmount: uint256, tokenAmount: uint256)                                                                  | 使用 ETH 购买 YD 代币，兑换比例为 1:1000 |
| sellTokens               | tokenAmount (uint256)                                                      | -                          | TokensSold (seller: address, tokenAmount: uint256, ethAmount: uint256)                                                                      | 将 YD 代币卖回换取 ETH                   |
| remainingMintableSupply  | -                                                                          | supply (uint256)           | -                                                                                                                                           | 查询剩余可铸造的代币数量                 |
| balanceOf                | account (address)                                                          | balance (uint256)          | -                                                                                                                                           | 查询指定地址的代币余额                   |
| approve                  | spender (address), amount (uint256)                                        | success (bool)             | Approval (owner: address, spender: address, value: uint256)                                                                                 | 授权指定地址可使用的代币数量             |
| transfer                 | recipient (address), amount (uint256)                                      | success (bool)             | Transfer (from: address, to: address, value: uint256)                                                                                       | 向指定地址转账代币                       |
| transferFrom             | sender (address), recipient (address), amount (uint256)                    | success (bool)             | Transfer (from: address, to: address, value: uint256)                                                                                       | 代表他人转账代币，需要事先获得授权       |
| distributeInitialTokens  | teamWallet (address), marketingWallet (address), communityWallet (address) | -                          | InitialDistributionCompleted (teamWallet: address, marketingWallet: address, communityWallet: address)                                      | 初始代币分配，只能由合约所有者调用一次   |
| addSigner                | newSigner (address)                                                        | -                          | -                                                                                                                                           | 添加多签成员，只能由合约所有者调用       |
| removeSigner             | signerToRemove (address)                                                   | -                          | -                                                                                                                                           | 移除多签成员，只能由合约所有者调用       |
| updateRequiredSignatures | newRequiredSignatures (uint256)                                            | -                          | -                                                                                                                                           | 修改所需签名数量，只能由合约所有者调用   |
| requestWithdrawal        | amount (uint256), recipient (address)                                      | -                          | WithdrawalRequested (withdrawalId: uint256, amount: uint256, recipient: address), WithdrawalSigned (withdrawalId: uint256, signer: address) | 发起提款请求，只能由多签成员调用         |
| signWithdrawal           | requestId (uint256)                                                        | -                          | WithdrawalSigned (withdrawalId: uint256, signer: address)                                                                                   | 签名提款请求，只能由多签成员调用         |
| withdrawalRequests       | requestId (uint256)                                                        | WithdrawalRequest (struct) | -                                                                                                                                           | 查询提款请求详情                         |

### 数据结构

```typescript
struct WithdrawalRequest {
    amount: uint256;          // 提款金额
    signatureCount: uint256;  // 已签名数量
    recipient: address;       // 接收者地址
    executed: boolean;        // 是否已执行
    signatures: mapping(address => bool); // 签名记录
}
```

## CourseCertificate (YDCC) NFT 合约

### 方法列表

| 方法名                 | 参数 (类型)                                                    | 返回值 (类型)        | 触发事件 (参数)                                                              | 说明                         |
| ---------------------- | -------------------------------------------------------------- | -------------------- | ---------------------------------------------------------------------------- | ---------------------------- |
| mintCertificate        | student (address), web2CourseId (string), metadataURI (string) | tokenId (uint256)    | CertificateMinted (tokenId: uint256, web2CourseId: string, student: address) | 为学生铸造课程完成证书       |
| hasCertificate         | student (address), web2CourseId (string)                       | hasToken (bool)      | -                                                                            | 检查学生是否拥有某课程的证书 |
| getStudentCertificates | student (address), web2CourseId (string)                       | tokenIds (uint256[]) | -                                                                            | 获取学生某课程的所有证书 ID  |
| tokenURI               | tokenId (uint256)                                              | uri (string)         | -                                                                            | 获取证书的元数据 URI         |
| ownerOf                | tokenId (uint256)                                              | owner (address)      | -                                                                            | 查询证书的所有者             |

## CourseMarket 课程市场合约

### 数据结构

```typescript
struct Course {
    web2CourseId: string;    // Web2平台的课程ID
    name: string;            // 课程名称
    price: uint256;          // 课程价格(YD代币)
    isActive: boolean;       // 课程是否可购买
    creator: address;        // 课程创建者地址
}
```

### 方法列表

| 方法名                      | 参数 (类型)                                           | 返回值 (类型)       | 触发事件 (参数)                                                               | 说明                                       |
| --------------------------- | ----------------------------------------------------- | ------------------- | ----------------------------------------------------------------------------- | ------------------------------------------ |
| addCourse                   | web2CourseId (string), name (string), price (uint256) | -                   | CourseAdded (courseId: uint256, web2CourseId: string, name: string)           | 添加新课程，仅合约拥有者可调用             |
| purchaseCourse              | web2CourseId (string)                                 | -                   | CoursePurchased (buyer: address, courseId: uint256, web2CourseId: string)     | 购买课程，需要先授权代币合约               |
| verifyCourseCompletion      | student (address), web2CourseId (string)              | -                   | CourseCompleted (student: address, courseId: uint256, certificateId: uint256) | 验证课程完成并发放证书，仅合约拥有者可调用 |
| batchVerifyCourseCompletion | students (address[]), web2CourseId (string)           | -                   | CourseCompleted (student: address, courseId: uint256, certificateId: uint256) | 批量验证课程完成，仅合约拥有者可调用       |
| hasCourse                   | user (address), web2CourseId (string)                 | hasPurchased (bool) | -                                                                             | 检查用户是否已购买课程                     |
| courses                     | courseId (uint256)                                    | course (Course)     | -                                                                             | 获取课程详细信息                           |
| web2ToCourseId              | web2CourseId (string)                                 | courseId (uint256)  | -                                                                             | 获取 Web2 课程 ID 对应的链上课程 ID        |

### 权限说明

- `onlyOwner`: 只有合约所有者可以调用
  - addCourse
  - verifyCourseCompletion
  - batchVerifyCourseCompletion

### 常见错误码

| 错误码          | 描述         |
| --------------- | ------------ |
| 4001            | 用户拒绝交易 |
| -32603          | 合约执行错误 |
| -32000 ~ -32099 | 服务器错误   |

### 交易前检查清单

1. YiDengToken 相关：

   - 购买前检查 ETH 余额是否充足
   - 出售前检查 YD 余额是否充足
   - 转账前检查授权额度是否充足

2. CourseCertificate 相关：

   - 检查是否已拥有该课程的证书
   - 检查证书 ID 是否存在

3. CourseMarket 相关：
   - 购买前检查课程是否存在且激活
   - 购买前检查是否已经购买过
   - 购买前检查 YD 余额和授权额度

## 错误处理

所有合约调用都应该包含适当的错误处理：

```typescript
try {
  await contract.method();
} catch (error) {
  if (error.code === 4001) {
    console.log("用户拒绝了交易");
  } else if (error.code === -32603) {
    console.log("合约执行错误");
  } else {
    console.log("未知错误:", error);
  }
}
```

## 常见错误代码

- 4001: 用户拒绝交易
- -32603: 内部 JSON-RPC 错误
- -32000 到 -32099: 服务器错误

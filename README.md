# 多源财务数据清洗迁移——审计场景实战

使用 Oracle PL/SQL 构建的多源异构财务数据清洗迁移流水线，覆盖用友NC、金蝶、Excel手工台账三套系统的数据标准化、审计校验与可追溯性设计。

## 项目背景

审计公司对被审计单位进行财务审计时，数据往往来自多个异构系统，格式不统一、质量参差不齐。本项目模拟了这一场景，构建完整的数据清洗迁移流水线。

## 系统架构

```
用友NC ────┐
金蝶 ──────┤
Excel台账 ─┘
    │
    ▼
[数据质量探查] ── 4维度检查：完整性/合法性/唯一性/一致性
    │
    ▼
[清洗存储过程] ── 一键执行：日期标准化/金额清洗/编码清洗/迁移/异常隔离
    │
    ▼
[科目映射] ── acc_mapping 表统一多系统科目编码
    │
    ▼
[质量闸门] ── 四级检查过滤 → aud_rejected 异常表
    │
    ▼
[标准审计库] ── aud_voucher (146条)
    │
    ▼
[审计校验] ── 试算平衡 / 异常追溯 / 操作日志
```

## 三套源系统的异构挑战

| 系统 | 数据量 | 特殊问题 | 处理方案 |
|------|--------|---------|---------|
| 用友NC | 64条 | 科目编码含空格/制表符、日期3种格式混用、金额带逗号 | 4种日期格式分别TO_DATE、嵌套REPLACE去逗号空格、TRIM编码 |
| 金蝶 | 44条 | 科目编码带段位号(1001.01)、存在完全重复行、借贷方向出现'Z' | ROW_NUMBER() OVER去重、段位号映射 |
| 手工台账 | 50条 | 借贷方向为中文("借方"/"贷方"/"借"/"贷")、日期格式混乱 | LIKE '%借%' → 'D'、LIKE '%贷%' → 'C' |

## 自动化：一键清洗存储过程

将手动15步操作封装为3个参数化存储过程，一行调用完成全流程：

```sql
CALL sp_cleanse_uf();       -- 用友：探查 → 清洗 → 迁移 → 日志 → 异常隔离
CALL sp_cleanse_kd();       -- 金蝶：探查 → 清洗 → 去重 → 迁移 → 日志
CALL sp_cleanse_manual();   -- 手工：探查 → 清洗 → 中文方向转换 → 迁移 → 日志
```

每个过程自动完成6步操作：加清洗列 → 日期标准化 → 金额清洗 → 编码清洗 → 质量闸门迁移 → 异常数据隔离，全程记录到 `aud_log`。

## 核心 SQL 技能

### 数据探查
- `COUNT(*)` vs `COUNT(列名)` —— NULL 检测
- `GROUP BY + HAVING COUNT(*) > 1` —— 重复检测
- `REGEXP_LIKE(v_date, '^\d{4}-\d{2}-\d{2}')` —— 日期格式识别

### 数据清洗
- `TO_DATE(v, 'YYYY/MM/DD')` —— 多格式日期标准化
- `TO_NUMBER(REPLACE(REPLACE(amount, ','), ' '))` —— 金额去分隔符转数字
- `REPLACE(REPLACE(TRIM(code), CHR(9)), ' ')` —— 科目编码去除隐藏字符
- `ROW_NUMBER() OVER(PARTITION BY ...)` —— 完全重复行去重

### 审计校验
- `SUM(CASE WHEN dr_cr='D' THEN amount ELSE -amount END)` —— 试算平衡
- `ABS(diff) < 0.01` —— 浮点误差容忍
- 异常数据隔离 + 操作日志记录 —— 审计可追溯

## 成果数据流统计

| 阶段 | 表名 | 行数 |
|------|------|------|
| 用友源数据 | src_voucher_uf | 64 |
| 金蝶源数据 | src_voucher_kd | 44 |
| 手工台账源数据 | src_manual | 50 |
| **源数据合计** | | **158** |
| 清洗入库 | aud_voucher | **146** |
| 异常隔离 | aud_rejected | 14+ |
| 操作日志 | aud_log | 10+ |
| 试算平衡 | aud_trial_balance | 1 |

## 项目结构

```
audit-data-migration/
├── sql/
│   ├── 01_create_tables.sql      # 建表脚本 (8张表)
│   └── 02_insert_dirty_data.sql  # 脏数据 (3套系统 + 科目映射)
├── images/
│   └── (成果截图)
├── 学习总结.docx                  # 完整学习笔记 (含面试10问)
└── README.md
```

## 环境搭建

```bash
# Docker 拉取 Oracle XE
docker run -d --name oracle-xe -p 1521:1521 -e ORACLE_PASSWORD=test123 gvenzl/oracle-xe

# DBeaver 连接参数
Host: localhost | Port: 1521 | SID: XE | User: system | Password: test123
```

## 面试相关技能清单

- Oracle PL/SQL 数据清洗（TO_DATE / TO_NUMBER / REGEXP_LIKE / REPLACE / TRIM）
- 多源异构数据标准化（不同系统的科目编码体系、日期格式、方向表示）
- 财务数据试算平衡校验（SUM CASE WHEN 条件聚合）
- 完全重复行检测与去重（ROW_NUMBER OVER PARTITION）
- 存储过程封装（EXECUTE IMMEDIATE + COMMIT + EXCEPTION）
- 审计数据可追溯性设计（异常表 + 日志表）
- Data Pump 数据迁移 (expdp/impdp)
- SQL*Loader 外部文件加载

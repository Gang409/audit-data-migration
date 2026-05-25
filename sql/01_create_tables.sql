-- 多源财务数据清洗迁移审计系统 - 建表脚本

-- 删除旧表（如果存在）
DROP TABLE aud_trial_balance CASCADE CONSTRAINTS;
DROP TABLE aud_rejected CASCADE CONSTRAINTS;
DROP TABLE aud_log CASCADE CONSTRAINTS;
DROP TABLE aud_voucher CASCADE CONSTRAINTS;
DROP TABLE acc_mapping CASCADE CONSTRAINTS;
DROP TABLE src_manual CASCADE CONSTRAINTS;
DROP TABLE src_voucher_kd CASCADE CONSTRAINTS;
DROP TABLE src_voucher_uf CASCADE CONSTRAINTS;

-- 1. 用友NC系统凭证表
CREATE TABLE src_voucher_uf (
    voucher_id      VARCHAR2(50),
    company         VARCHAR2(100),
    acc_code        VARCHAR2(50),
    acc_name        VARCHAR2(200),
    voucher_date    VARCHAR2(50),
    amount          VARCHAR2(50),
    dr_cr           VARCHAR2(1),
    summary         VARCHAR2(500),
    last_mod_time   DATE
);

-- 2. 金蝶系统凭证表
CREATE TABLE src_voucher_kd (
    voucher_id      VARCHAR2(50),
    company         VARCHAR2(100),
    acc_code        VARCHAR2(50),
    acc_name        VARCHAR2(200),
    voucher_date    VARCHAR2(50),
    amount          VARCHAR2(50),
    dr_cr           VARCHAR2(1),
    summary         VARCHAR2(500),
    last_mod_time   DATE
);

-- 3. 手工台账（Excel导入）
CREATE TABLE src_manual (
    row_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    voucher_no      VARCHAR2(50),
    company         VARCHAR2(100),
    account_code    VARCHAR2(50),
    account_name    VARCHAR2(200),
    trans_date      VARCHAR2(50),
    trans_amount    VARCHAR2(50),
    direction       VARCHAR2(10),
    remarks         VARCHAR2(500),
    input_time      DATE DEFAULT SYSDATE
);

-- 4. 标准审计凭证表（目标表）
CREATE TABLE aud_voucher (
    audit_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_system   VARCHAR2(50),
    voucher_id      VARCHAR2(50) NOT NULL,
    company         VARCHAR2(100),
    acc_code_std    VARCHAR2(50),
    acc_name        VARCHAR2(200),
    voucher_date    DATE NOT NULL,
    amount          NUMBER(18,2) NOT NULL,
    dr_cr           VARCHAR2(1) NOT NULL,
    summary         VARCHAR2(500),
    cleanse_batch   VARCHAR2(50),
    cleanse_time    DATE DEFAULT SYSDATE
);

-- 5. 科目映射表
CREATE TABLE acc_mapping (
    source_system   VARCHAR2(50),
    old_code        VARCHAR2(50),
    new_code        VARCHAR2(50),
    new_name        VARCHAR2(200)
);

-- 6. 清洗日志表
CREATE TABLE aud_log (
    log_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id        VARCHAR2(50),
    step_name       VARCHAR2(100),
    rule_desc       VARCHAR2(500),
    rows_affected   NUMBER,
    status          VARCHAR2(20),
    error_detail    VARCHAR2(1000),
    exec_time       DATE DEFAULT SYSDATE
);

-- 7. 异常数据表
CREATE TABLE aud_rejected (
    reject_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_system   VARCHAR2(50),
    voucher_id      VARCHAR2(50),
    reject_reason   VARCHAR2(500),
    raw_data        VARCHAR2(1000),
    reject_time     DATE DEFAULT SYSDATE
);

-- 8. 试算平衡校验结果表
CREATE TABLE aud_trial_balance (
    check_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id        VARCHAR2(50),
    total_debit     NUMBER(18,2),
    total_credit    NUMBER(18,2),
    difference      NUMBER(18,2),
    is_balanced     VARCHAR2(1),
    check_time      DATE DEFAULT SYSDATE
);

COMMIT;

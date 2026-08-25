---
title: Java 金额用 long 还是 BigDecimal？
description: Java 金额类型选择指南：讲清 long 存储最小货币单位与 BigDecimal 进行精确计算的适用场景，以及舍入、溢出、单位转换和数据库字段设计。
category: Java
tag:
  - Java基础
  - Java金额计算
head:
  - - meta
    - name: keywords
      content: Java金额类型,long存金额,Long存分,BigDecimal金额计算,金额精度,金额舍入,DECIMAL,BIGINT
---

我在一篇讨论金额字段类型的文章评论区里，看到几种完全不同的答案：有人坚持用 `Long` 存分，有人说利息、汇率这类场景要用 `BigDecimal`，还有人提到接口里直接传字符串。

这些说法讨论的不是同一件事。用 `Long` 存分，说的是金额如何保存；利息和汇率用 `BigDecimal`，说的是金额如何计算；接口传字符串，通常只是数据传输格式。

已经确定最小单位的金额可以用 `long` 保存。计算过程中需要保留小数，或者要明确指定舍入方式，则使用 `BigDecimal`。两种类型可以出现在同一个系统里。

下文提到的 Long 方案，都是指用整数保存最小货币单位。Java 代码参与运算时通常使用基本类型 `long`，需要表达空值时才使用包装类型 `Long`。

| 对比项         | `long`                                   | `BigDecimal`                     |
| -------------- | ---------------------------------------- | -------------------------------- |
| 表示方式       | 固定最小单位的整数                       | 带 `scale` 的十进制数            |
| 常见用途       | 已确定最小单位的订单金额、余额、入账金额 | 折扣、税费、利率、汇率计算       |
| 主要风险       | 单位混淆、静默溢出、精度难扩展           | 构造方式、舍入规则、`scale` 差异 |
| 常见数据库类型 | `BIGINT`                                 | `DECIMAL(p, s)`                  |

## 为什么金额不能用 double？

`double` 和 `float` 保存的是二进制浮点数。很多有限位的十进制小数，换成二进制后会变成无限循环小数，只能取一个最接近的可表示值。

```java
double a = 1.0;
double b = 0.9;

System.out.println(a - b);
// 0.09999999999999998

System.out.println(0.1 + 0.1 + 0.1);
// 0.30000000000000004
```

这个误差与 Java 实现无关，采用 IEEE 754 二进制浮点数的语言都会遇到。金额计算通常要求结果遵循明确的十进制精度和舍入规则，近似值很难满足这个要求。

`new BigDecimal(0.1)` 可以把 `double` 中保存的近似值完整展示出来：

```java
System.out.println(new BigDecimal(0.1));
// 0.1000000000000000055511151231257827021181583404541015625
```

这也是为什么金额对象不应该从 `double` 构造。一个已经产生误差的值，再转成 `BigDecimal` 并不会自动恢复成原来的十进制小数。

## 哪些金额适合用 Long？

如果业务规定人民币金额统一精确到分，那么 `19.99` 元可以保存为 `1999` 分。加减法都在整数上完成，不会产生小数误差。

```java
long priceCents = 1_999L;
long shippingCents = 500L;
long totalCents = Math.addExact(priceCents, shippingCents);
```

`long` 适合订单金额、账户余额、支付金额这类已经完成舍入的值，数据库中可以使用 `BIGINT`。

数据库存储的时候，字段名最好带上单位，这样看着更直观一些：

```sql
CREATE TABLE orders (
    id           BIGINT PRIMARY KEY,
    amount_cents BIGINT NOT NULL
);
```

如果用 `amount` 的话，`amount = 100` 到底表示 100 元还是 100 分，只看数值无法判断。换成 `amount_cents = 100`，就不一样了。

**使用 long 时要注意什么？**

把金额统一存成分，精度也被固定在了两位小数。汇率、利息、税费或者按量计费的中间结果可能需要四位、六位甚至更多小数，这些计算不能继续拿“分”硬算。

还要防止溢出。普通的 `+` 和 `*` 在溢出后不会报错，金额代码可以改用 `Math.addExact()`、`Math.subtractExact()` 和 `Math.multiplyExact()`：

```java
long subtotalCents = Math.multiplyExact(unitPriceCents, quantity);
long balanceCents = Math.subtractExact(currentBalanceCents, paymentCents);
```

乘法还要检查中间结果。最终金额没有超过 `Long.MAX_VALUE`，不代表 `单价 × 数量 × 倍率` 的某一步也不会溢出。

多币种系统也不能假设所有货币都有两位小数。金额至少要和币种一起出现，最小单位位数由币种或业务规则决定，不能从一个孤立的 `long` 值中推断出来。

## 哪些金额适合用 BigDecimal？

折扣、税费、利息和汇率换算经常产生超过货币最小单位的中间结果。

`BigDecimal` 用任意精度整数和 `scale` 表示十进制数，能够把这些中间值保留下来，再在业务规定的位置舍入。

```java
BigDecimal price = new BigDecimal("19.99");
BigDecimal discountRate = new BigDecimal("0.95");

BigDecimal discountedPrice = price.multiply(discountRate);
// 18.9905
```

金额常量直接使用字符串构造。接口传过来的是字符串就直接转成 `BigDecimal`，数据库字段是 `DECIMAL` 就直接映射成 `BigDecimal`，中间不需要再转成 `double`。

**如果 `divide()` 除不尽的话，怎么办呢？**

这个时候需要指定保留位数和舍入方式。

下面的代码的意思就是保留两位小数，并使用 `HALF_UP`（四舍五入）。如果直接调用 `a.divide(b)`，程序会抛出 `ArithmeticException`。

```java
BigDecimal a = new BigDecimal("10");
BigDecimal b = new BigDecimal("3");

System.out.println(a.divide(b, 2, RoundingMode.HALF_UP)); // 3.33
```

还有一点需要注意：`BigDecimal` 是不可变类，运算结果要用新的变量接收，或者重新赋值。第一次调用 `add()` 时没有接收返回值，`amount` 还是 `10.00`：

```java
BigDecimal amount = new BigDecimal("10.00");

amount.add(new BigDecimal("2.00"));
System.out.println(amount); // 仍然是 10.00

amount = amount.add(new BigDecimal("2.00"));
System.out.println(amount); // 12.00
```

比较金额大小一般使用 `compareTo()`。`equals()` 还会比较 `scale`，所以 `1.0` 和 `1.00` 调用 `equals()` 的结果为 `false`：

```java
BigDecimal a = new BigDecimal("1.0");
BigDecimal b = new BigDecimal("1.00");

System.out.println(a.equals(b));         // false
System.out.println(a.compareTo(b) == 0); // true
```

这个差异也会影响 `HashMap` 和 `HashSet`。如果用 `BigDecimal` 作为键，最好先统一 `scale`，否则 `1.0` 和 `1.00` 会被当成两个键。

## Long 和 BigDecimal 可以一起用吗？

可以。以商品单价 `19.99` 元、购买 3 件、折扣 `0.95` 为例，计算时使用 `BigDecimal`，最终支付金额再转成以分为单位的 `long`：

```java
BigDecimal unitPrice = new BigDecimal("19.99");
BigDecimal discountRate = new BigDecimal("0.95");
long quantity = 3L;

BigDecimal payable = unitPrice
        .multiply(BigDecimal.valueOf(quantity))
        .multiply(discountRate)
        .setScale(2, RoundingMode.HALF_UP);

long payableCents = payable
        .movePointRight(2)
        .longValueExact();
```

这段代码算出的 `payable` 是 `56.97`，`movePointRight(2)` 将其转换为 `5697`。`longValueExact()` 只接受 `long` 范围内的整数，只要还有非零小数部分或者数值越界，就会抛出 `ArithmeticException`。

金额转换不要直接使用 `longValue()`，它会丢掉小数部分：

```java
long amount = new BigDecimal("19.99").longValue();
System.out.println(amount); // 19
```

如果输入金额最多只能有两位小数，还可以使用 `RoundingMode.UNNECESSARY` 做校验：

```java
public static long toCentsExact(BigDecimal amount) {
    return amount
            .setScale(2, RoundingMode.UNNECESSARY)
            .movePointRight(2)
            .longValueExact();
}

public static BigDecimal fromCents(long cents) {
    return BigDecimal.valueOf(cents, 2);
}
```

`19.9` 可以补成 `19.90`，`19.999` 则会直接抛出异常，不会悄悄截断或者四舍五入。

支付接口接收分，就传 `5697`；接收以元为单位的字符串，就传 `payable.toPlainString()`。转换代码放在接口适配层，业务计算过程中不要来回切换类型和单位。

## 数据库应该用 BIGINT 还是 DECIMAL？

Java 中使用 `long` 保存最小单位，数据库字段一般使用 `BIGINT`；Java 中使用 `BigDecimal`，数据库字段一般使用 `DECIMAL(p, s)`。

```sql
CREATE TABLE settlement_detail (
    id               BIGINT PRIMARY KEY,
    payable_cents    BIGINT        NOT NULL,
    exchange_rate    DECIMAL(18, 8) NOT NULL,
    settlement_amount DECIMAL(18, 2) NOT NULL
);
```

MySQL 把整数和 `DECIMAL` 都归为精确值类型。`DECIMAL(18, 2)` 中的 `18` 是总有效位数，`2` 是小数位数；它能否覆盖业务金额，要按最大值反推，不能见到金额字段就统一套一个精度。

不要依赖 MySQL 在写入 `DECIMAL` 时自动舍入。Java 代码先调用 `setScale()` 舍入或校验，再把结果写入数据库，这样入库值和程序计算结果才能对得上。

金额字段是否使用 `DEFAULT 0` 要看业务含义。缺失金额和金额为零并不总是一回事，随手加默认值可能掩盖漏传数据。`NOT NULL` 通常值得保留，默认值则应由领域规则决定。

## 总结

已经完成舍入、最小单位固定的金额，适合用 `long` 保存；折扣、税费、利率和汇率等需要保留小数的计算，使用 `BigDecimal`。舍入时要写明保留位数和 `RoundingMode`。

两种类型可以一起用。计算阶段保留 `BigDecimal`，最终金额确定后，先按最小单位位数移动小数点，再用 `longValueExact()` 转成整数。字段名要写清单位，整数运算要检查溢出，类型和单位的转换集中放在接口或数据库适配代码中。

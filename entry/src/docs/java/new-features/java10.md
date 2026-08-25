---
title: Java 10 新特性概览
description: 概览 JDK 10 的主要更新，重点介绍 var 类型推断与其他平台改进。
category: Java
tag:
  - Java新特性
head:
  - - meta
    - name: keywords
      content: Java 10,JDK10,var 局部变量类型推断,垃圾回收改进,性能
---

**Java 10** 发布于 2018 年 3 月 20 日，这是一个非 LTS（长期支持）版本，Oracle 仅提供六个月的支持。

下图是从 JDK 8 到 JDK 25 每个版本的更新带来的新特性数量和更新时间：

![ JDK 8 到 JDK 25 每个版本的更新带来的新特性数量和更新时间](https://oss.javaguide.cn/github/javaguide/java/new-features/jdk8~jdk24.png)

这篇文章会挑选其中较为重要的一些新特性进行详细介绍：

- [JEP 286: Local-Variable Type Inference（局部变量类型推断）](https://openjdk.org/jeps/286)
- [JEP 304: Garbage-Collector Interface（垃圾回收器接口）](https://openjdk.org/jeps/304)
- [JEP 307: Parallel Full GC for G1（G1 并行 Full GC）](https://openjdk.org/jeps/307)
- [JEP 310: Application Class-Data Sharing（应用程序类数据共享）](https://openjdk.org/jeps/310)
- [JEP 317: Experimental Java-Based JIT Compiler（实验性的基于 Java 的 JIT 编译器）](https://openjdk.org/jeps/317)

## JEP 286: Local-Variable Type Inference

由于太多 Java 开发者希望 Java 中引入局部变量类型推断，于是 Java 10 的时候它来了，也算是众望所归了！

Java 10 提供了 `var` 关键字声明局部变量。

```java
var id = 0;
var codefx = new URL("https://mp.weixin.qq.com/");
var list = new ArrayList<>();
var list = List.of(1, 2, 3);
var map = new HashMap<String, String>();
var p = Paths.of("src/test/java/Java9FeaturesTest.java");
var numbers = List.of("a", "b", "c");
for (var n : numbers)
    System.out.print(n+ " ");
```

`var` 只能用于有初始化器的局部变量声明，也可以用于基本或增强 `for` 循环中的局部变量，以及 `try`-with-resources 的资源变量。它不能用于字段、方法参数或返回类型。

```java
var count = null; //❌编译不通过，不能声明为 null
var r = () -> Math.random();//❌编译不通过，不能声明为 Lambda表达式
var array = {1, 2, 3};//❌编译不通过，不能声明数组
```

`var` 并不会改变 Java 是一门静态类型语言的事实，编译器负责推断出类型。

另外，Scala 和 Kotlin 中已经有了 `val` 关键字 ( `final var` 组合关键字)。

## JEP 304: Garbage-Collector Interface

在早期的 JDK 结构中，组成垃圾收集器 (GC) 实现的组件分散在代码库的各个部分。 Java 10 通过引入一套纯净的垃圾收集器接口来将不同垃圾收集器的源代码分隔开。

## JEP 307: Parallel Full GC for G1

从 Java 9 开始 G1 就成了默认的垃圾回收器，G1 是以一种低延时的垃圾回收器来设计的，旨在避免进行 Full GC，但是 Java 9 的 G1 的 Full GC 依然是使用单线程去完成标记清除算法，这可能会导致垃圾回收器在无法回收内存的时候触发 Full GC。

为了减少 Full GC 造成的应用停顿，从 Java 10 开始，G1 的 Full GC 改为使用多个并行工作线程执行标记、清除和压缩。这个变化缩短的是 Full GC 的停顿时间，并不会直接减少 Full GC 的触发次数。

## JEP 310: **应用程序类数据共享（扩展 CDS 功能）**

Java 5 已经引入类数据共享机制（Class Data Sharing，简称 CDS），允许将一组系统类预处理为共享归档文件，以便在运行时进行内存映射，从而减少 Java 程序的启动时间和多个 JVM 的内存占用。将应用类加入共享归档的 AppCDS 此前只在 Oracle JDK 中作为商业特性提供。

Java 10 在现有 CDS 功能基础上进一步扩展并开放 AppCDS，允许应用类放入共享归档。典型流程是先生成应用类列表，再根据类列表创建共享归档，后续启动时通过内存映射加载该归档；类列表文本本身并不是 JVM 在后续启动时直接加载的缓存。

## JEP 317: **实验性的基于 Java 的 JIT 编译器**

Graal 是一个基于 Java 语言编写的 JIT 编译器，是 JDK 9 中引入的实验性 Ahead-of-Time (AOT) 编译器的基础。

Oracle 的 HotSpot VM 便附带两个用 C++ 实现的 JIT compiler：C1 及 C2。在 Java 10 (Linux/x64, macOS/x64) 中，默认情况下 HotSpot 仍使用 C2，但通过向 java 命令添加 `-XX:+UnlockExperimentalVMOptions -XX:+UseJVMCICompiler` 参数便可将 C2 替换成 Graal。

## API 增强

并不是所有的 API 改动都会通过 JEP（Java Enhancement Proposal）来发布。

在 JDK 的开发流程中：**JEP** 通常用于重大的改变，例如引入新的语言特性（如 `var`）、新的 JVM 机制（如 ZGC）或者大规模的库重构。像 `List.copyOf()` 这种在现有类中增加几个静态方法的操作，通常被视为常规的库维护。它们由 JDK 开发者直接通过 **JBS (JDK Bug System)** 的工单（Ticket）进行提交和评审，然后随版本直接发布。

### 集合增强

`List`，`Set`，`Map` 提供了静态方法 `copyOf()` 返回入参集合的一个不可变拷贝。

```java
static <E> List<E> copyOf(Collection<? extends E> coll) {
    return ImmutableCollections.listCopy(coll);
}
```

使用 `copyOf()` 创建的集合为不可变集合，不能进行添加、删除、替换、 排序等操作，不然会报 `java.lang.UnsupportedOperationException` 异常。 IDEA 也会有相应的提示。

![使用 `copyOf()` 创建的集合为不可变集合](https://oss.javaguide.cn/java-guide-blog/image-20210816154125579.png)

并且，`java.util.stream.Collectors` 中新增了静态方法，用于将流中的元素收集为不可变的集合。

```java
var list = new ArrayList<>();
list.stream().collect(Collectors.toUnmodifiableList());
list.stream().collect(Collectors.toUnmodifiableSet());
```

### Optional 增强

`Optional` 新增了一个无参的 `orElseThrow()` 方法，作为带参数的 `orElseThrow(Supplier<? extends X> exceptionSupplier)` 的简化版本，在没有值时默认抛出一个 NoSuchElementException 异常。

```java
Optional<String> optional = Optional.empty();
String result = optional.orElseThrow();
```

## 其他

- **线程-局部管控**：Java 10 中线程管控引入 JVM 安全点的概念，将允许在不运行全局 JVM 安全点的情况下实现线程回调，由线程本身或者 JVM 线程来执行，同时保持线程处于阻塞状态，这种方式使得停止单个线程变成可能，而不是只能启用或停止所有线程
- **备用存储装置上的堆分配**：Java 10 中将使得 JVM 能够使用适用于不同类型的存储机制的堆，在可选内存设备上进行堆内存分配
- ……

## 参考

- Java 10 Features and Enhancements : <https://howtodoinjava.com/java10/java10-features/>

- Guide to Java10 : <https://www.baeldung.com/java-10-overview>

- 4 Class Data Sharing : <https://docs.oracle.com/javase/10/vm/class-data-sharing.htm#JSJVM-GUID-7EAA3411-8CF0-4D19-BD05-DF5E1780AA91>

<!-- @include: @article-footer.snippet.md -->

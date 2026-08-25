---
title: 红黑树详解（性质、旋转、应用）
description: 深入讲解红黑树的五大性质与旋转调整过程，理解自平衡机制及在标准库与索引结构中的应用。
category: 计算机基础
tag:
  - 数据结构
head:
  - - meta
    - name: keywords
      content: 红黑树,自平衡,旋转,插入删除,性质,黑高,时间复杂度
---

# 红黑树

## 红黑树介绍

红黑树（Red Black Tree）是一种自平衡二叉查找树。它是在 1972 年由 Rudolf Bayer 发明的，当时被称为平衡二叉 B 树（symmetric binary B-trees）。后来，在 1978 年被 Leo J. Guibas 和 Robert Sedgewick 修改为如今的“红黑树”。

由于其自平衡的特性，保证了最坏情形下在 O(logn) 时间复杂度内完成查找、增加、删除等操作，性能表现稳定。

在 JDK 中，`TreeMap`、`TreeSet` 以及 JDK1.8 的 `HashMap` 底层都用到了红黑树。

## 为什么需要红黑树？

红黑树的诞生就是为了解决二叉查找树的缺陷。

二叉查找树是一种基于比较的数据结构，它的每个节点都有一个键值，而且左子节点的键值小于父节点的键值，右子节点的键值大于父节点的键值。这样的结构可以方便地进行查找、插入和删除操作，因为只需要比较节点的键值就可以确定目标节点的位置。但是，二叉查找树有一个很大的问题，就是它的形状取决于节点插入的顺序。如果节点是按照升序或降序的方式插入的，那么二叉查找树就会退化成一个线性结构，也就是一个链表。这样的情况下，二叉查找树的性能就会大大降低，时间复杂度就会从 O(logn) 变为 O(n)。

红黑树的诞生就是为了解决二叉查找树的缺陷，因为二叉查找树在某些情况下会退化成一个线性结构。

## 红黑树特点

1. 每个节点非红即黑。
2. 根节点总是黑色的。
3. 每个空子链接都视为黑色的 NIL 叶节点。
4. 如果节点是红色的，则它的子节点必须是黑色的，也就是不会出现连续的红色节点。
5. 从任意节点到其所有后代 NIL 节点的每条路径，都包含相同数量的黑色节点，即具有相同的黑高。

在红黑树与 2-3 树的对应关系中，一个黑节点和与其相连的红节点可以共同表示一个多键节点。这只是一种结构映射，红黑树节点本身始终至多有两个子节点。

正是这些特点才保证了红黑树的平衡，让红黑树的高度不会超过 2log(n+1)。

## 红黑树数据结构

AVL 树和红黑树都是自平衡二叉搜索树，2-3 树则是多路搜索树。红黑树可以与 2-3 树或 2-3-4 树建立结构对应，但它们不能统称为 B 树。相比 AVL 树，红黑树的平衡条件更宽松，它通过颜色规则和黑高约束限制树高。

## 红黑树结构实现

```java
public class Node {

    public Class<?> clazz;
    public Integer value;
    public Node parent;
    public Node left;
    public Node right;

    // AVL 树所需属性
    public int height;
    // 红黑树所需属性
    public Color color = Color.RED;

}
```

### 1. 左倾染色

![红黑树左倾染色示意图](https://oss.javaguide.cn/github/javaguide/cs-basics/data-structure/red-black-tree-1.png)

- 染色时根据当前节点的爷爷节点，找到当前节点的叔叔节点。
- 再把父节点染黑、叔叔节点染黑，爷爷节点染红。但爷爷节点染红是临时的，当平衡树高操作后会把根节点染黑。

### 2. 右倾染色

![红黑树右倾染色示意图](https://oss.javaguide.cn/github/javaguide/cs-basics/data-structure/red-black-tree-2.png)

### 3. 左旋调衡

#### 3.1 一次左旋

![红黑树一次左旋调衡示意图](https://oss.javaguide.cn/github/javaguide/cs-basics/data-structure/red-black-tree-3.png)

#### 3.2 右旋 + 左旋

![红黑树右旋加左旋调衡示意图](https://oss.javaguide.cn/github/javaguide/cs-basics/data-structure/red-black-tree-4.png)

### 4. 右旋调衡

#### 4.1 一次右旋

![红黑树一次右旋调衡示意图](https://oss.javaguide.cn/github/javaguide/cs-basics/data-structure/red-black-tree-5.png)

#### 4.2 左旋 + 右旋

![红黑树左旋加右旋调衡示意图](https://oss.javaguide.cn/github/javaguide/cs-basics/data-structure/red-black-tree-6.png)

## 面试复盘重点

红黑树面试一般不会要求完整手写插入删除修复，更常见的是让你说清性质、为什么近似平衡、和 AVL 树有什么区别、Java 里哪里用到了。

| 对比点   | AVL 树             | 红黑树                               |
| -------- | ------------------ | ------------------------------------ |
| 平衡要求 | 更严格             | 相对宽松                             |
| 查询性能 | 更稳定             | 也能保持 `O(logn)`                   |
| 插入删除 | 旋转调整可能更多   | 调整次数通常更少                     |
| 常见应用 | 读多写少的搜索结构 | `TreeMap`、`TreeSet`、`HashMap` 树化 |

面试回答可以按这个顺序组织：

1. 普通二叉搜索树在有序插入时会退化成链表。
2. 红黑树通过颜色规则限制树高，保证查询、插入、删除仍然是 `O(logn)`。
3. 它不是完全平衡，而是近似平衡，所以插入删除时调整成本比 AVL 树更低。
4. Java 中 `TreeMap`、`TreeSet` 基于红黑树，JDK 8 后 `HashMap` 链表过长时也会树化为红黑树。

`HashMap` 树化还要满足容量条件，并不是链表长度到阈值就一定树化。这个细节在 Java 集合面试里经常被追问。

<!-- @include: @article-footer.snippet.md -->
